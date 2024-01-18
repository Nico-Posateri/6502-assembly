;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ASM code for 6502 which clears cartridge memory from $00 to $FF
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    processor 6502

    seg code
    org $F000       ; Define the code origin at $F000

Start:
    sei             ; Disable interrupts
    cld             ; Disable the BCD decimal math mode
    ldx #$FF        ; Loads the X register with literal hex FF
    txs             ; (T)ransfer (X) register to the (S)tack pointer

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Clear the Page Zero region ($00 to $FF)
;; Meaning the entirety of RAM and entirety of the TIA registers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    lda #0          ; Load A register with literal value of 0, A = 0
    ldx #$FF        ; X = #$FF
    sta $FF         ; Make sure $FF is zeroed before the loop starts

MemLoop:
    dex             ; Decrements X register, X--
    sta $0,X        ; Store the value of A inside mem address $0 + X
    bne MemLoop     ; Loops until X is equal to zero (z-flag is set)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fill the ROM size to exactly 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    org $FFFC       ; Jump to address $FFFC at bottom of cartridge
    .word Start     ; +2 bytes, reset vector at $FFFC, program start
    .word Start     ; +2 bytes

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; In the Windows Command Prompt, navigate to folder containing .asm
;; To assemble, enter: dasm "FILE NAME".asm -f3 -v0 -ocart.bin
;; In Windows, you MUST include .asm extension, bin is named cart
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
