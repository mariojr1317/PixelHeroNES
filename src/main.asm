; ============================================================
; PIXEL HERO NES - colorful original platformer
; Target: NES / NROM-256 (Mapper 0), ca65
; ============================================================

.segment "HEADER"
.byte "NES", $1A
.byte 2                  ; 2 x 16 KiB PRG-ROM = 32 KiB
.byte 1                  ; 1 x 8 KiB CHR-ROM = 8 KiB
.byte %00000000          ; Mapper 0, horizontal mirroring
.byte %00000000
.byte $00
.byte $00
.res 5, $00

.segment "ZEROPAGE"
player_x:       .res 1
player_y:       .res 1
velocity_y:     .res 1
buttons:        .res 1
frame_ready:    .res 1

.segment "BSS"
oam_buffer:     .res 256

PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
PPUADDR   = $2006
PPUDATA   = $2007
OAMADDR   = $2003
OAMDMA    = $4014
CONTROLLER = $4016

.segment "CODE"

.proc reset
    sei
    cld
    ldx #$40
    stx $4017
    ldx #$FF
    txs
    inx
    stx PPUCTRL
    stx PPUMASK

    jsr wait_vblank
    jsr wait_vblank

    ; Clear internal RAM ($0000-$07FF).
    lda #$00
    tax
@clear_ram:
    sta $0000,x
    sta $0100,x
    sta $0200,x
    sta $0300,x
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
    inx
    bne @clear_ram

    lda #$30
    sta player_x
    lda #$C8
    sta player_y
    lda #$00
    sta velocity_y

    jsr load_palette
    jsr load_nametable
    jsr update_sprite

    ; Enable NMI, use pattern table 0 for background and sprites.
    lda #%10000000
    sta PPUCTRL
    lda #%00011110
    sta PPUMASK

@main_loop:
    lda frame_ready
    beq @main_loop
    lda #$00
    sta frame_ready

    jsr read_controller
    jsr update_player
    jsr update_sprite
    jmp @main_loop
.endproc

.proc wait_vblank
    bit PPUSTATUS
@wait:
    bit PPUSTATUS
    bpl @wait
    rts
.endproc

.proc load_palette
    ; Background palettes: bright sky, grass, soil and white clouds.
    lda PPUSTATUS
    lda #$3F
    sta PPUADDR
    lda #$00
    sta PPUADDR

    lda #$21               ; universal sky blue
    sta PPUDATA
    lda #$2A               ; green grass
    sta PPUDATA
    lda #$17               ; earthy brown
    sta PPUDATA
    lda #$30               ; white
    sta PPUDATA

    ; Background palette 1
    lda #$21
    sta PPUDATA
    lda #$12
    sta PPUDATA
    lda #$16
    sta PPUDATA
    lda #$30
    sta PPUDATA

    ; Background palette 2
    lda #$21
    sta PPUDATA
    lda #$06
    sta PPUDATA
    lda #$16
    sta PPUDATA
    lda #$30
    sta PPUDATA

    ; Background palette 3
    lda #$21
    sta PPUDATA
    lda #$2A
    sta PPUDATA
    lda #$17
    sta PPUDATA
    lda #$30
    sta PPUDATA

    ; Sprite palettes live at $3F10, not in the background palette area.
    lda PPUSTATUS
    lda #$3F
    sta PPUADDR
    lda #$10
    sta PPUADDR

    ; Palette 0: blue outfit, warm face, white highlights.
    lda #$0F
    sta PPUDATA
    lda #$16
    sta PPUDATA
    lda #$27
    sta PPUDATA
    lda #$30
    sta PPUDATA

    ; Initialize the remaining sprite palettes too.
    lda #$0F
    sta PPUDATA
    lda #$16
    sta PPUDATA
    lda #$27
    sta PPUDATA
    lda #$30
    sta PPUDATA
    lda #$0F
    sta PPUDATA
    lda #$16
    sta PPUDATA
    lda #$27
    sta PPUDATA
    lda #$30
    sta PPUDATA
    lda #$0F
    sta PPUDATA
    lda #$16
    sta PPUDATA
    lda #$27
    sta PPUDATA
    lda #$30
    sta PPUDATA
    rts
.endproc

.proc load_nametable
    lda PPUSTATUS
    lda #$20
    sta PPUADDR
    lda #$00
    sta PPUADDR

    ; 26 rows of sky (26 * 32 = 832 tiles).
    ldx #$00
@empty_rows:
    ldy #$00
@empty_tiles:
    lda #$00
    sta PPUDATA
    iny
    cpy #32
    bne @empty_tiles
    inx
    cpx #26
    bne @empty_rows

    ; First ground row is grass; three lower rows are dirt.
    ldx #$00
@grass:
    lda #$01
    sta PPUDATA
    inx
    cpx #32
    bne @grass

    ldx #$00
@dirt:
    lda #$02
    sta PPUDATA
    inx
    cpx #96
    bne @dirt

    ; Attribute table: use background palette 0 throughout.
    ldx #$00
@attributes:
    lda #$00
    sta PPUDATA
    inx
    cpx #64
    bne @attributes

    ; Add small cloud clusters high in the sky.
    lda PPUSTATUS
    lda #$20
    sta PPUADDR
    lda #$84               ; row 4, column 4
    sta PPUADDR
    lda #$03
    sta PPUDATA
    lda #$03
    sta PPUDATA

    lda PPUSTATUS
    lda #$20
    sta PPUADDR
    lda #$8D               ; row 4, column 13
    sta PPUADDR
    lda #$03
    sta PPUDATA
    lda #$03
    sta PPUDATA

    lda PPUSTATUS
    lda #$20
    sta PPUADDR
    lda #$97               ; row 4, column 23
    sta PPUADDR
    lda #$03
    sta PPUDATA
    lda #$03
    sta PPUDATA

    ; Flowers just above the ground.
    lda PPUSTATUS
    lda #$23
    sta PPUADDR
    lda #$26               ; row 25, column 6
    sta PPUADDR
    lda #$05
    sta PPUDATA

    lda PPUSTATUS
    lda #$23
    sta PPUADDR
    lda #$30               ; row 25, column 16
    sta PPUADDR
    lda #$05
    sta PPUDATA

    lda PPUSTATUS
    lda #$23
    sta PPUADDR
    lda #$3B               ; row 25, column 27
    sta PPUADDR
    lda #$05
    sta PPUDATA
    rts
.endproc

; NES controller bits: A=$01, B=$02, Select=$04, Start=$08,
; Up=$10, Down=$20, Left=$40, Right=$80.
.proc read_controller
    lda #$01
    sta CONTROLLER
    lda #$00
    sta CONTROLLER

    sta buttons
    ldx #$00
@read:
    lda CONTROLLER
    and #$01
    beq @not_pressed
    lda buttons
    ora controller_mask,x
    sta buttons
@not_pressed:
    inx
    cpx #$08
    bne @read
    rts
.endproc

controller_mask:
.byte $01, $02, $04, $08, $10, $20, $40, $80

.proc update_player
    ; Left
    lda buttons
    and #%01000000
    beq @right
    lda player_x
    cmp #$02
    bcc @right
    sec
    sbc #$02
    sta player_x

@right:
    lda buttons
    and #%10000000
    beq @jump
    lda player_x
    cmp #$E8
    bcs @jump
    clc
    adc #$02
    sta player_x

@jump:
    lda buttons
    and #%00000001
    beq @gravity
    lda player_y
    cmp #$C8
    bne @gravity
    lda #$F0               ; upward velocity (-16 pixels/frame)
    sta velocity_y

@gravity:
    ; Signed velocity is increased by 2 each frame.
    lda velocity_y
    clc
    adc #$02
    sta velocity_y
    lda player_y
    clc
    adc velocity_y
    sta player_y

    ; Ground top is at screen Y=208; the 8x8 player rests at Y=200.
    lda player_y
    cmp #$C8
    bcc @done
    lda #$C8
    sta player_y
    lda #$00
    sta velocity_y
@done:
    rts
.endproc

.proc update_sprite
    lda player_y
    sta oam_buffer
    lda #$04               ; character artwork tile
    sta oam_buffer+1
    lda #$00
    sta oam_buffer+2
    lda player_x
    sta oam_buffer+3

    ; Hide all remaining sprites off-screen.
    lda #$FE
    ldx #$04
@hide:
    sta oam_buffer,x
    inx
    bne @hide
    rts
.endproc

.proc nmi
    pha
    txa
    pha
    tya
    pha

    lda #$00
    sta OAMADDR
    lda #$02               ; OAM DMA source page $0200
    sta OAMDMA

    lda #$01
    sta frame_ready

    pla
    tay
    pla
    tax
    pla
    rti
.endproc

.proc irq
    rti
.endproc

.segment "CHARS"
; Tile 0: transparent sky.
.res 16, $00

; Tile 1: grassy top with earthy underside (background palette 0).
.byte $FF,$FF,$92,$00,$20,$12,$00,$10
.byte $00,$00,$6D,$FF,$DF,$ED,$FF,$EF

; Tile 2: textured dirt.
.byte $00,$10,$00,$22,$00,$10,$00,$08
.byte $FF,$EF,$FF,$DD,$FF,$EF,$FF,$F7

; Tile 3: puffy white cloud.
.byte $00,$38,$7E,$FF,$FF,$7E,$38,$00
.byte $00,$38,$7E,$FF,$FF,$7E,$38,$00

; Tile 4: tiny blue-haired adventurer, orange face, light shirt.
.byte $38,$7E,$42,$42,$38,$3C,$5A,$C3
.byte $00,$00,$3C,$3C,$38,$7E,$00,$00

; Tile 5: little flower for the landscape.
.byte $10,$38,$54,$38,$10,$10,$38,$00
.byte $10,$38,$54,$38,$00,$00,$00,$00

; Fill remaining CHR-ROM to exactly 8 KiB.
.res 8096, $00

.segment "VECTORS"
.word nmi
.word reset
.word irq
