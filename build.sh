rm build/*
rm yarnes.nes
../cc65/bin/ca65 src/main.s -o build/main.o
../cc65/bin/ca65 src/header.s -o build/header.o
../cc65/bin/ld65 -C yarnes.ld65 build/main.o build/header.o -o yarnes.nes
