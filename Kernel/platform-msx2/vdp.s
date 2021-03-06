            .module vdp

            .include "kernel.def"
            .include "../kernel.def"

	    ; video driver
	    .globl _scroll_up
	    .globl _scroll_down
	    .globl _plot_char
	    .globl _clear_lines
	    .globl _clear_across
	    .globl _cursor_on
	    .globl _cursor_off
	    .globl _cursorpos

	    .globl _vdpport

	    .area _CODE
;
;	Register write value E to register A
;
vdpout:	    ld bc, (_vdpport)
	    out (c), e
	    out (c), d
	    ret

;
;	FIXME: table.. and move into init ROM
;
vdpinit:    ld de, #0x8004		; M4 }
	    call vdpout 		;    }	80x25 mode
	    ld de, #0x8170		; M1 }  screen on, virq on hirq off
	    call vdpout
	    ld de, #0x8200		; characters at VRAM 0
	    call vdpout
	    ld de, #0x8320		; blink at 0x800
	    ld de, #0x8402		; font at 0x1000
	    call vdpout
	    ld de, #0x870F		; white text on black
	    call vdpout
	    ; FIXME: read reg 9 and set bit 7 to 0
	    ld de, #0x8C00		; vanish for blink
	    call vdpout
	    ld de, #0x8D33		; blink time
	    call vdpout
	    ld de, #0x8A00		; zero high bits of blink
	    call vdpout
            ld de, #0x8F00		; and we want status register 0 visible
	    call vdpout
	    ld de, #0x8E00		; we only look at the low area 
	    call vdpout
	    ; R45 - banking off ???
	    ; Wipe ram ?
            ret

;
;	FIXME: need to IRQ protect the pairs of writes
;


_videopos:	; turn E=Y D=X into HL = addr
	        ; pass B = 0x40 if writing
	        ; preserves C
	    ld a, e			; 0-24 Y
	    add a, a
	    add a, a
	    add a, a			; x 8
	    ld l, a
	    ld h, #0
	    add hl, hl			; x 16
	    push hl
	    add hl, hl
	    add hl, hl			; x 64
	    ld a, e
	    pop de
	    add hl, de			; x 80
	    ld l, a
	    ld h, b			; 0 for read 0x40 for write
	    add hl, de			; + X
	    ret
;
;	Eww.. wonder if VT should provide a hint that its the 'next char'
;
_plot_char: pop hl
	    pop de			; D = x E = y
	    pop bc
	    push bc
	    push de
	    push hl
plotit:
	    ld b, #0x40			; writing
	    call _videopos
	    ld a, c
	    ld bc, (_vdpport)
	    out (c), l			; address
	    out (c), h			; address | 0x40
	    out (c), a			; character
	    ret

;
;	FIXME: on the VDP9958 we can set R25 bit 6 and use the GPU
;	operations
;
;
;	Painful
;
	    .area	_DATA

scrollbuf:   .ds		80

	    .area	_CODE
;
;	We don't yet use attributes...
;
_scroll_down:
	    ld b, #23
	    ld de, #0x730	; start of bottom line
upline:
	    push bc
	    ld bc, (_vdpport)	; vdpport + 1 always holds #80
	    ld hl, #scrollbuf
	    out (c), e		; our position
	    out (c), d
	    inir		; safe on MSX2 but not MSX1
	    ld hl, #0x4080	; go down one line and into write mode
	    add hl, de		; relative to our position
	    out (c), l
	    out (c), h
	    ld b, #0x80
	    ld hl, #scrollbuf
	    otir		; video ptr is to the line below so keep going
	    pop bc		; recover line counter
	    ld hl, #0xffb0
	    add hl, de		; up 80 bytes
	    ex de, hl		; and back into DE
	    djnz upline
	    ret

_scroll_up:
	    ld b, #23
	    ld de, #80		; start of second line
downline:   push bc
	    ld bc, (_vdpport)
	    ld hl, #scrollbuf
	    out (c), e
	    out (c), d
	    inir
	    ld hl, #0x3FB0	; up 80 bytes in the low 12 bits, add 0x40
				; for write ( we will carry one into the top
				; nybble)
	    add hl, de
	    out (c), l
	    out (c), h
	    ld hl, #scrollbuf
	    ld b, #0x80
	    otir
	    pop bc
	    ld hl, #80
	    add hl, de
	    ex de, hl
	    djnz downline
	    ret

_clear_lines:
	    pop hl
	    pop de	; E = line, D = count
	    push de
	    push hl
	    ld c, d
	    ld d, #0
	    call _videopos
	    ld e, c
	    ld bc, (_vdpport)
	    out (c), l
	    out (c), h
				; Safe on MSX 2 to loop the data with IRQ on
				; but *not* on MSX 1
            ld a, #' '
l2:	    ld b, #80    	
l1:	    out (c), a		; Inner loop clears a line, outer counts
				; need 20 clocks between writes. DJNZ is 13,
				; out is 11
            djnz l1
	    dec e
	    jr nz, l2
	    ret

_clear_across:
	    pop hl
	    pop de	; DE = coords
	    pop bc	; C = count
	    push bc
	    push de
	    push hl
	    call _videopos
	    ld a, c
	    ld bc, (_vdpport)
	    out (c), l
	    out (c), h
	    ld b, a
            ld a, #' '
l3:	    out (c), a
            djnz l1
	    ret

;
;	FIXME: should use attribute blink flag not a char
;
_cursor_on:
	    pop hl
	    pop de
	    push de
	    push hl
	    ld (cursorpos), de
	    ld c, #'_'
            call plotit
	    ret
_cursor_off:
	    ld de, (cursorpos)
	    ld c, #' '
	    call plotit
	    ret
;
;	This must be in data or common not code
;
	    .area _DATA
cursorpos:  .dw 0
