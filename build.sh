rm build/*
rm yarnes.nes
../cc65/bin/ca65 src/main.s -o build/main.o
../cc65/bin/ca65 src/chr.s -o build/chr.o
../cc65/bin/ca65 src/header.s -o build/header.o
../cc65/bin/ld65 -C yarnes.ld65 build/chr.o build/header.o build/main.o -o yarnes.nes
