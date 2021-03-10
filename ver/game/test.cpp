#include "Vjts16_game.h"

class JTSim {
public:
    Vjts16_game& game;
    JTSim( Vjts16_game& g);
    void clock(int n);
};

int main(int argc, char *argv[]) {
    Vjts16_game game;
    JTSim sim(game);


    return 0;
}

JTSim::JTSim( Vjts16_game& g) : game(g) {
    game.rst = 1;
    clock(10);
    game.rst = 0;
    clock(10);
}

void JTSim::clock(int n) {
    while( n-- > 0 ) {
        game.clk = 1;
        game.eval();
        game.clk = 0;
        game.eval();
    }
}