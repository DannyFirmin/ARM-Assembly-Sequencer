@ Based on Billie Eilish - bad guy
@ STEM32 ARM Version By Danny Feng (u6611178)
.syntax unified
.global main

.type main, %function
main:
  bl init

myinit:
  ldr r0, =pitch_array @ Base address of the array
  ldr r4, =duration_array
  ldr r5, [r0] @ Load array size
  mov r6, #1 @ Array loop counter

loop:
  mov r1, #0
  lsl r1, r6, #2 @ r1 = r6 * 4, index to offset, a faster way
  ldr r2, [r4, r1]
  ldr r1, [r0, r1]
  add r6, #1
  @ Check if pitch is equals to 0, which means rest
  mov r3, 0 @ Temp value for calculation
  cmp r1, r3
  beq rest
  udiv r2, r1, r2 @ r2 is loop how many time
  bl play_envelope
  cmp r6, r5
  IT hi
  bhi myinit
  b loop

@ This function is used for playing a note with Envelope
@ ADSR Envelope. Play Attack for 30% of the note time. Play Decay for 20% of the note time
@ Sustain time: 50%, Release time: extra 30% of the note time
@ Param r1 - Pitch(Hz), r2 - Duration (Loop how many time)
@ r1 = 0 means Rest
play_envelope:
  push {r0-r11,lr}
  @ Start doing duration/pitch/2, temp register used: r5 r6
  mov r11, #48000
  udiv r6, r11, r1 
  lsr r6, r6, #1
  @ Finished duration/pitch/2, result in r6, means how many dot
  push {r6,lr} @ r5 r6 need to be used in lowdot as well, store them
  mov r5, 0 @ Counter
  bl highdot
  pop {r6,lr}
  mov r5, 0 @ Counter
  bl lowdot
  pop {r0-r11,lr}

  @ Check r2, which is how many time I need to loop
  subs r2, 1
  IT eq
  bxeq lr
  b play_envelope

rest:
  push {r0,r2,lr}
  mov r0, 0
  bl BSP_AUDIO_OUT_Play_Sample
  pop {r0,r2,lr}
  subs r2, 1
  beq rest_end @ Go back where play_envelope function is called
  b rest
  
rest_end:
  cmp r6, r5
  bhi myinit
  b loop

highdot:
  @ Start ploting based on r6
  mov r0, 0x7FFF
  push {lr}
  bl BSP_AUDIO_OUT_Play_Sample
  pop {lr}
  add r5, 1 @ Counter ++
  cmp r6, r5
  IT ls
  bxls lr
  b highdot

lowdot:
  @ Start ploting based on r6
  mov r0, 0x8000
  push {lr}
  bl BSP_AUDIO_OUT_Play_Sample
  pop {lr}
  add r5, 1
  cmp r6, r5
  IT ls
  bxls lr
  b lowdot

.size main, .-main

.data
@ First element in array in the size
pitch_array:
  .word 24, 0, 294, 0, 349, 0, 392, 0, 294, 0, 349, 0, 415, 392, 0, 294, 0, 349, 0, 392, 0, 349, 0, 294, 0
duration_array:
 @ Duration divisor. r2 = 4 means 0.25s, r2 = 2 means 0.5s, r2 = 1 means 1s
  .word 24, 12000, 4, 12000, 4, 12000, 2, 12000, 4, 12000, 4, 12000, 4, 2, 24000, 4, 12000, 4, 12000, 2, 12000, 4, 12000, 1, 12000
  @ Rest 0.25s, Here 12000=0.25s, 48000=1s
