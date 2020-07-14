del build\*.o
del yarnes.nes

ca65 src\chr.s -o build\chr.o
ca65 src\header.s -o build\header.o
ca65 src\main.s -o build\main.o

ld65 -C yarnes.ld65 build\chr.o build\header.o build\main.o -o yarnes.nes
