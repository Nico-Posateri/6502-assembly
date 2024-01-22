;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ASM code for a simple Atari 2600 bomber game
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    processor 6502

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Include required files for VCS register memory mapping and macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    include "vcs.h"
    include "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Declare variables starting from memory address $80
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    seg.u Variables
    org $80

JetXPos         byte            ; player0 X-position
JetYPos         byte            ; player0 Y-position
BomberXPos      byte            ; player1 X-position
BomberYPos      byte            ; player1 Y-position
Score           byte            ; 2-digit score stored as BCD
Timer           byte            ; 2-digit timer stored as BCD
OnesDigitOffset word            ; Lookup table offset for the score 1's digit
TensDigitOffset word            ; Lookup table offset for the score 10's digit
JetSpritePtr    word            ; Pointer to player0 sprite lookup table
JetColorPtr     word            ; Pointer to player0 color lookup table
BomberSpritePtr word            ; Pointer to player1 sprite lookup table
BomberColorPtr  word            ; Pointer to player1 color lookup table
JetAnimOffset   byte            ; player0 sprite frame offset for animation
Random          byte            ; Random number generated to set enemy position

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Define constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

JET_HEIGHT = 9                  ; player0 sprite height (# of lookup table rows)
BOMBER_HEIGHT = 9               ; player1 sprite height
DIGITS_HEIGHT = 5               ; Scoreboard digit height

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start our ROM code at memory address $F000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    seg code
    org $F000

Reset:
    CLEAN_START                 ; Call macro to reset memory & registers

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize RAM variables and TIA registers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    lda #66
    sta JetXPos                 ; JetXPos = 66 (centered)
    lda #10
    sta JetYPos                 ; JetYPos = 10
    lda #61
    sta BomberXPos              ; BomberXPos = 61 (centered)
    lda #83
    sta BomberYPos              ; BomberYPos = 83
    lda #%11010100
    sta Random                  ; Random = $D4
    lda #0
    sta Score
    staa Timer                  ; Score and Timer = 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize the pointers to the correct lookup table addresses
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    lda #<JetSprite
    sta JetSpritePtr            ; lo-byte pointer for jet sprite lookup table
    lda #>JetSprite
    sta JetSpritePtr+1          ; hi-byte pointer for jet sprite lookup table

    lda #<JetColor
    sta JetColorPtr             ; lo-byte pointer for jet color lookup table
    lda #>JetColor
    sta JetColorPtr+1           ; hi-byte pointer for jet color lookup table

    lda #<BomberSprite
    sta BomberSpritePtr         ; lo-byte pointer for bomber sprite lookup table
    lda #>BomberSprite
    sta BomberSpritePtr+1       ; hi-byte pointer for bomber sprite lookup table

    lda #<BomberColor
    sta BomberColorPtr          ; lo-byte pointer for bomber color lookup table
    lda #>BomberColor
    sta BomberColorPtr+1        ; hi-byte pointer for bomber color lookup table

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start the main disaply loop and frame rendering
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartFrame:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calculations and tasks performed pre-VBLANK (jsr = jump to subroutine)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    lda JetXPos
    ldy #0
    jsr SetObjectXPos           ; Set player0 horizontal position

    lda BomberXPos
    ldy #1
    jsr SetObjectXPos           ; Set player1 horizontal position

    jsr CalculateDigitOffset    ; Calculates the scoreboard digit lookup table offset

    sta WSYNC
    sta HMOVE                   ; Apply the horizontal offsets previously set

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display VSYNC and VBLANK (40 scanlines)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    lda #2
    sta VBLANK                  ; Turn on VBLANK
    sta VSYNC                   ; Turn on VSYNC

    REPEAT 3
        sta WSYNC               ; Display 3 recommended lines of VSYNC
    REPEND
    lda #0
    sta VSYNC                   ; Turn off VSYNC

    REPEAT 37
        sta WSYNC               ; Display 37 recommended lines of VBLANK
    REPEND
    sta VBLANK                  ; Turn off VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display the scoreboard scanlines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    lda #0                      ; Clear the TIA registers before each new frame
    sta PF0
    sta PF1
    sta PF2
    sta GRP0
    sta GRP1
    lda #$1C                    ; Set playfield/scoreboard color to white
    sta COLUPF
    lda #%00000000
    sta CTRLPF                  ; Disable playfield reflection
    REPEAT 20
        sta WSYNC               ; Displays 20 scanlines for the scoreboard
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display the 96 visible scanlines of the game (because 2-line kernel)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GameVisibleLine:
    lda #$84                    ; Hexadecimal color code for blue
    sta COLUBK                  ; Store blue in background color (river)

    lda #$C2                    ; Hexadecimal color code for green
    sta COLUPF                  ; Store green in playfield color (grass)

    lda #%00000001              ; Enables playfield reflection
    sta CTRLPF                  ; Stores to Control Playfield to enable

    lda #$F0
    sta PF0                     ; Setting PF0 bit pattern

    lda #$FC
    sta PF1                     ; Setting PF1 bit pattern

    lda #0
    sta PF2                     ; Setting PF2 bit pattern

    ldx #84                     ; X counts the number of remaining scanlines

.GameLineLoop:

.AreWeInsideJetSprite:
    txa                         ; Transfer X to a
    sec                         ; Set carry flag before subtraction
    sbc JetYPos                 ; Subtract sprite Y-coordinate
    cmp JET_HEIGHT              ; Check if we're inside sprite height bounds
    bcc .DrawSpriteP0           ; Result < SpriteHeight? Call new draw routine
    lda #0                      ; Else, set lookup to zero
.DrawSpriteP0:
    clc                         ; Clear carry flag for addition
    adc JetAnimOffset           ; Jump to the correct sprite frame address in memory

    tay                         ; Load Y so we can work with the pointer
    lda (JetSpritePtr),Y        ; Load player0 bitmap data from the lookup table
    sta WSYNC                   ; Wait for scanline
    sta GRP0                    ; Set graphics for player0
    lda (JetColorPtr),Y         ; Load player0 color from lookup table
    sta COLUP0                  ; Set color for player0

.AreWeInsideBomberSprite:
    txa                         ; Transfer X to a
    sec                         ; Set carry flag before subtraction
    sbc BomberYPos              ; Subtract sprite Y-coordinate
    cmp BOMBER_HEIGHT           ; Check if we're inside sprite height bounds
    bcc .DrawSpriteP1           ; Result < SpriteHeight? Call new draw routine
    lda #0                      ; Else, set lookup to zero
.DrawSpriteP1:
    tay                         ; Load Y so we can work with the pointer
    lda #%00000101
    sta NUSIZ1                  ; Stretch player1 sprite
    lda (BomberSpritePtr),Y     ; Load player1 bitmap data from the lookup table
    sta WSYNC                   ; Wait for scanline
    sta GRP1                    ; Set graphics for player1
    lda (BomberColorPtr),Y      ; Load player1 color from lookup table
    sta COLUP1                  ; Set color for player1

    dex                         ; X--
    bne .GameLineLoop           ; Repeat next game scanline until finish

    lda #0
    sta JetAnimOffset           ; Reset sprite animation to first frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display overscan (30 scanlines)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    lda #2
    sta VBLANK                  ; Turn VBLANK back on
    REPEAT 30
        sta WSYNC               ; Displays 30 overscan lines
    REPEND
    lda #0
    sta VBLANK                  ; Turn VBLANK off again

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Process joystick input for player0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckP0Up:
    lda #%00010000              ; player0 joystick up
    bit SWCHA
    bne CheckP0Down             ; If bit pattern doesn't match, bypass Up block
    inc JetYPos
    lda #0
    sta JetAnimOffset           ; Reset sprite animation to first frame

CheckP0Down:
    lda #%00100000              ; player0 joystick down
    bit SWCHA
    bne CheckP0Left             ; If bit pattern doesn't match, bypass Down block
    dec JetYPos
    lda #0
    sta JetAnimOffset           ; Reset sprite animation to first frame

CheckP0Left:
    lda #%01000000              ; player0 joystick left
    bit SWCHA
    bne CheckP0Right            ; If bit pattern doesn't match, bypass Left block
    dec JetXPos
    lda JET_HEIGHT              ; 9
    sta JetAnimOffset           ; Set animation offset to the second frame

CheckP0Right:
    lda #%10000000              ; player0 joystick right
    bit SWCHA
    bne EndInputCheck           ; If bit pattern doesn't match, bypass Right block
    inc JetXPos
    lda JET_HEIGHT              ; 9
    sta JetAnimOffset           ; Set animation offset to the second frame

EndInputCheck:                  ; Fallback if no input was performed

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calculations to update position for next frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateBomberPosition:
    lda BomberYPos
    clc
    cmp #0                      ; Compare bomber Y-position with 0
    bmi .ResetBomberPosition    ; If < 0, reset bomber Y-position back to top
    dec BomberYPos              ; Else, decrement enemy Y-position for next frame
    jmp EndPositionUpdate
.ResetBomberPosition
    jsr GetRandomBomberPos      ; Call subroutine for random X-position

EndPositionUpdate               ; Fallback for the position update code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Checks for object collision
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckCollisionP0P1:
    lda #%10000000              ; CXPPMM bit 7 detects P0 and P1 collision
    bit CXPPMM                  ; Check CXPPMM with above pattern
    bne .CollisionP0P1          ; If P0 and P1 have collided, game over
    jmp CheckCollisionP0PF      ; Else, jump to next check
.CollisionP0P1:
    jsr GameOver                ; Call "Game Over" subroutine upon collsion

CheckCollisionP0PF:
    lda #%10000000              ; CXP0FB bit 7 detects P0 and PF collision
    bit CXP0FB                  ; Check CXP0FB with above pattern
    bne .CollisionP0PF          ; If P0 has collided with PF, game over
    jmp EndCollisionCheck       ; Else, jump to finally check
.CollisionP0PF:
    jsr GameOver

EndCollisionCheck:              ; Fallback
    sta CXCLR                   ; Clear collision flags before the next frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Loop back to start a new frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    jmp StartFrame              ; Continue displaying next frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to handle object horizontal position with fine offset
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; A is the target X-coordinatre position in pixels of our object
;; Y is the object type (0: player0, 1: player1 2: missile0, 3: missile1, 4: ball)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetObjectXPos subroutine
    sta WSYNC                   ; Start a fresh new scanline
    sec                         ; Make sure carry-flag is set before subtraction

.Div15Loop
    sbc #15                     ; Subtract 15 from accumulator
    bcs .Div15Loop              ; Loop until cary-flag is clear
    eor #7                      ; Handle offset range from -8 to 7
    asl
    asl
    asl
    asl                         ; Four shift-lefts to get only the top 4 bits
    sta HMP0,Y                  ; Store the fine offset to the correct HMxx
    sta RESP0,Y                 ; Fix object position in 15-step increment
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to mark Game Over upon collision
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GameOver subroutine

    lda #$30
    sta COLUBK
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to generate a Linear-Feedback Shift Registar random number
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Generate a LFSR random number
;; Divide the random value by 4 to limit the size of the result to match river
;; Add 30 to compensate for the left green playfield
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetRandomBomberPos subroutine
    lda Random
    asl
    eor Random
    asl
    eor Random
    asl
    asl
    eor Random
    asl
    rol Random                  ; Performs a series of shifts and bit operations

    lsr
    lsr                         ; Divide value by 4 by performing 2 right shifts
    sta BomberXPos              ; Saves to the variable BomberXPos
    lda #30
    adc BomberXPos              ; Adds 30 + BomberXPos to compensate for left playfield
    sta BomberXPos              ; Sets this value in the bomber X-position

    lda #96
    sta BomberYPos              ; Sets the bomber Y-position to the top of the screen

    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Declare ROM lookup tables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Digits:
    .byte %01110111             ; ### ###
    .byte %01010101             ; # # # #
    .byte %01010101             ; # # # #
    .byte %01010101             ; # # # #
    .byte %01110111             ; ### ###

    .byte %00010001             ;   #   #
    .byte %00010001             ;   #   #
    .byte %00010001             ;   #   #
    .byte %00010001             ;   #   #
    .byte %00010001             ;   #   #

    .byte %01110111             ; ### ###
    .byte %00010001             ;   #   #
    .byte %01110111             ; ### ###
    .byte %01000100             ; #   #
    .byte %01110111             ; ### ###

    .byte %01110111             ; ### ###
    .byte %00010001             ;   #   #
    .byte %00110011             ;  ##  ##
    .byte %00010001             ;   #   #
    .byte %01110111             ; ### ###

    .byte %01010101             ; # # # #
    .byte %01010101             ; # # # #
    .byte %01110111             ; ### ###
    .byte %00010001             ;   #   #
    .byte %00010001             ;   #   #

    .byte %01110111             ; ### ###
    .byte %01000100             ; #   #
    .byte %01110111             ; ### ###
    .byte %00010001             ;   #   #
    .byte %01110111             ; ### ###

    .byte %01110111             ; ### ###
    .byte %01000100             ; #   #
    .byte %01110111             ; ### ###
    .byte %01010101             ; # # # #
    .byte %01110111             ; ### ###

    .byte %01110111             ; ### ###
    .byte %00010001             ;   #   #
    .byte %00010001             ;   #   #
    .byte %00010001             ;   #   #
    .byte %00010001             ;   #   #

    .byte %01110111             ; ### ###
    .byte %01010101             ; # # # #
    .byte %01110111             ; ### ###
    .byte %01010101             ; # # # #
    .byte %01110111             ; ### ###

    .byte %01110111             ; ### ###
    .byte %01010101             ; # # # #
    .byte %01110111             ; ### ###
    .byte %00010001             ;   #   #
    .byte %01110111             ; ### ###

    .byte %00100010             ;  #   #
    .byte %01010101             ; # # # #
    .byte %01110111             ; ### ###
    .byte %01010101             ; # # # #
    .byte %01010101             ; # # # #

    .byte %01110111             ; ### ###
    .byte %01010101             ; # # # #
    .byte %01100110             ; ##  ##
    .byte %01010101             ; # # # #
    .byte %01110111             ; ### ###

    .byte %01110111             ; ### ###
    .byte %01000100             ; #   #
    .byte %01000100             ; #   #
    .byte %01000100             ; #   #
    .byte %01110111             ; ### ###

    .byte %01100110             ; ##  ##
    .byte %01010101             ; # # # #
    .byte %01010101             ; # # # #
    .byte %01010101             ; # # # #
    .byte %01100110             ; ##  ##

    .byte %01110111             ; ### ###
    .byte %01000100             ; #   #
    .byte %01110111             ; ### ###
    .byte %01000100             ; #   #
    .byte %01110111             ; ### ###

    .byte %01110111             ; ### ###
    .byte %01000100             ; #   #
    .byte %01100110             ; ##  ##
    .byte %01000100             ; #   #
    .byte %01000100             ; #   #

JetSprite:
    .byte #%00000000            ;
    .byte #%00010100            ;   # #
    .byte #%01111111            ; #######
    .byte #%00111110            ;  #####
    .byte #%00011100            ;   ###
    .byte #%00011100            ;   ###
    .byte #%00001000            ;    #
    .byte #%00001000            ;    #
    .byte #%00001000            ;    #

JetSpriteTurn:
    .byte #%00000000            ;
    .byte #%00001000            ;    #
    .byte #%00111110            ;  #####
    .byte #%00011100            ;   ###
    .byte #%00011100            ;   ###
    .byte #%00011100            ;   ###
    .byte #%00001000            ;    #
    .byte #%00001000            ;    #
    .byte #%00001000            ;    #

BomberSprite:
    .byte #%00000000            ;
    .byte #%00001000            ;    #
    .byte #%00001000            ;    #
    .byte #%00101010            ;  # # #
    .byte #%00101010            ;  # # #
    .byte #%01111111            ; #######
    .byte #%01110111            ; ### ###
    .byte #%00111110            ;  #####
    .byte #%00101010            ;  # # #

JetColor:
    .byte #$00
    .byte #$3C
    .byte #$06
    .byte #$0C
    .byte #$0C
    .byte #$9E
    .byte #$0C
    .byte #$0C
    .byte #$06

JetColorTurn:
    .byte #$00
    .byte #$3C
    .byte #$06
    .byte #$0C
    .byte #$0C
    .byte #$9E
    .byte #$0C
    .byte #$0C
    .byte #$06

BomberColor:
    .byte #$00
    .byte #$42
    .byte #$42
    .byte #$42
    .byte #$42
    .byte #$42
    .byte #$42
    .byte #$42
    .byte #$06

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Complete ROM size
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    org $FFFC                   ; Move to position $FFFC
    .word Reset                 ; Write 2 bytes (program reset address)
    .word Reset                 ; Write 2 bytes (interruption vector)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; In the Windows Command Prompt, navigate to folder containing .asm
;; To assemble, enter: dasm "FILE NAME".asm -f3 -v0 -ocart.bin
;; In Windows, you MUST include .asm extension, bin is named cart
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
