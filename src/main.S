@ Happy Birthday Sone By Danny Feng (u6611178)
.syntax unified
.global main

.type main, %function
main:
  bl init
  mov r8, #48000 @ Constant
loop:
@G4
  mov r1, #392
  mov r2, #4 @ Duration divisor. r2 = 4 means 0.25s, r2 = 2 means 0.5s, r2 = 1 means 1s
  udiv r2, r1, r2 @ r2 is loop how many time
  bl play_note
  mov r1, 0
  mov r2, #12000 @ Rest 0.25s, Here 12000=0.25s, 48000=1s
  bl play_note
@G4
  mov r1, #392
  mov r2, #4
  udiv r2, r1, r2
  bl play_note
  mov r1, 0
  mov r2, #12000
  bl play_note
@A4
  mov r1, #440
  mov r2, #2
  udiv r2, r1, r2
  bl play_note
  mov r1, 0
  mov r2, #12000
  bl play_note
@G4
  mov r1, #392
  mov r2, #2
  udiv r2, r1, r2
  bl play_note
  mov r1, 0
  mov r2, #12000
  bl play_note
@C5
  mov r1, #523
  mov r2, #2
  udiv r2, r1, r2
  bl play_note
  mov r1, 0
  mov r2, #12000
  bl play_note
@B4
  mov r1, #494
  mov r2, #1
  udiv r2, r1, r2
  bl play_note
  mov r1, 0
  mov r2, #24000
  bl play_note
@G4
  mov r1, #392
  mov r2, #4
  udiv r2, r1, r2
  bl play_note
  mov r1, 0
  mov r2, #12000
  bl play_note
@G4
  mov r1, #392
  mov r2, #4
  udiv r2, r1, r2
  bl play_note
  mov r1, 0
  mov r2, #12000
  bl play_note
@A4
  mov r1, #440
  mov r2, #2
  udiv r2, r1, r2
  bl play_note
  mov r1, 0
  mov r2, #12000
  bl play_note
@G4
  mov r1, #392
  mov r2, #2
  udiv r2, r1, r2
  bl play_note
  mov r1, 0
  mov r2, #12000
  bl play_note
@D5
  mov r1, #587
  mov r2, #2
  udiv r2, r1, r2
  bl play_note
  mov r1, 0
  mov r2, #12000
  bl play_note
@C5
  mov r1, #523
  mov r2, #1
  udiv r2, r1, r2
  bl play_note
  mov r1, 0
  mov r2, #24000
  bl play_note
@G4
  mov r1, #392
  mov r2, #4
  udiv r2, r1, r2
  bl play_note
  mov r1, 0
  mov r2, #12000
  bl play_note
@G4
  mov r1, #392
  mov r2, #4
  udiv r2, r1, r2
  bl play_note
  mov r1, 0
  mov r2, #12000
  bl play_note
@G5
  mov r1, #784
  mov r2, #2
  udiv r2, r1, r2
  bl play_note
  mov r1, 0
  mov r2, #12000
  bl play_note
@E5
  mov r1, #659
  mov r2, #2
  udiv r2, r1, r2
  bl play_note
  mov r1, 0
  mov r2, #12000
  bl play_note
@C5
  mov r1, #523
  mov r2, #2
  udiv r2, r1, r2
  bl play_note
  mov r1, 0
  mov r2, #12000
  bl play_note
@B4
  mov r1, #494
  mov r2, #4
  udiv r2, r1, r2
  bl play_note
  mov r1, 0
  mov r2, #12000
  bl play_note
@A4
  mov r1, #440
  mov r2, #1
  udiv r2, r1, r2
  bl play_note
  mov r1, 0
  mov r2, #24000
  bl play_note

@F5
  mov r1, #698
  mov r2, #4
  udiv r2, r1, r2
  bl play_note
  mov r1, 0
  mov r2, #12000
  bl play_note
@F5
  mov r1, #698
  mov r2, #4
  udiv r2, r1, r2
  bl play_note
  mov r1, 0
  mov r2, #12000
  bl play_note
@E5
  mov r1, #659
  mov r2, #2
  udiv r2, r1, r2
  bl play_note
  mov r1, 0
  mov r2, #12000
  bl play_note
@C5
  mov r1, #523
  mov r2, #2
  udiv r2, r1, r2
  bl play_note
  mov r1, 0
  mov r2, #12000
  bl play_note
@D5
  mov r1, #587
  mov r2, #2
  udiv r2, r1, r2
  bl play_note
  mov r1, 0
  mov r2, #12000
  bl play_note
@C5
  mov r1, #523
  mov r2, #1
  udiv r2, r1, r2
  bl play_note
  mov r1, 0
  mov r2, #48000
  bl play_note


  b loop

@ Note playing function
@ Param r1 - Pitch, r2 - Duration (Loop how many time)
@ r1 = 0 means Rest
play_note:
  stmdb sp!,{r1-r8,lr}  @ Will borrow these registers. Remain them untouch by push to stack
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
  ldmia sp!, {r1-r8,lr} @ I know I can use push and pull to make it simpler, but Uwe won't like that

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