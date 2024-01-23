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
MissileXPos     byte            ; Missile X-position
MissileYPos     byte            ; Missile Y-position
Score           byte            ; 2-digit score stored as BCD
Timer           byte            ; 2-digit timer stored as BCD
Temp            byte            ; Auxiliary variable to store temporary score values
OnesDigitOffset word            ; Lookup table offset for the score 1's digit
TensDigitOffset word            ; Lookup table offset for the score 10's digit
JetSpritePtr    word            ; Pointer to player0 sprite lookup table
JetColorPtr     word            ; Pointer to player0 color lookup table
BomberSpritePtr word            ; Pointer to player1 sprite lookup table
BomberColorPtr  word            ; Pointer to player1 color lookup table
JetAnimOffset   byte            ; player0 sprite frame offset for animation
Random          byte            ; Random number generated to set enemy position
ScoreSprite     byte            ; Store the sprite bit pattern for the score
TimerSprite     byte            ; Store the sprite bit pattern for the timer
TerrainColor    byte            ; Store the color of the terrain playfield
RiverColor      byte            ; Store the color of the river playfield

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
    sta Score                   ; Score = 0
    sta Timer                   ; Timer = 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Declare a MACRO to check if the missile 0 should be drawn
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    MAC DRAW_MISSILE
        lda #%00000000
        cpx MissileYPos         ; Compare X (current scanline) with missile Y-position
        bne .SkipMissileDraw    ; If X != missile Y-position, skip draw
.DrawMissile:
        lda #%00000010          ; Else, enable missile 0 display
        inc MissileYPos         ; MissileYPos++
.SkipMissileDraw:
        sta ENAM0               ; Store the correct value in the TIA missile register
    ENDM

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
;; Start the main display loop and frame rendering
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartFrame:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display VSYNC and VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    lda #2
    sta VBLANK                  ; Turn on VBLANK
    sta VSYNC                   ; Turn on VSYNC

    REPEAT 3
        sta WSYNC               ; Display 3 recommended lines of VSYNC
    REPEND
    lda #0
    sta VSYNC                   ; Turn off VSYNC

    REPEAT 33                   ; The following block executes inside the VBLANK ...
        sta WSYNC               ; So, display 33 remaining lines of VBLANK instead of 37
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calculations and tasks performed inside the VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    lda JetXPos
    ldy #0
    jsr SetObjectXPos           ; Set player0 horizontal position

    lda BomberXPos
    ldy #1
    jsr SetObjectXPos           ; Set player1 horizontal position

    lda MissileXPos
    ldy #2
    jsr SetObjectXPos           ; Set missile horizontal position

    jsr CalculateDigitOffset    ; Calculates the scoreboard digit lookup table offset

    jsr GenerateJetSound        ; Configure and enable jet engine audio

    sta WSYNC
    sta HMOVE                   ; Apply the horizontal offsets previously set

    lda #0
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
    sta CTRLPF
    sta COLUBK

    lda #$1E
    sta COLUPF                  ; Set the scoreboard playfield color to yellow

    ldx #DIGITS_HEIGHT          ; Start x counter with 5 (height of digits)

.ScoreDigitLoop:
    ldy TensDigitOffset         ; Get the tens digit offset for the score
    lda Digits,Y                ; Load the bit pattern from the lookup table
    and #$F0                    ; Mask/remove the graphics for the ones digit
    sta ScoreSprite             ; Save the score tens digit pattern in a variable

    ldy OnesDigitOffset         ; Get the ones digit offset for the score
    lda Digits,Y                ; Load the bit pattern from the lookup table
    and #$0F                    ; Mask/remove the graphics for the tens digit
    ora ScoreSprite             ; Merge it with the saved tens digit sprite
    sta ScoreSprite             ; Save it
    sta WSYNC                   ; Wait for the end of the scanline
    sta PF1                     ; Update the playfield to display the score sprite

    ldy TensDigitOffset+1       ; Get the left digit offset for the timer
    lda Digits,Y                ; Load the bit pattern from the lookup table
    and #$F0                    ; Mask/remove the graphics for the ones digit
    sta TimerSprite             ; Save the timer tens digit pattern in a variable

    ldy OnesDigitOffset+1       ; Get the ones digit offset for the timer
    lda Digits,Y                ; Load the bit pattern from the lookup table
    and #$0F                    ; Mask/remove the graphics for the tens digit
    ora TimerSprite             ; Merge it with the saved tens digit sprite
    sta TimerSprite             ; Save it

    jsr Sleep12Cycles           ; Wastes 12 cycles

    sta PF1                     ; Update the playfield to display the timer sprite

    ldy ScoreSprite             ; Preload for the next scanline
    sta WSYNC                   ; Wait for next scanline

    sty PF1                     ; Update playfield for the score display
    inc TensDigitOffset
    inc TensDigitOffset+1
    inc OnesDigitOffset
    inc OnesDigitOffset+1       ; Increment all digits for the next line of data

    jsr Sleep12Cycles           ; Wastes 12 cycles

    dex                         ; X--
    sta PF1                     ; Update the playfield for the Timer display
    bne .ScoreDigitLoop         ; If dex != 0, branch to ScoreDigitLoop

    sta WSYNC

    lda #0
    sta PF0
    sta PF1
    sta PF2
    sta WSYNC
    sta WSYNC
    sta WSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display the 96 visible scanlines of the game (not 192, because of the 2-line kernel)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GameVisibleLine:

    lda TerrainColor
    sta COLUPF                  ; Set the terrain background color

    lda RiverColor
    sta COLUBK                  ; Set the river background color

    lda #%00000001              ; Enables playfield reflection
    sta CTRLPF                  ; Stores to Control Playfield to enable

    lda #$F0
    sta PF0                     ; Setting PF0 bit pattern

    lda #$FC
    sta PF1                     ; Setting PF1 bit pattern

    lda #0
    sta PF2                     ; Setting PF2 bit pattern

    ldx #85                     ; X counts the number of remaining scanlines

.GameLineLoop:
    DRAW_MISSILE                ; Macro to check if the missile should be drawn

.AreWeInsideJetSprite:
    txa                         ; Transfer X to a
    sec                         ; Set carry flag before subtraction
    sbc JetYPos                 ; Subtract sprite Y-coordinate
    cmp #JET_HEIGHT              ; Check if we're inside sprite height bounds
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
    cmp #BOMBER_HEIGHT           ; Check if we're inside sprite height bounds
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
    lda JetYPos
    cmp #70                     ; If player0 Y-position > 70
    bpl CheckP0Down             ; Then, skip increment
.P0UpPressed:
    inc JetYPos                 ; Else, increment Y-position
    lda #0
    sta JetAnimOffset           ; Reset sprite animation to first frame

CheckP0Down:
    lda #%00100000              ; player0 joystick down
    bit SWCHA
    bne CheckP0Left             ; If bit pattern doesn't match, bypass Down block
    lda JetYPos
    cmp #5                      ; If player0 Y-position < 5
    bmi CheckP0Left             ; Then, skip decrement
.P0DownPressed:
    dec JetYPos                 ; Else, decrement Y-position
    lda #0
    sta JetAnimOffset           ; Reset sprite animation to first frame

CheckP0Left:
    lda #%01000000              ; player0 joystick left
    bit SWCHA
    bne CheckP0Right            ; If bit pattern doesn't match, bypass Left block
    lda JetXPos
    cmp #35                     ; If player0 X-position < 35
    bmi CheckP0Right            ; Then, skip decrement
.P0LeftPressed:
    dec JetXPos                 ; Else, decrement X-position
    lda #JET_HEIGHT              ; 9
    sta JetAnimOffset           ; Set animation offset to the second frame

CheckP0Right:
    lda #%10000000              ; player0 joystick right
    bit SWCHA
    bne CheckButtonPressed      ; If bit pattern doesn't match, bypass Right block
    lda JetXPos
    cmp #100                    ; If player0 X-position > 100
    bpl CheckButtonPressed      ; Then, skip increment
.P0RightPressed:
    inc JetXPos                 ; Else, increment X-position
    lda #JET_HEIGHT              ; 9
    sta JetAnimOffset           ; Set animation offset to the second frame

CheckButtonPressed:
    lda #%10000000              ; If button is pressed
    bit INPT4
    bne EndInputCheck
.ButtonPressed:
    lda JetXPos
    clc
    adc #5
    sta MissileXPos             ; Set missile X-position equal to player0 X-position
    lda JetYPos
    clc
    adc #8
    sta MissileYPos             ; Set missile Y-position equal to player0 Y-position

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
.ResetBomberPosition:
    jsr GetRandomBomberPos      ; Call subroutine for random X-position

.SetScoreValues:
    sed                         ; Set decimal mode (BCD) for Score and Timer values
    lda Timer
    clc
    adc #1
    sta Timer                   ; Add 1 to Timer (BCD does not work well with INC)
    cld                         ; Disable decimal mode after Score and Timer have updated

EndPositionUpdate:              ; Fallback for the position update code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Checks for object collision
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckCollisionP0P1:
    lda #%10000000              ; CXPPMM bit 7 detects P0 and P1 collision
    bit CXPPMM                  ; Check CXPPMM with above pattern
    bne .P0P1Collided           ; If P0 and P1 have collided, game over
    jsr SetTerrainRiverColor    ; Else, set playfield color to green and blue
    jmp CheckCollisionM0P1      ; Else, jump to next check
.P0P1Collided:
    jsr GameOver                ; Call "Game Over" subroutine upon collsion

CheckCollisionM0P1:
    lda #%10000000              ; CXM0P bit 7 detects M0 and P1 collision
    bit CXM0P                   ; Check CXM0P with above pattern
    bne .M0P1Collided           ; If M0 and P1 have collided, increase the score
    jmp EndCollisionCheck       ; Else, jump to final check
.M0P1Collided:
    sed                         ; Start BCD
    lda Score
    clc
    adc #1
    sta Score                   ; Score++ using BCD
    cld                         ; End BCD
    lda #0
    sta MissileYPos             ; Removes missile from play upon collision

EndCollisionCheck:              ; Fallback
    sta CXCLR                   ; Clear collision flags before the next frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Loop back to start a new frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    jmp StartFrame              ; Continue displaying next frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to generate audio for the jet engine sound on the jet Y-position
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; AUDV0 & AUDV1 Channels: Volume scale from 0 (off) to 15 (loudest)
;; AUDF0 & AUDF1 Channels: Frequency scale from 31 (lowest pitch) to 0 (highest pitch)
;; AUDC0 & AUDC1 Channels: Circuit that alters waveform via 1 of 15 values
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GenerateJetSound subroutine
    lda #3
    sta AUDV0                   ; Volume
    lda #15
    sta AUDF0                   ; Frequency
    lda #4
    sta AUDC0                   ; Distortion
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to set the colors for the terrain and river to green and blue
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetTerrainRiverColor subroutine
    lda #$C2
    sta TerrainColor            ; Set terrain color to green
    lda #$84
    sta RiverColor              ; Set river color to blue
    rts

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
    sta TerrainColor            ; Set terrain color to red upon collision
    sta RiverColor              ; Set river color to red upon collision
    lda #0
    sta Score                   ; Reset score to 0 at game over
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
;; Subroutine to handle scoreboard digits to be displayed on the screen
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Convert the high and low nibbles of the variable Score and Timer into the offsets of
;; the digits lookup table so the values can be displayed ... each digit has a height
;; of 5 bytes in the lookup table ...
;;
;; The low nibble needs to be multiplied by 5:
;;    - Left shifts can be used to multiply by 2
;;    - For any number N, the value of N*5 = (N*2*2) + N
;;
;; The high nibble, since it's *16, needs to be divided then multiplied by 5:
;;    - Right shifts can be used to divide by 2
;;    - For any number N, the value of (N/16)*5 = (N/2/2) + (N/2/2/2/2)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalculateDigitOffset subroutine
    ldx #1                      ; x register is the loop counter
.PrepareScoreLoop               ; This will loop twice, first x = 1, then x = 0

    lda Score,X                 ; Load A with Timer (x = 1) or Score (x = 0)
    and #$0F                    ; Removes the 10's digit by masking 4 bits with 00001111
    sta Temp                    ; Save value of A into Temp
    asl                         ; Shift left, now (N*2)
    asl                         ; Shift left, now (N*4)
    adc Temp                    ; Add the value saved in Temp (+N)
    sta OnesDigitOffset,X       ; Save A in in OnesDigitOffset+1 or OnesDigitOffset

    lda Score,X                 ; Load A with Timer (x = 1) or Score (x = 0)
    and #$F0                    ; Removes the 10's digit by masking 4 bits with 11110000
    lsr                         ; Shift right, now (N/2)
    lsr                         ; Shift right, now (N/4)
    sta Temp                    ; Save the value of A into Temp
    lsr                         ; Shift right, now (N/8)
    lsr                         ; Shift right, now (N/16)
    adc Temp                    ; Add the value saved in Temp, (N/16) + (N/4) 
    sta TensDigitOffset,X       ; Save A in in TensDigitOffset+1 or TensDigitOffset

    dex                         ; X--
    bpl .PrepareScoreLoop       ; While x >= 0, loop to pass a second time
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to waste 12 cycles
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; jsr (jump subroutine) takes 6 cycles
;; rts (return subroutine) takes 6 cycles
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Sleep12Cycles subroutine
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
