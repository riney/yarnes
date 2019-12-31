; PPU registers
PPUCTRL       = $2000
PPUMASK       = $2001
PPUSTATUS     = $2002
OAMADDR       = $2003
OAMDATA       = $2004
PPUSCROLL     = $2005
PPUADDR       = $2006
PPUDATA       = $2007

; Other IO registers
OAMDMA        = $4014
APUSTATUS     = $4015

; PPU register constants; all constants starting with "PPU_" are in the
; PPU's address space, not the 2A03's.
PPU_PALETTE   = $3F00

; Controller ports and button constants
CONTROLLER_1  = $4016
CONTROLLER_2  = $4017
BUTTON_A      = %10000000
BUTTON_B      = %01000000
BUTTON_SELECT = %00100000
BUTTON_START  = %00010000
BUTTON_UP     = %00001000
BUTTON_DOWN   = %00000100
BUTTON_LEFT   = %00000010
BUTTON_RIGHT  = %00000001