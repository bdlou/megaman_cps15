 org  0
   incbin  "build\megaman.bin"
   
qsound_fifo_offset = -$7000
qsound_fifo_head_offset = -$6000
qsound_fifo_tail_offset = -$5FE0

 org $000A9A
	jmp Do_Qsound_Test

 org $01C744
	jmp Initialize_QSound_Fifo

 org $000E52
	jmp Hijack_More_Init

 org $01C6E6
	jmp Hijack_Upload_Audio_Commands

 org $01C714
	jmp Hijack_Add_Audio_Command_To_Fifo
  
 org $0080E8
	jmp Hijack_Sound_Test_Add_Audio
  
; ==============================
;
; QSound screen in attract mode
;
; ==============================
 
 org $18F0
	dc.w	$10
	
; ==============================
;
; Region text
;
; ==============================

 org $52EA	; Offset table for region text
 
	dc.w	$E0, $E0, $E0, $E0, $E0, $E0		; Region and version
	dc.w	$242, $242, $242, $242, $242, $242	; Warning
	
 org $53CA

	dc.b	$0C
	dc.b	$24
	dc.b	$02
	dc.b	"MEGA MAN THE POWER BATTLE /"
	
	dc.b	$12
	dc.b	$30
	dc.b	$02
	dc.b	"2 0 1 2 1 8 /"
	
	dc.b	$11
	dc.b	$3C
	dc.b	$02
	dc.b	"C P S  1 . 5"
	
	dc.w	$0

 org $552C
 
	dc.b	$14
	dc.b	$10
	dc.b	$02
	dc.b	"WARNING/"
	
	dc.b	$03
	dc.b	$20
	dc.b	$02
	dc.b	"You are not authorized to use this software/"
	
	dc.b	$03
	dc.b	$28
	dc.b	$02
	dc.b	"at all./"
	
	dc.b	$03
	dc.b	$34
	dc.b	$02
	dc.b	"We accept no responsibility for any/"
	
	dc.b	$03
	dc.b	$3C
	dc.b	$02
	dc.b	"misfortunes which may befall you as a result/"
	
	dc.b	$03
	dc.b	$44
	dc.b	$02
	dc.b	"of operating this game./"
	
	dc.b	$02
	dc.b	$60
	dc.b	$03
	dc.b	"Another CPS 1.5 conversion brought to you by:/"
	
	dc.b	$05
	dc.b	$6C
	dc.b	$04
	dc.b	"grego2d/"
	
	dc.b	$13
	dc.b	$6C
	dc.b	$04
	dc.b	" Rotwang/"
	
	dc.b	$22
	dc.b	$6C
	dc.b	$04
	dc.b	" bdlou"
	
	dc.w	$0
	
; ================================
; ================================
; Hijack QSound jingle cue

 org $194C
	jmp		hijack_qsound_jingle

; ================================
; ================================	

; Free space
 org $163C00
 
;----------------
 Do_Qsound_Test:
	cmpi.l  #$5642194, D0
	cmpi.b  #$77, $f19fff.l
	bne     Do_Qsound_Test ; Wait loop

	lea     $f18000.l, A0 ; QSound mem
	lea     ($1ffe,A0), A1 ; Length
	
	movea.l A0, A3
	move.w  #$1, D1
	moveq   #$0, D3

Do_Qsound_Test_Loop:
	move.w  tbl_qsound_test_data(PC,D3.w), D0
	lea     (A3), A0

Do_Qsound_Test_Loop_2:
	cmpi.l  #$5642194, D0
	move.w  D0, (A0)
	cmp.b   ($1,A0), D0
	;bne     $d6e

	lea     ($2,A0), A0
	cmpa.l  A1, A0
	bls     Do_Qsound_Test_Loop_2

	addq.w  #2, D3
	dbra    D1, Do_Qsound_Test_Loop 
	
Clear_Qsound_Ram:
	lea     $F18000.l, A0
	lea     $F19ff9.l, A1
	moveq   #-$1, D0
  
Clear_Qsound_Ram_Loop:
	cmpi.l  #$5642194, D0
	move.w  D0, (A0)+
	cmpa.l  A1, A0
	bls     Clear_Qsound_Ram_Loop

	lea     $ab4, A6
	jmp     (A6)

tbl_qsound_test_data:
	dc.w	$0000, $5555
;----------------

;----------------
Initialize_QSound_Fifo:
  move.w  #$ff, D6 ; Loop count
  lea     (qsound_fifo_offset,A5), A0

  moveq   #$0, D0
 
Initialize_QSound_Fifo_Loop:
  move.l  D0, (A0)+
  move.l  D0, (A0)+
  move.l  D0, (A0)+
  move.l  D0, (A0)+
  dbra    D6, Initialize_QSound_Fifo_Loop
 
  move.l  D0, (qsound_fifo_tail_offset,A5) ; Clear fifo tail
  move.l  D0, (qsound_fifo_head_offset,A5) ; Clear fifo head

  rts
;----------------

;----------------
Hijack_More_init:
	move.b  #$88, $f19ffb.l
	move.b  #$0, $f19ffd.l
	move.b  #$ff, $f19fff.l

	; Original code from 000ECA
	lea     $ff8000.l, A7
	lea     $ff8000.l, A5
	moveq   #$0, D0
	; Original code from 000ECA

	jmp $000E60
;----------------

;----------------
Hijack_Upload_Audio_Commands:
;  moveq   #$0, D0 ; Ignore stereo on sounds
  
;  tst.b   ($19a,A5)
;  beq     Hijack_Upload_Audio_Commands_Continue

  moveq   #-$1, D0 ; Handle stereo
  
Hijack_Upload_Audio_Commands_Continue:
  move.b  D0, $F19ffd.l

  move.w  (qsound_fifo_head_offset,A5), D0 ; Fifo head
  cmp.w   (qsound_fifo_tail_offset,A5), D0 ; Compare against fifo tail
  beq     Hijack_Upload_Audio_Commands_Exit

  cmpi.b  #-$1, $F1801f.l
  bne     Hijack_Upload_Audio_Commands_Exit

  lea     (qsound_fifo_offset,A5), A4 ; Load fifo location
  move.w  (qsound_fifo_head_offset,A5), D0 ; Load fifo index
  move.b  (A4,D0.w), $F18007.l
  move.b  ($1,A4,D0.w), $F18009.l
  move.b  ($2,A4,D0.w), $F18001.l
  move.b  ($3,A4,D0.w), $F18003.l
  move.b  ($4,A4,D0.w), $F18005.l
  move.b  ($5,A4,D0.w), $F1800d.l
  move.b  ($6,A4,D0.w), $F1800f.l
  move.b  ($7,A4,D0.w), $F18011.l
  move.b  ($8,A4,D0.w), $F18017.l
  move.b  ($9,A4,D0.w), $F18019.l
  move.b  ($a,A4,D0.w), $F18013.l
  move.b  ($b,A4,D0.w), $F18015.l
  move.b  #$0, $F1801f.l
  addi.w  #$10, D0
  andi.w  #$ff0, D0
  move.w  D0, (qsound_fifo_head_offset,A5) ; Update fifo head
  
Hijack_Upload_Audio_Commands_Exit:
  rts
;----------------

;----------------
Hijack_Sound_Test_Add_Audio:
	lsl.l   #$1, D1
	move.w  tbl_sound_mappings(PC,D1.w), D1	

	bsr Add_Audio_Command_To_Fifo_Continue

	rts
;----------------

;----------------
Hijack_Add_Audio_Command_To_Fifo:
	lsl.l   #$1, D1
	move.w  tbl_sound_mappings(PC,D1.w), D1	

	moveq   #$0, D2
	moveq   #$0, D3

	cmpi.w #$100, D1
	blt	Add_Audio_Command_To_Fifo_No_Stereo

	cmpi.w #$200, D1
	bgt	Add_Audio_Command_To_Fifo_No_Stereo

	bsr Stereo_Calculation

Add_Audio_Command_To_Fifo_No_Stereo
	tst.b   ($92,A5)
	bne     Add_Audio_Command_To_Fifo_Continue

	tst.b   ($81,A5)
	bne     Add_Audio_Command_To_Fifo_Exit

Add_Audio_Command_To_Fifo_Continue:
	lea     (qsound_fifo_offset,A5), A4 ; Load fifo address
	move.w  (qsound_fifo_tail_offset,A5), D0 ; Fifo tail
	move.l  D1, (A4,D0.w)
	move.l  D2, ($4,A4,D0.w)
	move.l  D3, ($8,A4,D0.w)
	addi.w  #$10, D0
	andi.w  #$ff0, D0
	move.w  D0, (qsound_fifo_tail_offset,A5) ; Udate Fifo tail

Add_Audio_Command_To_Fifo_Exit:
    moveq   #$0, D1
	rts
;----------------

tbl_sound_mappings:
	incbin "sound_mappings.bin"

;----------------
; Stereo calculation
Stereo_Calculation:
	moveq   #$0, D2
	move.w  ($10,A6), D2 ; Player x pos
	sub.w   ($210,A5), D2 ; Screen scroll
	bge     Stereo_Calculation_Check_Max

	moveq   #$0, D2
	bls     Stereo_Calculation_Cont

Stereo_Calculation_Check_Max:
	cmpi.w  #$17f, D2
	bls     Stereo_Calculation_Cont

	move.w  #$17f, D2

Stereo_Calculation_Cont:
	lsr.w   #2, D2
	andi.w  #$7e, D2
	add.w   tbl_stereo_calc_table(PC,D2.w), D2
	andi.l  #$ff00, D0
	rts
;----------------

tbl_stereo_calc_table:
	incbin "megaman_stereo_table.bin"
	
	
; ============================

hijack_qsound_jingle:

	jsr		$4FAC		; subroutine that this hijack overwrote

	tst.b   ($c5,A5)
	bne     hijack_qsound_jingle_return
	jsr     $1C810
	moveq   #$22, D1		; QSound jingle 1
	moveq   #$0, D2
	moveq   #$0, D3
	jsr     Add_Audio_Command_To_Fifo_No_Stereo
	moveq   #$23, D1		; Qsound jingle 2
	move.l  #$21020, D2
	moveq   #$70, D3
	jsr     Add_Audio_Command_To_Fifo_No_Stereo
	jmp     $1C808
	
hijack_qsound_jingle_return:
	rts
	
	
	
	
	