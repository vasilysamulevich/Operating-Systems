Astack SEGMENT STACK
    DW 128 DUP (?)
Astack ENDS

DATA SEGMENT
    DTA_buffer DB 45 DUP (?)
    first_clear_error DB "Error clearing memory: control block destroyed.",0Dh,0Ah,'$'
    second_clear_error DB "Error while clearing memory: Not enough memory to execute function.",0Dh,0Ah,'$'
    fird_clear_error DB "Error clearing memory: invalid memory block address.",0Dh,0Ah,'$'


    size_calculation_error_header DB "Error while determining module size of overlay structure: ",'$'
    size_calculation_error_1 DB "file not found.",0Dh,0Ah,'$'
    size_calculation_error_2 DB "route not found.",0Dh,0Ah,'$'
    allocation_error DB "Error while allocating memory for overlay structure module.",0Dh,0Ah,'$'

    load_error_header DB "Error loading overlay into memory:",'$'
    load_error_1 DB "non-existent function.",0Dh,0Ah,'$'
    load_error_4 DB "too many open files.",0Dh,0Ah,'$'
    load_error_5 DB "no access",0Dh,0Ah,'$'
    load_error_6 DB "not enough memory",0Dh,0Ah,'$'
    load_error_7 DB "wrong environment",0Dh,0Ah,'$'
   
    

    overlay_name_1 DB "first.ovl",'$'
    overlay_name_2 DB "second.ovl",'$'
    overlay_path DB 128 DUP (0)

    overlay_segment DW 0
    overlay_offset DW 0

end_data DB 0

DATA ENDS


CODE SEGMENT
ASSUME CS:CODE, DS:DATA, SS:Astack

Main PROC FAR
    push DS
    sub AX,AX
    push AX
    mov AX,DATA
    mov DS,AX

    mov AH,1ah
    mov DX,offset DTA_buffer
    int 21h

    call free_memory
    jb Main_end 
    mov BX,offset overlay_name_1
    call execute_overlay
    mov BX,offset overlay_name_2
    call execute_overlay

    
Main_end:
    mov AX,0
    mov AH,4ch
    int 21h
 
Main ENDP

execute_overlay PROC NEAR; BX- offset имени модуля
    push AX
    push ES
    call init_file_path
    call Request_memory
    jb execute_end
    call Load_overlay
    jb execute_end
   
    mov AX,overlay_segment
    mov ES,AX
    xchg AX,overlay_offset
    xchg AX,overlay_segment

    call DWORD PTR overlay_segment
    mov ES,overlay_offset
    mov AH,49h
    int 21h
    mov overlay_segment,0
    mov overlay_offset,0

execute_end:
    pop ES
    pop AX
    ret
execute_overlay ENDP



Load_overlay PROC NEAR
    push AX
    push BX
    push DX
    push ES

    mov DX,offset overlay_path
    push DS
    pop ES
    mov BX,offset overlay_segment
    mov AX,4B03h
    int 21h
    jae successful_upload

    cmp AX,1
    jne load_error_check2
    mov DX,offset load_error_1
    jmp print_load_error

load_error_check2:    
    cmp AX,2
    jne load_error_check3
    mov DX,offset size_calculation_error_1
    jmp print_load_error

load_error_check3:    
    cmp AX,3
    jne load_error_check4
    mov DX,offset size_calculation_error_2
    jmp print_load_error

load_error_check4:    
    cmp AX,4
    jne load_error_check5
    mov DX,offset load_error_4
    jmp print_load_error


load_error_check5:    
    cmp AX,5
    jne load_error_check6
    mov DX,offset load_error_5
    jmp print_load_error


load_error_check6:    
    cmp AX,8
    jne load_error_check7
    mov DX,offset load_error_6
    jmp print_load_error


load_error_check7:    
    mov DX,offset load_error_7

print_load_error:
    call print
    STC
    jmp load_end
successful_upload:
    CLC

Load_end: 
    pop ES
    pop DX
    pop BX
    pop AX
    ret
Load_overlay ENDP

Request_memory PROC NEAR
    push CX
    push DX
    push AX
    push SI

    mov CX,0
    mov DX,offset overlay_path
    mov AX,0
    mov AH,4eh
    int 21h
    jae start_allocating_memory

    mov DX,offset size_calculation_error_header
    call print
 
    cmp AX,2
    jne second_size_calculation_error
    mov DX,offset overlay_name_1
    jmp print_size_calculation_error

second_size_calculation_error:
    mov DX,offset size_calculation_error_2

print_size_calculation_error:
    call print
    STC
    jmp Request_end

start_allocating_memory:
    mov SI,offset DTA_buffer
    mov DX,[SI+1Ch]
    mov AX, [SI+1Ah]
    mov CX,16
    div CX
    inc AX
    mov BX,AX
    mov AH,48h
    int 21h
    jae successful_memory_allocation

    mov DX,offset allocation_error
    call print
    STC
    jmp Request_end

successful_memory_allocation:
    mov overlay_segment,AX
    CLC
     
Request_end:
    pop SI
    pop AX
    pop DX
    pop CX
    ret
Request_memory ENDP



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

init_file_path PROC NEAR ;BX - смещение имени файла 
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
    mov DI,offset overlay_path
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
    mov SI,BX
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


print PROC NEAR
    push AX
    mov AH,09h
    int 21h
    pop AX
    ret
print ENDP

end_code:

CODE ENDS
END Main