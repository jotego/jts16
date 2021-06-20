#include <fstream>
#include <iostream>
#include <exception>
#include "fd1089.h"
#include "obj_dir/Vjts16_fd1089.h"

using namespace std;

class ROM {
    unique_ptr<uint8_t> buf;
public:
    ROM( const char* fname );
    operator unsigned char*() { return (unsigned char*) buf.get(); }
};

using DUT=Vjts16_fd1089;

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
        ROM keys("317-5021.key");
        fd1089b_device ref;     // select A/B type here
        DUT dut;
        dut.dec_en = 1;
        dut.dec_type = 1; // 0=A, 1=B
        dut.rst=1;
        clock_dut( dut, 4 );
        dut.rst=0;
        for( int k=0; k<100000; k++ ) {
            //printf("------------- %d -----------\n",k);
            int addr = rand()&0xff'ffff;
            int enc  = rand()&0xffff;
            int op   = rand()&1;
            int dec  = ref.decrypt_one( addr, enc, keys, op);

            dut.op_n     = 1-op;
            dut.addr     = addr>>1;
            dut.enc      = enc;
            dut.dec      = dec;
            clock_dut( dut, 3 );
            int dut_dec = dut.dec;
            if( dut_dec != dec ) {
                printf("%d - %06X %04X %04X <> %04X\n\n", k, addr, enc, dec, dut_dec );
                if( dut.debug_luta != ref.luta ) throw runtime_error("lut_a failed");
                if( dut.debug_lut2_a != ref.lut2_a ) throw runtime_error("lut2_a failed");
                if( dut.debug_preval != ref.preval ) throw runtime_error("preval failed");
                if( dut.debug_key != ref.unshuffled_key ) throw runtime_error("unshuffled key failed");
                if( dut.dec_en==0 ) {
                    if( dut.debug_family != ref.family ) throw runtime_error("family failed");
                    if( dut.debug_last_in != ref.last_in ) throw runtime_error("last_in failed");
                }
                throw runtime_error("Decoder mismatch");
            }
        }
        // ofstream fout("fd1089.bin",ios_base::binary);
        // fout.write( (char*)fd1089_base_device::s_basetable_fd1089,
        //     sizeof(fd1089_base_device::s_basetable_fd1089) );
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
    buf = unique_ptr<uint8_t>( new uint8_t[len] );
    fin.seekg(0, ios_base::beg );
    fin.read( (char*)buf.get(), len );
    if( len != fin.gcount() ) {
        throw( runtime_error("File size different from expected"));
    }
}