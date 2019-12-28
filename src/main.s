.include "nes_constants.s"

FRAME = $10

.code

  ; Reset handler
.proc reset
  sei           ; Disable interrupts
  cld           ; Clear decimal mode
  ldx #$ff
  txs           ; Initialize SP = $FF
  inx
  stx PPUCTRL   ; PPUCTRL = 0
  stx PPUMASK   ; PPUMASK = 0
  stx APUSTATUS ; APUSTATUS = 0

  ; PPU warmup, wait two frames, plus a third later.
  ; http://forums.nesdev.com/viewtopic.php?f=2&t=3958
ppu_wait1:
  bit PPUSTATUS
  bpl ppu_wait1
ppu_wait2:
  bit PPUSTATUS
  bpl ppu_wait2

  ; Zero ram.
  txa
zeroram:
  sta $000, x
  sta $100, x
  sta $200, x
  sta $300, x
  sta $400, x
  sta $500, x
  sta $600, x
  sta $700, x
  inx
  bne zeroram

  ; Final wait for PPU warmup.
ppu_wait3:
  bit PPUSTATUS
  bpl ppu_wait3

  ; Initialize palettes.
  lda #(>PPU_PALETTE)         ; Set PPU address $3F00
  sta PPUADDR
  lda #(<PPU_PALETTE)
  sta PPUADDR

  ldx #0           ; Reset X index register
setpal:
  lda palettes, x  ; Load 32 bytes from the "palettes" label into PPUDATA
  sta PPUDATA
  inx
  cpx #$20
  bne setpal

  ; Stick some stuff into the OAM buffer
  lda #$04         ; Set sprite 1 to use tile 2
  sta $0201
  lda #$80
  sta $0200        ; put sprite 0 in center ($80) of screen vertically
  sta $0203        ; put sprite 0 in center ($80) of screen horizontally
  lda #$00
  sta PPUMASK      ; tile number = 0
  sta $0202        ; color palette = 0, no flipping

  lda #$06         ; Set sprite 1 to use tile 2
  sta $0205
  lda #$80
  sta $0204        ; put sprite 1 in center ($80) of screen vertically
  lda #$88
  sta $0207        ; put sprite 1 a little to the right ($88) of the other one
  lda #$00
  sta $0206        ; color palette = 0, no flipping

  lda #%10100000   ; enable NMI, sprites from Pattern Table 0
  sta PPUCTRL

  lda #%00010000   ; no intensify (black background), enable sprites
  sta PPUMASK

forever:
  lda FRAME
  beq flap
  lda #$02         ; Set sprite 1 to use tile 2
  sta $0205
  lda #$00         ; Set sprite 1 to use tile 2
  sta $0201
  sta FRAME
  jmp forever
flap:
  lda #$04         ; Set sprite 1 to use tile 2
  sta $0201
  lda #$06         ; Set sprite 1 to use tile 2
  sta $0205
  sta FRAME
  jmp forever

palettes:
  .byte $15           ; Universal BG color
  .byte $0F, $0F, $0F, $0F  ; BG 0
  .byte $0F, $0F, $0F, $0F  ; BG 1
  .byte $0F, $0F, $0F, $0F  ; BG 2
  .byte $0F, $0F, $0F, $0F  ; BG 3
  .byte $31, $27, $18, $0F  ; Sprite 0
  .byte $0F, $0F, $0F, $0F  ; Sprite 1
  .byte $0F, $0F, $0F, $0F  ; Sprite 2
  .byte $0F, $0F, $0F, $0F  ; Sprite 3
.endproc

; NMI (vertical blank) handler
.proc nmi
  ; Do OAM buffer copy here
  lda #0              ; copy into the beginning of OAM
  sta OAMADDR
  lda #(>OAMBUFFER)   ; from our OAM buffer in RAM ($0200)
  sta OAMDMA          ; and start DMA
.endproc

; IRQ handler
.proc irq
  rti
.endproc

; Vector table
.segment "VECTOR"
  .addr nmi
  .addr reset
  .addr irq

; CHR table
.segment "CHR0"
  .incbin "graphics/chr0_rearranged.chr"
