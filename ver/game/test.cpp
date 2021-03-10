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

class JTSim {
    vluint64_t simtime;
    const vluint64_t semi_period=9930;

    void parse_args( int argc, char *argv[] );
    bool trace;
    VerilatedVcdC* tracer;
    SDRAM sdram;
public:
    int finish_time;
    bool done() { return simtime/1000'000'000 >= finish_time; };
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
    parse_args( argc, argv );
    if( trace ) {
        Verilated::traceEverOn(true);
        tracer = new VerilatedVcdC;
        game.trace( tracer, 99 );
        tracer->open("test.vcd");
    } else {
        tracer = nullptr;
    }
    game.rst = 1;
    clock(10);
    game.rst = 0;
    clock(10);
}

JTSim::~JTSim() {
    delete tracer;
}

void JTSim::clock(int n) {
    while( n-- > 0 ) {
        sdram.update();
        game.clk = 1;
        game.eval();
        simtime += semi_period;
        if( tracer ) tracer->dump(simtime);
        game.clk = 0;
        game.eval();
        simtime += semi_period;
        if( tracer ) tracer->dump(simtime);
    }
}

void JTSim::parse_args( int argc, char *argv[] ) {
    trace = false;
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
    }
}