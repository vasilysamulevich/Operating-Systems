CODE SEGMENT
ORG 100h
ASSUME CS:CODE,DS:CODE,SS:CODE,ES:NOTHING

start: jmp MAIN
    blocked_memory DB "Inaccessible memory adress:    h",0DH,0AH,'$'
    enviroment     DB "Enviroment segment adress:    h",0DH,0AH,'$'
    arguments_message DB "Command line arguments:$"
    content  DB "Enviroment content:",0DH,0AH,'$'
    path DB "path of the loaded module:$"
    buffer DB 259 DUP(?)



MAIN:
    call print_adresses
    call print_arguments
    call print_enviroment
    xor AL,AL
    mov AH,4Ch
    int 21h



print_enviroment PROC NEAR
    push SI
    push DX
    push ES
    mov DX,offset content
    call print 
    mov SI,0
    mov ES, DS:02ch
enviroment_cycle:
    cmp [ES:SI], BYTE PTR 0
    je enviroment_stop
    call print_sentence
    inc SI
    jmp enviroment_cycle

enviroment_stop:
    mov DX,offset path
    call print
    add SI,3
    call print_sentence
    pop ES
    pop DX
    pop SI
    ret
print_enviroment ENDP

print_sentence PROC NEAR ; ES:SI - cтарт, DS:DI - финиш
    push DI
    push DX
    push AX

    mov DI,offset buffer
sentence_cycle:
    cmp [ES:SI],BYTE PTR 0
    je sentence_stop
    mov AL,[ES:SI]
    mov [DI],AL
    inc SI
    inc DI
    jmp sentence_cycle
sentence_stop:
    mov [DI],  BYTE PTR 0Dh
    inc DI
    mov [DI],  BYTE PTR 0Ah
    inc DI
    mov [DI], BYTE PTR 36
    mov DX, offset buffer
    call print

    pop AX
    pop DX
    pop DI
    ret
print_sentence ENDP

print_adresses PROC NEAR
    push AX
    push DX
    push DI

    mov AX,DS:02h
    mov DI,offset blocked_memory
    add DI,30
    call WRD_TO_HEX
    mov DX,offset blocked_memory
    call print
    mov AX,DS:02cH
    mov DI,offset enviroment
    add DI,29
    call WRD_TO_HEX
    mov DX,offset enviroment
    call print
    pop DI
    pop DX
    pop AX
    ret 		
print_adresses ENDP


print_arguments PROC NEAR
    push DX
    push CX
    push SI
    push DI

    mov CX,0
    mov CL,DS:80h
    mov SI,81h
    mov DI,offset buffer
    REP movsb
    mov [DI],  BYTE PTR 0Dh
    inc DI
    mov [DI],  BYTE PTR 0Ah
    inc DI
    mov [DI], BYTE PTR 36

    mov DX,offset arguments_message
    call print

    mov DX,offset buffer
    call print

    pop DI
    pop SI
    pop CX
    pop DX
    ret
print_arguments ENDP


print PROC NEAR
    push AX
    mov AH,09h
    int 21h
    pop AX
    ret
print ENDP


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