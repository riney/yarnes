del build\*.*
del yarnes.nes
ca65 src\main.s -o build\main.o
ca65 src\header.s -o build\header.o
ld65 -C yarnes.ld65 build\main.o build\header.o -o yarnes.nes
