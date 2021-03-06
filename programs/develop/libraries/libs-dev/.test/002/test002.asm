use32
org 0x0

db 'MENUET01'
dd 0x01, START, I_END, 0x1000, 0x1000, @PARAMS, 0x0

;-----------------------------------------------------------------------------

FALSE = 0
TRUE  = 1

include '../../../../../proc32.inc'
include '../../../../../macros.inc'
include '../../../../../dll.inc'

include '../../libio/libio.inc'
include '../../libimg/libimg.inc'

;-----------------------------------------------------------------------------

START:
	mcall	68, 11

	stdcall dll.Load, @IMPORT
	or	eax, eax
	jnz	exit

	invoke	file.open, @PARAMS, O_READ
	or	eax, eax
	jz	exit
	mov	[fh], eax
	invoke	file.size, @PARAMS
	mov	[img_data_len], ebx
	stdcall mem.Alloc, ebx
	or	eax, eax
	jz	exit
	mov	[img_data], eax
	invoke	file.read, [fh], eax, [img_data_len]
	cmp	eax, -1
	je	exit
	cmp	eax, [img_data_len]
	jne	exit
	invoke	file.close, [fh]
	inc	eax
	jz	exit
	
	invoke	img.decode, [img_data], [img_data_len], 0
	or	eax, eax
	jz	exit
	mov	[image], eax
;-----------------------------------------------------------------------------

redraw:
	call	draw_window

still:
	mcall	10
	cmp	eax, 1
	je	redraw
	cmp	eax, 2
	je	key
	cmp	eax, 3
	je	button
	jmp	still

  key:
	mcall	2
	jmp	still

  button:
	mcall	17
	shr	eax, 8

	; flip horizontally
	cmp	eax, 'flh'
	jne	@f

	invoke	img.flip, [image], FLIP_HORIZONTAL
	jmp	redraw

	; flip vertically
    @@: cmp	eax, 'flv'
	jne	@f

	invoke	img.flip, [image], FLIP_VERTICAL
	jmp	redraw

	; flip both horizontally and vertically
    @@: cmp	eax, 'flb'
	jne	@f

	invoke	img.flip, [image], FLIP_BOTH
	jmp	redraw

	; rotate left
    @@: cmp	eax, 'rtl'
	jne	@f

	invoke	img.rotate, [image], ROTATE_90_CCW
	jmp	redraw

	; rotate right
    @@: cmp	eax, 'rtr'
	jne	@f

	invoke	img.rotate, [image], ROTATE_90_CW
	jmp	redraw

    @@: cmp	eax, 1
	jne	still

  exit:
	mcall	-1


draw_window:
	invoke	gfx.open, TRUE
	mov	[ctx], eax

	mcall	0, <100, 640>, <100, 480>, 0x33FFFFFF, , s_header

	invoke	gfx.pen.color, [ctx], 0x007F7F7F
	invoke	gfx.line, [ctx], 0, 30, 630, 30

	mcall	8, <5 + 25 * 0, 20>, <5, 20>, 'flh', 0x007F7F7F
	mcall	8, <5 + 25 * 1, 20>, <5, 20>, 'flv', 0x007F7F7F
	mcall	8, <5 + 25 * 2, 20>, <5, 20>, 'flb', 0x007F7F7F

	invoke	gfx.line, [ctx], 5 + 25 * 3, 0, 5 + 25 * 3, 30

	mcall	8, <10 + 25 * 3, 20>, <5, 20>, 'rtl', 0x007F7F7F
	mcall	8, <10 + 25 * 4, 20>, <5, 20>, 'rtr', 0x007F7F7F

	mov	eax, [image]
	stdcall	[img.draw], eax, 5, 35, [eax + Image.Width], [eax + Image.Height], 0, 0

	invoke	gfx.close, [ctx]
	ret

;-----------------------------------------------------------------------------

s_header db 'Image Viewer (test app)', 0

;-----------------------------------------------------------------------------

align 16
@IMPORT:

library 			\
	libio  , 'libio.obj'  , \
	libgfx , 'libgfx.obj' , \
	libimg , 'libimg.obj'

import	libio			  , \
	libio.init , 'lib_init'   , \
	file.size  , 'file_size'  , \
	file.open  , 'file_open'  , \
	file.read  , 'file_read'  , \
	file.close , 'file_close'

import	libgfx				, \
	libgfx.init   , 'lib_init'	, \
	gfx.open      , 'gfx_open'	, \
	gfx.close     , 'gfx_close'	, \
	gfx.pen.color , 'gfx_pen_color' , \
	gfx.line      , 'gfx_line'

import	libimg			   , \
	libimg.init , 'lib_init'   , \
	img.draw    , 'img_draw'   , \
	img.decode  , 'img_decode' , \
	img.flip    , 'img_flip'   , \
	img.rotate  , 'img_rotate'

;-----------------------------------------------------------------------------

I_END:

img_data     dd ?
img_data_len dd ?
fh	     dd ?
image	     dd ?

ctx dd ?

@PARAMS rb 512
