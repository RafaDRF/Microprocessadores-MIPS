.kdata 
_regs:.space 100
.ktext 0x80000180
interrupt:
	#Salvar Registradores
	move 	$k0, $at
	la	$k1, _regs
	sw	$k0, 0($k1)
	sw	$v0, 4($k1)
	sw	$v1, 8($k1)
	sw	$a0, 12($k1)
	sw	$a1, 16($k1)
	sw	$a2, 20($k1)
	sw	$a3, 24($k1)
	sw	$t0, 28($k1)
	sw	$t1, 32($k1)
	sw	$t2, 36($k1)
	sw	$t3, 40($k1)
	sw	$t4, 44($k1)
	sw	$t5, 48($k1)
	sw	$t6, 52($k1)
	sw	$t7, 56($k1)
	sw	$s0, 60($k1)
	sw	$s1, 64($k1)
	sw	$s2, 68($k1)
	sw	$s3, 72($k1)
	sw	$s4, 76($k1)
	sw	$s5, 80($k1)
	sw	$s6, 84($k1)
	sw	$s7, 88($k1)
	sw	$t8, 92($k1)
	sw	$t9, 96($k1)
	sw	$ra,100($k1)
	
	
	la $k0, disable_keyboard
	jalr $k0
	
	andi	$t0, $13, 0x80	#verifica se a interrupcao foi do teclado
	beq	$t0, 0x80, interupt_not_keyboard
	
	lui     	$t0,0xffff     # get address of control regs
	lw	$t1,0($t0)     # read rcv ctrl
	andi	$t1,$t1,0x0001 # extract ready bit
	
	lw	$t1,4($t0)     # read key
	
	# se for i,o,k ou l ele escreve
	bne	$t1, 105, interrupt_continue0
	li	$t1, 0
	j	interrupt_write
interrupt_continue0:
	bne	$t1, 111, interrupt_continue1
	li	$t1, 1
	j	interrupt_write
 interrupt_continue1:
 	bne	$t1, 107, interrupt_continue2
	li	$t1, 2
	j	interrupt_write
 interrupt_continue2:
 	bne	$t1, 108, intDone
	li	$t1, 3
interrupt_write:
	#escreve no ringbuffer
	la	$a0, ringbuffer 	
	move	$a1, $t1
	la $t1, write
	jalr $t1
	
intDone:	
	## Clear Cause register
	mfc0	$t0,$13			# get Cause register, then clear it
	mtc0	$0, $13
	
	
	mtc0	$0, $13	
	
	la $k0, enable_keyboard_int
	jalr $k0
	
	
	lw	$k0, 0($k1)
	lw	$v0, 4($k1)
	lw	$v1, 8($k1)
	lw	$a0, 12($k1)
	lw	$a1, 16($k1)
	lw	$a2, 20($k1)
	lw	$a3, 24($k1)
	lw	$t0, 28($k1)
	lw	$t1, 32($k1)
	lw	$t2, 36($k1)
	lw	$t3, 40($k1)
	lw	$t4, 44($k1)
	lw	$t5, 48($k1)
	lw	$t6, 52($k1)
	lw	$t7, 56($k1)
	lw	$s0, 60($k1)
	lw	$s1, 64($k1)
	lw	$s2, 68($k1)
	lw	$s3, 72($k1)
	lw	$s4, 76($k1)
	lw	$s5, 80($k1)
	lw	$s6, 84($k1)
	lw	$s7, 88($k1)
	lw	$t8, 92($k1)
	lw	$t9, 96($k1)
	lw	$ra,100($k1)
	
	eret
	
interupt_not_keyboard:
	li	$v0, 10
	syscall
	


.eqv Display 0x10040000
	# 256 x 256
	# Pixels 32 x 32
.data 
	# 124
	sequence:  .space 124
	ringbuffer:   .space 28
	# 28
	Ask:	   .asciiz " Insira o nível de dificuldade (1 - 4): \n"
	Error: 	   .asciiz "\n Numero invalido, tente novamente \n"
	lose:	   .asciiz "\n Voce Perdeu"
	win:	   .asciiz "\n Voce Ganhou"			
.text
main:
	la	$a0, ringbuffer
	jal	init_buffer
	jal	enable_keyboard_int
	
	jal	menu
	
	move	$s0, $v0
	
	
	la	$a0, sequence
	move	$a1, $s0
	jal	get_sequence
	
	move	$s4, $zero	#verifica se e a ultima interacao
	li	$s1, 1		# $s0 - numero maximo de sequencias
				# $s1 - numero atual de sequencias
main_for:
	bgt	$s1, $s0, main_last
	
	#desabilitar interrupcoes de teclado
	jal	disable_keyboard
	
	la	$a0, sequence
	move	$a1, $s1			# imprime a sequencia atual
	jal	print_sequence
	
	#habilitar interrupcoes de teclado
	jal	enable_keyboard_int
	
	move	$s2, $zero
	main_for2:
		bge	$s2, $s1, main_for2_end
	#---------------------------------------------------------------------------	
		# esperar ter dado para ler
		main_wait:
		la	$a0, ringbuffer
		jal	buffer_vazio
		beqz 	$v0, main_continue
		j	main_wait
		main_continue:
		
		# ler buffer e imprimir valor
		la	$a0, ringbuffer
		jal	read
		move	$s5, $v0
		move	$a0, $v0
		
		jal 	print_rectangle
		
		# validar dado lido     lido == sequence[j]
		la	$a0, sequence
		sll	$t0, $s2, 2
		addu	$t0, $a0,$t0	
		lw	$t0, 0($t0) 	
		bne	$s5, $t0, main_lose
	#---------------------------------------------------------------------------
		beq	$s2,  $s0, main_end
		#beq	$s4, 1 , main_end
		addiu	$s2, $s2, 1
	j main_for2	
	main_for2_end:
	addiu	$s1, $s1, 1
	j 	main_for
main_last:
	li	$s4, 1	
	j	main_for2
main_end:	
	li 	$v0 , 4	
	la 	$a0, win
	syscall																																																																	
	li	$v0, 10
	syscall
main_lose:
	li 	$v0 , 4	
	la 	$a0, lose
	syscall
	li	$v0, 10
	syscall

# RX Interrupts Enable (Keyboard)-----------------------------------------
enable_keyboard_int:
	addiu $sp, $sp, -8
	sw   $ra, 0($sp)
	
	jal  disable_int
	lui  $t0,0xffff
	lw   $t1,0($t0)      # read rcv ctrl
	ori  $t1,$t1,0x0002  # set the input interupt enable
	sw   $t1,0($t0)	     # update rcv ctrl
	jal  enable_int
	
	lw   $ra, 0($sp)
	addiu $sp, $sp, 8
	jr   $ra
#-------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------
disable_keyboard:
		addiu $sp, $sp, -8
		sw   $ra, 0($sp)
		
		jal  disable_int
		# disable keyboard
		sw $zero, 0xffff0000
		jal  enable_int
		
		lw   $ra, 0($sp)
		addiu $sp, $sp, 8
		jr $ra
#-------------------------------------------------------------------------------------	

# Global Interrupt Handle Routines---------------------------------------
enable_int:
	addiu $sp, $sp, -8
	sw   $ra, 0($sp)
       	
       	mfc0	$t0, $12	 # record interrupt state
	ori	$t0, $t0, 0x0001 # set int enable flag
	
	mtc0    $t0, $12	 # Turn interrupts on.
	
	sw   $ra, 0($sp)
	addiu $sp, $sp,8

	jr      $ra
	
disable_int:
	addiu $sp, $sp, -8
	sw   $ra, 0($sp)
	
	mfc0	$t0, $12	 # record interrupt state
	andi	$t0, $t0, 0xFFFE # clear int enable flag
	mtc0    $t0, $12         # Turn interrupts off.
	
	lw   $ra, 0($sp)
	addiu $sp, $sp, 8
	jr      $ra
#---------------------------------------------------------------------------------------
# Retorna o numero de sequencias  -------------------------------------------------------
menu:
	addiu $sp, $sp, -8
	sw   $ra, 0($sp)
	#Pede ao usuario um numero entre 1 e 4 
	li 	$v0 , 4	
	la 	$a0, Ask
	syscall 
	
	li 	$v0 , 12	
	syscall
	
	blt 	$v0, 49, menu_invalid 
	bgt 	$v0, 52, menu_invalid	
	addiu	$t0, $v0, -49
	
	li	$v0, 8
	bne	$t0, 1, menu_continue1	# Nivel 1 - ate 08 sequencias			
	li	$v0, 16			# Nivel 2 - ate 16 sequencias
	jr	$ra			# Nivel 3 - ate 20 sequencias
					# Nivel 4 - ate 31 sequencias	
menu_continue1:				
	bne	$t0, 2, menu_continue2
	li	$v0, 20
	jr	$ra

menu_continue2:
	beqz	$t0, menu_end	 
	li	$v0, 31
	jr	$ra
	
menu_end:
	
	lw   $ra, 0($sp)
	addiu $sp, $sp, 8
		
	jr 	$ra

menu_invalid:
	li 	$v0 , 4	
	la 	$a0, Error
	syscall 
	b menu
# ------------------------------------------------------------------------------------------------------


# Preenche o vetor em $a0 com $a1 sequencias de numeros aleatorios de 0 a 3 ------------------
get_sequence:
	# stack
	#____________
	#      empty	8
	#____________
	#         a1	4
	#____________	
	#         a0 	0
	#____________
	
	addiu	$sp, $sp, -8
	sw	$ra, 8($sp)
	sw	$a1, 4($sp)
	sw	$a0, 0($sp)
	
	
	move	$t0, $a0 
	move	$t1, $a1 

	#semente para gerar numeros pseuoaleatorios
	li	$v0, 30				#System time
	syscall
	
	li	$v0, 40				#Set Seed
	syscall
get_sequence_for:
	beqz	$t1, get_sequence_end
	
	
	li	$v0, 42				#random int range
	li	$a0, 0
	li	$a1, 3
	syscall
	
	sw	$a0,0($t0)
	
	addiu	$t0, $t0, 4
	addiu	$t1, $t1, -1
	j get_sequence_for
get_sequence_end:

	#Restaura os valores salvos e destroi o quadro gerado
	lw	$ra, 8($sp)
	lw	$a1, 4($sp)
	lw	$a0, 0($sp)
	addiu	$sp, $sp, 8
							
	jr	$ra
# -------------------------------------------------------------------------------------------------------------------------------

# imprime a sequencia com $a1 numeros ------------------------------------------		
print_sequence:
	#_Stack________
	#	$s1	16
	#_____________
	#	$s0	12
	#_____________	
	#	$a1	8
	#_____________
	#	$ra	4
	#_____________
	#	$a0	0
	#_____________
	addiu	$sp, $sp, -16
	sw	$a0, 0($sp)
	sw	$ra,  4($sp)
	sw	$a1, 8($sp)
	sw	$s0,12($sp)
	sw	$s1,16($sp)
	
	move	$s0, $a0
	move	$s1, $a1
	
		
print_sequence_for:
	blez	$s1, print_sequence_end
	lw	$a0, 0($s0)
	
	jal	print_rectangle
	
	addiu	$s0, $s0, 4		
	addiu	$s1, $s1, -1
	j print_sequence_for
	
print_sequence_end:

	
	lw	$s1,  16($sp)
	lw	$s0, 12($sp)
	lw	$a1, 8($sp)
	lw	$ra, 4($sp)
	lw	$a0, 0($sp)	
	addiu	$sp, $sp, 16
	jr	$ra
#-----------------------------------------------------------------------------------------------------------
				
# acende por 1 segundo a cor -------------------------------------------------------------------
print_rectangle:
#	0 - acende verde	 
#	1 - acende amarelo	
#	2 - acende vermelho	
#	3 - acende azul
	addiu $sp, $sp, -8	
	sw  	$ra, 0($sp)
	move	$t4, $zero
back:
	la	$t0, Display
	
	move	$t1, $a0
	
	li	$t2, 0x000000
	
	addu	$t3, $t0, $zero
	bnez	$t1, print_rectangle_continue0
	beq	$t4, 1, array 
	
	li	$t5, 61	
	li	$t2, 0x00ff00	
	j	array 

print_rectangle_continue0:
	addiu	$t3, $t0, 16		
	bne	$t1, 1, print_rectangle_continue1
	beq	$t4, 1, array 
	
	li	$t5, 71	
	li	$t2, 0xffff00
	j	array
print_rectangle_continue1:
	addiu	$t3, $t0, 128
	bne	$t1, 2, print_rectangle_continue2
	beq	$t4, 1, array 
	
	li	$t5, 64
	li	$t2, 0xff0000
	j	array
print_rectangle_continue2:
	addiu	$t3, $t0, 144
	bne	$t1, 3, array
	beq	$t4, 1, array 
	
	li	$t5, 68
	li	$t2, 0x0000ff

array:	# $t2 - Cor	$t3 endereço com offset
	li   	$t1, 4
loop_column:
	li	$t4, 4
	beqz 	$t1, loop_column_end
loop_row:	
	beqz 	$t4, loop_row_end
	
	sw 	$t2, 0($t3)

	addiu 	$t3, $t3, 4
	
	addiu 	$t4, $t4, -1
	j	loop_row
loop_row_end:
	addiu 	$t3, $t3, 16
	addiu 	$t1, $t1, -1
	j 	loop_column

loop_column_end:
	beq	$t2, 0x000000, print_rectangle_end 
	li	$t4, 1
	
	move $t0, $a0
	
	move $a0, $t5		#sons 
	li $a1, 1000		#duracao
	li $a2, 26			#instrumento	
	li $a3, 20			#volume			
	li $v0, 33
	syscall
	
	move	$a0, $t0
	j	back
print_rectangle_end:	
	
	lw  	$ra, 0($sp)
	addiu $sp, $sp, 8	
	jr	$ra
#-------------------------------------------------------------------------------------------------------

# void init(t_ringbuffer * rbuf)  zera todos os elementos da struct -----	
init_buffer:
	addiu $sp, $sp, -8	
	sw  	$ra, 0($sp)
	
	sw $zero, 0($a0)
	sw $zero, 4($a0)
	sw $zero, 8($a0)
	
	sw  	$ra, 0($sp)
	addiu $sp, $sp, 8
	jr $ra
#-------------------------------------------------------------------------------------------

read:
    	addiu $sp, $sp, -16
   	sw    $s0, 4($sp)
    	sw    $ra, 8($sp)

    	li $v0, 0        # tmp = 0
    	move $s0, $a0        # $s0 = $a0

    	jal buffer_vazio
    	bne $v0, $zero, read_end

    	lb $t0, 0($s0)
    	addiu $t0, $t0, -1
   	sw $t0, ($s0)

    	lw $t0, 4($s0)
    	add $t0, $s0, $t0
    	lb $v0, 12($t0)

   	lw $t0, 4($s0)
    	addiu $t0, $t0, 1
    	li $t1, 16
    	div $t0, $t1
    	mfhi $t0
    	sw $t0, 4($s0)

read_end:
    	lw    $ra, 8($sp)
    	lw    $s0, 4($sp)
    	addiu $sp, $sp, 16
    	jr $ra 

#  char write(t_ringbuffer * rbuf, char byte) nao escreve quando o buffer estiver cheio retornando 0 
write:	# a0 = *ringbuffer; a1 = byte
	
	addiu	$sp, $sp, -16
	sw	$a0, 0($sp)		#precisa de pilha para garantir o valor do $s0 (anterior)			
	sw	$s0, 4($sp)		#e o valor de $ra
	sw	$s1, 8($sp)		
	sw	$ra, 12($sp)
	
	move $s0, $a0		
	move $s1, $a1			
	
	jal buffer_cheio
	
	beq $v0, 1, write_if_fim
	
	lw $t1, 0($s0)	
	addiu $t1, $t1, 1
	sw $t1, 0($s0)			# rb->size++
			
	lw  $t1, 8($s0)
	
	addiu $t2, $t1, 1			# rb->rd + 1
	
					
	addu  $t1, $t1, $s0			#offset				
	
	sb $s1, 12($t1)			# rbuf->buf[rbuf->wr] = byte; 
	
	rem $t2, $t2, 16
	sw $t2, 8($s0)		
	
	li $v0,1
	
	lw	$ra, 12($sp)
	lw	$s1, 8($sp)
	lw	$s0, 4($sp)
	lw	$a0, 0($sp)
	addiu	$sp, $sp, 16
				
	jr $ra																																																																							
write_if_fim:
	move $v0, $zero	
			
	lw	$ra, 12($sp)
	lw	$s1, 8($sp)
	lw	$s0, 4($sp)
	lw	$a0, 0($sp)
	addiu	$sp, $sp, 16
	jr $ra
#-------------------------------------------------------------------------------------------------------------------------
		
#int buffer_cheio(t_ringbuffer * rbuf)   retorna 1 se o buffer estiver cheio, caso contrário 0	
buffer_cheio:
	addiu	$sp, $sp, -8
	sw	$ra, 0($sp)
	lw $t0, 0($a0)
	
	blt  $t0, 16,  if_cheio
	li $v0, 1
	j buffer_cheio_fim
if_cheio:
	li $v0, 0	
buffer_cheio_fim:
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 8
	
	jr $ra
#-------------------------------------------------------------------------------------------------------------------------

#int buffer_vazio(t_ringbuffer * rbuf)   retorna 1 se o buffer estiver vazio, caso contrário 0
buffer_vazio:
	addiu	$sp, $sp, -8
	sw	$ra, 0($sp)
	lw $t0, 0($a0)
	beqz $t0, if_vazio
	li $v0, 0
	j buffer_vazio_fim
if_vazio:
	li $v0, 1	
buffer_vazio_fim:
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 8
	jr $ra

