.include "nes_constants.s"

OAMBUFFER = $0200

.zeropage
  frame:        .res 1    ; current fly animation frame
  update_ready: .res 1    ; Has the main loop finished updating the OAM buffer?
  nmi_done:     .res 1    ; Has the NMI handler completed?
  fly_x:        .res 1    ; fly position
  fly_y:        .res 1
  buttons:      .res 1    ; button state
  eight_px:     .res 1

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

  ; Initialize game variables
  ldx #$20
  stx fly_x
  stx fly_y
  ldx #$7
  stx eight_px
  ldx #0
  stx update_ready
  stx nmi_done
  stx frame
  stx buttons

  ; Stick some stuff into the OAM buffer
  lda #$04         ; Set sprite 1 to use tile 2
  sta $0201
  lda fly_y
  sta $0200        ; put sprite 0 in center ($80) of screen vertically
  lda fly_x
  sta $0203        ; put sprite 0 in center ($80) of screen horizontally
  lda #$00
  sta PPUMASK      ; tile number = 0
  sta $0202        ; color palette = 0, no flipping

  lda #$06         ; Set sprite 1 to use tile 2
  sta $0205
  lda fly_y
  sta $0204        ; put sprite 1 in center ($80) of screen vertically
  lda fly_x
  adc eight_px
  sta $0207        ; put sprite 1 a little to the right ($88) of the other one
  lda #$00
  sta $0206        ; color palette = 0, no flipping

  lda #%10100000   ; enable NMI, sprites from Pattern Table 0
  sta PPUCTRL

  lda #%00010000   ; no intensify (black background), enable sprites
  sta PPUMASK

forever:

  ; Wait for NMI to complete
wait_nmi:
  lda nmi_done
  beq wait_nmi
  lda #0
  sta nmi_done

  ; Cycle sprites 0 and 0 between animation frames, using the "frame" variable
  ; to keep track of the current state.
  lda frame
  beq flap
  lda #$02         ; Set sprite 1 to use tile 2
  sta $0205
  lda #$00         ; Set sprite 0 to use tile 0
  sta $0201
  sta frame
  jmp anim_done
flap:
  lda #$04         ; Set sprite 0 to use tile 4
  sta $0201
  lda #$06         ; Set sprite 1 to use tile 6
  sta $0205
  sta frame

anim_done:
  ; Read the joypad and move the fly sprites
  jsr read_controller
  lda buttons
  and #BUTTON_LEFT
  beq right
  dec fly_x
right:
  lda buttons
  and #BUTTON_RIGHT
  beq up
  inc fly_x
up:
  lda buttons
  and #BUTTON_UP
  beq down
  dec fly_y
down:
  lda buttons
  and #BUTTON_DOWN
  beq update_sprites
  inc fly_y

update_sprites:
  ; Update sprite positions
  lda fly_y
  sta $0200        ; put sprite 0 in center ($80) of screen vertically
  lda fly_x
  sta $0203        ; put sprite 0 in center ($80) of screen horizontally
  lda fly_y
  sta $0204        ; put sprite 1 in center ($80) of screen vertically
  lda fly_x
  adc eight_px
  sta $0207        ; put sprite 1 a little to the right ($88) of the other one

  lda #1
  sta update_ready ; Let the NMI handler know we're ready to update OAM
  jmp forever

read_controller:
    lda #$01
    ; While the strobe bit is set, buttons will be continuously reloaded.
    ; This means that reading from CONTROLLER_1 will only return the state of the
    ; first button: button A.
    sta CONTROLLER_1
    sta buttons
    lsr a        ; now A is 0
    ; By storing 0 into CONTROLLER_1, the strobe bit is cleared and the reloading stops.
    ; This allows all 8 buttons (newly reloaded) to be read from CONTROLLER_1.
    sta CONTROLLER_1
loop:
    lda CONTROLLER_1
    lsr a	       ; bit 0 -> Carry
    rol buttons  ; Carry -> bit 0; bit 7 -> Carry
    bcc loop
    rts

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
  pha
  lda update_ready
  beq skip_update
  lda #0              ; copy into the beginning of OAM
  sta OAMADDR
  lda #(>OAMBUFFER)   ; from our OAM buffer in RAM ($0200)
  sta OAMDMA          ; and start DMA
  lda #0              ; clear the update flag
  sta update_ready
skip_update:
  inc nmi_done
  pla                 ; and pop the accumulator, back to your regularly scheduled loop
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
