CODE SEGMENT
ASSUME CS:CODE

Main PROC FAR
    push DX
    push AX
    push DI
    push DS

    mov AX,CS
    mov DS,AX

    mov DX,offset message
    call Print_msg
    mov DI,offset segment_adress
    add DI,18
    call WRD_TO_HEX
    mov DX,offset segment_adress
    call Print_msg
    pop DS
    pop DI
    pop AX 
    pop DX
    retf
Main ENDP
    
Print_msg PROC NEAR
    push AX
    mov AH,09h
    int 21h
    pop AX
    ret
Print_msg ENDP

TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
   push CX
   mov AH,AL
   call TETR_TO_HEX
   xchg AL,AH
   mov CL,4
   shr AL,CL
   call TETR_TO_HEX 
   pop CX
   ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near
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


   message DB "The Overlay module first.ovl is executed.",0DH,0Ah,'$'
   segment_adress DB "Segment adress:    h",0DH,0Ah,0DH,0Ah,'$'

CODE ENDS
END Main