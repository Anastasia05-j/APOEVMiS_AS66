.686
.model flat, c

.data
; Константы для Раздела 1 (Целочисленные)
c_1    dd 1
c_2    dd 2
c_3    dd 3
c_4    dd 4
c_5    dd 5
c_9    dd 9
c_m5   dd -5

; Константы для Раздела 2 (Вещественные/Real)
c_1_r  dd 1.0
c_2_r  dd 2.0
c_3_r  dd 3.0
c_4_r  dd 4.0
c_5_r  dd 5.0
c_9_r  dd 9.0
c_m5_r dd -5.0

; Глобальные переменные для удобного доступа из внутренних процедур
; (Команды FPU требуют загрузки данных именно из памяти)
global_x   dd 0
global_y   dd 0
global_ptr dd 0

global_x_r dd 0.0
global_y_r dd 0.0

.code


; Ветка 1: 5x + 2xy + 1
branch1_int PROC
    fild dword ptr [global_x]  ; загружаем целое x
    fimul dword ptr [c_5]      ; st(0) = 5x

    fild dword ptr [global_x]  
    fimul dword ptr [global_y] 
    fimul dword ptr [c_2]      ; st(0) = 2xy, st(1) = 5x
    
    faddp st(1), st(0)         ; st(0) = 5x + 2xy
    fiadd dword ptr [c_1]      ; st(0) = 5x + 2xy + 1
    
    mov eax, [global_ptr]
    fistp dword ptr [eax]      ; выгружаем как целое с округлением
    ret
branch1_int ENDP

; Ветка 2: (2xy + 3) / (y^2 + 4)
branch2_int PROC
    fild dword ptr [global_x]
    fimul dword ptr [global_y]
    fimul dword ptr [c_2]
    fiadd dword ptr [c_3]      ; st(0) = числитель (2xy + 3)

    fild dword ptr [global_y]
    fimul dword ptr [global_y]
    fiadd dword ptr [c_4]      ; st(0) = знаменатель (y^2 + 4), st(1) = числитель

    fdivp st(1), st(0)         ; st(0) = числитель / знаменатель

    mov eax, [global_ptr]
    fistp dword ptr [eax]
    ret
branch2_int ENDP

; Ветка 3: 3x^2 - 2y^2 + 1
branch3_int PROC
    fild dword ptr [global_x]
    fimul dword ptr [global_x]
    fimul dword ptr [c_3]      ; st(0) = 3x^2
    
    fild dword ptr [global_y]
    fimul dword ptr [global_y]
    fimul dword ptr [c_2]      ; st(0) = 2y^2, st(1) = 3x^2
    
    fsubp st(1), st(0)         ; st(0) = 3x^2 - 2y^2
    fiadd dword ptr [c_1]      ; st(0) = 3x^2 - 2y^2 + 1
    
    mov eax, [global_ptr]
    fistp dword ptr [eax]
    ret
branch3_int ENDP

; Главная функция Раздела 1
calculate_int PROC x:DWORD, y:DWORD, res_ptr:DWORD
    ; Копируем параметры в глобальную память для внутренних процедур FPU
    mov eax, x
    mov [global_x], eax
    mov eax, y
    mov [global_y], eax
    mov eax, res_ptr
    mov [global_ptr], eax

    ; Проверка условия x + y > 9
    fild dword ptr [global_x]
    fiadd dword ptr [global_y] 
    ficomp dword ptr [c_9]     ; сравниваем st(0) с 9 и выталкиваем
    fnstsw ax                  ; копируем флаги FPU в регистр AX
    sahf                       ; переносим в стандартные флаги процессора
    ja do_b1_int

    ; Проверка условия x + y < -5
    fild dword ptr [global_x]
    fiadd dword ptr [global_y]
    ficomp dword ptr [c_m5]
    fnstsw ax
    sahf
    jb do_b2_int

    ; Иначе (от -5 до 9) ветка 3
    call branch3_int
    jmp end_int

do_b1_int:
    call branch1_int
    jmp end_int

do_b2_int:
    call branch2_int

end_int:
    ret
calculate_int ENDP


; Ветка 1: 5x + 2xy + 1
branch1_real PROC
    fld dword ptr [global_x_r] ; загружаем float x
    fmul dword ptr [c_5_r]      

    fld dword ptr [global_x_r]
    fmul dword ptr [global_y_r]
    fmul dword ptr [c_2_r]      
    
    faddp st(1), st(0)          
    fadd dword ptr [c_1_r]      
    
    mov eax, [global_ptr]
    fstp dword ptr [eax]       ; выгружаем как float
    ret
branch1_real ENDP

; Ветка 2: (2xy + 3) / (y^2 + 4)
branch2_real PROC
    fld dword ptr [global_x_r]
    fmul dword ptr [global_y_r]
    fmul dword ptr [c_2_r]
    fadd dword ptr [c_3_r]      

    fld dword ptr [global_y_r]
    fmul dword ptr [global_y_r]
    fadd dword ptr [c_4_r]      

    fdivp st(1), st(0)          

    mov eax, [global_ptr]
    fstp dword ptr [eax]
    ret
branch2_real ENDP

; Ветка 3: 3x^2 - 2y^2 + 1
branch3_real PROC
    fld dword ptr [global_x_r]
    fmul dword ptr [global_x_r]
    fmul dword ptr [c_3_r]      
    
    fld dword ptr [global_y_r]
    fmul dword ptr [global_y_r]
    fmul dword ptr [c_2_r]      
    
    fsubp st(1), st(0)          
    fadd dword ptr [c_1_r]      
    
    mov eax, [global_ptr]
    fstp dword ptr [eax]
    ret
branch3_real ENDP

; Главная функция Раздела 2
calculate_real PROC x:DWORD, y:DWORD, res_ptr:DWORD
    ; Копируем
    mov eax, x
    mov [global_x_r], eax
    mov eax, y
    mov [global_y_r], eax
    mov eax, res_ptr
    mov [global_ptr], eax

    ; Проверка условия x + y > 9
    fld dword ptr [global_x_r]
    fadd dword ptr [global_y_r]
    fcomp dword ptr [c_9_r]
    fnstsw ax
    sahf
    ja do_b1_real

    ; Проверка условия x + y < -5
    fld dword ptr [global_x_r]
    fadd dword ptr [global_y_r]
    fcomp dword ptr [c_m5_r]
    fnstsw ax
    sahf
    jb do_b2_real

    ; Иначе (от -5 до 9) ветка 3
    call branch3_real
    jmp end_real

do_b1_real:
    call branch1_real
    jmp end_real

do_b2_real:
    call branch2_real

end_real:
    ret
calculate_real ENDP

END