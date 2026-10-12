; ============================================================
; PIXEL HERO NES - original platformer prototype
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
    lda #$C0
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
    lda PPUSTATUS
    lda #$3F
    sta PPUADDR
    lda #$00
    sta PPUADDR

    ; Background palette 0
    lda #$0F
    sta PPUDATA
    lda #$16
    sta PPUDATA
    lda #$27
    sta PPUDATA
    lda #$30
    sta PPUDATA

    ; Background palettes 1-2
    lda #$0F
    sta PPUDATA
    lda #$12
    sta PPUDATA
    lda #$21
    sta PPUDATA
    lda #$30
    sta PPUDATA
    lda #$0F
    sta PPUDATA
    lda #$06
    sta PPUDATA
    lda #$16
    sta PPUDATA
    lda #$30
    sta PPUDATA

    ; Sprite palette 0
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

    ; 26 empty rows (26 * 32 = 832 tiles).
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

    ; Four rows of ground (4 * 32 = 128 tiles).
    ldx #$00
@floor:
    lda #$01
    sta PPUDATA
    inx
    cpx #128
    bne @floor

    ; 64 bytes of attribute table.
    ldx #$00
@attributes:
    lda #$00
    sta PPUDATA
    inx
    cpx #64
    bne @attributes
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
    cmp #$C0
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

    ; Ground top is at screen Y=208; player rests at Y=192.
    lda player_y
    cmp #$C0
    bcc @done
    lda #$C0
    sta player_y
    lda #$00
    sta velocity_y
@done:
    rts
.endproc

.proc update_sprite
    lda player_y
    sta oam_buffer
    lda #$02
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
; Tile 0: blank.
.res 16, $00

; Tile 1: ground block, color 1.
.byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte $00,$00,$00,$00,$00,$00,$00,$00

; Tile 2: solid-color player, color 3.
.byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; Fill remaining CHR-ROM to exactly 8 KiB.
.res 8128, $00

.segment "VECTORS"
.word nmi
.word reset
.word irq
