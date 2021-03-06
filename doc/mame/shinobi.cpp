// license:BSD-3-Clause
// copyright-holders:Aaron Giles
/***************************************************************************

    Sega pre-System 16 & System 16A hardware

****************************************************************************

    Known bugs:
        * some games are stuck after reset when i8751 is present

    DIP locations verified from manual for:
        * aceattaca
        * aliensyn
        * aliensynj
        * passsht16a
        * quartet
        * quart2
        * shinobi
        * tetris
        * timescan
        * wb3

***************************************************************************

System16A Hardware Overview
---------------------------

The games on this system include... (there may be more??)
Action Fighter (C) Sega 1985
Alex Kidd      (C) Sega 1986
Fantasy Zone   (C) Sega 1986
SDI            (C) Sega 1987
Shinobi        (C) Sega 1987
Tetris         (C) Sega 1988
Passing Shot   (C) Sega 1988

PCB Layout
----------

Top PCB

171-5306 (number under PCB, no numbers on top)
         |----------|     |-----------|     |-----------|
  |------|----------|-----|-----------|-----|-----------|------|
|-|      16MHz    25.1478MHz                                   |
| |                                  315-5149                  |
|-|    YM3012 YM2151  ROM.IC24 ROM.IC41                        |
  | VOL                                                        |
  |                   ROM.IC25 ROM.IC42  MB3771                |
|-|         D8255                           315-5155           |
|                     ROM.IC26 ROM.IC43     315-5155  ROM.IC93 |
|S                                                             |
|E          Z80A      TC5565   TC5565       315-5155  ROM.IC94 |
|G                315-5141                  315-5155           |
|A         ROM.IC12                                   ROM.IC95 |
|5                                          315-5155           |
|6          2016                            315-5155           |
|                                                     2016     |
|-|                                       8751                 |
  |        DSW2        |-------------|                2016     |
|-|                    |    68000    | 315-5244                |
|                      |-------------|       315-5142          |
|          DSW1                                                |
|                        10MHz                                 |
|--------------------------------------------------------------|
Notes:
      68000    - running at 10.000MHz. Is replaced with a Hitachi FD1094 in some games.
      Z80      - running at 4.000MHz [16/4]
      YM2151   - running at 4.000MHz [16/4]
      2016     - Fujitsu MB8128 2K x8 SRAM (DIP24)
      TC5565   - Toshiba TC5565 8K x8 SRAM (DIP28)
      8751     - Intel 8751 Microcontroller. It appears to be not used, and instead, games use a small plug-in board
                 containing only one 74HC04 TTL IC. The daughterboard has Sega part number '837-0068' & '171-5468' stamped onto it.
      315-5141 - Signetics CK2605 stamped '315-5141' (DIP20)
      315-5149 - 82S153 Field Programmable Logic Array, sticker '315-5149'(DIP20)
      315-5244 - 82S153 Field Programmable Logic Array, sticker '315-5244'(DIP20)
      315-5142 - Signetics CK2605 stamped '315-5142' (DIP20)
      315-5155 - Custom Sega IC (DIP20)

                         Sound     |---------------------- Main Program --------------------|  |---------- Tiles ---------|
                         Program
Game           CPU       IC12      IC24      IC25      IC26      IC41      IC42      IC43      IC93      IC94      IC95
---------------------------------------------------------------------------------------------------------------------------
Action Fighter 317-0018  EPR10284  EPR10353  EPR10351  EPR10349  EPR10352  EPR10350  EPR10348  EPR10283  EPR10282  EPR10281
Alex Kid       317-0021  EPR10434  -         EPR10428  EPR10427  -         EPR10429  EPR10430  EPR10433  EPR10432  EPR10431
Alex Kid (Alt) 317-0021  EPR10434  -         EPR10446  EPR10445  -         EPR10448  EPR10447  EPR10433  EPR10432  EPR10431
Fantasy Zone   68000     EPR7535   EPR7384   EPR7383   EPR7382   EPR7387   EPR7386   EPR7385   EPR7390   EPR7389   EPR7388
SDI            317-0027  EPR10759  EPR10752  EPR10969  EPR10968  EPR10755  EPR10971  EPR10970  EPR10758  EPR10757  EPR10756
Shinobi        317-0050  EPR11267  -         EPR11261  EPR11260  -         EPR11262  EPR11263  EPR11266  EPR11265  EPR11264
Tetris         317-0093  EPR12205  -         -         EPR12200  -         -         EPR12201  EPR12204  EPR12203  EPR12202


Bottom PCB

171-5307 (number under PCB, no numbers on top)
         |----------|     |-----------|     |-----------|
|--------|----------|-----|-----------|-----|-----------|------|
|                                           315-5144           |-|
|                                                              | |
|                                                              |-|
|        2148 2148 2148                                        |
|                              ROM.IC24    ROM.IC11            |
|        2148 2148 2148  ROM.IC30   ROM.IC18                   |
|                                                   D7751      |
|                                                        6MHz  |
|                              ROM.IC23    ROM.IC10     D8243C |
|            315-5049    ROM.IC29   ROM.IC17                   |
|                                                              |
|                  315-5106    315-5108                        |
|                        315-5107     2018  2018               |
|                                                              |
|            315-5049                                          |
|                                              ROM.IC5 ROM.IC2 |
|TC5565 TC5565                  315-5011                       |
|                                                              |
|               2016  315-5143       315-5012  ROM.IC4 ROM.IC1 |
|TC5565 TC5565  2016                                           |
|--------------------------------------------------------------|
Notes:
      D7751    - NEC uPD7751C Microcontroller, running at 6.000MHz. This is a clone of an 8048 MCU
      D8243C   - NEC D8243C (DIP24)
      2016     - Fujitsu MB8128 2K x8 SRAM (DIP24)
      2018     - Sony CXD5813 2K x8 SRAM
      TC5565   - Toshiba TC5565 8K x8 SRAM (DIP28)
      2148     - Fujitsu MBM2148 1K x4 SRAM (DIP18)
      315-5144 - Signetics CK2605 stamped '315-5144' (DIP20)
      315-5143 - Signetics CK2605 stamped '315-5143' (DIP20)
      315-5106 - PAL16R6 stamped '315-5106' (DIP20)
      315-5107 - PAL16R6 stamped '315-5107' (DIP20)
      315-5108 - PAL16R6 stamped '315-5108' (DIP20)
      315-5011 - Custom Sega IC (DIP40)
      315-5012 - Custom Sega IC (DIP48)
      315-5049 - Custom Sega IC (SDIP64)

               |---------- 7751 Sound Data ---------|  |--------------------------------- Sprites ----------------------------------|

Game           IC1       IC2       IC4       IC5       IC10      IC11      IC17      IC18      IC23      IC24      IC29      IC30
-------------------------------------------------------------------------------------------------------------------------------------
Action Fighter -         -         -         -         EPR10285  EPR10289  EPR10286  EPR10290  EPR10287  EPR10291  EPR10288  EPR10292
Alex Kid       EPR10435  EPR10436  -         -         EPR10437  EPR10441  EPR10438  EPR10442  EPR10439  EPR10443  EPR10440  EPR10444
Fantasy Zone   -         -         -         -         EPR7392   EPR7396   EPR7393   EPR7397   EPR7394   EPR7398   -         -
SDI            -         -         -         -         EPR10760  EPR10763  EPR10761  EPR10764  EPR10762  EPR10765  -         -
Shinobi        EPR11268  -         -         -         EPR11290  EPR11294  EPR11291  EPR11295  EPR11292  EPR11296  EPR11293  EPR11297
Tetris         -         -         -         -         EPR12169  EPR12170  -         -         -         -         -         -

***************************************************************************/

#include "emu.h"
#include "includes/segas16a.h"
#include "includes/segaipt.h"

#include "machine/fd1089.h"
#include "machine/fd1094.h"
#include "machine/nvram.h"
#include "machine/segacrp2_device.h"
#include "sound/dac.h"
#include "sound/volt_reg.h"
#include "speaker.h"


//**************************************************************************
//  PPI READ/WRITE CALLBACKS
//**************************************************************************

//-------------------------------------------------
//  misc_control_w - miscellaneous video controls
//-------------------------------------------------

void segas16a_state::misc_control_w(uint8_t data)
{
    //
    //  PPI port B
    //
    //  D7 : Screen flip (1= flip, 0= normal orientation)
    //  D6 : To 8751 pin 13 (/INT1)
    //  D5 : To 315-5149 pin 17.
    //  D4 : Screen enable (1= display, 0= blank)
    //  D3 : Lamp #2 (1= on, 0= off)
    //  D2 : Lamp #1 (1= on, 0= off)
    //  D1 : Coin meter #2
    //  D0 : Coin meter #1
    //

    // bits 2 & 3: control the lamps, allowing for overrides
    if (((m_video_control ^ data) & 0x0c) && !m_lamp_changed_w.isnull())
        m_lamp_changed_w(m_video_control ^ data, data);
    m_lamps[1] = BIT(data, 3);
    m_lamps[0] = BIT(data, 2);

    m_video_control = data;

    // bit 7: screen flip
    m_segaic16vid->tilemap_set_flip(0, data & 0x80);
    m_sprites->set_flip(data & 0x80);

    // bit 6: set 8751 interrupt line
    if (m_mcu != nullptr)
        m_mcu->set_input_line(MCS51_INT1_LINE, (data & 0x40) ? CLEAR_LINE : ASSERT_LINE);

    // bit 4: enable display
    m_segaic16vid->set_display_enable(data & 0x10);

    // bits 0 & 1: update coin counters
    machine().bookkeeping().coin_counter_w(1, data & 0x02);
    machine().bookkeeping().coin_counter_w(0, data & 0x01);
}


//-------------------------------------------------
//  tilemap_sound_w - tilemap and sound control
//-------------------------------------------------

void segas16a_state::tilemap_sound_w(uint8_t data)
{
    //
    //  PPI port C
    //
    //  D7 : Port A handshaking signal /OBF
    //  D6 : Port A handshaking signal ACK
    //  D5 : Port A handshaking signal IBF
    //  D4 : Port A handshaking signal /STB
    //  D3 : Port A handshaking signal INTR
    //  D2 : To PAL 315-5107 pin 9 (SCONT1)
    //  D1 : To PAL 315-5108 pin 19 (SCONT0)
    //  D0 : To MUTE input on MB3733 amplifier.
    //       0= Sound is disabled
    //       1= sound is enabled
    //
    m_soundcpu->set_input_line(INPUT_LINE_NMI, (data & 0x80) ? CLEAR_LINE : ASSERT_LINE);
    m_segaic16vid->tilemap_set_colscroll(0, ~data & 0x04);
    m_segaic16vid->tilemap_set_rowscroll(0, ~data & 0x02);
}



//**************************************************************************
//  MAIN CPU READ/WRITE HANDLERS
//**************************************************************************

//-------------------------------------------------
//  standard_io_r - default I/O handler for reads
//-------------------------------------------------

uint16_t segas16a_state::standard_io_r(offs_t offset)
{
    offset &= 0x3fff/2;
    switch (offset & (0x3000/2))
    {
        case 0x0000/2:
            return m_i8255->read(offset & 3);

        case 0x1000/2:
        {
            static const char *const sysports[] = { "SERVICE", "P1", "UNUSED", "P2" };
            return ioport(sysports[offset & 3])->read();
        }

        case 0x2000/2:
            return ioport((offset & 1) ? "DSW2" : "DSW1")->read();
    }
    //logerror("%06X:standard_io_r - unknown read access to address %04X\n", m_maincpu->state_int(STATE_GENPC), offset * 2);
    return 0xffff;
}


//-------------------------------------------------
//  standard_io_r - default I/O handler for writes
//-------------------------------------------------

void segas16a_state::standard_io_w(offs_t offset, uint16_t data, uint16_t mem_mask)
{
    offset &= 0x3fff/2;
    switch (offset & (0x3000/2))
    {
        case 0x0000/2:
            // the port C handshaking signals control the Z80 NMI,
            // so we have to sync whenever we access this PPI
            if (ACCESSING_BITS_0_7)
                synchronize(TID_PPI_WRITE, ((offset & 3) << 8) | (data & 0xff));
            return;
    }
    //logerror("%06X:standard_io_w - unknown write access to address %04X = %04X & %04X\n", m_maincpu->state_int(STATE_GENPC), offset * 2, data, mem_mask);
}


//-------------------------------------------------
//  misc_io_r - miscellaneous I/O reads
//-------------------------------------------------

uint16_t segas16a_state::misc_io_r(offs_t offset)
{
    // just call custom handler
    return m_custom_io_r(offset);
}


//-------------------------------------------------
//  misc_io_w - miscellaneous I/O writes
//-------------------------------------------------

void segas16a_state::misc_io_w(offs_t offset, uint16_t data, uint16_t mem_mask)
{
    // just call custom handler
    m_custom_io_w(offset, data, mem_mask);
}



//**************************************************************************
//  Z80 SOUND CPU READ/WRITE HANDLERS
//**************************************************************************

//-------------------------------------------------
//  sound_data_r - read data from the sound latch
//-------------------------------------------------

uint8_t segas16a_state::sound_data_r()
{
    // assert ACK
    m_i8255->pc6_w(CLEAR_LINE);
    return m_soundlatch->read();
}


//-------------------------------------------------
//  n7751_command_w - control the N7751
//-------------------------------------------------

void segas16a_state::n7751_command_w(uint8_t data)
{
    //
    //  Z80 7751 control port
    //
    //  D7-D5 = connected to 7751 port C
    //  D4    = /CS for ROM 3
    //  D3    = /CS for ROM 2
    //  D2    = /CS for ROM 1
    //  D1    = /CS for ROM 0
    //  D0    = A14 line to ROMs
    //
    int numroms = memregion("n7751data")->bytes() / 0x8000;
    m_n7751_rom_address &= 0x3fff;
    m_n7751_rom_address |= (data & 0x01) << 14;
    if (!(data & 0x02) && numroms >= 1) m_n7751_rom_address |= 0x00000;
    if (!(data & 0x04) && numroms >= 2) m_n7751_rom_address |= 0x08000;
    if (!(data & 0x08) && numroms >= 3) m_n7751_rom_address |= 0x10000;
    if (!(data & 0x10) && numroms >= 4) m_n7751_rom_address |= 0x18000;
    m_n7751_command = data >> 5;
}


//-------------------------------------------------
//  n7751_control_w - YM2151 output port callback
//-------------------------------------------------

void segas16a_state::n7751_control_w(uint8_t data)
{
    //
    //  YM2151 output port
    //
    //  D1 = /RESET line on 7751
    //  D0 = /IRQ line on 7751
    //
    m_n7751->set_input_line(INPUT_LINE_RESET, (data & 0x01) ? CLEAR_LINE : ASSERT_LINE);
    m_n7751->set_input_line(0, (data & 0x02) ? CLEAR_LINE : ASSERT_LINE);
    machine().scheduler().boost_interleave(attotime::zero, attotime::from_usec(100));
}


//-------------------------------------------------
//  n7751_rom_offset_w - post expander callback
//-------------------------------------------------

template<int Shift>
void segas16a_state::n7751_rom_offset_w(uint8_t data)
{
    // P4 - address lines 0-3
    // P5 - address lines 4-7
    // P6 - address lines 8-11
    // P7 - address lines 12-13
    int mask = (0xf << Shift) & 0x3fff;
    int newdata = (data << Shift) & mask;
    m_n7751_rom_address = (m_n7751_rom_address & ~mask) | newdata;
}

//**************************************************************************
//  N7751 SOUND GENERATOR CPU READ/WRITE HANDLERS
//**************************************************************************

//-------------------------------------------------
//  n7751_rom_r - MCU reads from BUS
//-------------------------------------------------

uint8_t segas16a_state::n7751_rom_r()
{
    // read from BUS
    return memregion("n7751data")->base()[m_n7751_rom_address];
}


//-------------------------------------------------
//  n7751_p2_r - MCU reads from the P2 lines
//-------------------------------------------------

uint8_t segas16a_state::n7751_p2_r()
{
    // read from P2 - 8255's PC0-2 connects to 7751's S0-2 (P24-P26 on an 8048)
    // bit 0x80 is an alternate way to control the sample on/off; doesn't appear to be used
    return 0x80 | ((m_n7751_command & 0x07) << 4) | (m_n7751_i8243->p2_r() & 0x0f);
}


//-------------------------------------------------
//  n7751_p2_w - MCU writes to the P2 lines
//-------------------------------------------------

void segas16a_state::n7751_p2_w(uint8_t data)
{
    // write to P2; low 4 bits go to 8243
    m_n7751_i8243->p2_w(data & 0x0f);

    // output of bit $80 indicates we are ready (1) or busy (0)
    // no other outputs are used
}


//**************************************************************************
//  DRIVER OVERRIDES
//**************************************************************************

//-------------------------------------------------
//  machine_reset - reset the state of the machine
//-------------------------------------------------

void segas16a_state::machine_reset()
{
    // queue up a timer to either boost interleave or disable the MCU
    synchronize(TID_INIT_I8751);
    m_video_control = 0;
    m_mcu_control = 0x00;
    m_n7751_command = 0;
    m_n7751_rom_address = 0;
    m_last_buttons1 = 0;
    m_last_buttons2 = 0;
    m_read_port = 0;
    m_mj_input_num = 0;
}


//**************************************************************************
//  MAIN CPU ADDRESS MAPS
//**************************************************************************

void segas16a_state::system16a_map(address_map &map)
{
    map.unmap_value_high();
    map(0x000000, 0x03ffff).mirror(0x380000).rom();
    map(0x400000, 0x407fff).mirror(0xb88000).rw(m_segaic16vid, FUNC(segaic16_video_device::tileram_r), FUNC(segaic16_video_device::tileram_w)).share("tileram");
    map(0x410000, 0x410fff).mirror(0xb8f000).rw(m_segaic16vid, FUNC(segaic16_video_device::textram_r), FUNC(segaic16_video_device::textram_w)).share("textram");
    map(0x440000, 0x4407ff).mirror(0x3bf800).ram().share("sprites");
    map(0x840000, 0x840fff).mirror(0x3bf000).ram().w(FUNC(segas16a_state::paletteram_w)).share("paletteram");
    map(0xc40000, 0xc43fff).mirror(0x39c000).rw(FUNC(segas16a_state::misc_io_r), FUNC(segas16a_state::misc_io_w));
    map(0xc60000, 0xc6ffff).r(m_watchdog, FUNC(watchdog_timer_device::reset16_r));
    map(0xc70000, 0xc73fff).mirror(0x38c000).ram().share("nvram");
}

//**************************************************************************
//  SOUND CPU ADDRESS MAPS
//**************************************************************************

void segas16a_state::sound_map(address_map &map)
{
    map.unmap_value_high();
    map(0x0000, 0x7fff).rom();
    map(0xe800, 0xe800).r(FUNC(segas16a_state::sound_data_r));
    map(0xf800, 0xffff).ram();
}

void segas16a_state::sound_portmap(address_map &map)
{
    map.unmap_value_high();
    map.global_mask(0xff);
    map(0x00, 0x01).mirror(0x3e).rw(m_ymsnd, FUNC(ym2151_device::read), FUNC(ym2151_device::write));
    map(0x80, 0x80).mirror(0x3f).w(FUNC(segas16a_state::n7751_command_w));
    map(0xc0, 0xc0).mirror(0x3f).r(FUNC(segas16a_state::sound_data_r));
}

//**************************************************************************
//  GENERIC PORT DEFINITIONS
//**************************************************************************

static INPUT_PORTS_START( system16a_generic )
    PORT_START("SERVICE")
    PORT_BIT( 0x01, IP_ACTIVE_LOW, IPT_COIN1 )
    PORT_BIT( 0x02, IP_ACTIVE_LOW, IPT_COIN2 )
    PORT_SERVICE_NO_TOGGLE( 0x04, IP_ACTIVE_LOW )
    PORT_BIT( 0x08, IP_ACTIVE_LOW, IPT_SERVICE1 )
    PORT_BIT( 0x10, IP_ACTIVE_LOW, IPT_START1 )
    PORT_BIT( 0x20, IP_ACTIVE_LOW, IPT_START2 )
    PORT_BIT( 0x40, IP_ACTIVE_LOW, IPT_UNKNOWN )
    PORT_BIT( 0x80, IP_ACTIVE_LOW, IPT_UNKNOWN )

    PORT_START("P1")
    PORT_BIT( 0x01, IP_ACTIVE_LOW, IPT_BUTTON3 )
    PORT_BIT( 0x02, IP_ACTIVE_LOW, IPT_BUTTON1 )
    PORT_BIT( 0x04, IP_ACTIVE_LOW, IPT_BUTTON2 )
    PORT_BIT( 0x08, IP_ACTIVE_LOW, IPT_UNKNOWN )
    PORT_BIT( 0x10, IP_ACTIVE_LOW, IPT_JOYSTICK_DOWN ) PORT_8WAY
    PORT_BIT( 0x20, IP_ACTIVE_LOW, IPT_JOYSTICK_UP ) PORT_8WAY
    PORT_BIT( 0x40, IP_ACTIVE_LOW, IPT_JOYSTICK_RIGHT ) PORT_8WAY
    PORT_BIT( 0x80, IP_ACTIVE_LOW, IPT_JOYSTICK_LEFT ) PORT_8WAY

    PORT_START("UNUSED")
    PORT_BIT( 0xff, IP_ACTIVE_LOW, IPT_UNUSED )

    PORT_START("P2")
    PORT_BIT( 0x01, IP_ACTIVE_LOW, IPT_BUTTON3 ) PORT_COCKTAIL
    PORT_BIT( 0x02, IP_ACTIVE_LOW, IPT_BUTTON1 ) PORT_COCKTAIL
    PORT_BIT( 0x04, IP_ACTIVE_LOW, IPT_BUTTON2 ) PORT_COCKTAIL
    PORT_BIT( 0x08, IP_ACTIVE_LOW, IPT_UNKNOWN )
    PORT_BIT( 0x10, IP_ACTIVE_LOW, IPT_JOYSTICK_DOWN ) PORT_8WAY PORT_COCKTAIL
    PORT_BIT( 0x20, IP_ACTIVE_LOW, IPT_JOYSTICK_UP ) PORT_8WAY PORT_COCKTAIL
    PORT_BIT( 0x40, IP_ACTIVE_LOW, IPT_JOYSTICK_RIGHT ) PORT_8WAY PORT_COCKTAIL
    PORT_BIT( 0x80, IP_ACTIVE_LOW, IPT_JOYSTICK_LEFT ) PORT_8WAY PORT_COCKTAIL

    PORT_START("DSW1")
    SEGA_COINAGE_LOC(SW1)

    PORT_START("DSW2")
    PORT_DIPUNUSED_DIPLOC( 0x01, IP_ACTIVE_LOW, "SW2:1" )
    PORT_DIPUNUSED_DIPLOC( 0x02, IP_ACTIVE_LOW, "SW2:2" )
    PORT_DIPUNUSED_DIPLOC( 0x04, IP_ACTIVE_LOW, "SW2:3" )
    PORT_DIPUNUSED_DIPLOC( 0x08, IP_ACTIVE_LOW, "SW2:4" )
    PORT_DIPUNUSED_DIPLOC( 0x10, IP_ACTIVE_LOW, "SW2:5" )
    PORT_DIPUNUSED_DIPLOC( 0x20, IP_ACTIVE_LOW, "SW2:6" )
    PORT_DIPUNUSED_DIPLOC( 0x40, IP_ACTIVE_LOW, "SW2:7" )
    PORT_DIPUNUSED_DIPLOC( 0x80, IP_ACTIVE_LOW, "SW2:8" )
INPUT_PORTS_END

static INPUT_PORTS_START( shinobi )
    PORT_INCLUDE( system16a_generic )

    PORT_MODIFY("DSW2")
    PORT_DIPNAME( 0x01, 0x00, DEF_STR( Cabinet ) ) PORT_DIPLOCATION("SW2:1")
    PORT_DIPSETTING(    0x00, DEF_STR( Upright ) )
    PORT_DIPSETTING(    0x01, DEF_STR( Cocktail ) )
    PORT_DIPNAME( 0x02, 0x00, DEF_STR( Demo_Sounds ) ) PORT_DIPLOCATION("SW2:2")
    PORT_DIPSETTING(    0x02, DEF_STR( Off ) )
    PORT_DIPSETTING(    0x00, DEF_STR( On ) )
    PORT_DIPNAME( 0x0c, 0x0c, DEF_STR( Lives ) ) PORT_DIPLOCATION("SW2:3,4")
    PORT_DIPSETTING(    0x08, "2" )
    PORT_DIPSETTING(    0x0c, "3" )
    PORT_DIPSETTING(    0x04, "5" )
    PORT_DIPSETTING(    0x00, DEF_STR( Free_Play ) )
    PORT_DIPNAME( 0x30, 0x30, DEF_STR( Difficulty ) ) PORT_DIPLOCATION("SW2:5,6")
    PORT_DIPSETTING(    0x20, DEF_STR( Easy ) )
    PORT_DIPSETTING(    0x30, DEF_STR( Normal ) )
    PORT_DIPSETTING(    0x10, DEF_STR( Hard ) )
    PORT_DIPSETTING(    0x00, DEF_STR( Hardest ) )
    PORT_DIPNAME( 0x40, 0x40, "Enemy's Bullet Speed" ) PORT_DIPLOCATION("SW2:7")
    PORT_DIPSETTING(    0x40, "Slow" )
    PORT_DIPSETTING(    0x00, "Fast" )
    PORT_DIPNAME( 0x80, 0x80, DEF_STR( Language ) ) PORT_DIPLOCATION("SW2:8")
    PORT_DIPSETTING(    0x80, DEF_STR( Japanese ) )
    PORT_DIPSETTING(    0x00, DEF_STR( English ) )
INPUT_PORTS_END



//**************************************************************************
//  GRAPHICS DECODING
//**************************************************************************

static GFXDECODE_START( gfx_segas16a )
    GFXDECODE_ENTRY( "gfx1", 0, gfx_8x8x3_planar, 0, 1024 )
GFXDECODE_END



//**************************************************************************
//  GENERIC MACHINE DRIVERS
//**************************************************************************

void segas16a_state::system16a(machine_config &config)
{
    // basic machine hardware
    M68000(config, m_maincpu, 10000000);
    m_maincpu->set_addrmap(AS_PROGRAM, &segas16a_state::system16a_map);
    m_maincpu->set_vblank_int("screen", FUNC(segas16a_state::irq4_line_hold));

    Z80(config, m_soundcpu, 4000000);
    m_soundcpu->set_addrmap(AS_PROGRAM, &segas16a_state::sound_map);
    m_soundcpu->set_addrmap(AS_IO, &segas16a_state::sound_portmap);

    N7751(config, m_n7751, 6000000);
    m_n7751->bus_in_cb().set(FUNC(segas16a_state::n7751_rom_r));
    m_n7751->t1_in_cb().set_constant(0); // labelled as "TEST", connected to ground
    m_n7751->p1_out_cb().set("dac", FUNC(dac_byte_interface::data_w));
    m_n7751->p2_in_cb().set(FUNC(segas16a_state::n7751_p2_r));
    m_n7751->p2_out_cb().set(FUNC(segas16a_state::n7751_p2_w));
    m_n7751->prog_out_cb().set("n7751_8243", FUNC(i8243_device::prog_w));

    I8243(config, m_n7751_i8243);
    m_n7751_i8243->p4_out_cb().set(FUNC(segas16a_state::n7751_rom_offset_w<0>));
    m_n7751_i8243->p5_out_cb().set(FUNC(segas16a_state::n7751_rom_offset_w<4>));
    m_n7751_i8243->p6_out_cb().set(FUNC(segas16a_state::n7751_rom_offset_w<8>));
    m_n7751_i8243->p7_out_cb().set(FUNC(segas16a_state::n7751_rom_offset_w<12>));

    NVRAM(config, "nvram", nvram_device::DEFAULT_ALL_0);

    WATCHDOG_TIMER(config, m_watchdog);

    I8255(config, m_i8255);
    m_i8255->out_pa_callback().set("soundlatch", FUNC(generic_latch_8_device::write));
    m_i8255->out_pb_callback().set(FUNC(segas16a_state::misc_control_w));
    m_i8255->out_pc_callback().set(FUNC(segas16a_state::tilemap_sound_w));

    // video hardware
    SCREEN(config, m_screen, SCREEN_TYPE_RASTER);
    m_screen->set_refresh_hz(60);
    m_screen->set_size(342, 262);   // to be verified
    m_screen->set_visarea(0*8, 40*8-1, 0*8, 28*8-1);
    m_screen->set_screen_update(FUNC(segas16a_state::screen_update));
    m_screen->set_palette(m_palette);

    SEGA_SYS16A_SPRITES(config, m_sprites, 0);
    SEGAIC16VID(config, m_segaic16vid, 0, "gfxdecode");

    GFXDECODE(config, "gfxdecode", m_palette, gfx_segas16a);
    PALETTE(config, m_palette).set_entries(2048*2);

    // sound hardware
    SPEAKER(config, "speaker").front_center();

    GENERIC_LATCH_8(config, m_soundlatch);

    YM2151(config, m_ymsnd, 4000000);
    m_ymsnd->port_write_handler().set(FUNC(segas16a_state::n7751_control_w));
    m_ymsnd->add_route(ALL_OUTPUTS, "speaker", 0.43);

    DAC_8BIT_R2R(config, "dac", 0).add_route(ALL_OUTPUTS, "speaker", 0.4); // unknown DAC
    voltage_regulator_device &vref(VOLTAGE_REGULATOR(config, "vref", 0));
    vref.add_route(0, "dac", 1.0, DAC_VREF_POS_INPUT);
    vref.add_route(0, "dac", -1.0, DAC_VREF_NEG_INPUT);
}


void segas16a_state::system16a_i8751(machine_config &config)
{
    system16a(config);
    m_maincpu->remove_vblank_int();

    I8751(config, m_mcu, 8000000);
    m_mcu->set_addrmap(AS_IO, &segas16a_state::mcu_io_map);
    m_mcu->port_out_cb<1>().set(FUNC(segas16a_state::mcu_control_w));

    m_screen->screen_vblank().set(FUNC(segas16a_state::i8751_main_cpu_vblank_w));
}

void segas16a_state::system16a_no7751(machine_config &config)
{
    system16a(config);
    m_soundcpu->set_addrmap(AS_IO, &segas16a_state::sound_no7751_portmap);

    config.device_remove("n7751");
    config.device_remove("n7751_8243");
    config.device_remove("dac");
    config.device_remove("vref");

    YM2151(config.replace(), m_ymsnd, 4000000);
    m_ymsnd->add_route(ALL_OUTPUTS, "speaker", 1.0);
}

void segas16a_state::system16a_no7751p(machine_config &config)
{
    system16a_no7751(config);
    segacrp2_z80_device &z80(SEGA_315_5177(config.replace(), m_soundcpu, 4000000));
    z80.set_addrmap(AS_PROGRAM, &segas16a_state::sound_map);
    z80.set_addrmap(AS_IO, &segas16a_state::sound_no7751_portmap);
    z80.set_addrmap(AS_OPCODES, &segas16a_state::sound_decrypted_opcodes_map);
    z80.set_decrypted_tag(m_sound_decrypted_opcodes);
}


//*************************************************************************************************************************
//*************************************************************************************************************************
//*************************************************************************************************************************
//  Shinobi, Sega System 16A
//  CPU: 68000 (unprotected)
//
ROM_START( shinobi )
    ROM_REGION( 0x40000, "maincpu", 0 ) // 68000 code
    ROM_LOAD16_BYTE( "epr-12010.43", 0x000000, 0x10000, CRC(7df7f4a2) SHA1(86ac00a3a8ecc1a7fcb00533ea12a6cb6d59089b) )
    ROM_LOAD16_BYTE( "epr-12008.26", 0x000001, 0x10000, CRC(f5ae64cd) SHA1(33c9f25fcaff80b03d074d9d44d94976162411bf) )
    ROM_LOAD16_BYTE( "epr-12011.42", 0x020000, 0x10000, CRC(9d46e707) SHA1(37ab25b3b37365c9f45837bfb6ec80652691dd4c) ) // == epr-11283
    ROM_LOAD16_BYTE( "epr-12009.25", 0x020001, 0x10000, CRC(7961d07e) SHA1(38cbdab35f901532c0ad99ad0083513abd2ff182) ) // == epr-11281

    ROM_REGION( 0x30000, "gfx1", 0 ) // tiles
    ROM_LOAD( "epr-11264.95", 0x00000, 0x10000, CRC(46627e7d) SHA1(66bb5b22a2100e7b9df303007a837bc2d52cf7ba) )
    ROM_LOAD( "epr-11265.94", 0x10000, 0x10000, CRC(87d0f321) SHA1(885b38eaff2dcaeab4eeaa20cc8a2885d520abd6) )
    ROM_LOAD( "epr-11266.93", 0x20000, 0x10000, CRC(efb4af87) SHA1(0b8a905023e1bc808fd2b1c3cfa3778cde79e659) )

    ROM_REGION16_BE( 0x080000, "sprites", 0 ) // sprites
    ROM_LOAD16_BYTE( "epr-11290.10", 0x00001, 0x08000, CRC(611f413a) SHA1(180f83216e2dfbfd77b0fb3be83c3042954d12df) )
    ROM_CONTINUE(                    0x40001, 0x08000 )
    ROM_LOAD16_BYTE( "epr-11294.11", 0x00000, 0x08000, CRC(5eb00fc1) SHA1(97e02eee74f61fabcad2a9e24f1868cafaac1d51) )
    ROM_CONTINUE(                    0x40000, 0x08000 )
    ROM_LOAD16_BYTE( "epr-11291.17", 0x10001, 0x08000, CRC(3c0797c0) SHA1(df18c7987281bd9379026c6cf7f96f6ae49fd7f9) )
    ROM_CONTINUE(                    0x50001, 0x08000 )
    ROM_LOAD16_BYTE( "epr-11295.18", 0x10000, 0x08000, CRC(25307ef8) SHA1(91ffbe436f80d583524ee113a8b7c0cf5d8ab286) )
    ROM_CONTINUE(                    0x50000, 0x08000 )
    ROM_LOAD16_BYTE( "epr-11292.23", 0x20001, 0x08000, CRC(c29ac34e) SHA1(b5e9b8c3233a7d6797f91531a0d9123febcf1660) )
    ROM_CONTINUE(                    0x60001, 0x08000 )
    ROM_LOAD16_BYTE( "epr-11296.24", 0x20000, 0x08000, CRC(04a437f8) SHA1(ea5fed64443236e3404fab243761e60e2e48c84c) )
    ROM_CONTINUE(                    0x60000, 0x08000 )
    ROM_LOAD16_BYTE( "epr-11293.29", 0x30001, 0x08000, CRC(41f41063) SHA1(5cc461e9738dddf9eea06831fce3702d94674163) )
    ROM_CONTINUE(                    0x70001, 0x08000 )
    ROM_LOAD16_BYTE( "epr-11297.30", 0x30000, 0x08000, CRC(b6e1fd72) SHA1(eb86e4bf880bd1a1d9bcab3f2f2e917bcaa06172) )
    ROM_CONTINUE(                    0x70000, 0x08000 )

    ROM_REGION( 0x20000, "soundcpu", 0 ) // sound CPU
    ROM_LOAD( "epr-11267.12", 0x0000, 0x8000, CRC(dd50b745) SHA1(52e1977569d3713ad864d607170c9a61cd059a65) )

    ROM_REGION( 0x1000, "n7751", 0 )      // 4k for 7751 onboard ROM
    ROM_LOAD( "7751.bin",     0x0000, 0x0400, CRC(6a9534fc) SHA1(67ad94674db5c2aab75785668f610f6f4eccd158) ) // 7751 - U34

    ROM_REGION( 0x08000, "n7751data", 0 ) // 7751 sound data
    ROM_LOAD( "epr-11268.1",  0x0000, 0x8000, CRC(6d7966da) SHA1(90f55a99f784c21d7c135e630f4e8b1d4d043d66) )
ROM_END

void segas16a_state::init_generic()
{
    // configure the NVRAM to point to our workram
    m_nvram->set_base(m_workram, m_workram.bytes());

    // create default read/write handlers
    m_custom_io_r = read16sm_delegate(*this, FUNC(segas16a_state::standard_io_r));
    m_custom_io_w = write16s_delegate(*this, FUNC(segas16a_state::standard_io_w));

    // save state
    save_item(NAME(m_video_control));
    save_item(NAME(m_mcu_control));
    save_item(NAME(m_n7751_command));
    save_item(NAME(m_n7751_rom_address));
    save_item(NAME(m_last_buttons1));
    save_item(NAME(m_last_buttons2));
    save_item(NAME(m_read_port));
    save_item(NAME(m_mj_input_num));
}





GAME( 1987, shinobi,    0,        system16a,                shinobi,         segas16a_state,            init_generic,     ROT0,   "Sega", "Shinobi (set 6, System 16A) (unprotected)", MACHINE_SUPPORTS_SAVE )
