 org  0
   incbin  "build\megaman.bin"
   
   
; ==============================
;
; QSound screen in attract mode
;
; ==============================
 
 org $18F0
	dc.w	$10

; Free space
 org $163C00
 