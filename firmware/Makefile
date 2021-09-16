s16mcu_alt.zip: 317-0104.c2 README
	zip s16mcu_alt.zip 317-0104.c2 README
	cp s16mcu_alt.zip /opt/mame
	echo "Copying to MiSTer"
	scp s16mcu_alt.zip root@MiSTer.home:/media/fat/games/mame

317-0104.c2: tturf.s
	as31 -l -Fbin -O317-0104.c2 tturf.s

clean:
	rm -f s16mcu_alt 317-0104.c2