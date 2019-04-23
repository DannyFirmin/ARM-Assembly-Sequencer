@ Based on Billie Eilish - bad guy
@ STEM32 ARM Version By Danny Feng (u6611178)
.syntax unified
.global main

.type main, %function
main:
  bl init
  mov r11, #48000 @ Constant
loop:
  mov r1, #98
  mov r2, #2 @ Duration divisor. r2 = 4 means 0.25s, r2 = 2 means 0.5s, r2 = 1 means 1s
  udiv r2, r1, r2 @ r2 is loop how many time
  bl play_envelope

  mov r1, 0
  mov r2, #12000 @ Rest 0.25s, Here 12000=0.25s, 48000=1s
  bl play_envelope

  b loop

@ This function is used for playing a note with Envelope
@ ADSR Envelope. Play Attack for 30% of the note time. Play Decay for 20% of the note time
@ Sustain time: 50%, Release time: extra 30% of the note time
@ Param r1 - Pitch(Hz), r2 - Duration (Loop how many time)
@ r1 = 0 means Rest
play_envelope:
  push {r1-r11,lr}
  @ Check if pitch is equals to 0, which means rest
  mov r5, 0
  mov r6, r2 @ Use r6 as counter in rest
  cmp r1, r5
  beq rest
  @ Start doing duration/pitch/2, temp register used: r5 r6
  udiv r6, r11, r1 
  mov r5, #2
  udiv r6, r6, r5
  @ Finished duration/pitch/2, result in r6, means how many dot
  mov r5, 0 @ Counter
  push {r5,r6,lr} @ r5 r6 need to be used in lowdot as well, store them
  bl highdot
  pop {r5,r6,lr}
  bl lowdot
  pop {r1-r11,lr}

  @ Check r2, which is how many time I need to loop
  subs r2, 1
  IT eq
  bxeq lr
  b play_envelope

rest:
  mov r0, 0
  push {lr}
  bl BSP_AUDIO_OUT_Play_Sample
  pop {lr}
  subs r6, 1
  IT eq
  bxeq lr @ Go back where play_envelope function is called
  b rest

highdot:
  @ Start ploting based on r6
  mov r0, 0x7FFF
  push {lr}
  bl BSP_AUDIO_OUT_Play_Sample
  pop {lr}
  add r5, 1 @ Counter ++
  cmp r6, r5
  bls dot_backhome
  b highdot

lowdot:
  @ Start ploting based on r6
  mov r0, 0x8000
  push {lr}
  bl BSP_AUDIO_OUT_Play_Sample
  pop {lr}
  add r5, 1
  cmp r6, r5
  bls dot_backhome
  b lowdot

dot_backhome:
  mov r5, 0 @ Clear counter
  bx lr

.size main, .-main