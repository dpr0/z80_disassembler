    device zxspectrum48
    org #6100 ; адрес на который компилировать    
begin_file:
;    push ix      ; dd e5
;    ld a,(#1234) ; 3a 34 12
;    ld l, 4       ; 2e 04
    ld ixl, 4     ; dd 2e 04
    nop
;    push ix
;    ld ix, iy
;    ld ixl, iyl
;    LD A, B       ; 78
;    ld a, h       ; 7c
;    ld a, ixh     ; dd 7c
;    LD A, B       ; 78
;    CALL #ffff
;    CALL NC,#eeee
    RET ; c9

end_file:
    display "code size: ", /d, end_file - begin_file
    savebin "error.C", begin_file, end_file - begin_file
