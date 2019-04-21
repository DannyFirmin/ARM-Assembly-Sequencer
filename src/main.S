@ Based on Billie Eilish - bad guy
@ STEM32 ARM Version By Danny Feng (u6611178)
.syntax unified
.global main

.type main, %function
main:
  bl init
  mov r8, #48000 @ Constant
loop:
@ @G4
@   mov r1, #392
@   mov r2, #4 @ Duration divisor. r2 = 4 means 0.25s, r2 = 2 means 0.5s, r2 = 1 means 1s
@   udiv r2, r1, r2 @ r2 is loop how many time
@   bl play_note
@   mov r1, 0
@   mov r2, #12000 @ Rest 0.25s, Here 12000=0.25s, 48000=1s
@   bl play_note

  mov r1, #440
  mov r2, #700
  mov r3, #48000
  mov r9, 1   @ Counter for harmony part
  mov r10, 0 @ Sound1 flag for harmony funtion, 0 means currently in upper part of the wave
  mov r11, 0 @ Sound2 flag for harmony funtion, 1 means currently in lower part of the wave
  b harmony_manager

  b loop
@ Two notes playing function
@ Param r1 - Pitch of Sound 1; r2 - Pitch of Sound2; r3 - duration, 48000 for one second
harmony_manager:
  stmdb sp!,{r1-r11,lr}
  @ r4: How many dot per half cycle for sound 1
  udiv r4, r8, r1 
  mov r5, #2
  udiv r4, r4, r5
  @ r6: How many dot per half cycle for sound 2
  udiv r6, r8, r2
  mov r5, #2
  udiv r6, r6, r5

  mov r1, r9
  mov r2, r4
  bl divisible_checker
  subs r0, 0 
  @ if it is 0, means not r1(current dot counter) is not divisible by r2 (how many dot per half cycle)
  @ so that the flag don't need to change
  bne sound1_flip_flag

  mov r1, r9
  mov r2, r6
  bl divisible_checker
  subs r0, 0 
  bne sound2_flip_flag

  @ Check two flags and decide how to play
  eor r5, r9, r10
  mov r0, 1
  cmp r5, r0
  beq dot_middle
  @ Case: r9 r10 are the same, check what exact number they have
  cmp r9, r0 @ if they are equal to 1, dot lower part
  beq dot_lower
  @ else, dot upper part
  b dot_upper

dot_middle:
  mov r0, 0
  b harmony_manager_windup
dot_upper:
  mov r0, 0x7FFF
  b harmony_manager_windup
dot_lower:
  mov r0, 0x8000
  b harmony_manager_windup

harmony_manager_windup:
  str lr, [sp, #-4]!
  bl BSP_AUDIO_OUT_Play_Sample
  ldr lr, [sp], #4
  @ if duration (r3) != current counter(r9), we need to loop back, and r9++;
  ldmia sp!, {r1-r11,lr} 
  cmp r3, r9
  beq backhome
  add r9, r9, 1
  b harmony_manager


@ Param: r1 - Dividend; r2 - Divisor
@ Return: r0, 0 for No; 1 for Yes
@ Function Tested OK. If r2 is 0, will return false
divisible_checker:
  stmdb sp!,{r1-r11,lr}
  @ if r1 ==0 && r2 != 0, return true
  mov r0, 0
  cmp r1, r0
  beq jump2_dc_dividend_iszero
  udiv r3, r1, r2 @ r3: how many times we need to loop
  @ if r3 == 0, return false
  mov r0, 0
  cmp r3, r0
  beq dc_false
  bl dc_loop_minus
  ldmia sp!, {r1-r11,lr} 
  bx lr

jump2_dc_dividend_iszero:
  str lr, [sp, #-4]!
  bl dc_dividend_iszero
  ldr lr, [sp], #4
  bx lr

dc_dividend_iszero:
  cmp r2, r0
  bne dc_true
  bx lr
dc_loop_minus:
  sub r1, r2
  subs r3, r3, #1
  beq dc_check_result
  b dc_loop_minus

dc_check_result:
  subs r1, 0
  beq dc_true
  b dc_false

dc_true:
  mov r0, 1
  bx lr

dc_false:
  mov r0, 0
  bx lr

sound1_flip_flag:
  // flip r10
  mov r5, 1
  eor r10, r10, r5

sound2_flip_flag:
  // flip r11
  mov r5, 1
  eor r11, r11, r5

@ Single note playing function
@ Param r1 - Pitch, r2 - Duration (Loop how many time)
@ r1 = 0 means Rest
play_note:
  stmdb sp!,{r1-r11,lr}  @ Will borrow these registers. Remain them untouch by push to stack
  @ Check if pitch is equals to 0, which means rest
  mov r5, 0
  mov r6, r2 @ Use r6 as counter in rest
  cmp r1, r5
  beq rest
  @ Start doing duration/pitch/2, temp register used: r5 r6
  udiv r6, r8, r1 
  mov r5, #2
  udiv r6, r6, r5
  @ Finished duration/pitch/2, result in r6, means how many dot
  mov r5, 0 @ Counter
  stmdb sp!,{r5,r6,lr} @ r5 r6 need to be used in lowdot as well, store them
  bl highdot
  ldmia sp!, {r5,r6,lr}
  bl lowdot
  ldmia sp!, {r1-r11,lr} @ I know I can use push and pull to make it simpler, but Uwe won't like that

  @ Check r2, which is how many time I need to loop
  subs r2, 1
  beq backhome
  b play_note

rest:
  mov r0, 0
  str lr, [sp, #-4]!
  bl BSP_AUDIO_OUT_Play_Sample
  ldr lr, [sp], #4
  subs r6, 1
  beq backhome @ Go back where play_note function is called
  b rest

backhome:
  bx lr

highdot:
  @ Start ploting based on r6
  mov r0, 0x7FFF
  str lr, [sp, #-4]!
  bl BSP_AUDIO_OUT_Play_Sample
  ldr lr, [sp], #4
  add r5, 1 @ Counter ++
  cmp r6, r5
  bls dot_backhome
  b highdot

lowdot:
  @ Start ploting based on r6
  mov r0, 0x8000
  str lr, [sp, #-4]!
  bl BSP_AUDIO_OUT_Play_Sample
  ldr lr, [sp], #4
  add r5, 1
  cmp r6, r5
  bls dot_backhome
  b lowdot

dot_backhome:
  mov r5, 0 @ Clear counter
  bx lr


.size main, .-main