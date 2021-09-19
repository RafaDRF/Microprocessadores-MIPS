# Calculadora Ponto flutuante
.macro getInt (%dreg)
    li $v0, 5
    syscall
    move %dreg, $v0
.end_macro

.macro getFloat
    li $v0, 6
    syscall 
.end_macro 

.macro printS (%str)
.data 
mStr: .asciiz %str
.text
    li $v0, 4
    la $a0, mStr
    syscall
.end_macro

.macro printFloat
    li $v0, 2
    syscall
.end_macro 


.macro exit
    li $v0, 10
    syscall
.end_macro

.data
jump_table: .word case_0, case_1, case_2, case_3, case_4, case_5, case_6

.text
main:
	# Menu
	printS("\n Bem vindo a calculadora em ponto flutuante.\n")
	printS(" Por favor, digite o inteiro correspondente a operação desejada: \n")
    	printS ("\n0 - Salvar valor no Acumulador \n")
    	printS ("1 - Exibir Acumulador \n")
   	printS ("2 - Zerar Acumulador \n")
   	printS ("3 - Realizar Soma \n")
   	printS ("4 - Realizar Subtração \n")
    	printS ("5 - Realizar Divisão \n")
    	printS ("6 - Realizar Multiplicação \n")
	printS ("7 - Sair do programa \n")
	
	getInt($s0)
	
	li  $t0, 7 
	beq $s0, $t0, main_exit
	
	
main_switch:
	sltiu $t0, $s0, 7
	beq  $t0, $zero, default
	
	
	la   $s1, jump_table
	sll  $s0, $s0, 2
	add  $s0, $s0, $s1
	lw   $s0, 0($s0)
	jr   $s0
	
    case_0:
        printS(" Digite um valor: ")
        getFloat()
	mov.s $f12, $f0      
        j main_switch_end
        
    case_1:
    	printS(" Acumulador: ")
        printFloat()
        j main_switch_end
        
    case_2:
    	mtc1 $zero, $f12
    	j main_switch_end
    	
    case_3:
    	printFloat()
        printS(" + ")
        getFloat()
        add.s $f12, $f12, $f0
        printS("= ")
        printFloat()
        j main_switch_end
        
    case_4:
    	printFloat()
        printS(" - ")
        getFloat()
        sub.s $f12, $f12, $f0
        printS("= ")
        printFloat()
        j main_switch_end
        
    case_5:		
    	 printFloat()	
    	 printS(" / ")
    	 getFloat()			 
    	 div.s $f12, $f12, $f0
    	 printS("= ")
    	 printFloat()
        j main_switch_end
    case_6:
    	 printFloat()	
    	 printS(" * ")
    	 getFloat()
    	 mul.s $f12, $f12, $f0
    	 printS("= ")
    	 printFloat()
        j main_switch_end
        
    default:
        printS("valor inválido, tente novamente\n")
main_switch_end:

	j main
	
main_exit:
	exit()
