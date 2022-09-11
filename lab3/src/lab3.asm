CODE SEGMENT
ORG 100h
ASSUME CS:CODE, DS:CODE,CS:CODE,ES:NOTHING

    programm_start: jmp MAIN
    available_memory DB "Amount of available memory:        ",0DH,0AH,'$'
    extended_memory DB "Extended memory size:               ",0DH,0AH,'$' 
    MCB_info DB "MCB#  ,adress:    ,owner:    ,size:         ,SD/SC:        ",0DH,0AH,'$'


MAIN:
    
    call print_available_memory
    call print_extended_memory
    call print_all_MCB
    xor AL,AL
    mov AH, 4ch
    int 21h

print PROC NEAR
    push AX
    mov AH,09h
    int 21h
    pop AX
ret
print ENDP



CLEAR_MCB_INFO PROC NEAR; SI - начало строки
    push SI
    push AX
    push BX

    mov BX,0
clear_loop:
    mov AL,[SI]
    cmp AL,36
    je clear_loop_end
    cmp AL,58
    je clear_active_mode
    cmp AL,35
    je clear_active_mode
    cmp AL,44
    je clear_passive_mode
    cmp AL, 0dh
    je clear_passive_mode
    jmp clear_continue
clear_active_mode:
    mov BX,1
    inc SI
    jmp clear_loop

clear_passive_mode:
    mov BX,0
    inc SI
    jmp clear_loop

clear_continue:
    cmp BX,1
    je change
    inc SI
    jmp clear_loop

change:
    mov AL,32
    mov [SI],AL
    inc SI
    jmp clear_loop    
     
clear_loop_end:
    pop BX
    pop AX
    pop SI
    ret
CLEAR_MCB_INFO ENDP


print_one_MCB PROC NEAR ;ES-адрес начала блока, CX- счетчик
    push AX
    push SI
    push DI
    push CX
    push DX

    
    mov AL,CL
    mov SI,offset MCB_info
    add SI,4
    call byte_to_dec
    mov AX,ES
    mov DI,offset MCB_info
    add DI,17
    call wrd_to_hex
    mov AX, ES:[1]
    mov DI,offset MCB_info
    add DI,28
    call wrd_to_hex
    mov AX,ES:[3]
    mov DI,offset MCB_info
    add DI,43
    call paragraphs_to_bytes
    mov DI,8
    mov CX,8
    mov SI,offset MCB_info
    add SI,51
bytes_loop:
    mov AL,ES:[DI]
    mov [SI],AL
    inc DI
    inc SI
    loop bytes_loop

    mov DX, offset MCB_info
    call print
    mov SI,offset MCB_info
    call CLEAR_MCB_INFO
    pop DX
    pop CX
    pop DI
    pop SI
    pop AX
    ret
print_one_MCB ENDP


print_all_MCB PROC NEAR
    push AX
    push BX
    push CX
    push ES
    
    mov AH,52h
    int 21h
    mov AX, ES:[BX-2]
    mov ES,AX
    mov CX,1
print_all_loop:
    call print_one_MCB
    cmp BYTE PTR ES:[0], 05ah
    je end_loop
    mov AX,ES
    mov BX, ES:[3]
    add AX, BX
    inc AX
    mov ES,AX
    inc CX
    jmp print_all_loop

end_loop:
    pop ES
    pop CX
    pop BX
    pop AX
    ret
print_all_MCB ENDP

print_extended_memory PROC NEAR
    push AX
    push BX
    push DX
    push DI
    
    mov AL,30h
    out 70h,AL
    in AL,71h
    mov BL,AL
    mov AL,31h
    out 70h,AL
    in AL,71h
    mov AH,AL
    mov AL,BL
    mov DI,offset extended_memory
    add DI,35
    call kilobytes_to_bytes
    mov DX,offset extended_memory
    call print

    pop DI
    pop DX
    pop BX
    pop AX
    ret
print_extended_memory ENDP

;------------------------------------
kilobytes_to_bytes PROC NEAR; AX - количество килобайт, DI - адрес последнего символа результата
    push AX
    push BX
    push DX
    push CX
    push DI

    mov DX,0

    mov BX,1024
    mul BX
    mov BX,10
kilobytes_cycle:
    cmp DX,0
    jne check_passed
    cmp AX,10
    ja check_passed
    add AX,48
    mov [DI],AL
    jmp kilobytes_end
    
check_passed:
    call division_32
    add CX,48
    mov [DI],CL
    dec DI
   jmp kilobytes_cycle

kilobytes_end:

    pop DI
    pop CX
    pop DX
    pop BX
    pop AX  
    ret
kilobytes_to_bytes ENDP

paragraphs_to_bytes PROC NEAR ; AX-число параграфов, DI-арес последнего символа,куда надо записать результат
    push BX
    push DX
    push AX
    push DI

    mov DX,0
    mov BX, 16
    mul BX
    mov BX,10
paragraphs_start:
    cmp DX,0
    jne paragraphs_skip_check
    cmp AX,10
    jb paragraphs_end
paragraphs_skip_check:
    div BX
    add DX,48
    mov [DI],DL
    dec DI
    mov DX,0
    jmp paragraphs_start    
paragraphs_end:
    add AX,48
    mov [DI],AL

    pop DI
    pop AX
    pop DX
    pop BX  
    ret
paragraphs_to_bytes ENDP


division_32 PROC NEAR ;AX - младший байт, DX - старший байт,BX - делитель.Результат: AX - младший байт, DX - старший байт, CX - остаток
    push DI
    push BX

    jmp division_begin
    HIGHT DW 0
    LOW  DW  0
    DIVIDER DW 0
    REMAINDER_HIGHT DW 0
    REMAINDER_LOW DW 0
    TEMP_LOW DW 0

division_begin:

    mov [HIGHT],DX
    mov [LOW],AX
    mov [DIVIDER],BX
    mov AX,0
    mov BX,0
    mov DX,0
    mov DI,0
    mov CX,0

    mov DI,DIVIDER
    mov AX,HIGHT
    DIV DI
    mov REMAINDER_HIGHT, DX
    mov HIGHT,AX   
  
    mov AX,0FFFFh
    mov DX,0
    DIV DI
    mov BX,DX
    mov CX,REMAINDER_HIGHT
    mul CX ; В AX-нижний байт, В DX-остаток
    mov DX,0
    cmp CX,0
    je skip_division
start:
    call Module
    loop start

skip_division:
    mov BX,REMAINDER_HIGHT
    call Module
    mov REMAINDER_LOW,DX
    mov TEMP_LOW,AX

    mov AX,LOW
    mov DX,0
    DIV DI
    mov BX,REMAINDER_LOW
    call Module
    add AX,TEMP_LOW
    adc HIGHT,0000
    mov LOW,AX
    mov REMAINDER_LOW,DX

    mov AX,[LOW]
    mov DX,[HIGHT]
    mov CX,[REMAINDER_LOW]

    pop BX
    pop DI
    ret 
division_32 ENDP



Module PROC NEAR
    add DX,BX
    cmp DX,DI
    jb finish
    sub DX,DI
    inc AX
finish:
    ret
Module ENDP


tetr_to_hex PROC near 
    and AL,0Fh
    cmp AL,09
    jbe next
    add AL,07
next: 
    add AL,30h
    ret
tetr_to_hex ENDP

byte_to_hex PROC near
    push CX
    mov AH,AL
    call tetr_to_hex
    xchg AL,AH
    mov CL,4
    shr AL,CL
    call tetr_to_hex
    pop CX
    ret
byte_to_hex ENDP 

wrd_to_hex PROC near
    push BX
    mov BH,AH
    call byte_to_hex
    mov [DI],AH
    dec DI
    mov [DI],AL
    dec DI
    mov AL,BH
    call byte_to_hex
    mov [DI],AH
    dec DI
    mov [DI],AL
    pop BX
    ret
wrd_to_hex ENDP 



byte_to_dec PROC near
    push CX
    push DX
    push AX
    xor AH,AH
    xor DX,DX
    mov CX,10
loop_bd:
    div CX
    or DL,30h
    mov [SI],DL
    dec SI
    xor DX,DX
    cmp AX,10
    jae loop_bd
    cmp AL,00h
    je end_l
    or AL,30h
    mov [SI],AL
end_l: 
    pop AX
    pop DX
    pop CX
    ret
byte_to_dec ENDP




;-----------------------------------
print_available_memory PROC NEAR
    push AX
    push BX
    push DI
    push DX

    mov AH,4ah
    mov BX, 0ffffh
    int 21h
    mov AX,BX
    mov DI, offset available_memory
    add DI,33
    call paragraphs_to_bytes
    mov DX,offset available_memory
    call print

    pop DX 
    pop DI
    pop BX
    pop AX
    ret
print_available_memory ENDP
CODE ENDS
END programm_start