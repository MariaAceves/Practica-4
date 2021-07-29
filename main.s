/*Defining a global variable in data segment of word type*/
	.data			/*Data Segment*/
		bPinState:	/*Variable Name*/
	.word 8			/*Variable Size and Initial Value*/

	.data			/*Data Segment*/
		bSubState:	/*Variable Name*/
	.word 0			/*Variable Size and Initial Value*/

	.data			/*Data Segment*/
		bCurrSeq:	/*Variable Name*/
	.word 0			/*Variable Size and Initial Value*/

	.data			/*Data Segment*/
		bPrevSeq:	/*Variable Name*/
	.word 0			/*Variable Size and Initial Value*/

	.data			/*Data Segment*/
		bCount:	/*Variable Name*/
	.word 0			/*Variable Size and Initial Value*/

	.data			/*Data Segment*/
		bDbouncer:	/*Variable Name*/
	.word 0			/*Variable Size and Initial Value*/

	.text
	.section	.rodata
	.align	2
.LC0:

/*Defining a global variable in data segment of word type*/
.text						/*Memory segment where the function will be placed*/
.align	2					/*Memory aligment set to 16 Bit*/
.global	main				/*Function name*/
.type main function			/*Specifying main as function*/

.set SIM_SCGC5,			0x40048038
.set PORTC_PCR0,		0x4004B000
.set PORTC_PCR3,		0x4004B00C
.set PORTC_PCR4,		0x4004B010
.set PORTC_PCR5,		0x4004B014
.set PORTC_PCR6,		0x4004B018
.set GPIOC_PDDR,		0x400FF094
.set GPIOC_PDOR,		0x400FF080
.set PinsDirValue,		0x78		 //Pines 3, 4, 5, 6 Se configuran como salida. El pin 0 es etrada por lo que no hace falta establecer es bit 0.
.set Delay100msValue,	300000
.set GPIOC_PDIR,		0x400FF090


main:
	push {r3, lr}
	add	r3, sp, #4

	//PORTC Clock Gate Enable
	ldr r0,=SIM_SCGC5
	ldr r2,[r0]
	mov r1,#1
	lsl r1,#11
	add r1,r2
	str r1,[r0]

	//Port Control->Configurar PTCx como GPIO
	ldr r0,=PORTC_PCR0
	ldr r2,[r0]
	mov r1,#1
	lsl r1,#8
	add r1,r2
	str r1,[r0]

	ldr r0,=PORTC_PCR3
	ldr r2,[r0]
	mov r1,#1
	lsl r1,#8
	add r1,r2
	str r1,[r0]

	ldr r0,=PORTC_PCR4
	ldr r2,[r0]
	mov r1,#1
	lsl r1,#8
	add r1,r2
	str r1,[r0]

	ldr r0,=PORTC_PCR5
	ldr r2,[r0]
	mov r1,#1
	lsl r1,#8
	add r1,r2
	str r1,[r0]

	ldr r0,=PORTC_PCR6
	ldr r2,[r0]
	mov r1,#1
	lsl r1,#8
	add r1,r2
	str r1,[r0]

	//Activacion de los puertos como salida.
	ldr r0,=GPIOC_PDDR
	ldr r1,=PinsDirValue
	str r1,[r0]

	//Prueba para prender todos los leds
	//ldr r0,=GPIOC_PDOR
	//ldr r1,=PinsDirValue
	//str r1,[r0]

	WHILE_LOOP:
		bl vfnDelay100ms

		//Se lee el boton
		ldr r0, =GPIOC_PDIR
		ldr r1, [r0]
		mov r2, #1
		and r1, r2

		//Si es uno se le suma uno a bDBouncer sino se pone en cero la var.
		cmp r1, #1
		bne CleanDbouncer
		ldr r2, =bDbouncer
		ldr r3, [r2]
		add r3, r1
		str r3, [r2]
		bl ButtonPressed

		CleanDbouncer:
		ldr r2, =bDbouncer
		mov r3, #0
		str r3, [r2]

		//Si ya van 200ms del boton presionado se resetea la variable.
		ButtonPressed:
		cmp r3, #2
		bne KeepSeq
		mov r3, #0
		str r3, [r2]

		ldr r0, =bCount
		mov r1, #5
		str r1, [r0]
		//Se actualiza la maquina de estados.
		ldr r0, =bCurrSeq
		ldr r1, [r0]
		cmp r1, #2
		beq ResetSeq
		add r1, #1
		str r1, [r0]
		bl KeepSeq

		ResetSeq:
		mov r1, #0
		str r1, [r0]

		//Se verifica que ya pasaron 500ms.
		KeepSeq:
		ldr r0, =bCount
		ldr r1, [r0]

		cmp r1, #5
		bne Continue
		mov r1, #0
		str r1, [r0]

		ldr r0, =bCurrSeq
		ldr r1, [r0]
		ldr r2, =bPrevSeq
		ldr r3, [r2]

		cmp r1, r3
		beq SeqList
		//Si no son iguales se resetean las variables bPinState y bSubState
		ldr r0, =bPinState
		mov r1, #8
		str r1, [r0]
		ldr r0, =bSubState
		mov r1, #0
		str r1, [r0]

		SeqList:
		ldr r0, =bCurrSeq
		ldr r1, [r0]
		cmp r1, #0
		beq HotSeq
		cmp r1, #1
		beq JohnSeq
		bl BounceSeq

		HotSeq:
		bl vfnOneHotSeq
		bl FINN

		JohnSeq:
		bl vfnJohnsonSeq
		bl FINN

		BounceSeq:
		bl vfnBounceSeq
		bl FINN

		Continue:
			add r1, #1
			str r1, [r0]

		FINN:
		ldr r0, =bCurrSeq
		ldr r1, [r0]
		ldr r2, =bPrevSeq
		str r1, [r2]

	    b WHILE_LOOP

	mov	r3, #0
	mov	r0, r3
	pop {r3, pc}

		.align 2
		.type vfnDelay100ms function

		vfnDelay100ms:
			ldr r0,=Delay100msValue
		DELAY:			/*Compares versus 0 automatically using the Z (Zero) flag, it is the same if we coded */
			sub r0,#1	/* DELAY:	   */
			bne DELAY   /*	sub r0, #1 */
			BX LR		/*	cmp r0, #0 */
						/*	bne DELAY  */
						/*	BX LR	   */


		.align 2
		.type vfnOneHotSeq function

		vfnOneHotSeq:
		//Se le la variable que tiene los estados de los pines
		ldr r0, =bPinState
		ldr r1, [r0]

		//Se carga el registro para actualizar el estado de los pines
		ldr r2, =GPIOC_PDOR

		lsl r1, #3
		str r1, [r2]
		lsr r1, #3

		cmp r1, #1
		beq ResetOneHot
		b ShiftValue

		ResetOneHot:
			mov r1, #8
			b SaveValue

		ShiftValue:
			lsr r1, #1
			b SaveValue

		SaveValue:
			str r1, [r0]
			bx lr


		.align 2
		.type vfnBounceSeq function

		vfnBounceSeq:
		//Se lee la variable que tiene los estados de los pines
		ldr r0, =bPinState
		ldr r1, [r0]

		//Se lee la variable del sub-estado.
		ldr r2, =bSubState
		ldr r3, [r2]

		//Se carga el registro para actualizar el estado de los pines.
		ldr r4, =GPIOC_PDOR

		//Se escribe el valor de la variable 'bPinState' en los reg del micro.
		lsl r1, #3
		str r1, [r4]
		lsr r1, #3

		//Se compara si la secuencia esta recorriendose a la izq o der.
		cmp r3, #0
		beq Shift2Right
		//La secuencia se esta mobiendo a la izq.
		cmp r1, #8
		beq UpdateSubStateR
		lsl r1, #1
		b SaveValue

		Shift2Right:
			cmp r1, #1
			beq UpdateSubStateL
			lsr r1, #1
			b SaveValue

		UpdateSubStateL:
			mov r1, #2
			mov r3, #1
			str r3, [r2]
			b SaveValue

		UpdateSubStateR:
			mov r1, #4
			mov r3, #0
			str r3, [r2]
			b SaveValue

		SaveStateValue:
			str r1, [r0]
			bx lr

		.align 2
		.type vfnJohnsonSeq function

		vfnJohnsonSeq:
		//Se lee la variable que tiene los estados de los pines
		ldr r0, =bPinState
		ldr r1, [r0]

		//Se lee la variable del sub-estado.
		ldr r2, =bSubState
		ldr r3, [r2]

		//Se carga el registro para actualizar el estado de los pines.
		ldr r4, =GPIOC_PDOR

		//Se escribe el valor de la variable 'bPinState' en los reg del micro.
		lsl r1, #3
		str r1, [r4]
		lsr r1, #3
		//Se compara si la secuencia esta sumando
		cmp r1, #8
		bhs AddHalf
		b SubHalf

		AddHalf:
		cmp r1, #15
		beq SubHalf
		//Operación a realizar: bState += (1 << ( 2 - bSubState))
		mov r5, #2
		sub r5, r3
		mov r6, #1
		lsl r6, r5
		add r1, r6

		add r3, #1
		b LastSave

		SubHalf:
		cmp r1, #0
		beq OneCycle
		//Operación a realizar: bState -= (1 << ( bSubState))
		mov r6, #1
		lsl r6, r3
		sub r1, r6

		sub r3, #1
		b LastSave

		OneCycle:
		mov r1, #8
		mov r3, #0
		b LastSave

		LastSave:
		str r1, [r0]
		str r3, [r2]
		bx lr

	.align	2
.L3:
	.word	.LC0
	.end
