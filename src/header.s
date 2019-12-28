.segment "INES"
.byte "NES", $1A
.byte 1          ; Size of PRG ROM in 16 KB chunks
.byte 1          ; Size of CHR ROM in 8 KB chunks
.byte 0          ; mapper 0, horizontal mirroring
.byte 0          ; mapper 0