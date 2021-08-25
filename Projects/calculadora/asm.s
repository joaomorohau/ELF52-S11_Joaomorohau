        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(2)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB
        
; System Control definitions
SYSCTL_BASE             EQU     0x400FE000
SYSCTL_RCGCGPIO         EQU     0x0608
SYSCTL_PRGPIO		EQU     0x0A08
SYSCTL_RCGCUART         EQU     0x0618
SYSCTL_PRUART           EQU     0x0A18
PORTA_BIT               EQU     000000000000001b ; bit  0 = Port A
UART0_BIT               EQU     00000001b        ; bit  0 = UART 0

; NVIC definitions
NVIC_BASE               EQU     0xE000E000
NVIC_EN1                EQU     0x0104
VIC_DIS1                EQU     0x0184
NVIC_PEND1              EQU     0x0204
NVIC_UNPEND1            EQU     0x04
NVIC_ACTIVE1            EQU     0x0304
NVIC_PRI12              EQU     0x0430

; GPIO Port definitions
GPIO_PORTA_BASE         EQU     0x40058000
GPIO_DIR                EQU     0x0400
GPIO_IS                 EQU     0x0404
GPIO_IBE                EQU     0x0408
GPIO_IEV                EQU     0x040C
GPIO_IM                 EQU     0x0410
GPIO_RIS                EQU     0x0414
GPIO_MIS                EQU     0x0418
GPIO_ICR                EQU     0x041C
GPIO_AFSEL              EQU     0x0420
GPIO_PUR                EQU     0x0510
GPIO_DEN                EQU     0x051C
GPIO_PCTL               EQU     0x052C

; UART Definitions
UART_PORT0_BASE         EQU     0x4000C000
UART_FR                 EQU     0x0018
UART_IBRD               EQU     0x0024
UART_FBRD               EQU     0x0028
UART_LCRH               EQU     0x002C
UART_CTL                EQU     0x0030
UART_CC                 EQU     0x0FC8

;UART bit definitions
TXFE_BIT                EQU     10000000b ; TX FIFO full
RXFF_BIT                EQU     01000000b ; RX FIFO empty
BUSY_BIT                EQU     00001000b ; Busy

/*----------------------------------------------------------------------------*/
; PROGRAMA PRINCIPAL

__iar_program_start
        
main:   MOV R2, #(UART0_BIT)
	BL UART_enable ; habilita clock ao port 0 de UART

        MOV R2, #(PORTA_BIT)
	BL GPIO_enable ; habilita clock ao port A de GPIO
        
	LDR R0, =GPIO_PORTA_BASE
        MOV R1, #00000011b ; bits 0 e 1 como especiais
        BL GPIO_special

	MOV R1, #0xFF ; m�scara das fun��es especiais no port A (bits 1 e 0)
        MOV R2, #0x11  ; fun��es especiais RX e TX no port A (UART)
        BL GPIO_select

	LDR R0, =UART_PORT0_BASE
        BL UART_config ; configura perif�rico UART0

 /*----------------------------------------------------------------------------*/
 
loop:   MOV R3, #0      ; Registrador para armazenar os numeros dos calculos
        MOV R9, #10     ; Registrador constante 10 para definir a ordem dos numeros digitados
        MOV R10, #0     ; Registrador para indicar o tamanho dos numeros

/*----------------------------------------------------------------------------*/

wrx:    LDR R2, [R0, #UART_FR] ; status da UART
        TST R2, #RXFF_BIT ; receptor cheio?
        BEQ wrx
        LDR R1, [R0] ; l� do registrador de dados da UART0 (recebe)

        B Valida_char      

/*----------------------------------------------------------------------------*/

wtx:    LDR R2, [R0, #UART_FR] ; status da UART
        TST R2, #TXFE_BIT ; transmissor vazio?
        BEQ wtx
        STR R1, [R0] ; escreve no registrador de dados da UART0 (transmite)
        
        CMP R1, #'+' 
        BEQ Recebe_soma
                
        CMP R1, #'-' 
        BEQ Recebe_sub
                
        CMP R1, #'*' 
        BEQ Recebe_mul
        
        CMP R1, #'/' 
        BEQ Recebe_div
        
        CMP R1, #'='
        BEQ Calculo
        
        MOV R2, R1
        SUBS R2, #48    ; Converte para ASCII
        MUL  R3, R9     ; Empurra o numero atual para frente
        ADD R3, R2      ; Soma o numero atual com o antigo deslocado
        ADD R10, #1     ; Indica o tamanho do numero (max 3 char)

        B wrx

/*----------------------------------------------------------------------------*/

Recebe_soma             ; Caso seja soma -> R11=1
      MOV R4, R3
      MOV R11, #1
      B loop 

Recebe_sub              ; Caso seja subtra��o -> R11=2
      MOV R4, R3
      MOV R11, #2
      B loop

Recebe_mul              ; Caso seja multiplica��o -> R11=3
      MOV R4, R3
      MOV R11, #3
      B loop

Recebe_div              ; Caso seja divis�o -> R11=4
      MOV R4, R3
      MOV R11, #4
      B loop

/*----------------------------------------------------------------------------*/

Calculo                 ; Switch Case para efetuar os calculos
      CMP R11, #1
      IT EQ
        BLEQ Soma
      
      CMP R11, #2
      IT EQ
        BLEQ Subtracao
        
      CMP R11, #3
      IT EQ
        BLEQ Multiplicacao
        
      CMP R11, #4
      IT EQ
        BLEQ Divisao

/*----------------------------------------------------------------------------*/
   
      MOV R8, R1       ; Verifica��o da impress�o
      BL Verifica_loop
      BL Imprime
      MOV R11, #0       ; Reseta a conta
      BL Enter          ; Pula a linha com lf e cr
      B loop

/*----------------------------------------------------------------------------*/
      
Verifica_loop
      PUSH {R1}
      SDIV R1, R9
      CBZ R1, out
      B Verifica_loop
out
      BX LR

Imprime
      POP {R1} 
      ADD R1, #48
      PUSH {LR}
      BL Print
      POP {LR}
      SUBS R1, #48
      CMP R1, R8
      IT EQ
        BXEQ LR 

/*----------------------------------------------------------------------------*/

Retorno_calculo         ; Recebe o retorno da UART e printa na tela
      POP {R7}
      MUL R1, R9
      SUBS R1, R7, R1
      PUSH {R7}
      PUSH {LR}
      ADD R1, #48       
      BL Print
      POP {LR}
      SUBS R1, #48      
      POP {R1}
      
      CMP R8, R1        
      IT EQ
        BXEQ LR
        
      B Retorno_calculo

/*----------------------------------------------------------------------------*/

Valida_char             ; Subrotina para validar a recep��o de numeros ou operandos apenas
        CMP R1, #'0' 
        BEQ Valida_tam
        
        CMP R1, #'1' 
        BEQ Valida_tam
                
        CMP R1, #'2' 
        BEQ Valida_tam
                
        CMP R1, #'3' 
        BEQ Valida_tam
                
        CMP R1, #'4' 
        BEQ Valida_tam
                
        CMP R1, #'5' 
        BEQ Valida_tam
        
        CMP R1, #'6' 
        BEQ Valida_tam
                
        CMP R1, #'7' 
        BEQ Valida_tam
                
        CMP R1, #'8' 
        BEQ Valida_tam
                
        CMP R1, #'9' 
        BEQ Valida_tam
                
        CMP R1, #'+' 
        BEQ wtx
                
        CMP R1, #'-' 
        BEQ wtx
                
        CMP R1, #'*' 
        BEQ wtx
        
        CMP R1, #'/' 
        BEQ wtx
        
        CMP R1, #'='
        BEQ wtx
        
        B wrx

/*----------------------------------------------------------------------------*/

Valida_tam              ; Subrotina para validar se o numero n�o passou de 3 digitos
        CMP R10, #3
        BEQ wrx
        
        B wtx  

/*----------------------------------------------------------------------------*/

Soma                    ;  Efetua o calculo de soma entre os numeros
     MOV R1, R3
     ADD R1, R4
     BX LR
         
Subtracao                 ;  Efetua o calculo de subtra��o entre os numeros
     MOV R1, R4
     SUBS R1, R3
     BX LR

Multiplicacao              ;  Efetua o calculo de multiplica��o entre os numeros
     MOV R1, R3
     MULS R1, R4
     BX LR 
     
Divisao                  ;  Efetua o calculo de divis�o entre os numeros
     MOV R1, R4
     SDIV R1, R3
     BX LR   

/*----------------------------------------------------------------------------*/
; UART_enable: habilita clock para as UARTs selecionadas em R2
; R2 = padr�o de bits de habilita��o das UARTs
; Destr�i: R0 e R1
UART_enable:
        LDR R0, =SYSCTL_BASE
	LDR R1, [R0, #SYSCTL_RCGCUART]
	ORR R1, R2 ; habilita UARTs selecionados
	STR R1, [R0, #SYSCTL_RCGCUART]

waitu	LDR R1, [R0, #SYSCTL_PRUART]
	TEQ R1, R2 ; clock das UARTs habilitados?
	BNE waitu

        BX LR
        
; UART_config: configura a UART desejada
; R0 = endere�o base da UART desejada
; Destr�i: R1
UART_config:
        LDR R1, [R0, #UART_CTL]
        BIC R1, #0x01 ; desabilita UART (bit UARTEN = 0)
        STR R1, [R0, #UART_CTL]

        ; clock = 16MHz, baud rate = 9600 bdr
        MOV R1, #104
        STR R1, [R0, #UART_IBRD]
        MOV R1, #11
        STR R1, [R0, #UART_FBRD]
        
        ; 8 bits, parity odd, 1 stop; 
        MOV R1, #0x6A
        STR R1, [R0, #UART_LCRH]
        
        ; clock source = system clock
        MOV R1, #0x00
        STR R1, [R0, #UART_CC]
        
        LDR R1, [R0, #UART_CTL]
        ORR R1, #0x01 ; habilita UART (bit UARTEN = 1)
        STR R1, [R0, #UART_CTL]

        BX LR


; GPIO_special: habilita func�es especiais no port de GPIO desejado
; R0 = endere�o base do port desejado
; R1 = padr�o de bits (1) a serem habilitados como fun��es especiais
; Destr�i: R2
GPIO_special:
	LDR R2, [R0, #GPIO_AFSEL]
	ORR R2, R1 ; configura bits especiais
	STR R2, [R0, #GPIO_AFSEL]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1 ; habilita fun��o digital
	STR R2, [R0, #GPIO_DEN]

        BX LR

; GPIO_select: seleciona func�es especiais no port de GPIO desejado
; R0 = endere�o base do port desejado
; R1 = m�scara de bits a serem alterados
; R2 = padr�o de bits (1) a serem selecionados como fun��es especiais
; Destr�i: R3
GPIO_select:
	LDR R3, [R0, #GPIO_PCTL]
        BIC R3, R1
	ORR R3, R2 ; seleciona bits especiais
	STR R3, [R0, #GPIO_PCTL]

        BX LR

; GPIO_enable: habilita clock para os ports de GPIO selecionados em R2
; R2 = padr�o de bits de habilita��o dos ports
; Destr�i: R0 e R1
GPIO_enable:
        LDR R0, =SYSCTL_BASE
	LDR R1, [R0, #SYSCTL_RCGCGPIO]
	ORR R1, R2 ; habilita ports selecionados
	STR R1, [R0, #SYSCTL_RCGCGPIO]

waitg	LDR R1, [R0, #SYSCTL_PRGPIO]
	TEQ R1, R2 ; clock dos ports habilitados?
	BNE waitg

        BX LR

; GPIO_digital_output: habilita sa�das digitais no port de GPIO desejado
; R0 = endere�o base do port desejado
; R1 = padr�o de bits (1) a serem habilitados como sa�das digitais
; Destr�i: R2
GPIO_digital_output:
	LDR R2, [R0, #GPIO_DIR]
	ORR R2, R1 ; configura bits de sa�da
	STR R2, [R0, #GPIO_DIR]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1 ; habilita fun��o digital
	STR R2, [R0, #GPIO_DEN]

        BX LR

; GPIO_write: escreve nas sa�das do port de GPIO desejado
; R0 = endere�o base do port desejado
; R1 = m�scara de bits a serem acessados
; R2 = bits a serem escritos
GPIO_write:
        STR R2, [R0, R1, LSL #2] ; escreve bits com m�scara de acesso
        BX LR

; GPIO_digital_input: habilita entradas digitais no port de GPIO desejado
; R0 = endere�o base do port desejado
; R1 = padr�o de bits (1) a serem habilitados como entradas digitais
; Destr�i: R2
GPIO_digital_input:
	LDR R2, [R0, #GPIO_DIR]
	BIC R2, R1 ; configura bits de entrada
	STR R2, [R0, #GPIO_DIR]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1 ; habilita fun��o digital
	STR R2, [R0, #GPIO_DEN]

	LDR R2, [R0, #GPIO_PUR]
	ORR R2, R1 ; habilita resitor de pull-up
	STR R2, [R0, #GPIO_PUR]

        BX LR

; GPIO_read: l� as entradas do port de GPIO desejado
; R0 = endere�o base do port desejado
; R1 = m�scara de bits a serem acessados
; R2 = bits lidos
GPIO_read:
        LDR R2, [R0, R1, LSL #2] ; l� bits com m�scara de acesso
        BX LR

; SW_delay: atraso de tempo por software
; R0 = valor do atraso
; Destr�i: R0
SW_delay:
        CBZ R0, out_delay
        SUB R0, R0, #1
        B SW_delay        
out_delay:
        BX LR     

/*----------------------------------------------------------------------------*/

Enter:
        PUSH {LR}
        LDR R3, =lf ; ponteiro de origem
        LDR R1, [R3] ; leitura
        BL Print ;
        LDR R3, =cr ; ponteiro de origem
        LDR R1, [R3] ; leitura
        BL Print ;
        POP {LR}
        BX LR      

/*----------------------------------------------------------------------------*/

Print:
        STR R1, [R0] ; escreve no registrador de dados da UART0 (transmite)
        
        PUSH {R0}
        MOV R0, #0x2000 ; atraso de alguns milissegundos
        PUSH {LR}
        BL SW_delay
        POP {LR}
        POP {R0}
        
        BX LR

/*----------------------------------------------------------------------------*/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;; Constants in ROM
;;

        SECTION .rodata:CONST(2)
        DATA
lf          DC8  00001010b
cr          DC8  00001101b

        ;; Forward declaration of sections.
        SECTION CSTACK:DATA:NOROOT(3)
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Interrupt vector table.
;;

        SECTION .intvec:CODE:NOROOT(2)
        
        DATA

__vector_table
        DCD     sfe(CSTACK)
        DCD     __iar_program_start

        DCD     NMI_Handler
        DCD     HardFault_Handler
        DCD     MemManage_Handler
        DCD     BusFault_Handler
        DCD     UsageFault_Handler
        DCD     0
        DCD     0
        DCD     0
        DCD     0
        DCD     SVC_Handler
        DCD     DebugMon_Handler
        DCD     0
        DCD     PendSV_Handler
        DCD     SysTick_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Default interrupt handlers.
;;

        PUBWEAK NMI_Handler
        PUBWEAK HardFault_Handler
        PUBWEAK MemManage_Handler
        PUBWEAK BusFault_Handler
        PUBWEAK UsageFault_Handler
        PUBWEAK SVC_Handler
        PUBWEAK DebugMon_Handler
        PUBWEAK PendSV_Handler
        PUBWEAK SysTick_Handler

        SECTION .text:CODE:REORDER:NOROOT(1)
        THUMB

NMI_Handler
HardFault_Handler
MemManage_Handler
BusFault_Handler
UsageFault_Handler
SVC_Handler
DebugMon_Handler
PendSV_Handler
SysTick_Handler
Default_Handler
__default_handler
        CALL_GRAPH_ROOT __default_handler, "interrupt"
        NOCALL __default_handler
        B __default_handler

        END
