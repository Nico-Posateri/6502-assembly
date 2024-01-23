;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ASM code to display playfield graphics
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    processor 6502

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Include required files with definitions and macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    include "vcs.h"
    include "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start ROM code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    seg
    org $F000       ; Defines the origin of the ROM at $F000

Reset:
    CLEAN_START     ; Macro to safely clear the memory

    ldx #$80        ; Blue background color
    stx COLUBK

    lda #$1C        ; Yellow playfield color
    sta COLUPF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start a new frame by configuring VBLANK and VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartFrame:
    lda #2
    sta VBLANK      ; Turn on VBLANK
    sta VSYNC       ; Turn on VSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Generate the three lines of VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    REPEAT 3        ; Shortcut in DASM for looping (here, 3 times)
        sta WSYNC   ; Scanlines for VSYNC
    REPEND

    lda #0
    sta VSYNC       ; Turn off VSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Let the TIA output the recommended 37 scanlines of VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    REPEAT 37
        sta WSYNC
    REPEND

    lda #0
    sta VBLANK      ; Turn off VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set the CTRLPF register to allow playfield reflection
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ldx #%00000001  ; CTRLPF register (D0 means reflect the PF)
    stx CTRLPF      ; Stores value in playfield

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw the 192 visible scanlines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Skip 7 vertical scanlines with no PF set
    ldx #0
    stx PF0
    stx PF1
    stx PF2
    REPEAT 7
        sta WSYNC
    REPEND

    ; Set the PF0 to 1110 (LSB first) and PF1-PF2 as 1111 1111
    ldx #%11100000
    stx PF0
    ldx #%11111111
    stx PF1
    stx PF2
    REPEAT 7
        sta WSYNC
    REPEND

    ; Set the next 164 lines only with PF0 third bit enabled
    ldx #%00100000
    stx PF0
    ldx #0
    stx PF1
    stx PF2
    REPEAT 164
        sta WSYNC
    REPEND

    ; Set the PF0 to 1110 (LSB first) and PF1-PF2 as 1111 1111
    ldx #%11100000
    stx PF0
    ldx #%11111111
    stx PF1
    stx PF2
    REPEAT 7
        sta WSYNC
    REPEND

    ; Skip 7 vertical scanlines with no PF set
    ldx #0
    stx PF0
    stx PF1
    stx PF2
    REPEAT 7
        sta WSYNC
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Output 30 more VBLANK lines (overscan) to complete the frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    lda #2
    sta VBLANK
    REPEAT 30
        sta WSYNC
    REPEND
    lda #0
    sta VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Loop to next frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    jmp StartFrame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Complete ROM size to 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    org $FFFC
    .word Reset
    .word Reset

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; In the Windows Command Prompt, navigate to folder containing .asm
;; To assemble, enter: dasm "FILE NAME".asm -f3 -v0 -ocart.bin
;; In Windows, you MUST include .asm extension, bin is named cart
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
