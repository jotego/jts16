package main

import (
	"encoding/csv"
	"fmt"
	"io"
	"log"
	"os"
	"strconv"
)
/*
type struct CPU_st {
    time,
    pc,
    irqn
}

func parse_st( time string, data []string, old []CPU_st ) (new []CPU_st) {
    var st CPU_st
    st.time = time
    st.pc = data[2]
    st.irqn = data[1]

    if len(old)==0 {
        new = append( old, st )
    } else {
        top := old[ len(old)-1 ]
        if top.pc != st.pc {
            new = append( old, st )
        } else {
            new = old
        }
    }

    return new
}
*/
func push( last []string, newv string ) {
	last[0] = last[1]
	last[1] = newv
}

func append_rom( data []string, newv string ) ([]string, bool) {
	iv,_ := strconv.ParseInt( newv, 16, 0 )
	if iv < 0x40000 {
		if len(data)>0 {
			if data[ len(data)-1 ] != newv {
				return append( data, newv ), true
			} else {
				return data, false
			}
		} else {
			return append( data, newv ), true
		}
	} else {
		return data, false
	}
}

func make_int( s string ) int {
    n, _ := strconv.ParseInt( s, 16, 0 )
    return int(n)
}

func main() {
	fin, err := os.Open("bonus.csv")
	if err != nil {
		log.Fatal("Cannot open simvision.csv")
	}
	r := csv.NewReader(fin)
	fx68k := make([]string, 0, 100000)
	j68 := make([]string, 0, 100000)
    fx68k_times := make([]string,0,100000)
    j68_times := make([]string,0,100000)
    const J68_X = 1
    const FX_X  = 5
    const FRAME = 0
    const IRQN=1
    const PC=2
    const FC=3
    // Frame at which the important data starts
    // const FX_START=1599
    // const J68_START=1595
    const FX_START=1599+2
    const J68_START=FX_START-4
    dump := [2]bool{false,false}
	for k:= 0; ; k++ {
		record, err := r.Read()
        var aux bool
		if err == io.EOF {
			break
		}
		if err != nil {
			log.Fatal(err)
		}
		if len(record[0]) == 0 {
			continue
		}
        if make_int(record[J68_X+FRAME]) == J68_START && record[J68_X+IRQN]=="0" {
            dump[0] = true
        }
        if make_int(record[FX_X+FRAME]) == FX_START && record[FX_X+IRQN]=="0"  {
            dump[1] = true
        }
		if dump[0] {
			j68, aux = append_rom( j68, record[J68_X+PC] )
            if aux {
                j68_times = append( j68_times, record[0] )
            }

		}
        if dump[1] {
			fx68k, aux = append_rom( fx68k, record[FX_X+PC] )
            if aux {
                fx68k_times = append( fx68k_times, record[0] )
            }
        }
	}
	tlen := len(j68)
	fmt.Printf("Read %d entries\n", tlen)
	// Compare
	last_fx  := [2]string{ fx68k[0], fx68k[0] }
	last_j68 := [2]string{ j68[0], j68[0] }
	//last := 2
	k, j := 0, 0
	for div := 0; k < tlen && j < tlen; {
		fmt.Printf("[%d] %s <> [%d] %s", k, fx68k[k], j, j68[j])
		if div != 0 {
			fmt.Printf(" ... %d*", div)
		}
		fmt.Println()
		if fx68k[k] == j68[j] {
			push( last_fx[:], fx68k[k] )
			push( last_j68[:], j68[j] )
			k++
			j++
			div = 0
			continue
		}
		if fx68k[k] == last_j68[1] || fx68k[k] == last_j68[0] {
			// advance fx68k only
			push( last_fx[:], fx68k[k] )
			k++
			//last = 0
			continue
		}
		if j68[j] == last_fx[1] || j68[j] == last_fx[0] {
			// advance fx68k only
			push( last_j68[:], j68[j] )
			j++
			//last = 1
			continue
		}
		div++
		// kpos,_ := strconv.ParseInt(fx68k[k], 16, 0)
		// jpos,_ := strconv.ParseInt(j68[j], 16, 0)

            push( last_fx[:], fx68k[k] )
            push( last_j68[:], j68[j] )
			k++
			j++
/*
		if kpos > jpos {
			push( last_j68[:], j68[j] )
			j++
			//last = 1
		} else {
			push( last_fx[:], fx68k[k] )
			k++
			//last = 0
		}*/
		/*
		   if j68[j][0]=='F' && fx68k[k][0]!='F' {
			   last_fx  = fx68k[k]
			   k++
			   last = 0
		   } else if last==0 {
			   last_j68 = j68[j]
			   j++
			   last = 1
		   } else if last==1 {
			   last_fx  = fx68k[k]
			   k++
			   last = 0
		   }
		*/
		if div > 6 {
			fmt.Printf("Diverged at FX time %s, J68 time %s\n", fx68k_times[k], j68_times[j])
			break
		}
	}
}
