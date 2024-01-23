;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ASM code to implement vertical movement
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    processor 6502

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Include required files for register mapping and macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    include "vcs.h"
    include "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start an uninitialized segment at $80 for variable declaration
;; There is memory from $80 to $FF to work with, minus a few at
;; the end if the stack is used
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    seg.u Variables
    org $80
P0Height   byte    ; Player sprite height
PlayerYPos byte    ; Player sprite Y coordinate

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start a ROM code segment, starting at $F000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    seg Code
    org $F000

Reset:
    CLEAN_START    ; Macro to clean memory and TIA

    ldx #149       ; Light blue background color
    stx COLUBK
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    lda #180
    sta PlayerYPos ; PlayerYPos = 180

    lda #9         
    sta P0Height   ; P0Height = 9

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start a new frame by configuring VBLANK and VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartFrame:
    lda #2
    sta VBLANK     ; Turn VBLANK on
    sta VSYNC      ; Turn VSYNC on

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display 3 vertical lines of VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    REPEAT 3
        sta WSYNC  ; First three VSYNC scanlines
    REPEND

    lda #0
    sta VSYNC      ; Turn VSYNC off

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Let the TIA output the 37 recommended lines of VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    REPEAT 37
        sta WSYNC
    REPEND

    lda #0
    sta VBLANK     ; Turn VBLANK off

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw the 192 visible scanlines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ldx #192       ; X counter containing the remaining scanlines

Scanline:
    txa            ; Transfer X to A
    sec            ; Make sure the carry flag is set
    sbc PlayerYPos ; Subtract the sprite Y coordinate
    cmp P0Height   ; Are we inside the sprite height bounds?
    bcc LoadBitmap ; If result < SpriteHeight, call the subroutine
    lda #0         ; Else, set index to 0

LoadBitmap:
    tay
    lda P0Bitmap,Y ; Load player bitmap slice of data

    sta WSYNC      ; Wait for the next scanline

    sta GRP0       ; Set graphics for player 0 slice

    lda P0Color,Y  ; Load player color from the lookup table

    sta COLUP0     ; Set color for player 0 slice

    dex
    bne Scanline   ; Repeat next scanline until finished

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Output 30 more VBLANK overscan lines to complete our frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Overscan:
    lda #2
    sta VBLANK     ; Turn VBLANK on again for overscan
    REPEAT 30
        sta WSYNC
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Decrement Y-coordinate in each frame for animation effect
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    dec PlayerYPos

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Loop to next frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    jmp StartFrame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Lookup table for the player graphics bitmap
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

P0Bitmap:
    byte #%00000000
    byte #%00101000
    byte #%01110100
    byte #%11111010
    byte #%11111010
    byte #%11111010
    byte #%11111110
    byte #%01101100
    byte #%00110000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Lookup table for the player colors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

P0Color:
    byte #$00
    byte #$40
    byte #$40
    byte #$40
    byte #$40
    byte #$42
    byte #$42
    byte #$44
    byte #$D2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Complete ROM size adding reset addresses at $FFFC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    org $FFFC
    .word Reset
    .word Reset

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; In the Windows Command Prompt, navigate to folder containing .asm
;; To assemble, enter: dasm "FILE NAME".asm -f3 -v0 -ocart.bin
;; In Windows, you MUST include .asm extension, bin is named cart
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
