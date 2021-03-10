#include <cstring>
#include <iostream>
#include "Vjts16_game.h"
#include "verilated_vcd_c.h"

using namespace std;

class JTSim {
    vluint64_t simtime;
    const vluint64_t semi_period=9930;

    void parse_args( int argc, char *argv[] );
    bool trace;
    VerilatedVcdC* tracer;
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

JTSim::JTSim( Vjts16_game& g, int argc, char *argv[]) : game(g) {
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
        game.clk = 1;
        game.eval();
        if( tracer )
        simtime += semi_period;
        tracer->dump(simtime);
        game.clk = 0;
        game.eval();
        simtime += semi_period;
        tracer->dump(simtime);
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