section .data
    ; login and error messages
    msg_boot db 10, 'Terminal locked. PIN: ', 0
    boot_len equ $ - msg_boot

    msg_admin_pin db 10, 'Manager PIN: ', 0
    admin_pin_len equ $ - msg_admin_pin

    msg_denied db 'Access denied.', 10, 0
    denied_len equ $ - msg_denied

    msg_lock db 'Finish or void current order first.', 10, 0
    lock_len equ $ - msg_lock

    msg_empty db 'Cart is empty. Add items first.', 10, 0
    empty_len equ $ - msg_empty

    ; pos menu stuff
    menu db 10, '--- Cafe POS ---', 10, '1: Premium Coffee ($12.50)', 10, '2: Matcha Latte ($8.75)', 10, '3: Checkout', 10, '4: Void Order', 10, 'Choice (9 for Admin): ', 0
    menu_len equ $ - menu
    
    admin_menu db 10, '--- Admin ---', 10, '1: X-Report (End Shift)', 10, '2: Z-Report (End Day)', 10, '3: Shutdown', 10, '4: Back', 10, 'Choice: ', 0
    admin_menu_len equ $ - admin_menu

    msg_coffee db 'Added Premium Coffee.', 10, 0
    coffee_len equ $ - msg_coffee
    
    msg_tea db 'Added Matcha Latte.', 10, 0
    tea_len equ $ - msg_tea

    msg_void db 'Order voided.', 10, 0
    void_len equ $ - msg_void

    msg_discount db 10, 'Discount applied (-$5.00)', 10, 0
    discount_len equ $ - msg_discount
    
    ; receipt and report text
    msg_receipt_header db 10, '--- Receipt ---', 10, 0
    receipt_header_len equ $ - msg_receipt_header

    msg_rcpt_coffee db 'Coffee: ', 0
    rcpt_coffee_len equ $ - msg_rcpt_coffee

    msg_rcpt_tea db 10, 'Tea   : ', 0
    rcpt_tea_len equ $ - msg_rcpt_tea
    
    msg_total db 10, 'Total : $', 0
    total_len equ $ - msg_total
    
    msg_x_header db 10, '--- X-REPORT (SHIFT SUMMARY) ---', 10, 0
    x_header_len equ $ - msg_x_header

    msg_z_header db 10, '--- Z-REPORT (DAILY SUMMARY) ---', 10, 0
    z_header_len equ $ - msg_z_header

    msg_shifts db 10, 'Total Shifts Today: ', 0
    shifts_len equ $ - msg_shifts

    msg_drawer db 10, 'Drawer Cash: $', 0
    drawer_len equ $ - msg_drawer

    msg_reset_x db 10, 'Shift closed. Memory reset for next cashier.', 10, 0
    reset_x_len equ $ - msg_reset_x

    msg_reset_z db 10, 'Cash removed. Drawer reset to $100.00.', 10, 0
    reset_z_len equ $ - msg_reset_z

    msg_shutdown db 'Shutting down...', 10, 0
    shutdown_len equ $ - msg_shutdown

    decimal_pt db '.', 0
    zero_char db '0', 0
    newline db 10, 0

section .bss
    choice resb 100     
    
    ; current cart
    total resd 1        
    coffee_qty resd 1   
    tea_qty resd 1      
    
    ; shift records
    shift_total resd 1
    shift_coffee resd 1
    shift_tea resd 1

    ; daily records
    daily_total resd 1
    daily_coffee resd 1
    daily_tea resd 1
    
    drawer_balance resd 1 
    shift_count resd 1
    char_buf resb 1     

section .text
    global _start

_start:
    ; set everything to 0 first
    mov dword [total], 0
    mov dword [coffee_qty], 0
    mov dword [tea_qty], 0
    mov dword [shift_total], 0
    mov dword [shift_coffee], 0
    mov dword [shift_tea], 0
    mov dword [daily_total], 0
    mov dword [daily_coffee], 0
    mov dword [daily_tea], 0
    mov dword [shift_count], 0
    ; drawer starts with 100 bucks (10000 cents)
    mov dword [drawer_balance], 10000 

cashier_login:
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_boot
    mov edx, boot_len
    int 0x80

    mov eax, 3
    mov ebx, 0
    mov ecx, choice
    mov edx, 100        
    int 0x80

    ; check for pin 1111
    mov al, [choice]
    cmp al, '1'
    jne boot_denied
    mov al, [choice+1]
    cmp al, '1'
    jne boot_denied
    mov al, [choice+2]
    cmp al, '1'
    jne boot_denied
    mov al, [choice+3]
    cmp al, '1'
    jne boot_denied
    jmp menu_loop

boot_denied:
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_denied
    mov edx, denied_len
    int 0x80
    jmp cashier_login

menu_loop:
    mov eax, 4
    mov ebx, 1
    mov ecx, menu
    mov edx, menu_len
    int 0x80

    mov eax, 3
    mov ebx, 0
    mov ecx, choice
    mov edx, 100
    int 0x80

    ; see what user picked
    mov al, [choice]
    cmp al, '1'
    je add_coffee
    cmp al, '2'
    je add_tea
    cmp al, '3'
    je checkout
    cmp al, '4'
    je void_order
    cmp al, '9'
    je try_admin_login  
    jmp menu_loop

add_coffee:
    ; add 12.50
    mov eax, [total]
    add eax, 1250        
    mov [total], eax
    mov eax, [coffee_qty]
    inc eax
    mov [coffee_qty], eax
    
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_coffee
    mov edx, coffee_len
    int 0x80
    jmp menu_loop

add_tea:
    ; add 8.75
    mov eax, [total]
    add eax, 875         
    mov [total], eax
    mov eax, [tea_qty]
    inc eax
    mov [tea_qty], eax
    
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_tea
    mov edx, tea_len
    int 0x80
    jmp menu_loop

void_order:
    ; wipe the cart if mistake was made
    mov dword [total], 0
    mov dword [coffee_qty], 0
    mov dword [tea_qty], 0
    
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_void
    mov edx, void_len
    int 0x80
    jmp menu_loop

try_admin_login:
    ; block manager login if items are still in cart
    cmp dword [total], 0
    je admin_login
    
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_lock
    mov edx, lock_len
    int 0x80
    jmp menu_loop

checkout:
    ; skip if cart is empty
    cmp dword [total], 0
    je empty_error

    ; give 5 dollar discount if they buy 3 or more items
    mov eax, [coffee_qty]
    add eax, [tea_qty]       
    cmp eax, 3               
    jl print_receipt         
    
    mov eax, [total]
    sub eax, 500         
    mov [total], eax
    
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_discount
    mov edx, discount_len
    int 0x80

print_receipt:
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_receipt_header
    mov edx, receipt_header_len
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, msg_rcpt_coffee
    mov edx, rcpt_coffee_len
    int 0x80
    mov eax, [coffee_qty]
    call print_number

    mov eax, 4
    mov ebx, 1
    mov ecx, msg_rcpt_tea
    mov edx, rcpt_tea_len
    int 0x80
    mov eax, [tea_qty]
    call print_number

    mov eax, 4
    mov ebx, 1
    mov ecx, msg_total
    mov edx, total_len
    int 0x80
    mov eax, [total]
    call print_currency  

    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    ; save current order to shift and daily records
    mov eax, [total]
    add [shift_total], eax
    add [daily_total], eax
    add [drawer_balance], eax  
    
    mov eax, [coffee_qty]
    add [shift_coffee], eax
    add [daily_coffee], eax
    
    mov eax, [tea_qty]
    add [shift_tea], eax
    add [daily_tea], eax

    ; reset cart for next customer
    mov dword [total], 0
    mov dword [coffee_qty], 0
    mov dword [tea_qty], 0
    jmp menu_loop

empty_error:
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_empty
    mov edx, empty_len
    int 0x80
    jmp menu_loop

admin_login:
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_admin_pin
    mov edx, admin_pin_len
    int 0x80

    mov eax, 3
    mov ebx, 0
    mov ecx, choice
    mov edx, 100        
    int 0x80

    ; check manager pin 9999
    mov al, [choice]
    cmp al, '9'
    jne admin_denied
    mov al, [choice+1]
    cmp al, '9'
    jne admin_denied
    mov al, [choice+2]
    cmp al, '9'
    jne admin_denied
    mov al, [choice+3]
    cmp al, '9'
    jne admin_denied
    jmp admin_loop      

admin_denied:
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_denied
    mov edx, denied_len
    int 0x80
    jmp menu_loop

admin_loop:
    mov eax, 4
    mov ebx, 1
    mov ecx, admin_menu
    mov edx, admin_menu_len
    int 0x80

    mov eax, 3
    mov ebx, 0
    mov ecx, choice
    mov edx, 100
    int 0x80

    mov al, [choice]
    cmp al, '1'
    je x_report
    cmp al, '2'
    je z_report
    cmp al, '3'
    je end_program
    cmp al, '4'
    je menu_loop
    jmp admin_loop

x_report:
    ; add to shift counter
    mov eax, [shift_count]
    inc eax
    mov [shift_count], eax

    mov eax, 4
    mov ebx, 1
    mov ecx, msg_x_header  
    mov edx, x_header_len
    int 0x80
    
    ; print the shift totals
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_rcpt_coffee     
    mov edx, rcpt_coffee_len
    int 0x80
    mov eax, [shift_coffee]
    call print_number

    mov eax, 4
    mov ebx, 1
    mov ecx, msg_rcpt_tea     
    mov edx, rcpt_tea_len
    int 0x80
    mov eax, [shift_tea]
    call print_number

    mov eax, 4
    mov ebx, 1
    mov ecx, msg_total           
    mov edx, total_len
    int 0x80
    mov eax, [shift_total]
    call print_currency

    ; only reset the shift memory
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_reset_x
    mov edx, reset_x_len
    int 0x80

    mov dword [shift_total], 0
    mov dword [shift_coffee], 0
    mov dword [shift_tea], 0
    jmp admin_loop

z_report:
    ; count final shift
    mov eax, [shift_count]
    inc eax
    mov [shift_count], eax

    mov eax, 4
    mov ebx, 1
    mov ecx, msg_z_header  
    mov edx, z_header_len
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, msg_shifts
    mov edx, shifts_len
    int 0x80
    mov eax, [shift_count]
    call print_number

    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    ; print all daily totals
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_rcpt_coffee     
    mov edx, rcpt_coffee_len
    int 0x80
    mov eax, [daily_coffee]
    call print_number

    mov eax, 4
    mov ebx, 1
    mov ecx, msg_rcpt_tea     
    mov edx, rcpt_tea_len
    int 0x80
    mov eax, [daily_tea]
    call print_number

    mov eax, 4
    mov ebx, 1
    mov ecx, msg_total           
    mov edx, total_len
    int 0x80
    mov eax, [daily_total]
    call print_currency

    mov eax, 4
    mov ebx, 1
    mov ecx, msg_drawer           
    mov edx, drawer_len
    int 0x80
    mov eax, [drawer_balance]
    call print_currency

    ; wipe EVERYTHING
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_reset_z
    mov edx, reset_z_len
    int 0x80

    mov dword [shift_total], 0
    mov dword [shift_coffee], 0
    mov dword [shift_tea], 0
    mov dword [daily_total], 0
    mov dword [daily_coffee], 0
    mov dword [daily_tea], 0
    mov dword [shift_count], 0
    mov dword [drawer_balance], 10000 
    jmp admin_loop

end_program:
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_shutdown
    mov edx, shutdown_len
    int 0x80

    mov eax, 1
    mov ebx, 0
    int 0x80

; divide to print decimals
print_currency:
    pusha
    mov edx, 0
    mov ebx, 100
    div ebx             
    
    push edx            
    call print_number   

    ; add the dot
    mov eax, 4          
    mov ebx, 1
    mov ecx, decimal_pt
    mov edx, 1
    int 0x80
    
    ; format single digit cents
    pop eax             
    cmp eax, 10         
    jge .print_cents
    
    push eax
    mov eax, 4
    mov ebx, 1
    mov ecx, zero_char
    mov edx, 1
    int 0x80
    pop eax

.print_cents:
    call print_number   
    popa
    ret

; loop to print numbers
print_number:
    pusha               
    mov ecx, 0          
    
    cmp eax, 0
    jne .divide_loop
    push 0              
    inc ecx
    jmp .print_loop
    
.divide_loop:
    mov edx, 0          
    mov ebx, 10         
    div ebx             
    push edx            
    inc ecx             
    cmp eax, 0          
    jne .divide_loop    

.print_loop:
    pop edx             
    add dl, '0'         
    mov [char_buf], dl  
    
    push ecx            
    mov eax, 4
    mov ebx, 1
    mov ecx, char_buf
    mov edx, 1
    int 0x80            
    pop ecx             
    
    loop .print_loop    
    
    popa                
    ret