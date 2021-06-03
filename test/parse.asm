    device zxspectrum48
    org #8000 ; адрес на который компилировать
begin_file:
    LD IXL, 4
    LD HL,(IX)
    LD A,#04
    LD HL,#5800
    LD DE,#5801
    LD BC,#02FF
    LD (HL),A
    LDIR
    RET
end_file:
    display "code size: ", /d, end_file - begin_file
    savebin "parse.C", begin_file, end_file - begin_file
