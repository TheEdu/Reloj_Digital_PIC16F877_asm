; Reloj digital en asm PIC16F877

include P16F877.INC ; Importo la libreria del PIC 16F877

;__CONFIG  _WDT_OFF  ; no anda!!!

CBLOCK 0x30
SU ; Segundo Unidad
SD ; Segudon Decena
MU ; Minuto Unidad
MD ; Minuto Decena
HU ; Hora Unidad
HD ; Hora Decena
CONTADOR_500_P1 ; Contador (parte1) para ejecutar la rutina de Aumentar_Un_Segundo
CONTADOR_500_P2 ; Contador (parte2) para ejecutar la rutina de Aumentar_Un_Segundo
DOS
TRES
CINCO
NUEVE
CONTROL_SEGUNDOS_BOTON
CONTROL_MINUTOS_BOTON
CONTROL_HORAS_BOTON
ENDC

ORG 0X00
	GOTO Begin

ORG 004H 
	GOTO Interrupt_handler ; Llamado a la rutina de interrupcion

Begin:
ORG 0X10 ; Comienzo del programa principal

	;prueba para controlar el modo configuracion
	MOVLW 0X00
	MOVWF CONTROL_SEGUNDOS_BOTON
	MOVWF CONTROL_MINUTOS_BOTON
	MOVWF CONTROL_HORAS_BOTON

	;Inicializar constantes
	MOVLW d'2'
	MOVWF DOS
	MOVLW d'3'
	MOVWF TRES
	MOVLW d'5'
	MOVWF CINCO
	MOVLW d'9'
	MOVWF NUEVE

	CLRF STATUS ; limpio el STATUS REGISTER (asi me aseguro de estar en la pagina 0)
	CLRF PORTC  ; PORTC Muestra el Display si su bit correspondiente esta en 0, ej: RD0 = 0 --> Display0 muestra un numero
	CLRF PORTD	; PORTD Numero que voy a mostrar en el Display
	CLRF PORTB  ; PORTB Puerto de entrada para manejar las interrupciones por Boton

	BSF  STATUS,RP0 ; Cambio a la pagina 1

		CLRF TRISC ; PORTC --> puerto de salida (OUTPUT)
		CLRF TRISD ; PORTD --> puerto de salida (OUTPUT)
		CLRF TRISB 
		COMF TRISB ; PORTB --> puerto de entrada (INPUT)

		BCF OPTION_REG, T0CS ; Selecciono la clock source como interna (TOCS = 0 --> Internal instruction cycle clock (CLKOUT) as source)
		BCF OPTION_REG, PSA ; Activo el Prescaler (PSA = 0 --> Prescaler is assigned to the Timer0 module)
		; Seteo del prescaler en 001
		BCF OPTION_REG, PS2 ; Cleaneo el bit 2 del prescaler
		BCF OPTION_REG, PS1	; Cleaneo el bit 1 del prescaler
		BSF OPTION_REG, PS0 ; Seteo el bit 0 del prescaler (por magia me da 2.1ms)

    BCF  STATUS,RP0 ; Vuelvo a la pagina 0
	

	;HORA POR DEFECTO 00:00:00
	MOVLW d'0'
	MOVWF SU
	MOVWF SD	
	MOVWF MU
	MOVWF MD
	MOVWF HU
	MOVWF HD

	;Inicializo PORD en 0 y apago todos los Displays
	CLRF PORTD
	CLRF PORTC
	COMF PORTC  ; Apago todos los displays


	; Inicializo el Timer 0 en 134
	MOVLW d'134'
	MOVWF TMR0


	; Inicializo Contador a 500
	CLRF CONTADOR_500_P1
	CLRF CONTADOR_500_P2
	MOVLW 0x05
	MOVWF CONTADOR_500_P1
	MOVWF CONTADOR_500_P2
	
	CLRF INTCON ; Inicializo en 0 todos los bits del Registro INTCON
	BSF  INTCON,T0IE ; Seteo el bit T0IE para poner en enable al Timer 0
	
	BSF INTCON, INTE ;  Seteo el bit RBIE para poner en enable las interrupcion externas
   
	BSF  INTCON,GIE  ; Seteo el bit GIE para permitir las interrupciones globales


	Infinite_loop:
		NOP
		CLRWDT
	GOTO Infinite_loop


	TABLA
		addwf	PCL, 1
		retlw	d'63'  ;0
		retlw	d'6'   ;1
		retlw	d'91'  ;2
		retlw	d'79'  ;3
		retlw	d'102' ;4
		retlw	d'109' ;5
		retlw	d'125' ;6
		retlw	d'7'   ;7
		retlw	d'127' ;8
		retlw	d'103' ;9


	Interrupt_handler: ; Rutina de interrupcion
		BCF INTCON,GIE ; Desactivo las interrupciones globales
		BTFSC INTCON,T0IF ; Si TOIF = 0 --> Salta la siguiente instruccion
		GOTO Timer0_Interrupt   ; Si TOIF = 1 --> Interrupcion de Timer 0
		BTFSC INTCON,INTF ; Si RB0 = 0 --> Salta la siguiente instruccion
		GOTO Button_Interrupt ; Si RB0 = 1 --> Interrupcion de Boton
		Retorno:
		BSF INTCON,GIE ; Activo las interrupciones globales
		RETFIE ; El programa principal retoma el control


	Timer0_Interrupt:
		NOP
		GOTO Rutina_Contador_500       ; Rutina que aumenta 1 segundo, si ya pasaron 500*20ms
		Retornar_Rutina_Contador_500:  ; Vuelvo de la rutina anterior	
		GOTO Refresh				   ; Rutina que mueve el Display
		Retornar_Refresh:			   ; Vuelvo de la rutina anterior
		; Reseteando Timer0
		BCF INTCON,T0IF  ; Reseteo el timer 0
		MOVLW d'134'       ; Reseteo el timer 0
		MOVWF TMR0       ; Reseteo el timer 0
		GOTO Retorno


	Button_Interrupt:
		NOP

		MODO_CONFIGURACION:
		
		; chequeo si el bit rb0 sigue en 1, si esta en 0 significa que sali del modo configuracion
		BTFSS PORTB,RB0
		GOTO FIN_MODO_CONFIGURACION
		CLRWDT
		
		GOTO Refresh
		Retornar_Refresh_Button:		
		
		;prueba control con semaforos
		GOTO RESET_CONTROL_BOTON
		RETURN_RESET_CONTROL:

		BTFSC PORTB,RB1
		GOTO Button_Plus_Second
		End_Button_Second_Logic:

		BTFSC PORTB,RB2
		GOTO Button_Plus_Minute
		End_Button_Minute_Logic:

		BTFSC PORTB,RB3
		GOTO Button_Plus_Hour
		End_Button_Hour_Logic
	
		GOTO MODO_CONFIGURACION
		FIN_MODO_CONFIGURACION:
		BCF INTCON,INTF ; reset INTF
		GOTO Retorno

	RESET_CONTROL_BOTON
		MOVLW 0X00
		BTFSS PORTB,RB1
		MOVWF CONTROL_SEGUNDOS_BOTON
		BTFSS PORTB,RB2
		MOVWF CONTROL_MINUTOS_BOTON
		BTFSS PORTB,RB3
		MOVWF CONTROL_HORAS_BOTON
		GOTO RETURN_RESET_CONTROL

	Button_Plus_Second:

		MOVFW CONTROL_SEGUNDOS_BOTON
		SKPZ
		GOTO End_Button_Second_Logic
		MOVLW 0XFF
		MOVWF CONTROL_SEGUNDOS_BOTON

		MOVFW SU
		SUBWF NUEVE,0
		SKPNZ
		GOTO Button_Plus_Second_2
		INCF SU
		GOTO End_Button_Second_Logic

	Button_Plus_Second_2:
		MOVLW 0X00
		MOVWF SU
		MOVFW SD
		SUBWF CINCO,0
		SKPNZ
		GOTO Reset_SD
		INCF SD
		GOTO End_Button_Second_Logic

	Reset_SD:
		MOVLW 0X00
		MOVWF SD
		GOTO End_Button_Second_Logic

	Button_Plus_Minute:
		MOVFW CONTROL_MINUTOS_BOTON
		SKPZ
		GOTO End_Button_Minute_Logic
		MOVLW 0XFF
		MOVWF CONTROL_MINUTOS_BOTON

		MOVFW MU
		SUBWF NUEVE,0
		SKPNZ
		GOTO Button_Plus_Minute_2
		INCF MU
		GOTO End_Button_Minute_Logic

	Button_Plus_Minute_2:
		MOVLW 0X00
		MOVWF MU
		MOVFW MD
		SUBWF CINCO,0
		SKPNZ
		GOTO Reset_MD
		INCF MD
		GOTO End_Button_Minute_Logic

	Reset_MD:
		MOVLW 0X00
		MOVWF MD
		GOTO End_Button_Minute_Logic

	Button_Plus_Hour:
		MOVFW CONTROL_HORAS_BOTON
		SKPZ
		GOTO End_Button_Hour_Logic
		MOVLW 0XFF
		MOVWF CONTROL_HORAS_BOTON

		MOVFW HD
		SUBWF DOS,0
		SKPNZ
		GOTO Button_Plus_Hour_2HD
		MOVFW HU
		SUBWF NUEVE,0
		SKPNZ
		GOTO Button_Plus_Hour_9HU
		INCF HU	
		GOTO End_Button_Hour_Logic
	
	Button_Plus_Hour_9HU:
		MOVLW 0X00
		MOVWF HU
		INCF HD
		GOTO End_Button_Hour_Logic

	Button_Plus_Hour_2HD:
		MOVFW HU
		SUBWF TRES,0
		SKPNZ
		GOTO Button_Plus_Hour_2HD_3HU
		INCF HU
		GOTO End_Button_Hour_Logic

	Button_Plus_Hour_2HD_3HU:
		MOVLW 0X00
		MOVWF HU
		MOVWF HD
		GOTO End_Button_Hour_Logic

	Rutina_Contador_500:
		COMF CONTADOR_500_P1,0
		SKPNZ ; Salta la siguiente linea si CONTADOR_500_P1 != 255
		GOTO Rutina_Contador_500_P2
		INCF CONTADOR_500_P1
		GOTO Retornar_Rutina_Contador_500

	Rutina_Contador_500_P2:
		COMF CONTADOR_500_P2,0
		SKPNZ ; Salta la siguiente linea si CONTADOR_500_P2 != 255
		GOTO Time_Increase
		INCF CONTADOR_500_P2
		GOTO Retornar_Rutina_Contador_500

	Time_Increase
		NOP
		;Resetear contadores
		MOVLW 0x05
		MOVWF CONTADOR_500_P1
		MOVWF CONTADOR_500_P2
		;Aqui iria la logica del reloj
		MOVFW SU
		SUBWF NUEVE,0
		SKPNZ
		GOTO CONTINUAR_SD
		INCF SU
		End_Time_Logic:	
		NOP
		GOTO Retornar_Rutina_Contador_500

	CONTINUAR_SD:
		MOVLW 0X00
		MOVWF SU
		MOVFW SD
		SUBWF CINCO,0
		SKPNZ
		GOTO CONTINUAR_MU
		INCF SD
		GOTO End_Time_Logic

	CONTINUAR_MU:
		MOVLW 0X00
		MOVWF SD
		MOVFW MU
		SUBWF NUEVE,0
		SKPNZ
		GOTO CONTINUAR_MD
		INCF MU
		GOTO End_Time_Logic

	CONTINUAR_MD
		MOVLW 0X00
		MOVWF MU
		MOVFW MD
		SUBWF CINCO,0
		SKPNZ
		GOTO CONTINUAR_HU
		INCF MD
		GOTO End_Time_Logic

	CONTINUAR_HU:
		MOVLW 0X00
		MOVWF MD
		MOVFW HD
		SUBWF DOS,0
		SKPNZ
		GOTO CONTINUAR_2HD
		MOVFW HU
		SUBWF NUEVE,0
		SKPNZ
		GOTO CONTINUAR_9HU
		INCF HU
		GOTO End_Time_Logic

	CONTINUAR_9HU:
		MOVLW 0X00
		MOVWF HU
		INCF HD
		GOTO End_Time_Logic

	CONTINUAR_2HD:
		MOVFW HU
		SUBWF TRES,0
		SKPNZ
		GOTO CONTINUAR_2HD_3HU
		INCF HU
		GOTO End_Time_Logic

	CONTINUAR_2HD_3HU:
		MOVLW 0X00
		MOVWF HU
		MOVWF HD
		GOTO End_Time_Logic

	Refresh	
		BTFSS PORTC,RC0
		GOTO Cambiar_Display0
		BTFSS PORTC,RC1
		GOTO Cambiar_Display1
		BTFSS PORTC,RC2
		GOTO Cambiar_Display2
		BTFSS PORTC,RC3
		GOTO Cambiar_Display3
		BTFSS PORTC,RC4
		GOTO Cambiar_Display4
		GOTO Cambiar_Display5
   

	Cambiar_Display0:
		;Display de Segundo Decena
		BSF PORTC,RC0
		MOVFW SD ; Muevo el contenido de SD a W
		call TABLA
		MOVWF PORTD
		BCF PORTC,RC1
		;Negrada para agregar el refresh al modo configuracion
		BTFSC PORTB,RB0
		GOTO Retornar_Refresh_Button
		GOTO Retornar_Refresh

	Cambiar_Display1:
		;Display de Minuto Unidad
		BSF PORTC,RC1
		MOVFW MU ; Muevo el contenido de MU a W
		call TABLA
		MOVWF PORTD
		BSF PORTD,RD7 ; pone el punto
		BCF PORTC,RC2
		;Negrada para agregar el refresh al modo configuracion
		BTFSC PORTB,RB0
		GOTO Retornar_Refresh_Button
		GOTO Retornar_Refresh  

	Cambiar_Display2:
		;Display de Minuto Decena
		BSF PORTC,RC2
		MOVFW MD ; Muevo el contenido de MD a W
		call TABLA
		MOVWF PORTD
		BCF PORTC,RC3
		;Negrada para agregar el refresh al modo configuracion
		BTFSC PORTB,RB0
		GOTO Retornar_Refresh_Button
		GOTO Retornar_Refresh

	Cambiar_Display3:
		;Display de Hora Unidad
		BSF PORTC,RC3
		MOVFW HU ; Muevo el contenido de HU a W
		call TABLA
		MOVWF PORTD
		BSF PORTD,RD7 ; pone el punto
		BCF PORTC,RC4
		;Negrada para agregar el refresh al modo configuracion
		BTFSC PORTB,RB0
		GOTO Retornar_Refresh_Button
		GOTO Retornar_Refresh

	Cambiar_Display4:
		;Display de Hora Decena
		BSF PORTC,RC4
		MOVFW HD ; Muevo el contenido de HD a W
		call TABLA
		MOVWF PORTD
		BCF PORTC,RC5
		;Negrada para agregar el refresh al modo configuracion
		BTFSC PORTB,RB0
		GOTO Retornar_Refresh_Button
		GOTO Retornar_Refresh

	Cambiar_Display5:
		;Display de Segundo Unidad
		BSF PORTC,RC5
		MOVFW SU ; Muevo el contenido de SU a W
		call TABLA
		MOVWF PORTD
		BCF PORTC,RC0
		;Negrada para agregar el refresh al modo configuracion
		BTFSC PORTB,RB0
		GOTO Retornar_Refresh_Button
		GOTO Retornar_Refresh
 
END ; Fin del programa
