
###################################################################### 
# CSCB58 Summer 2022 Project 
# University of Toronto, Scarborough 
# 
# Student Name: Preyansh Dutta, Student Number: 1007074498, UTorID: DuttaPre 
# 
# Bitmap Display Configuration: 
# - Unit width in pixels: 8 (update this as needed) 
# - Unit height in pixels: 8 (update this as needed) 
# - Display width in pixels: 256 (update this as needed) 
# - Display height in pixels: 256 (update this as needed) 
# - Base Address for Display: 0x10008000 
# 
# Basic features that were implemented successfully 
# - Basic feature a/b/c
# - Number of lives displayed: On the top-right with red squares, each square representing a life
# - 4 Different cars, some cars moving faster than others
# - Game Over screen with restart prompt, upon restart option the game restarts 
# 
# Additional features that were implemented successfully 
# - Additional feature a/b/c
# - Extra lives added (purple pickup)
# - Live score is shown on the left and progresses as more obstacles are passed
# - More challenging level starts when the score bar has almost reached the max (cars are harder to dodge - more speed) 
#  
# Link to the video demo 
# - https://clipchamp.com/watch/BOkaaXDhQmg
# 
# Any additional information that the TA needs to know: 
# - Thank you for a great semester, really appreciate it :)
#  
###################################################################### 

.data
displayAddress:	.word   0x10008000
xVel:		.word	0		# x velocity start 0
yVel:		.word	0		# y velocity start 0
startPos: 	.word 	3016 		# Start position of the car that gets modified
red:    	.word 	0x00ff0000  	# Red hex color
blue: 		.word 	0x000000FF	# Blue hex color
green: 		.word 	0x0000FF00 	# Green
black: 		.word 	0x00000000 	# black
speed: 		.word	1		# w increases this speed 1 -> 2 -> 3; s decreases this speed 
currentLane: 	.word   2               # current lane
collided:     	.word   0               # if collision is true set this to 1, else set to 0
resetPos:       .word   3016		# test
startPosEnemy1:	.word	388		# enemy 1 position
startPosEnemy2:	.word	40		# enemy 2 position  
startPosEnemy3:	.word	-1464		# enemy 3 position 
startPosEnemy4:	.word	104		# enemy 3 position 
darkGray: 	.word 	0x00100c08	# dark dark gray
newLine:        .asciiz   "\n"		# new line character
white: 		.word 	0x00FFFFFF 	# black
yesOrNo:        .space 20
playAgain:  	.asciiz	"Restart? 0(No) or 1(Yes): \n"
lives:          .word 	3 		# lives
score: 		.word   0 # score increases by 10 when a lane of car passes by, lane 3 car is the pivot. reset upon crash
highScore: 	.word 	0 # increases if a new score is greater than this
displayHighScore:  .asciiz	"High Score: \n"
darkOrange:     .word 0x00CC5500 # dark orange for loading screen
orange1:	.word 0x00FF7F50 # orange for loading screen
orange2:	.word 0x00FF8C00 # orange for loading screen
orange3:	.word 0x00FFA500 # orange for loading screen
orange4:	.word 0x00FF6347 # orange for loading screen
orange5:	.word 0x00FF4500 # orange for loading screen
scoreAddress:	.word 0 # this will keep track of the next score pixel position
carSpeed: 	.word 1 # car speed to do relative slow/fast
purple: 	.word 0x006a0dad # for max health pickup
maxHealthLocation: .word  -1080 # lanes 0, 1, 2, 3

.text
main:

jal drawBackground
jal drawCar
jal drawLives

gameLoop:
	li $t9, 0xffff0000 
	lw $t8, 0($t9) 
	beq $t8, 1, key_pressed
	jal drawBackground
	jal drawLives
	jal drawEnemyCar1
	jal enemyCar1_move
	jal drawEnemyCar2
	jal enemyCar2_move
	jal drawEnemyCar3
	jal enemyCar3_move
	jal drawEnemyCar4
	jal enemyCar4_move
	jal drawLiveScore
	jal drawMaxLife
	jal pickupMove
	jal drawCar
	addi	$v0, $zero, 32	# syscall sleep
	addi	$a0, $zero, 110	# 66 ms
	syscall
	j gameLoop

key_pressed:
	lw $t2, 4($t9) # this assumes $t9 is set to 0xfff0000  
	beq $t2, 0x77, w_pressed # ASCII code of 'w' is 0x77  
	beq $t2, 0x61, a_pressed # ASCII code of 'a' is 0x61 or 97 in decimal
	beq $t2, 0x73, s_pressed # ASCII code of 's' is 0x73 or 97 in decimal
	beq $t2, 0x64, d_pressed # ASCII code of 'd' is 0x64 or 97 in decimal
	jr $ra

q_pressed:
	# end of game
	jr $ra

w_pressed:
	# move the car forward by -128 * speed pixels
	la $t0, startPos
	lw $t1, 0($t0)
	# if speed <= 2 and >= 1 then increase speed else don't do anything
	addi $t1, $t1, -512
	sw $t1, 0($t0)
	la $t2, carSpeed
	lw $t3, 0($t2)
	bne $t3, 3, incrementSpeed
	jr $ra

incrementSpeed:
	la $t2, carSpeed
	lw $t3, 0($t2)
	addi $t3, $t3, 1
	sw $t3, 0($t2)
	li $v0, 1
	move $a0, $t3
	syscall
	jr $ra	
			
a_pressed:
	# move the car left by -4 pixels
	la $t0, currentLane
	lw $t1, 0($t0)
	beq $t1, 0, setCollision
	bne $t1, $zero, decrementLane
	jr $ra

s_pressed:
	# move the car forward by -128 * speed pixels
	la $t0, startPos
	lw $t1, 0($t0)
	# if speed <= 2 and >= 1 then increase speed else don't do anything
	addi $t1, $t1, 256
	sw $t1, 0($t0)
	la $t2, carSpeed
	lw $t3, 0($t2)
	bne $t3, 1, decrementSpeed
	li $v0, 1
	move $a0, $t3
	syscall
	jr $ra

decrementSpeed:
	la $t2, carSpeed
	lw $t3, 0($t2)
	addi $t3, $t3, -1
	sw $t3, 0($t2)
	jr $ra
d_pressed:
	# move the car right by 8 pixels
	la $t0, currentLane
	lw $t1, 0($t0)
	beq $t1, 3, setCollision
	bne $t1, 3, incrementLane
	jr $ra

decrementLane:
	la $t0, currentLane
	lw $t1, 0($t0)
	addi $t1, $t1, -1
	sw $t1, 0($t0)
	la $t2, startPos
	lw $t3, 0($t2)
	addi $t3, $t3, -32
	sw $t3, 0($t2) # update the startPos
	jr $ra

incrementLane:
	la $t0, currentLane
	lw $t1, 0($t0)
	addi $t1, $t1, 1
	sw $t1, 0($t0)
	la $t2, startPos
	lw $t3, 0($t2)
	addi $t3, $t3, 32
	sw $t3, 0($t2) # update the startPos
	jr $ra

setCollision:
	jal resetScore
	jal resetEnemyCar1
	jal resetEnemyCar2
	jal resetEnemyCar3
	jal resetEnemyCar4
	la $t0, collided
	lw $t1, 0($t0)
	li $t1, 1
	sw $t1, 0($t0)
	la $t2, lives
	lw $t3, 0($t2)
	bne $t3, 0, decrementLife
	jr $ra

setHighScore:
	la $t0, score
	lw $t1, 0($t0)
	la $t2, highScore
	lw $t3, 0($t2)
	sw $t1, 0($t2)
	jr $ra

decrementLife:
	la $t0, lives
	lw $t1, 0($t0)
	addi $t1, $t1, -1
	sw $t1, 0($t0)
	jal resetPosition
	la $t0, score
	lw $t1, 0($t0)
	li $t1, 0
	sw $t1, 0($t0)
	jr $ra

restartGame:
	jal resetLives
	jal resetPosition
	jal resetScore
	jal resetCarSpeed
	jal drawBackground
	jal drawLives
	jal drawCar
	jal gameLoop
	jr $ra

resetCarSpeed:
	la $t2, carSpeed
	lw $t3, 0($t2)
	li $t3, 1
	sw $t3, 0($t2)
	jr $ra
			
resetPosition:
	la $t0, startPos
	lw $t1, 0($t0)
	li $t2, 3016
	sw $t2, 0($t0)
	la $t4, currentLane
	lw $t5, 0($t4)
	li $t6, 2
	sw $t6, 0($t4)
	la $t0, collided
	lw $t1, 0($t0)
	li $t2, 0
	sw $t2, 0($t0)
	jal gameLoop
	jr $ra
	
### RESET LIVES ###
resetLives:
	la $t0, lives
	lw $t1, 0($t0)
	li $t1, 3
	sw $t1, 0($t0)
	jr $ra

### END RESET lIVES ###
					
increaseSpeed:
	# increase the speed
	la $t9, speed
	lw $t8, 0($t9)
	addi $t8, $t8, 1
	sw $t8, 0($t9)
	
decreaseSpeed:
	# increase the speed
	la $t9, speed
	lw $t8, 0($t9)
	addi $t8, $t8, -1
	sw $t8, 0($t9)

drawBackground:
	### DRAW BACKGROUND SECTION ###
	lw $t0, displayAddress	# load frame buffer addres
	li $t1, 1024		# save 256*256 pixels
	li $t2, 0x00696969		# load light gray color
	li $t3, 0x0000ff # $t3 stores the blue colour code
	
	l1:
	sw   $t2, 0($t0)
	addi $t0, $t0, 4 	# advance to next pixel position in display
	addi $t1, $t1, -1	# decrement number of pixels
	bnez $t1, l1		# repeat while number of pixels is not zero
	
	### DRAW BORDER SECTION
	# left wall section
	lw	$t0, displayAddress	# load frame buffer address
	addi	$t1, $zero, 256		# t1 = 512 length of col
	li $t2, 0x00000000
	
	drawBorderLeft:
	sw	$t2, 0($t0)		# color Pixel black
	addi	$t0, $t0, 128		# go to next pixel
	addi	$t1, $t1, -1		# decrease pixel count
	bnez	$t1, drawBorderLeft	# repeat unitl pixel count == 0
	
	# right wall section
	lw	$t0, displayAddress	# load frame buffer address
	addi	$t0, $t0, 124
	addi	$t1, $zero, 256		# t1 = 512 length of col
	
	drawBorderRight:
	sw	$t2, 0($t0)		# color Pixel black
	addi	$t0, $t0, 128		# go to next pixel
	addi	$t1, $t1, -1		# decrease pixel count
	bnez	$t1, drawBorderRight	# repeat unitl pixel count == 0
	
		# middle dotted section
	lw	$t0, displayAddress	# load frame buffer address
	addi	$t0, $t0, 60
	addi	$t1, $zero, 256		# t1 = 512 length of col
	li $t2, 0x00FFFF00
	
	drawMiddleLine:
	sw	$t2, 0($t0)		# color Pixel white
	addi	$t0, $t0, 128		# go to next pixel
	addi	$t1, $t1, -1		# decrease pixel count
	bnez	$t1, drawMiddleLine	# repeat unitl pixel count == 0
	
		# middle dotted section
	lw	$t0, displayAddress	# load frame buffer address
	addi	$t0, $t0, 32
	addi	$t1, $zero, 256		# t1 = 512 length of col
	li $t2, 0x00FFFFFF
	
	drawMiddleLeftLine:
	sw	$t2, 0($t0)		# color Pixel white
	addi	$t0, $t0, 256		# go to next pixel
	addi	$t1, $t1, -1		# decrease pixel count
	bnez	$t1, drawMiddleLeftLine	# repeat unitl pixel count == 0
	
		# middle dotted section
	lw	$t0, displayAddress	# load frame buffer address
	addi	$t0, $t0, 92
	addi	$t1, $zero, 256		# t1 = 512 length of col
	li $t2, 0x00FFFFFF
	
	drawMiddleRightLine:
	sw	$t2, 0($t0)		# color Pixel white
	addi	$t0, $t0, 256		# go to next pixel
	addi	$t1, $t1, -1		# decrease pixel count
	bnez	$t1, drawMiddleRightLine	# repeat unitl pixel count == 0

	jr $ra
	
### END OF DRAWING BACKGROUND SECTION ###	

drawGameOver:
	### DRAW BACKGROUND SECTION ###
	lw $t0, displayAddress	# load frame buffer addres
	li $t1, 1024		# save 256*256 pixels
	lw $t2, black		# load black color
	lw $t3, white		# load white color
	
	drawBlack:
	sw   $t2, 0($t0)
	addi $t0, $t0, 4 	# advance to next pixel position in display
	addi $t1, $t1, -1	# decrement number of pixels
	bnez $t1, drawBlack	# repeat while number of pixels is not zero
	
	lw $t0, displayAddress	# load frame buffer addres
	
	drawLetters:
	# O
	addi $t0, $t0, 1560
	sw   $t3, 0($t0)
	addi $t0, $t0, 4
	sw   $t3, 0($t0)
	addi $t0, $t0, -4
	sw   $t3, 0($t0)
	addi $t0, $t0, 124
	sw   $t3, 0($t0)
	addi $t0, $t0, 128
	sw   $t3, 0($t0)
	addi $t0, $t0, 128
	sw   $t3, 0($t0)
	addi $t0, $t0, 128
	sw   $t3, 0($t0)
	addi $t0, $t0, 132
	sw   $t3, 0($t0)
	addi $t0, $t0, 4
	sw   $t3, 0($t0)
	addi $t0, $t0, -124
	sw   $t3, 0($t0)
	addi $t0, $t0, -128
	sw   $t3, 0($t0)
	addi $t0, $t0, -128
	sw   $t3, 0($t0)
	addi $t0, $t0, -128
	sw   $t3, 0($t0)
	
	# V
	addi $t0, $t0, -120
	sw   $t3, 0($t0)
	addi $t0, $t0, 132
	sw   $t3, 0($t0)
	addi $t0, $t0, 128
	sw   $t3, 0($t0)
	addi $t0, $t0, 128
	sw   $t3, 0($t0)
	addi $t0, $t0, 132
	sw   $t3, 0($t0)
	addi $t0, $t0, 128
	sw   $t3, 0($t0)
	addi $t0, $t0, 4
	sw   $t3, 0($t0)
	addi $t0, $t0, -128
	sw   $t3, 0($t0)
	addi $t0, $t0, -124
	sw   $t3, 0($t0)
	addi $t0, $t0, -128
	sw   $t3, 0($t0)
	addi $t0, $t0, -128
	sw   $t3, 0($t0)
	addi $t0, $t0, -124
	sw   $t3, 0($t0)
	
	# E
	addi $t0, $t0, 8
	sw   $t3, 0($t0)
	addi $t0, $t0, 4
	sw   $t3, 0($t0)
	addi $t0, $t0, 4
	sw   $t3, 0($t0)
	addi $t0, $t0, 4
	sw   $t3, 0($t0)
	addi $t0, $t0, 116
	sw   $t3, 0($t0)
	addi $t0, $t0, 128
	sw   $t3, 0($t0)
	addi $t0, $t0, 128
	sw   $t3, 0($t0)
	addi $t0, $t0, 128
	sw   $t3, 0($t0)
	addi $t0, $t0, 128
	sw   $t3, 0($t0)
	addi $t0, $t0, 4
	sw   $t3, 0($t0)
	addi $t0, $t0, 4
	sw   $t3, 0($t0)
	addi $t0, $t0, 4
	sw   $t3, 0($t0)
	addi $t0, $t0, -388
	sw   $t3, 0($t0)
	
	# R
	addi $t0, $t0, -244
	sw $t3, 0($t0)
	addi $t0, $t0, 128
	sw $t3, 0($t0)
	addi $t0, $t0, 128
	sw $t3, 0($t0)
	addi $t0, $t0, 128
	sw $t3, 0($t0)
	addi $t0, $t0, 128
	sw $t3, 0($t0)
	addi $t0, $t0, 128
	sw $t3, 0($t0)
	addi $t0, $t0, -636
	sw $t3, 0($t0)
	addi $t0, $t0, 4
	sw $t3, 0($t0)
	addi $t0, $t0, 132
	sw $t3, 0($t0)
	addi $t0, $t0, 128
	sw $t3, 0($t0)
	addi $t0, $t0, 124
	sw $t3, 0($t0)
	addi $t0, $t0, 132
	sw $t3, 0($t0)
	addi $t0, $t0, 128
	sw $t3, 0($t0)
	jr $ra


### DRAW HEARTS ###

drawLives:
	la $t0, lives
	lw $t1, 0($t0)
	beq $t1, 0, gameEnd
	beq $t1, 1, drawOneLife
	beq $t1, 2, drawTwoLives
	beq $t1, 3, drawThreeLives
	jr $ra

## END OF DRAWING HEARTS ###
	

drawOneLife:
	lw $t0, displayAddress	# load frame buffer address
	la $t1, red
	lw $t2, 0($t1) 
	sw $t2, 112($t0) # first heart
	sw $t2, 116($t0) 
	sw $t2, 240($t0) 
	sw $t2, 244($t0) 
	jr $ra
	
drawTwoLives:
	lw $t0, displayAddress	# load frame buffer address
	la $t1, red
	lw $t2, 0($t1) 
	sw $t2, 112($t0) # first heart
	sw $t2, 116($t0) 
	sw $t2, 240($t0) 
	sw $t2, 244($t0) 
	
	sw $t2, 496($t0) # second heart
	sw $t2, 500($t0) 
	sw $t2, 624($t0) 
	sw $t2, 628($t0) 
	jr $ra

drawThreeLives:
	lw $t0, displayAddress	# load frame buffer address
	la $t1, red
	lw $t2, 0($t1) 
	sw $t2, 112($t0) # first heart
	sw $t2, 116($t0) 
	sw $t2, 240($t0) 
	sw $t2, 244($t0) 
	
	sw $t2, 496($t0) # second heart
	sw $t2, 500($t0) 
	sw $t2, 624($t0) 
	sw $t2, 628($t0) 
	
	sw $t2, 880($t0) # third heart
	sw $t2, 884($t0) 
	sw $t2, 1008($t0) 
	sw $t2, 1012($t0) 
	jr $ra

### DRAWING THE CAR ###

drawEnemyCar1:
	lw $t0, displayAddress # $t0 stores the base address for display
	lw $t1, darkGray # $t1 stores the black colour code
	lw $t2, blue
	lw $t4, startPosEnemy1
	
	# main position for the car i.e. top-left tire
	add $t0, $t0, $t4
	sw $t1, 0($t0)
	
	# green for the body of the car
	addi $t0, $t0, 4
	sw $t2, 0($t0)
	
	addi $t0, $t0, 4
	sw $t2, 0($t0)
	
	# move 24 pixels to the right for the front-right tire
	addi $t0, $t0, 4
	sw $t1, 0($t0)
	
	# move a few pixels down for the back right tire
	addi $t0, $t0, 640
	sw $t1, 0($t0)
	
	
	# green for the body of the car
	addi $t0, $t0, -4
	sw $t2, 0($t0)
	
	addi $t0, $t0, -4
	sw $t2, 0($t0)
	
	# move a few pixels down for the back left tire
	addi $t0, $t0, -4
	sw $t1, 0($t0)
	
	# body
	addi $t0, $t0, -124
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, -128
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, -128
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, -128
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, 4
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, 128
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, 128
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, 128
	sw $t2, 0($t0)
	
	jr $ra

enemyCar1_move:
	la $t0, startPosEnemy1
	lw $t1, 0($t0)
	bge $t1, 7000, resetEnemyCar1
	la $t2, carSpeed
	lw $t3, 0($t2)
	li $t4, 128
	mult $t4, $t3
	mflo $t5
	add $t1, $t1, $t5
	sw $t1, 0($t0)
	jr $ra

resetEnemyCar1:
	la $t0, startPosEnemy1
	lw $t1, 0($t0)
	li $t1, -1908
	sw $t1, 0($t0)
	la $t0, score
	lw $t1, 0($t0)
	addi $t1, $t1, 10
	sw $t1, 0($t0)
	la $t2, highScore
	lw $t3, 0($t2)
	bge $t1, $t3, updateHighScore # current score >= high score
	jr $ra

updateHighScore:
	la $t0, score
	lw $t1, 0($t0)
	la $t2, highScore
	sw $t1, 0($t2)
	jr $ra
	
resetScore:
	la $t0, score
	lw $t1, 0($t0)
	li $t1, 0
	sw $t1, 0($t0)
	jr $ra 

drawEnemyCar2:
	lw $t0, displayAddress # $t0 stores the base address for display
	lw $t1, darkGray # $t1 stores the black colour code
	lw $t2, blue
	lw $t4, startPosEnemy2
	
	# main position for the car i.e. top-left tire
	add $t0, $t0, $t4
	sw $t1, 0($t0)
	
	# green for the body of the car
	addi $t0, $t0, 4
	sw $t2, 0($t0)
	
	addi $t0, $t0, 4
	sw $t2, 0($t0)
	
	# move 24 pixels to the right for the front-right tire
	addi $t0, $t0, 4
	sw $t1, 0($t0)
	
	# move a few pixels down for the back right tire
	addi $t0, $t0, 640
	sw $t1, 0($t0)
	
	
	# green for the body of the car
	addi $t0, $t0, -4
	sw $t2, 0($t0)
	
	addi $t0, $t0, -4
	sw $t2, 0($t0)
	
	# move a few pixels down for the back left tire
	addi $t0, $t0, -4
	sw $t1, 0($t0)
	
	# body
	addi $t0, $t0, -124
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, -128
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, -128
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, -128
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, 4
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, 128
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, 128
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, 128
	sw $t2, 0($t0)
	
	jr $ra

enemyCar2_move:
	la $t0, startPosEnemy2
	lw $t1, 0($t0)
	bge $t1, 10000, resetEnemyCar2
	la $t2, carSpeed
	lw $t3, 0($t2)
	li $t4, 128
	mult $t4, $t3
	mflo $t5
	add $t1, $t1, $t5
	sw $t1, 0($t0)
	jr $ra

resetEnemyCar2:
	la $t0, startPosEnemy2
	lw $t1, 0($t0)
	li $t1, -1240
	sw $t1, 0($t0)
	la $t0, score
	lw $t1, 0($t0)
	addi $t1, $t1, 10
	sw $t1, 0($t0)
	la $t2, highScore
	lw $t3, 0($t2)
	bge $t1, $t3, updateHighScore # current score >= high score
	jr $ra

drawEnemyCar3:
	lw $t0, displayAddress # $t0 stores the base address for display
	lw $t1, darkGray # $t1 stores the black colour code
	lw $t2, blue
	lw $t4, startPosEnemy3
	
	# main position for the car i.e. top-left tire
	add $t0, $t0, $t4
	sw $t1, 0($t0)
	
	# green for the body of the car
	addi $t0, $t0, 4
	sw $t2, 0($t0)
	
	addi $t0, $t0, 4
	sw $t2, 0($t0)
	
	# move 24 pixels to the right for the front-right tire
	addi $t0, $t0, 4
	sw $t1, 0($t0)
	
	# move a few pixels down for the back right tire
	addi $t0, $t0, 640
	sw $t1, 0($t0)
	
	# green for the body of the car
	addi $t0, $t0, -4
	sw $t2, 0($t0)
	
	addi $t0, $t0, -4
	sw $t2, 0($t0)
	
	# move a few pixels down for the back left tire
	addi $t0, $t0, -4
	sw $t1, 0($t0)
	
	# body
	addi $t0, $t0, -124
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, -128
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, -128
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, -128
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, 4
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, 128
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, 128
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, 128
	sw $t2, 0($t0)
	
	jr $ra

enemyCar3_move:
	la $t0, startPosEnemy3
	lw $t1, 0($t0)
	bge $t1, 6000, resetEnemyCar3
	la $t2, carSpeed
	lw $t3, 0($t2)
	li $t4, 128
	mult $t4, $t3
	mflo $t5
	add $t1, $t1, $t5
	sw $t1, 0($t0)
	jr $ra

resetEnemyCar3:
	la $t0, startPosEnemy3
	lw $t1, 0($t0)
	li $t1, 328
	sw $t1, 0($t0)
	la $t0, score
	lw $t1, 0($t0)
	addi $t1, $t1, 10
	sw $t1, 0($t0)
	la $t2, highScore
	lw $t3, 0($t2)
	bge $t1, $t3, updateHighScore # current score >= high score
	jr $ra

drawEnemyCar4:
	lw $t0, displayAddress # $t0 stores the base address for display
	lw $t1, darkGray # $t1 stores the black colour code
	lw $t2, blue
	lw $t4, startPosEnemy4
	
	# main position for the car i.e. top-left tire
	add $t0, $t0, $t4
	sw $t1, 0($t0)
	
	# green for the body of the car
	addi $t0, $t0, 4
	sw $t2, 0($t0)
	
	addi $t0, $t0, 4
	sw $t2, 0($t0)
	
	# move 24 pixels to the right for the front-right tire
	addi $t0, $t0, 4
	sw $t1, 0($t0)
	
	# move a few pixels down for the back right tire
	addi $t0, $t0, 640
	sw $t1, 0($t0)
	
	
	# green for the body of the car
	addi $t0, $t0, -4
	sw $t2, 0($t0)
	
	addi $t0, $t0, -4
	sw $t2, 0($t0)
	
	# move a few pixels down for the back left tire
	addi $t0, $t0, -4
	sw $t1, 0($t0)
	
	# body
	addi $t0, $t0, -124
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, -128
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, -128
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, -128
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, 4
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, 128
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, 128
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, 128
	sw $t2, 0($t0)
	
	jr $ra

enemyCar4_move:
	la $t0, startPosEnemy4
	lw $t1, 0($t0)
	bge $t1, 9000, resetEnemyCar4
	addi $t1, $t1, 256
	la $t2, carSpeed
	lw $t3, 0($t2)
	li $t4, 128
	mult $t4, $t3
	mflo $t5
	add $t1, $t1, $t5
	sw $t1, 0($t0)
	jr $ra

resetEnemyCar4:
	la $t0, startPosEnemy4
	lw $t1, 0($t0)
	li $t1, 104
	sw $t1, 0($t0)
	la $t0, score
	lw $t1, 0($t0)
	addi $t1, $t1, 10
	sw $t1, 0($t0)
	la $t2, highScore
	lw $t3, 0($t2)
	bge $t1, $t3, updateHighScore # current score >= high score
	jr $ra

drawLiveScore:
	la $t7, score
	lw $t8, 0($t7)
	ble $t8, 40, overForty
	ble $t8, 80, overEighty
	ble $t8, 120, over120
	ble $t8, 160, over160
	ble $t8, 200, over200
	la $t2, maxHealthLocation
	lw $t3, 0($t2)
	li $t3, -3128
	ble $t8, 240, over240
	ble $t8, 280, over280
	la $t2, maxHealthLocation
	lw $t3, 0($t2)
	li $t3, -3128
	bge $t8, 280, over280
	bge $t8, 320, over320
	jr $ra
	
overForty:
	lw $t0, displayAddress	# load frame buffer address
	lw $t1, darkOrange
	sw $t1, 140($t0) # first heart
	la $t2, maxHealthLocation
	lw $t3, 0($t2)
	li $t3, -3128
	sw $t3, 0($t2)
	# update car speed when score == 40
	jr $ra

overEighty:
	lw $t0, displayAddress	# load frame buffer address
	lw $t1, darkOrange
	lw $t2, orange1
	sw $t1, 140($t0) # first heart
	sw $t2, 144($t0) # first heart
	la $t2, maxHealthLocation
	lw $t3, 0($t2)
	li $t3, -3128
	sw $t3, 0($t2)
	jr $ra
	
over120:
	lw $t0, displayAddress	# load frame buffer address
	lw $t1, darkOrange
	lw $t2, orange1
	lw $t3, orange2
	sw $t1, 140($t0) # first heart
	sw $t2, 144($t0) # first heart
	sw $t3, 148($t0) # first heart
	jr $ra
	
over160:
	lw $t0, displayAddress	# load frame buffer address
	lw $t1, darkOrange
	lw $t2, orange1
	lw $t3, orange2
	lw $t4, orange3
	sw $t1, 140($t0) # first heart
	sw $t2, 144($t0) # first heart
	sw $t3, 148($t0) # first heart
	sw $t4, 152($t0) # first heart
	la $t2, maxHealthLocation
	lw $t3, 0($t2)
	li $t3, -3128
	sw $t3, 0($t2)
	jr $ra
	
over200:
	lw $t0, displayAddress	# load frame buffer address
	lw $t1, darkOrange
	lw $t2, orange1
	lw $t3, orange2
	lw $t4, orange3
	lw $t5, orange4
	sw $t1, 140($t0) # first heart
	sw $t2, 144($t0) # first heart
	sw $t3, 148($t0) # first heart
	sw $t4, 152($t0) # first heart
	sw $t5, 156($t0) # first heart
	jr $ra
	
over240:
	lw $t0, displayAddress	# load frame buffer address
	lw $t1, darkOrange
	lw $t2, orange1
	lw $t3, orange2
	lw $t4, orange3
	lw $t5, orange4
	lw $t6, orange5
	sw $t1, 140($t0) # first heart
	sw $t2, 144($t0) # first heart
	sw $t3, 148($t0) # first heart
	sw $t4, 152($t0) # first heart
	sw $t5, 156($t0) # first heart
	sw $t6, 160($t0) # first heart
	jr $ra
	
over280:
	la $t4, carSpeed
	lw $t5, 0($t4)
	bne $t5, 3, incrementSpeed
	lw $t0, displayAddress	# load frame buffer address
	lw $t1, darkOrange
	lw $t2, orange1
	lw $t3, orange2
	lw $t4, orange3
	lw $t5, orange4
	lw $t6, orange5
	sw $t1, 140($t0) # first heart
	sw $t2, 144($t0) # first heart
	sw $t3, 148($t0) # first heart
	sw $t4, 152($t0) # first heart
	sw $t5, 156($t0) # first heart
	sw $t6, 160($t0) # first heart
	sw $t6, 164($t0) # first heart
	la $t2, maxHealthLocation
	lw $t3, 0($t2)
	li $t3, -2104
	sw $t3, 0($t2)
	jr $ra

over320:
	lw $t0, displayAddress	# load frame buffer address
	lw $t1, darkOrange
	lw $t2, orange1
	lw $t3, orange2
	lw $t4, orange3
	lw $t5, orange4
	lw $t6, orange5
	sw $t1, 140($t0)
	sw $t2, 144($t0)
	sw $t3, 148($t0) 
	sw $t4, 152($t0) 
	sw $t5, 156($t0) 
	sw $t6, 160($t0) 
	sw $t6, 164($t0) 
	sw $t1, 168($t0)
	# update speed -> add a more challenging level
	jr $ra

drawMaxLife:
	# generate random number 1 to 4 - indicates spawn location
	lw $t0, displayAddress	# load frame buffer address
	la $t1, purple
	lw $t2, 0($t1)
	lw $t3, maxHealthLocation
	add $t0, $t0, $t3
	sw $t2, 0($t0)
	addi $t0, $t0, 8
	sw $t2, 0($t0)
	addi $t0, $t0, 124
	sw $t2, 0($t0)
	addi $t0, $t0, 124
	sw $t2, 0($t0) 
	addi $t0, $t0, 8
	sw $t2, 0($t0) 
	jr $ra
	
pickupMove:
	la $t0, maxHealthLocation
	lw $t1, 0($t0)
	addi $t1, $t1, 128
	sw $t1, 0($t0)
	jr $ra
	

drawCar: 
	lw $t0, displayAddress # $t0 stores the base address for display
	lw $t1, black # $t1 stores the black colour code
	lw $t2, green 
	lw $t4, startPos
	
	# main position for the car i.e. top-left tire
	add $t0, $t0, $t4
	# if t0's position has a colour of black or blue then collide must be true
	add $t5, $gp, $t4
	lw $t3, 0($t5)
   	
   	beq $t3, 6950317, resetLives
    	beq $t3, 1051656, setCollision # collide with the tire of another car
    	beq $t3, 255, setCollision
    	
    	lw $t3, 4($t5)
    	
    	beq $t3, 6950317, resetLives
    	beq $t3, 1051656, setCollision # collide with the tire of another car
    	beq $t3, 255, setCollision
    	
	sw $t1, 0($t0)
	
	# green for the body of the car
	addi $t0, $t0, 4
	sw $t2, 0($t0)
	
	addi $t0, $t0, 4
	sw $t2, 0($t0)
	
	# move 24 pixels to the right for the front-right tire
	addi $t0, $t0, 4
	sw $t1, 0($t0)
	
	# move a few pixels down for the back right tire
	addi $t0, $t0, 640
	sw $t1, 0($t0)
	
	
	# green for the body of the car
	addi $t0, $t0, -4
	sw $t2, 0($t0)
	
	addi $t0, $t0, -4
	sw $t2, 0($t0)
	
	# move a few pixels down for the back left tire
	addi $t0, $t0, -4
	sw $t1, 0($t0)
	
	# body
	addi $t0, $t0, -124
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, -128
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, -128
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, -128
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, 4
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, 128
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, 128
	sw $t2, 0($t0)
	
	# body
	addi $t0, $t0, 128
	sw $t2, 0($t0)

	jr $ra

### END OF DRAWING THE CAR ###

endGameQuery:
	la $a0, playAgain
	li $v0, 4
	syscall
	li $v0, 5
	syscall
	move $t0, $v0
	beq $t0, 1, restartGame
	jr $ra

printHighScore:
	la $a0, displayHighScore
	li $v0, 4
	syscall
	la $t0, highScore
	lw $t1, 0($t0)
	li $v0, 1
	move $a0, $t1
	syscall
	la $t0, newLine
	li $v0, 4
	move $a0, $t0
	syscall
	jr $ra

gameEnd:
	jal printHighScore
	jal drawGameOver
	jal resetScore
	jal resetCarSpeed
	jal endGameQuery
	li $v0, 10 # terminate program run and
   	syscall    # Exit
