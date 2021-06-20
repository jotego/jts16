// This code has ben adapted from MAME file fd1089.cpp

#include <cstdio>
#include "fd1094.h"

using namespace std;

uint16_t decrypt_one(offs_t address, uint16_t val, const uint8_t *main_key,
                     uint8_t state, bool vector_fetch)
{
    // extract and adjust the global key
    uint8_t gkey1 = main_key[1];
    uint8_t gkey2 = main_key[2];
    uint8_t gkey3 = main_key[3];

    printf("ref gkey1 = %X\n", gkey1 );
    printf("ref gkey2 = %X\n", gkey2 );
    printf("ref gkey3 = %X\n", gkey3 );

    if (state & 0x0001)
    {
        gkey1 ^= 0x04;  // global_xor1
        gkey2 ^= 0x80;  // key_1a invert
        gkey3 ^= 0x80;  // key_2a invert
    }
    if (state & 0x0002)
    {
        gkey1 ^= 0x01;  // global_swap2
        gkey2 ^= 0x10;  // key_7a invert
        gkey3 ^= 0x01;  // key_4b invert
    }
    if (state & 0x0004)
    {
        gkey1 ^= 0x80;  // key_0b invert
        gkey2 ^= 0x40;  // key_6b invert
        gkey3 ^= 0x04;  // global_swap4
    }
    if (state & 0x0008)
    {
        gkey1 ^= 0x20;  // global_xor0
        gkey2 ^= 0x02;  // key_6a invert
        gkey3 ^= 0x20;  // key_5a invert
    }
    if (state & 0x0010)
    {
        gkey1 ^= 0x02;  // key_0c invert
        gkey1 ^= 0x40;  // key_5b invert
        gkey2 ^= 0x08;  // key_4a invert
    }
    if (state & 0x0020)
    {
        gkey1 ^= 0x08;  // key_1b invert
        gkey3 ^= 0x08;  // key_3b invert
        gkey3 ^= 0x10;  // global_swap1
    }
    if (state & 0x0040)
    {
        gkey1 ^= 0x10;  // key_2b invert
        gkey2 ^= 0x20;  // global_swap0a
        gkey2 ^= 0x04;  // global_swap0b
    }
    if (state & 0x0080)
    {
        gkey2 ^= 0x01;  // key_3a invert
        gkey3 ^= 0x02;  // key_0a invert
        gkey3 ^= 0x40;  // global_swap3
    }

    printf("ref masked gkey1 = %X\n", gkey1 );
    printf("ref masked gkey2 = %X\n", gkey2 );
    printf("ref masked gkey3 = %X\n", gkey3 );
    // for address xx0000-xx0006 (but only if >= 000008), use key xx2000-xx2006
    uint8_t mainkey;
    if ((address & 0x0ffc) == 0 && address >= 4)
        mainkey = main_key[(address & 0x1fff) | 0x1000];
    else
        mainkey = main_key[address & 0x1fff];

    printf("Ref mainkey = %X\n", mainkey );

    uint8_t key_F;
    if (address & 0x1000)   key_F = BIT(mainkey,7);
    else                    key_F = BIT(mainkey,6);

    // the CPU has been verified to produce different results when fetching opcodes
    // from 0000-0006 than when fetching the initial SP and PC on reset.
    if (vector_fetch)
    {
        if (address <= 3) gkey3 = 0x00; // supposed to always be the case
        if (address <= 2) gkey2 = 0x00;
        if (address <= 1) gkey1 = 0x00;
        if (address <= 1) key_F = 0;
    }

    uint8_t global_xor0         = 1^BIT(gkey1,5);
    uint8_t global_xor1         = 1^BIT(gkey1,2);
    uint8_t global_swap2        = 1^BIT(gkey1,0);

    uint8_t global_swap0a       = 1^BIT(gkey2,5);
    uint8_t global_swap0b       = 1^BIT(gkey2,2);

    uint8_t global_swap3        = 1^BIT(gkey3,6);
    uint8_t global_swap1        = 1^BIT(gkey3,4);
    uint8_t global_swap4        = 1^BIT(gkey3,2);

    uint8_t key_0a = BIT(mainkey,0) ^ BIT(gkey3,1);
    uint8_t key_0b = BIT(mainkey,0) ^ BIT(gkey1,7);
    uint8_t key_0c = BIT(mainkey,0) ^ BIT(gkey1,1);

    uint8_t key_1a = BIT(mainkey,1) ^ BIT(gkey2,7);
    uint8_t key_1b = BIT(mainkey,1) ^ BIT(gkey1,3);

    uint8_t key_2a = BIT(mainkey,2) ^ BIT(gkey3,7);
    uint8_t key_2b = BIT(mainkey,2) ^ BIT(gkey1,4);

    uint8_t key_3a = BIT(mainkey,3) ^ BIT(gkey2,0);
    uint8_t key_3b = BIT(mainkey,3) ^ BIT(gkey3,3);

    uint8_t key_4a = BIT(mainkey,4) ^ BIT(gkey2,3);
    uint8_t key_4b = BIT(mainkey,4) ^ BIT(gkey3,0);

    uint8_t key_5a = BIT(mainkey,5) ^ BIT(gkey3,5);
    uint8_t key_5b = BIT(mainkey,5) ^ BIT(gkey1,6);

    uint8_t key_6a = BIT(mainkey,6) ^ BIT(gkey2,1);
    uint8_t key_6b = BIT(mainkey,6) ^ BIT(gkey2,6);

    uint8_t key_7a = BIT(mainkey,7) ^ BIT(gkey2,4);


    if (val & 0x8000)           // block invariant: val & 0x8000 != 0
    {
        val = bitswap<16>(val, 15, 9,10,13, 3,12, 0,14, 6, 5, 2,11, 8, 1, 4, 7);

        if (!global_xor1)   if (~val & 0x0800)  val ^= 0x3002;                                      // 1,12,13
        if (true)           if (~val & 0x0020)  val ^= 0x0044;                                      // 2,6
        if (!key_1b)        if (~val & 0x0400)  val ^= 0x0890;                                      // 4,7,11
        if (!global_swap2)  if (!key_0c)        val ^= 0x0308;                                      // 3,8,9
                                                val ^= 0x6561;

        if (!key_2b)        val = bitswap<16>(val,15,10,13,12,11,14,9,8,7,6,0,4,3,2,1,5);             // 0-5, 10-14
    }
    printf("Ref point 0: %X (%d,%d,%d,%d)\n",val, global_xor1, key_1b, global_swap2, key_2b);
    if (val & 0x4000)           // block invariant: val & 0x4000 != 0
    {
        val = bitswap<16>(val, 13,14, 7, 0, 8, 6, 4, 2, 1,15, 3,11,12,10, 5, 9);

        if (!global_xor0)   if (val & 0x0010)   val ^= 0x0468;                                      // 3,5,6,10
        if (!key_3a)        if (val & 0x0100)   val ^= 0x0081;                                      // 0,7
        if (!key_6a)        if (val & 0x0004)   val ^= 0x0100;                                      // 8
        if (!key_5b)        if (!key_0b)        val ^= 0x3012;                                      // 1,4,12,13
                                                val ^= 0x3523;

        if (!global_swap0b) val = bitswap<16>(val, 2,14,13,12, 9,10,11, 8, 7, 6, 5, 4, 3,15, 1, 0);   // 2-15, 9-11
    }

    if (val & 0x2000)           // block invariant: val & 0x2000 != 0
    {
        val = bitswap<16>(val, 10, 2,13, 7, 8, 0, 3,14, 6,15, 1,11, 9, 4, 5,12);

        if (!key_4a)        if (val & 0x0800)   val ^= 0x010c;                                      // 2,3,8
        if (!key_1a)        if (val & 0x0080)   val ^= 0x1000;                                      // 12
        if (!key_7a)        if (val & 0x0400)   val ^= 0x0a21;                                      // 0,5,9,11
        if (!key_4b)        if (!key_0a)        val ^= 0x0080;                                      // 7
        if (!global_swap0a) if (!key_6b)        val ^= 0xc000;                                      // 14,15
                                                val ^= 0x99a5;

        if (!key_5b)        val = bitswap<16>(val,15,14,13,12,11, 1, 9, 8, 7,10, 5, 6, 3, 2, 4, 0);   // 1,4,6,10
    }

    if (val & 0xe000)           // block invariant: val & 0xe000 != 0
    {
        val = bitswap<16>(val,15,13,14, 5, 6, 0, 9,10, 4,11, 1, 2,12, 3, 7, 8);

        val ^= 0x17ff;

        if (!global_swap4)  val = bitswap<16>(val, 15,14,13, 6,11,10, 9, 5, 7,12, 8, 4, 3, 2, 1, 0);  // 5-8, 6-12
        if (!global_swap3)  val = bitswap<16>(val, 13,15,14,12,11,10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0);  // 15-14-13
        if (!global_swap2)  val = bitswap<16>(val, 15,14,13,12,11, 2, 9, 8,10, 6, 5, 4, 3, 0, 1, 7);  // 10-2-0-7
        if (!key_3b)        val = bitswap<16>(val, 15,14,13,12,11,10, 4, 8, 7, 6, 5, 9, 1, 2, 3, 0);  // 9-4, 3-1
        if (!key_2a)        val = bitswap<16>(val, 13,14,15,12,11,10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0);  // 13-15

        if (!global_swap1)  val = bitswap<16>(val, 15,14,13,12, 9, 8,11,10, 7, 6, 5, 4, 3, 2, 1, 0);  // 11...8
        if (!key_5a)        val = bitswap<16>(val, 15,14,13,12,11,10, 9, 8, 4, 5, 7, 6, 3, 2, 1, 0);  // 7...4
        if (!global_swap0a) val = bitswap<16>(val, 15,14,13,12,11,10, 9, 8, 7, 6, 5, 4, 0, 3, 2, 1);  // 3...0
    }

    val = bitswap<16>(val, 12,15,14,13,11,10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0);

    if ((val & 0xb080) == 0x8000) val ^= 0x4000;
    if ((val & 0xf000) == 0xc000) val ^= 0x0080;
    if ((val & 0xb100) == 0x0000) val ^= 0x4000;
/*
    // mask out opcodes doing PC-relative addressing, replace them with FFFF
    if ((m_masked_opcodes_lookup[key_F][val >> 4] >> ((val >> 1) & 7)) & 1)
        val = 0xffff;
*/
    return val;
}