#include <cstring>
#include <iostream>
#include <fstream>
#include "Vjts16_game.h"
#include "verilated_vcd_c.h"

using namespace std;

typedef Vjts16_game DUT;

class SDRAM {
    DUT& dut;
    char *banks[4];
    int dly[4];
    //int last_rd[5];
    char header[32];
    int read_offset( int region );
    int read_bank( char *bank, int addr );
public:
    SDRAM(DUT& _dut);
    ~SDRAM();
    void update();
};

const int VIDEO_BUFLEN = 256;

class JTSim {
    vluint64_t simtime;
    const vluint64_t semi_period=9930;

    void parse_args( int argc, char *argv[] );
    void video_dump();
    bool trace;
    VerilatedVcdC* tracer;
    SDRAM sdram;
    int frame_cnt, last_VS;
    // Video dump
    struct {
        ofstream fout;
        int ptr;
        int32_t buffer[VIDEO_BUFLEN];
    } dump;
public:
    int finish_time, finish_frame;
    bool done() {
        return (finish_time>0 ? frame_cnt > finish_frame : true) &&
                simtime/1000'000'000 >= finish_time;
    };
    Vjts16_game& game;
    JTSim( Vjts16_game& g, int argc, char *argv[] );
    ~JTSim();
    void clock(int n);
};

int main(int argc, char *argv[]) {
    Verilated::commandArgs(argc, argv);

    Vjts16_game game;
    JTSim sim(game, argc, argv);

    while( !sim.done() ) {
        sim.clock(10'000);
    }

    return 0;
}

int SDRAM::read_bank( char *bank, int addr ) {
    const int mask = 0x7f'ffff; // 8MB
    addr <<= 1;
    int v=0;
    for( int k=2; k>=0; k-- ) {
        v <<= 8;
        v |= bank[(addr+k)&mask]&0xff;
    }
    return v;
}

void SDRAM::update() {
    CData *ba_ack   = &dut.ba_ack;
    CData *ba_rdy   = &dut.ba_rdy;
    CData *ba_dst   = &dut.ba_dst;
    unsigned ba_rd  = dut.ba_rd;
    unsigned ba_add[4] = { dut.ba0_addr, dut.ba1_addr, dut.ba2_addr, dut.ba3_addr };

    if( dut.rst ) {
        *ba_ack = 0;
        *ba_rdy = 0;
        for( int k=0; k<4; k++ ) {
            //last_rd[k] = 0;
            dly[k] = -1;
        }
        return;
    }

    bool dout=false;
    *ba_dst = 0;
    *ba_rdy = 0;
    for( int k=0; k<4; k++) {
        // Data output at dly==1 and dly==0
        if( dly[k] == 1 && !dout) {
            dut.data_read = read_bank( banks[k], ba_add[k] );
            *ba_dst |= 1<<k;
            dout=true;
        }
        if( dly[k] == 0 && !dout) {
            dut.data_read = read_bank( banks[k], ba_add[k]+1 );
            *ba_rdy |= 1<<k;
            dly[k] = -1;
            dout=true;
            continue;
        }

        if( (ba_rd &(1<<k)) && dly[k]<0) {
            dly[k]    = 8;
            unsigned aux = *ba_rdy & ~(1<<k);
            *ba_rdy = aux;
            aux = *ba_ack | (1<<k);
            *ba_ack = aux;
        } else {
            if( dly[k]==7) *ba_ack = 0;
            if( dly[k]>0 ) --dly[k];
        }
    }
}

int SDRAM::read_offset( int region ) {
    if( region>=32 ) {
        region = 0;
        printf("ERROR: tried to read past the header\n");
        return 0;
    }
    int offset = (((int)header[region]<<8) | ((int)header[region+1]&0xff)) & 0xffff;
    return offset<<8;
}

SDRAM::SDRAM(DUT& _dut) : dut(_dut) {
    banks[0] = nullptr;
    for( int k=0; k<4; k++ ) {
        banks[k] = new char[0x80'0000];
        dly[k]=-1;
        // Try to load a file for it
        char fname[32];
        sprintf(fname,"sdram_bank%d.bin",k);
        ifstream fin( fname, ios_base::binary );
        if( fin ) {
            fin.read( banks[k], 0x80'0000 );
        }
    }
}

SDRAM::~SDRAM() {
    for( int k=0; k<4; k++ ) {
        delete [] banks[k];
        banks[k] = nullptr;
    }
}

JTSim::JTSim( Vjts16_game& g, int argc, char *argv[]) : game(g), sdram(g) {
    simtime=0;
    frame_cnt=0;
    last_VS = 0;

    // Video dump
    dump.fout.open("video.pipe", ios_base::binary );
    dump.ptr = 0;

    parse_args( argc, argv );
#ifdef VERILATOR_TRACE
    if( trace ) {
        Verilated::traceEverOn(true);
        tracer = new VerilatedVcdC;
        game.trace( tracer, 99 );
        tracer->open("test.vcd");
    } else {
        tracer = nullptr;
    }
#endif
    game.gfx_en=0xf;    // enable all layers
    game.rst = 1;
    clock(10);
    game.rst = 0;
    clock(10);
}

JTSim::~JTSim() {
    dump.fout.write( (char*) dump.buffer, dump.ptr*4 ); // flushes the buffer
#ifdef VERILATOR_TRACE
    delete tracer;
#endif
}

void JTSim::clock(int n) {
    while( n-- > 0 ) {
        sdram.update();
        game.clk = 1;
        game.eval();
        simtime += semi_period;
#ifdef VERILATOR_TRACE
        if( tracer ) tracer->dump(simtime);
#endif
        game.clk = 0;
        game.eval();
        simtime += semi_period;
#ifdef VERILATOR_TRACE
        if( tracer ) tracer->dump(simtime);
#endif
        // frame counter
        if( game.VS && !last_VS ) frame_cnt++;
        last_VS = game.VS;

        // Video dump
        video_dump();
    }
}

void JTSim::video_dump() {
    if( game.pxl_cen && game.LHBL_dly && game.LVBL_dly ) {
        int red   = game.red   & 0x1f;
        int green = game.green & 0x1f;
        int blue  = game.blue  & 0x1f;
        int mix = 0xFF000000 |
            ( ((blue <<3)|(blue>>2 )) << 16 ) |
            ( ((green<<3)|(green>>2)) <<  8 ) |
            ( ((red  <<3)|(red>>2))         );
        dump.buffer[dump.ptr++] = mix;
        if( dump.ptr==256 ) {
            dump.fout.write( (char*)dump.buffer, VIDEO_BUFLEN*4 );
            dump.ptr=0;
        }
    }
}

void JTSim::parse_args( int argc, char *argv[] ) {
    trace = false;
    finish_frame = -1;
    finish_time  = 10;
    for( int k=1; k<argc; k++ ) {
        if( strcmp( argv[k], "--trace")==0 ) {
            trace=true;
            continue;
        }
        if( strcmp( argv[k], "-time")==0 ) {
            if( ++k >= argc ) {
                cout << "ERROR: expecting time after -time argument\n";
            } else {
                finish_time = atol(argv[k]);
            }
            continue;
        }
        if( strcmp( argv[k], "-frame")==0 ) {
            if( ++k >= argc ) {
                cout << "ERROR: expecting frame count after -frame argument\n";
            } else {
                finish_frame = atol(argv[k]);
            }
            continue;
        }
    }
}