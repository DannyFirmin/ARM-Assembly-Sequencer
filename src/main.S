@ Happy Birthday Song (ADSR Envelope Version)- By Danny Feng (u6611178)
.syntax unified
.global main

.type main, %function

main:
  bl init

myinit:
  ldr r0, =pitch_array @ Base address of the array
  ldr r4, =duration_array
  ldr r5, [r0] @ Load array size
  mov r6, #1 @ Array pointer

loop:
  mov r1, #0
  lsl r1, r6, #2 @ r1 = r6 * 4, index to offset, a faster way
  ldr r2, [r4, r1]
  ldr r1, [r0, r1]
  add r6, #1
  @ Check if frequency is equals to 0, which means rest
  mov r3, 0
  cmp r1, r3
  beq rest
  udiv r2, r1, r2 @ r2 is how many waves
  mov r11, #0 @ Wave Counter
  bl play_envelope
  cmp r6, r5
  IT hi
  bhi myinit @ play the music again
  b loop


@ This function is used for playing a note with Envelope
@ ADSR Envelope. Play Attack for 30% of the note time. Play Decay for 20% of the note time
@ Sustain time: 50%, Release time: extra 20% of the note time
@ Param r1 - Frequency(Hz), r2 - Duration (Loop how many time)
@ r1 = 0 means Rest
play_envelope:
  push {r0-r10,lr}

  @ Start doing sample rate/frequency/2
  mov r4, #48000
  udiv r6, r4, r1 
  lsr r6, r6, #1 @ Faster way doing divided by 2
  @ Finished sample rate/frequency/2, result in r6, means how many dot

  @ if r11 >= r2, go to Release;
  cmp r2, r11
  bls release
  @ if r11 <= 30% * r2, go to Attack;
  mov r7, #3
  mul r7, r2, r7
  mov r4, #10
  udiv r7, r7, r4 @ r7 is the index of the element in the 30% position
  cmp r11, r7
  bls attack
  @ Check if it just finished the attack part, if yeet, we have something important to store
  mov r4, r11
  sub r4, #1
  cmp r4, r7
  IT eq
  bleq just_finish_a_stage

  @ if 30% * r2 < r11 <= 50% * r2, go to Decay;
  mov r7, #5
  mul r7, r2, r7
  mov r4, #10
  udiv r7, r7, r4 @ r7 is the index of the element in the 50% position. I will use this in the later code
  cmp r11, r7
  bls decay
  @ Check if it just finished the decay part, if yeet, we have something important to store
  mov r4, r11
  sub r4, #1
  cmp r4, r7
  IT eq
  bleq just_finish_a_stage

  @ if 50% * r2 < r11 < 100% * r2 go to Sustain. 
  mov r7, r2 @ Need to use r7 in the later calculation

  @ Check if it just finished the sustain part, if yeet, we have something important to store
  mov r4, r11
  add r4, #1
  cmp r4, r2
  IT eq
  bleq just_finish_a_stage
  cmp r2, r11
  bhi sustain

just_finish_a_stage:
  ldr r4, =my_memory
  str r7, [r4] @ Store the value of r7, will use in the next stage for calculate the difference between this index in different stage
  str r11, [r4, #4] @ Store the changing point
  bx lr

attack:
  mov r5, 0 @ init dot counter
  mov r0, 0x000A @ init amplitude to be +10
  mov r4, #32740 @ Amplitude total growth. From 0x000A to 0x7FEE; 0xFFF5 - 0x8011 = 32740
  udiv r4, r4, r7 @ Amplitude growth per each wave
  mul r4, r11 @ Amplitude growth per each wave * Current wave count
  add r0, r4 @ dot upper part of the wave, wave become stronger and stronger
  push {r6} @ r6 needs to be used for drawing lower dot as well, store it
  bl dot
  pop {r6}
  
  mov r5, 0 @ init dot counter
  mov r0, 0xFFF5 @ init amplitude to be -10
  @ mov r4, #32740 @ Amplitude total growth. From 0xFFF5 to 0x8011; 0xFFF5 - 0x8011 = 32740
  @ udiv r4, r4, r7 @ Amplitude growth per each wave
  @ mul r4, r11 @ Amplitude growth per each wave * Current wave count
  sub r0, r4 @ dot lower part of the wave, wave become stronger and stronger
  bl dot
  pop {r0-r10,lr}
  add r11, #1 @ increase counter
  b play_envelope

decay: @ Decay 30% from the max, so the Amplitude will gradually change to 0x598D and 0xA672
  mov r5, 0 @ init dot counter
  mov r0, 0x7FEE @ init amplitude to be at the max amplitude
  mov r4, #9825 @ Amplitude total negative growth. 0x7FEE - (0x7FEE * 70%) = 9825
  ldr r3, =my_memory
  ldr r10, [r3]
  sub r7, r10 @ Calculate the differece of r7 between this stage and previous stage, the result indicates when I should finish my negative growth
  udiv r4, r4, r7 @ Amplitude negative growth per each wave
  ldr r9, [r3, #4]
  sub r9, r11, r9 @ r9 is the wave index in current stage
  mul r4, r9 @ Amplitude negative growth per each wave * Current wave count
  sub r0, r4 @ dot upper part of the wave, wave become weaker and weaker
  push {r6} @ r6 needs to be used for drawing lower dot as well, store it
  bl dot
  pop {r6}
  
  mov r5, 0 @ init dot counter
  mov r0, 0x8011 @ init amplitude to be at the min amplitude
  @ mov r4, #9825 @ Amplitude total negative growth. Explained already
  @ udiv r4, r4, r7 @ Amplitude negative growth per each wave
  @ mul r4, r9 @ Amplitude negative growth per each wave * Current wave count
  add r0, r4 @ dot lower part of the wave, wave become weaker and weaker
  bl dot
  pop {r0-r10,lr}
  add r11, #1 @ increase counter
  b play_envelope

sustain: @ The Amplitude will stay at 0x598D and 0xA672
  mov r5, 0 @ init dot counter
  mov r0, 0x598D @ init amplitude to be at the max amplitude
  push {r6} @ r6 needs to be used for drawing lower dot as well, store it
  bl dot
  pop {r6}
  
  mov r5, 0 @ init dot counter
  mov r0, 0xA672 @ init amplitude to be at the min amplitude
  bl dot
  pop {r0-r10,lr}
  add r11, #1 @ increase counter
  b play_envelope

release: @ the Amplitude will gradually change from 0x598D or 0xA672 to +10 or -10, the gap is 22915
  mov r7, #2
  mul r7, r2, r7
  mov r4, #10
  udiv r7, r7, r4 @ release in 20% of the note time
  @ Store the end point
  ldr r3, =my_memory
  ldr r4, [r3, #4] @ Load changing point
  add r4, r7
  str r4, [r3, #8]

  mov r5, 0
  mov r0, 0x598D
  mov r4, #22915
  udiv r4, r4, r7 @ Amplitude negative growth per each wave
  ldr r9, [r3, #4]
  sub r9, r11, r9 @ r9 is the wave index in current stage
  mul r4, r9 @ Amplitude negative growth per each wave * Current wave count
  sub r0, r4 @ dot upper part of the wave, wave become weaker and weaker
  push {r6} @ r6 needs to be used for drawing lower dot as well, store it
  bl dot
  pop {r6}
  
  mov r5, 0 @ init dot counter
  mov r0, 0xA672 @ init amplitude to be -10
  @ mov r4, #22915 @ Amplitude total growth. From 0xFFF5 to 0x8011; 0xFFF5 - 0x8011 = 32740
  @ udiv r4, r4, r7 @ Amplitude growth per each wave
  @ sub r9, r11, r2
  @ mul r4, r9 @ Amplitude growth per each wave * Current wave count
  add r0, r4 @ dot lower part of the wave, wave become weaker and weaker
  bl dot
  @ check if the counter reach the end
  ldr r3, =my_memory
  ldr r4, [r3, #8]
  cmp r11, r4
  beq play_end
  pop {r0-r10,lr}
  add r11, #1 @ increase counter
  b play_envelope

play_end:
  pop {r0-r10,lr}
  bx lr
dot:
  @ Start ploting based on r6
  push {lr}
  bl BSP_AUDIO_OUT_Play_Sample
  pop {lr}
  add r5, 1 @ Dot counter ++
  cmp r6, r5
  IT ls
  bxls lr
  b dot

rest:
  push {r0,r2,lr}
  mov r0, 0
  bl BSP_AUDIO_OUT_Play_Sample
  pop {r0,r2,lr}
  subs r2, 1
  beq rest_end
  b rest
  
rest_end:
  cmp r6, r5
  bhi myinit
  b loop


.size main, .-main

.data
pitch_array:
@ First element in array in the size
@ Pitch_array is made of frequency(Hz)
  .word 51,0,392,0,392,0,440,0,392,0,523,0,494,0,392,0,392,0,440,0,392,0,587,0,523,0,392,0,392,0,784,0,659,0,523,0,494,0,440,0,698,0,698,0,659,0,523,0,587,0,523,0 
duration_array:
@ First element in array in the size
@ For a normal note, it's a duration divisor, 4 means play for 0.25s, 2 means 0.5s, 1 means 1s
@ For a rest note, it's a duration counter, 12000 means rest for 0.25s, 24000 means rest for 0.5s, 48000 means rest for 1s
  .word 51,12000,4,12000,4,12000,2,12000,2,12000,2,12000,1,24000,4,12000,4,12000,2,12000,2,12000,2,12000,1,24000,4,12000,4,12000,2,12000,2,12000,2,12000,4,12000,1,24000,4,12000,4,12000,2,12000,2,12000,2,12000,1,24000

my_memory:
