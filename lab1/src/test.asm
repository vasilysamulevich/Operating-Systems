CODE SEGMENT
ORG 100h
ASSUME CS:CODE,DS:CODE,SS:CODE,ES:NOTHING

  
start:jmp MAIN

pc_message DB "IBM PC TYPE: $"
pc_1	DB "PC",0Dh,0ah,'$'
pc_2    DB "PC/XT",0Dh,0ah,'$'
pc_3    DB "AT",0Dh,0ah,'$'
pc_4    DB "PS2, model 30",0Dh,0ah,'$'
pc_5    DB "PS2 model 80",0Dh,0ah,'$'
pc_6    DB "PCjr\n$"
pc_7    DB "PC convertible",0Dh,0ah,'$'

buffer DB 10 DUP(?)
point DB ".$"
string_end DB 0DH,0AH,'$'
dos_message DB "DOS type:",0Dh,0ah,'$'
dos_version DB "Version: $"
zero_version DB "less then 2.0",0Dh,0ah,'$'
dos_oem DB "OEM serial number: $"
dos_user DB 0Dh,0ah,"User serial number:       ",0Dh,0ah,'$'


MAIN:
    call PC_TYPE
    call DOS_TYPE
    xor AL,AL
    mov AH,4Ch
    int 21h

print PROC near
    push AX
    mov AH,09h
    int 21h
    pop AX
    ret
print ENDP

DOS_TYPE PROC near
    push AX
    push BX
    push CX
    push DX
    push DI
    mov AH,30h
    int 21h
    mov DX,offset dos_message
    call print
    mov DX,offset dos_version
    call print
    cmp AX,0
    jne modification
    mov DX,offset zero_version
    call print
    jmp oem
modification:
    push CX
    mov CH,AH
    mov AH,0
    call WORD_TO_DEC
    mov DX,offset buffer
    call print
    mov DX,offset point
    call print
    mov AL,0
    mov AH,CH
    call WORD_TO_DEC
    mov DX,offset buffer
    call print
    mov DX,offset string_end
    call print
    pop CX
oem:
    mov AX,0
    mov AL,BH
    call WORD_TO_DEC
    mov DX,offset dos_oem
    call print
    mov DX,offset buffer
    call print
user:
    mov DI,offset dos_user
    add DI,27
    mov AX,CX
    call WRD_TO_HEX
    dec DI
    mov AX,0
    mov AL,BL
    call WRITE_BYTE
    mov DX,offset dos_user
    call print
    pop DI
    pop DX
    pop CX
    pop BX
    pop AX
    ret
DOS_TYPE ENDP

PC_TYPE PROC near
    push AX
    push BX
    push DX
    mov AH,0C0h
    int 15h; ES:BX
    push ES
    pop DS
    mov AX,2[BX]
    push CS
    pop DS
 
    mov DX,offset pc_message
    call print
    cmp AL,0FFh
    je pc
    cmp AL,0FEh
    je  pc_xt
    cmp AL,0FBh
    je  pc_xt
    cmp AL,0FCh
    je at
    cmp AL,0FAh
    je ps2_30
    cmp AL,0F8h
    je ps2_80
    cmp AL, 0FDh
    je pcjr
    cmp AL,0F9h
    je pc_convertible
pc:
    mov DX,offset pc_1
    jmp stop
pc_xt:
    mov DX,offset pc_2
    jmp stop
at:
    mov DX,offset pc_3
    jmp stop
ps2_30:
    mov DX,offset pc_4
    jmp stop
ps2_80:
    mov DX,offset pc_5
    jmp stop
pcjr:
    mov DX,offset pc_6
    jmp stop
pc_convertible:
    mov DX,offset pc_7
stop:
    call print
    pop DX
    pop BX
    pop AX
    ret 
PC_TYPE ENDP

WORD_TO_DEC PROC near
    push BX
    push CX
    push DX
    push SI
    push DI
    mov SI,0
    mov BX,offset buffer
    mov DI,AX
    mov AX,1
    cmp DI,0
    jne start_1
    mov[BX][SI],BYTE PTR 48
    inc SI
    jmp stop_2
start_1:
    cmp AX,DI
    jae stop_1
    mov DX,10
    mul DX
    jmp start_1
stop_1:
    mov CX,10
    div CX
    mov CX,AX
    mov AX,DI    
start_2:
    DIV CX
    add AX,48
    mov [BX][SI],AL
    inc SI
    cmp CX,1
    je stop_2
    mov AX,DX
    xchg AX,CX
    mov DX,0
    mov DI,10
    DIV DI
    xchg AX,CX
    jmp start_2    
stop_2:
    mov [BX][SI],BYTE PTR 36
    pop DI
    pop SI
    pop DX
    pop CX
    pop BX
    ret
WORD_TO_DEC ENDP

TETR_TO_HEX PROC near
    and AL,0Fh
    cmp AL,09
    jbe NEXT
    add AL,07
NEXT: add AL,30h
    ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
; байт в AL переводится в два символа шестн. числа в AX
    push CX
    mov AH,AL
    call TETR_TO_HEX
    xchg AL,AH
    mov CL,4
    shr AL,CL
    call TETR_TO_HEX ;в AL старшая цифра
    pop CX ;в AH младшая
    ret
BYTE_TO_HEX ENDP
;-------------------------------

WRITE_BYTE PROC near ; AX-число, DI - адрес последнего символа
    call BYTE_TO_HEX
    mov [DI],AH
    dec DI
    mov [DI],AL
    ret
WRITE_BYTE ENDP

WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
    push BX
    mov BH,AH
    call BYTE_TO_HEX
    mov [DI],AH
    dec DI
    mov [DI],AL
    dec DI
    mov AL,BH
    call BYTE_TO_HEX
    mov [DI],AH
    dec DI
    mov [DI],AL
    pop BX
ret
WRD_TO_HEX ENDP
;--------------------------------------------------

CODE ENDS
END start