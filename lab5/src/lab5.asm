AStack SEGMENT STACK
    DW 12 DUP(?)
AStack ENDS

DATA SEGMENT
    FLAG DB "/un",0DH
    already_loaded_message DB "User interruption was already loaded", 0Dh,0AH,'$'
    already_unloaded_message DB "user interrupt not set",0Dh,0Ah,'$'
  
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:AStack

User_interrupt PROC FAR

jmp interrupt_start

    SIGNATURE DW 5555
    KEEP_PSP DW 0
    KEEP_SS DW 0
    KEEP_SP DW 0
    KEEP_IP DW 0
    KEEP_CS DW 0
    FIRST_BYTE_FLAG DB 0
    INT_STACK DW 100 DUP(0)

interrupt_start:
    mov KEEP_SS, SS
    mov KEEP_SP,SP
    mov SP, SEG INT_STACK
    mov SS,SP
    mov SP,offset interrupt_start


    push AX 
    push BX
    push CX
    push ES


 in AL,60h
    cmp AL,48h
    je up
    cmp AL,4bh
    je left
    cmp AL,50h
    je down
    cmp AL,4dh
    je right

base_handler:
    pushf
    call DWORD PTR CS:KEEP_IP
    jmp interrupt_end



up:
    mov CL,'w'
    jmp load_into_buffer

down:
    mov CL,'s'
    jmp load_into_buffer

left:
    mov CL,'a'
    jmp load_into_buffer

right:
    mov CL,'d'

load_into_buffer:
    in AL,61h
    mov AH,AL
    or AL,80h    
    out 61h,AL
    xchg AH,AL
    out 61h,AL
    mov AL,20h
    out 20h,AL
load_attempt:
    mov AH,05h
    mov CH,0
    int 16h
    cmp AL,0
    je interrupt_end
    mov AX,40h
    mov ES,AX
    mov AX,ES:[1ah]
    mov ES:[1ch],AX
    jmp load_attempt

 interrupt_end:
    pop ES
    pop CX
    pop BX
    pop AX
       

    mov SS,KEEP_SS
    mov SP,KEEP_SP
    mov AL,20h
    out 20h,AL
    iret
User_interrupt ENDP





Main PROC FAR
    push DS
    sub AX,AX
    push AX
    mov AX,DATA
    mov DS,AX
    mov WORD PTR KEEP_PSP,ES   
    call Select_mode

    ret
Main ENDP

Select_mode PROC NEAR
    push AX
    push SI
    push DI

    mov AL,32
    mov DI,081h

skip_spaces:
    SCASB
    je skip_spaces

    dec DI
    mov SI,offset  FLAG
 
cmp_loop:
    mov AL, ES:[DI]
    cmp AL, DS:[SI]
    jne load_mode
    cmp AL,0dh
    je unload_mode
    inc SI
    inc DI
    jmp cmp_loop

load_mode: 
    call load_interrupt
    jmp select_mode_end

unload_mode:
    call unload_interrupt  

select_mode_end:  
     
    pop DI
    pop SI
    pop AX

    ret
Select_mode ENDP

load_interrupt PROC NEAR
    push SI
    push AX
    push BX
    push CX
    push DX
    push ES
  
    mov AH,35h
    mov AL,09h
    int 21h
    mov SI,offset SIGNATURE
    mov AX, ES:[SI]
    cmp AX,5555
    je already_loaded
    mov KEEP_IP, BX
    mov KEEP_CS, ES
	
    push DS
    mov DX, offset User_interrupt
    mov AX, seg User_interrupt
    mov DS, AX
    mov AH, 25h 
    mov AL, 09h 
    int 21h
    pop DS
    mov DX, offset Main
    mov CL, 4
    shr DX, CL
    inc DX
    mov AX, CS
    sub AX, KEEP_PSP
    add DX, AX
    mov AX,0
    mov AH, 31h
    int 21h
    jmp load_end
already_loaded:
    mov DX, offset already_loaded_message
    call print
load_end:

    pop ES
    pop DX
    pop CX
    pop BX
    pop AX
    pop SI
    ret
load_interrupt ENDP



unload_interrupt PROC NEAR
    push AX
    push BX
    push DX
    push ES
    push SI
    
    
    mov AH,35h
    mov AL,09h 
    int 21h
    mov SI,offset SIGNATURE
    mov AX, es:[SI]
    cmp AX,5555
    jne already_unloaded
    CLI
    push DS
    mov DX,ES:KEEP_IP
    mov AX,ES:KEEP_CS
    mov DS,AX
    mov AH,25h
    mov AL,09h
    int 21h
    pop DS
    mov SI,offset KEEP_PSP
    mov AX,ES:[SI]
    mov ES,AX
    push ES
    mov AX,ES:[2ch]
    mov ES,AX
    mov AH,49h
    int 21h
    pop ES
    int 21h
    STI
    jmp unload_end 

already_unloaded:
    mov DX,offset already_unloaded_message
    call print
unload_end:
    pop SI
    pop ES
    pop DX
    pop BX
    pop AX
    ret
unload_interrupt ENDP


print PROC NEAR
    push AX
    mov AH,09h
    int 21h
    pop AX
    ret
print ENDP


CODE ENDS
    END Main
