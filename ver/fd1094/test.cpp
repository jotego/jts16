#include <fstream>
#include <iostream>
#include <exception>
#include "fd1094.h"
#include "obj_dir/Vjts16_fd1094.h"

using namespace std;

class ROM {
    char *buf;
public:
    ROM( const char* fname );
    ~ROM() { delete buf; buf=0; }
    operator unsigned char*() { return (unsigned char*) buf; }
    int operator[](int k) { return (int)buf[k]; }
};

using DUT=Vjts16_fd1094;

template <typename S>
void clock_dut( S& dut, int times ) {
    while( times-- ) {
        dut.clk = 1;
        //cout << "Rising" << endl;
        dut.eval();
        dut.clk = 0;
        dut.eval();
    }
}

int main() {
    try {
        ROM keys("317-0080.key");
        DUT dut;
        dut.dec_en = 1;
        dut.op_n = 0;
        dut.rst=1;
        clock_dut( dut, 4 );
        dut.rst=0;
        // Transfer key file
        for( int k=0; k<8*1024; k++ ) {
            dut.prog_addr = k;
            dut.prog_data = keys[k];
            dut.fd1094_we = 1;
            clock_dut( dut, 2 );
        }
        dut.fd1094_we = 0;
        for( int k=0; k<100000; k++ ) {
            //printf("------------- %d -----------\n",k);
            int addr = rand()&0xff'ffff;
            int enc  = rand()&0xffff;
            int state = rand()&0xff;
            int vrq   = 0; // rand()&1;
            int dec  = decrypt_one( addr, enc, keys, state, vrq );

            dut.addr = addr;
            dut.enc  = enc;
            dut.vrq  = vrq;
            dut.st   = state;
            clock_dut( dut, 3 );
            int dut_dec = dut.dec;
            if( dut_dec != dec ) {
                printf("%d - %06X %04X %04X <> %04X\n\n", k, addr, enc, dec, dut_dec );
                throw runtime_error("Decoder mismatch");
            }
        }
    } catch( const exception& error ) {
        cout.flush();
        cout << "ERROR: " << error.what() << endl;
        return 1;
    }
    return 0;
}

ROM::ROM( const char *fname ) {
    ifstream fin( fname );
    if( !fin ) {
        throw( runtime_error("Cannot open file"));
    }
    fin.seekg( 0, ios_base::end );
    auto len = fin.tellg();
    if( len == 0 ) {
        throw( runtime_error("Empty file"));
    }
    buf = (char*)new uint8_t[len];
    fin.seekg(0, ios_base::beg );
    fin.read( buf, len );
    if( len != fin.gcount() ) {
        throw( runtime_error("File size different from expected"));
    }
}