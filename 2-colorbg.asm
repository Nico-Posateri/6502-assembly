;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ASM code to change displayed background color
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    processor 6502

    include "vcs.h"
    include "macro.h"

    seg code
    org $F000       ; Defines the origin of the ROM at $F000

Start:
    CLEAN_START     ; Macro to safely clear the memory
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set background luminosity color to yellow (NTSC format)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    lda #$1E        ; Load color into A ($1E is NTSC yellow)
    sta COLUBK      ; Store A to BackgroundColor Address $09

    jmp Start       ; Repeat from Start

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fill ROM size to exactly 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    org $FFFC       ; Defines origin to $FFFC
    .word Start     ; Reset vector at $FFFC (where program starts)
    .word Start     ; Interrupt vector at $FFFE (unused in the VCS)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; In the Windows Command Prompt, navigate to folder containing .asm
;; To assemble, enter: dasm "FILE NAME".asm -f3 -v0 -ocart.bin
;; In Windows, you MUST include .asm extension, bin is named cart
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
