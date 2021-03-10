#include <cstring>
#include <iostream>
#include <fstream>
#include "Vjts16_game.h"
#include "verilated_vcd_c.h"

using namespace std;

typedef Vjts16_game DUT;

class SDRAM {
    DUT& dut;
    char *banks[5];     // index 0 is unused
    int dly[5];
    int last_rd[5];
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
    addr <<= 1;
    int v=0;
    for( int k=3; k>=0; k-- ) {
        v <<= 8;
        v |= bank[addr+k]&0xff;
    }
    return v;
}

void SDRAM::update() {
    if( dut.rst ) {
        last_rd[1]  = 0;
        dut.ba1_rdy = 0;
        dut.ba1_ack = 0;
        return;
    }

    if( dut.ba1_rd && !last_rd[1] || (dut.ba1_rd && dly[1]<0)) {
        dly[1] = 8;
        dut.ba1_rdy = 0;
        dut.ba1_ack = 1;
    }
    if( dly[1] == 0 ) {
        dut.data_read = read_bank( banks[1], dut.ba1_addr );;
        dut.ba1_rdy = 1;
    } else {
        if( dly[1]==7 ) dut.ba1_ack=0;
    }
    if( dly[1]>-1 ) --dly[1];

    last_rd[1] = dut.ba1_rd;
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
    for( int k=1; k<5; k++ ) {
        banks[k] = new char[0x80'0000];
        dly[k]=-1;
    }
    // Read the ROM file
    ifstream fin("rom.bin",ios_base::binary);
    fin.read( header, 32 );
    int char_start = read_offset(2<<1);
    int obj_start  = read_offset(3<<1);
    int len = obj_start-char_start;
    fin.seekg( char_start, ios_base::cur );
    fin.read( banks[1], len );
    printf("GFX1 start = %x\nOBJ start  = %x\n", char_start, obj_start );
    printf("Read %d kBytes in bank1 for Char/Tiles\n", len>>10 );
}

SDRAM::~SDRAM() {
    for( int k=1; k<5; k++ ) {
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