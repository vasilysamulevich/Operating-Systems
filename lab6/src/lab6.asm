Astack SEGMENT STACK
    DW 128 DUP(?)
Astack ENDS

DATA SEGMENT
    first_clear_error DB "Error clearing memory: control block destroyed.",0Dh,0Ah,'$'
    second_clear_error DB "Error while clearing memory: Not enough memory to execute function.",0Dh,0Ah,'$'
    fird_clear_error DB "Error clearing memory: invalid memory block address.",0Dh,0Ah,'$'
    file_name DB "lab2.com",'$'
    file_path DB 128 dup(0)
    segment_adress DW 0
    cmd_offset DW 0
    cmd_segment DW 0
    first_FCB DD 0
    second_FCB DD 0
        
    command_line_size DB 0
    command_line_args DB "Args for lab2",0Dh,0Ah,0
    normal_termination DB 0Dh,0Ah,"The called program has been executed. Program termination information:",0Dh,0Ah,'$'
    termination_reason_0 DB "Normal termination.",0Dh,0Ah,'$'
    termination_reason_1 DB "Terminate by pressing ctrl-break.",0Dh,0Ah,'$'
    termination_reason_2 DB "Device error termination.",0Dh,0Ah,'$'
    termination_reason_3 DB " Termination by function 31h.",0Dh,0Ah,'$'
    exit_code DB "Exit code: ",0Dh,0Ah,'$'
    
    abnormal_termination DB 0Dh,0Ah,"The called program was not loaded, error information:",0Dh,0Ah,'$'
    load_error_1 DB "Function number is invalid.",0Dh,0Ah,'$'
    load_error_2 DB "File not found.",0Dh,0Ah,'$'
    load_error_3 DB "Disk error.",0Dh,0Ah,'$'
    load_error_4 DB "Insufficient memory size.",0Dh,0Ah,'$'
    load_error_5 DB "Wrong environment string.",0Dh,0Ah,'$'
    load_error_6 DB "Wrong format.",0Dh,0Ah,'$'

 end_data DB 0
DATA ENDS

CODE SEGMENT
ASSUME CS:CODE, DS:DATA,SS:Astack,ES:NOTHING

KEEP_SS DW 0
KEEP_SP DW 0

Main PROC FAR
    push DS
    sub AX,AX
    push AX
    mov AX, DATA
    mov DS,AX
    call free_memory
    jb programm_end
    call run_loader

programm_end:
    mov AX,0
    mov AH,4ch
    int 21h

main ENDP

Free_memory PROC NEAR
    push AX
    push BX
    push DX

    mov DX,0
    mov AX,offset end_code
    add AX,offset end_data
    inc AX
    add AX,228h
    mov BX,16
    div BX
    inc AX
    mov BX,AX
    mov AX,0
    mov AH,4ah
    int 21h
    jae free_without_errors
    cmp AX,7
    jne second_free_check
    mov DX,offset first_clear_error
    jmp handle_free_error

second_free_check:
    cmp AX,8
    jne fird_free_check
    mov DX,offset second_clear_error
    jmp handle_free_error

fird_free_check:
     mov DX,offset fird_clear_error    

handle_free_error:
    call print
    STC ; флаг того,что очистка памяти не удалась
    jmp free_end

free_without_errors:
   CLC
free_end:
    pop DX
    pop BX
    pop AX
    ret
Free_memory ENDP

print PROC NEAR
    push AX
    mov AH,09h
    int 21h
    pop AX
    ret
print ENDP

init_file_path PROC NEAR
    push AX
    push ES
    push CX
    push SI
    push DI
 
    mov AX, ES:[2ch]
    mov ES,AX
    mov CX,0
    mov SI,0
find_file_path_cycle:
    mov AL,ES:[SI]
    cmp AL,0
    je two_zeros_checking
    mov CX,0
    inc SI
    jmp find_file_path_cycle
two_zeros_checking:
    inc CX
    cmp CX,2
    je stop_find_file_loop
    inc SI
    jmp find_file_path_cycle

stop_find_file_loop:
    add SI,3
    mov DI,offset file_path
file_path_copy_loop:
    cmp  BYTE PTR ES:[SI],0
    je stop_file_path_copy_loop
    mov AL,ES:[SI]
    mov DS:[DI],AL
    inc SI
    inc DI
    cmp AL,'\'
    je update_last_dir
    jmp file_path_copy_loop

update_last_dir:
    mov CX,DI
    jmp file_path_copy_loop
    

stop_file_path_copy_loop:
    mov DI,CX
    mov SI,offset file_name
copy_file_name_loop:
    mov AL,[SI]
    cmp AL,'$'
    je stop_copy_file_name_loop
    mov [DI],AL
    inc SI
    inc DI
    jmp copy_file_name_loop

stop_copy_file_name_loop:
    mov BYTE PTR [DI],0
  
    pop DI    
    pop SI
    pop CX
    pop ES
    pop AX
    ret
init_file_path ENDP


init_command_line PROC NEAR
    push CX
    push SI

    mov CX,0
    mov SI,offset command_line_args
get_cmd_size_loop:
    cmp  BYTE PTR [SI],0
    je end_cmd_size_loop
    inc SI
    inc CX
    jmp get_cmd_size_loop

end_cmd_size_loop:
    mov DS:command_line_size, CL
    mov cmd_offset,offset command_line_size
    mov cmd_segment, SEG command_line_size

    pop SI
    pop CX
    ret
init_command_line ENDP


run_loader PROC NEAR
    push DS
    push ES
    push AX
    push DX
    push BX

    mov CS:KEEP_SS,SS
    mov CS:KEEP_SP,SP
    call init_command_line
    call init_file_path
    mov AX,DS
    mov ES,AX
    mov BX,offset segment_adress
    mov DX,offset file_path

    mov AX,4B00h
    int 21h
  
    mov SS,CS:KEEP_SS
    mov SP,CS:KEEP_SP
    call process_the_result

    pop BX
    pop DX
    pop AX
    pop ES
    pop DS

    ret
run_loader ENDP

process_the_result PROC NEAR
    push AX
    push DX
    push SI

    jb hanlde_error_code
    mov DX,offset normal_termination
    call print
    mov AH,4Dh
    int 21h
    cmp AH,0
    jne completion_check_2
    mov DX,offset termination_reason_0
    jmp print_exit_code
    
completion_check_2:
    cmp AH,1
    jne completion_check_3
    mov DX,offset termination_reason_1
    jmp print_exit_code

completion_check_3:
    cmp AH,2
    jne completion_check_4
    mov DX,offset termination_reason_2
    jmp print_exit_code

completion_check_4:
    mov DX,offset termination_reason_3
    
print_exit_code:
    call print
    mov SI,offset exit_code
    add SI,10
    mov [SI],AL
    mov DX,offset exit_code
    call print
    jmp process_the_result_end

hanlde_error_code:
    cmp AX,1
    jne load_error_check_2
    mov DX,offset load_error_1
    jmp print_load_error

load_error_check_2:
    cmp AX,2
    jne load_error_check_3
    mov DX,offset load_error_2
    jmp print_load_error

load_error_check_3:
    cmp AX,5
    jne load_error_check_4
    mov DX,offset load_error_3
    jmp print_load_error

load_error_check_4:
    cmp AX,8
    jne load_error_check_5
    mov DX,offset load_error_4
    jmp print_load_error

load_error_check_5:
    cmp AX,10
    jne load_error_check_6
    mov DX,offset load_error_5
    jmp print_load_error

load_error_check_6:
    mov DX,offset load_error_6
    jmp print_load_error
print_load_error:
    call print

process_the_result_end:

    pop SI
    pop DX
    pop AX
    ret 
process_the_result ENDP

end_code:
CODE ENDS
END Main