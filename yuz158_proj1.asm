
.include "display_2211_0822.asm"
.include "math.asm"

# Player constants
.eqv PLAYER_X_START 0x1D00 # 30.0
.eqv PLAYER_Y_START 0x3200 # 50.0
.eqv PLAYER_X_MIN   0x0200 # 2.0
.eqv PLAYER_X_MAX   0x3900 # 57.0
.eqv PLAYER_Y_MIN   0x2E00 # 46.0
.eqv PLAYER_Y_MAX   0x3900 # 57.0
.eqv PLAYER_W       0x0500 # 5.0
.eqv PLAYER_H       0x0500 # 5.0
.eqv PLAYER_VEL     0x0100 # 1.0

# Bullet constants
.eqv BULLET_COLOR   COLOR_WHITE
.eqv MAX_BULLETS    10 # size of the bullet arrays
.eqv BULLET_DELAY   25 # frames
.eqv BULLET_VEL     0x0180 # 1.5

# Rock constants
.eqv ROCKS_TO_DESTROY 10
.eqv MAX_ROCKS        10
.eqv ROCK_VEL         0x0080 # 0.5 pixels/frame
.eqv ROCK_W           0x0500 # 5.00
.eqv ROCK_H           0x0500 # 5.00
.eqv ROCK_MAX_X       0x4000 # 64.0
.eqv ROCK_MAX_Y       0x4000 # 64.0
.eqv ROCK_DELAY       45 # frames
.eqv ROCK_MIN_ANGLE   115
.eqv ROCK_ANGLE_RANGE 110

.data

# Player variables
player_x:         .word PLAYER_X_START
player_y:         .word PLAYER_Y_START
player_next_shot: .word 0
player_lives:     .word 3
rocks_left:       .word ROCKS_TO_DESTROY

# Bullet variables
bullet_x:         .word 0:MAX_BULLETS
bullet_y:         .word 0:MAX_BULLETS
bullet_active:    .byte 0:MAX_BULLETS

# Rock variables
rock_x:           .word 0:MAX_ROCKS
rock_y:           .word 0:MAX_ROCKS
rock_vx:          .word 0:MAX_ROCKS
rock_vy:          .word 0:MAX_ROCKS
rock_active:      .byte 0:MAX_ROCKS
rock_next_spawn:  .word 0

# Sprites
player_sprite: .byte
-1 -1  4 -1 -1
-1  4  7  4 -1
 4  7  7  7  4
 4  4  4  4  4
 4 -1  2 -1  4

rock_sprite: .byte
-1 11 11 11 -1
11 11 11 11 11
11 11 11 11 11
11 11 11 11 11
-1 -1 11 11 11

.text

# -------------------------------------------------------------------------------------------------

.globl main
main:
	jal wait_for_start

	_loop:
		# TODO: uncomment these and implement them
		jal check_input
		jal update_all
		jal draw_all
		jal display_update_and_clear
		jal wait_for_next_frame
	jal check_game_over
	beq v0, 0, _loop
	
syscall_exit

# -------------------------------------------------------------------------------------------------
check_input:
enter 
	jal input_get_keys_held
	and t0, v0, KEY_L
	beq t0, 0, _endifL
 	lw t1 player_x
 	beq t1 PLAYER_X_MIN, _return
 	sub t1, t1, PLAYER_VEL
	sw t1 player_x
	_endifL:
	
	jal input_get_keys_held
	and t0 v0 KEY_R
	beq t0 0 _endifR
 	lw t1 player_x
 	beq t1 PLAYER_X_MAX, _return
 	add t1, t1, PLAYER_VEL
	sw t1 player_x
	_endifR:
	
	jal input_get_keys_held
	and t0 v0 KEY_U
	beq t0 0 _endifU
 	lw t2 player_y
 	beq t2 PLAYER_Y_MIN, _return
 	sub t2, t2, PLAYER_VEL
	sw t2 player_y
	_endifU:
	
	jal input_get_keys_held
	and t0 v0 KEY_D
	beq t0 0 _endifD
 	lw t2 player_y
 	beq t2 PLAYER_Y_MAX, _return
 	add t2, t2, PLAYER_VEL
	sw t2 player_y
	_endifD:
	
	jal input_get_keys_held
	and t0 v0 KEY_Z
	beq t0 0 _endifZ
	jal fire_bullet
	_endifZ:

	_return:
		leave
# -------------------------------------------------------------------------------------------------
update_all:
enter
	jal spawn_rocks
	jal move_bullets
	jal move_rocks
	jal collide_bullets_with_rocks
	jal collide_rocks_with_player
leave
# -------------------------------------------------------------------------------------------------
move_rocks:
enter s0
	li s0 0
	_loop:
	lb t0, rock_active(s0)
	beq t0, 0, _endif
	
	mul s1 s0 4
	lw t0 rock_x(s1)
	lw t1 rock_vx(s1)
	add t0 t0 t1
	and t0 t0 0x3FFF
	sw t0 rock_x(s1)
	
	lw t0 rock_y(s1)
	lw t1 rock_vy(s1)
	add t0 t0 t1
	sw t0 rock_y(s1)
	
	blt t0 ROCK_MAX_Y _return
	sb zero rock_active(s0)
	
	_endif:
	_return:
	add s0 s0 1
	blt s0 MAX_ROCKS _loop
leave s0
# -------------------------------------------------------------------------------------------------
spawn_rocks:
enter s0
	lw t0 frame_counter
	lw t1 rock_next_spawn
    
        blt t0 t1 _break
        add t1 t0 ROCK_DELAY
        sw t1 rock_next_spawn
        
        jal find_free_rock
        move t0 v0
        
        blt t0 0 _endif
        
	li t2, 1
        sb t2, rock_active(t0)
        
        mul s0 t0 4
        
        li a0 ROCK_MAX_X
        jal random 
        move t0 v0       
        sw t0 rock_x(s0)
    	
        sw zero rock_y(s0)
        
        li a0 ROCK_ANGLE_RANGE
        jal random
        move t1 v0
        
        add t0 t1 ROCK_MIN_ANGLE
        move a1 t0
        
        li a0 ROCK_VEL
        jal to_cartesian
        move t0 v0
        move t1 v1
        sw t0 rock_vx(s0)
        sw t1 rock_vy(s0)
        
        _endif:
           
    _break:
leave s0

# -------------------------------------------------------------------------------------------------
move_bullets:
enter s0
	li s0 0
	_loop:
	lb t0 bullet_active(s0)
	mul s1 s0 4
	bne t0 1 _endif
	
	lw t1 bullet_y(s1)

	sub t1 t1 BULLET_VEL	
	sw t1 bullet_y(s1)
	
	bge t1 0 _return
	sb zero, bullet_active(s0)
	
	_endif:
	_return:	
	add s0 s0 1
	blt s0 MAX_BULLETS _loop

leave s0
# -------------------------------------------------------------------------------------------------	
fire_bullet:
enter s0
	lw t0 frame_counter
	lw t1 player_next_shot
    
        blt t0 t1 _break
        add t1 t0 BULLET_DELAY
        sw t1 player_next_shot
        
        jal find_free_bullet
        move t0 v0
        #print_str "pow!"
        
        blt t0 0 _endif
        
	li t2, 1
        sb t2, bullet_active(t0)
        
        mul s0 t0 4
        
        lw t2 player_x
        add t2 t2 0x200
        sw t2 bullet_x(s0)
    	
        lw t2 player_y
        sub t2 t2 0x100
        sw t2 bullet_y(s0)
        _endif:
           
    _break:
leave s0
# -------------------------------------------------------------------------------------------------
find_free_bullet:
enter s0
	li s0 0
	_loop:
	lb t0, bullet_active(s0)
	move v0 s0
	beq t0 0 _return
	add s0 s0 1
	blt s0 MAX_BULLETS _loop
	li v0 -1
	_return:
     
leave s0
# -------------------------------------------------------------------------------------------------
find_free_rock:
enter s0
	li s0 0
	_loop:
	lb t0, rock_active(s0)
	move v0 s0
	beq t0 0 _return
	add s0 s0 1
	blt s0 MAX_ROCKS _loop
	li v0 -1
	_return:
     
leave s0
# -------------------------------------------------------------------------------------------------
draw_bullets:
enter s0
	li s0 0
	_loop:
	lb t0 bullet_active(s0)
	mul t1 s0 4
	
	bne t0 1 _endif
	lw a0 bullet_x(t1)
    	sra a0, a0, 8
    	lw a1 bullet_y(t1)
    	sra a1, a1, 8
    	li a2 BULLET_COLOR
    	jal display_set_pixel
    	
    	_endif:
    	add s0 s0 1
    	blt s0 MAX_BULLETS _loop
	
leave s0
# -------------------------------------------------------------------------------------------------
wait_for_start:
enter
	_loop:
		jal draw_all
		jal display_update_and_clear
		jal wait_for_next_frame
	jal input_get_keys_pressed
	beq v0, 0, _loop
_return:
leave

# -------------------------------------------------------------------------------------------------

check_game_over:
enter
	li  v0, 1
	lw  t0, player_lives
	beq t0, 0, _return
	lw  t0, rocks_left
	beq t0, 0, _return
	li  v0, 0
_return:
leave

# -------------------------------------------------------------------------------------------------

draw_all:
enter
	# TODO: uncomment and implement these
	jal draw_rocks
	jal draw_bullets
	jal draw_player
	jal draw_hud
leave

# -------------------------------------------------------------------------------------------------
draw_player:
enter
    lw a0 player_x
    sra a0, a0, 8
    lw a1 player_y
    sra a1, a1, 8
    la a2, player_sprite
    jal display_blit_5x5_trans
leave
# -------------------------------------------------------------------------------------------------
draw_hud:
enter
	# hide our shame :^)
	li a0, 0
	li a1, 0
	li a2, 64
	li a3, 7
	li v1, COLOR_DARK_GREY
	jal display_fill_rect

	# display rocks left
	li a0, 1
	li a1, 1
	lw a2, rocks_left
	jal display_draw_int

	# display lives left
	li a0, 45
	li a1, 1
	la a2, player_sprite
	jal display_blit_5x5_trans

	li a0, 51
	li a1, 1
	li a2, '='
	jal display_draw_char

	li a0, 57
	li a1, 1
	lw a2, player_lives
	jal display_draw_int
leave
# -------------------------------------------------------------------------------------------------
draw_rocks:
enter s0
	li s0 0
	_loop:
	lb t0, rock_active(s0)
	beq t0, 0, _endif
	mul s1 s0 4
	lw a0 rock_x(s1)
    	sra a0, a0, 8
    	lw a1 rock_y(s1)
    	sra a1, a1, 8
    	la a2, rock_sprite
    	jal display_blit_5x5_trans
    	
    	_endif:
    	add s0 s0 1
    	blt s0 MAX_ROCKS _loop
leave s0
# -------------------------------------------------------------------------------------------------
collide_bullets_with_rocks:
enter s0 s1
	li s0 0
	_loop1:
	li s1 0
	_loop2:
	move a0 s0
	move a1 s1
	
	jal rock_collides_with_bullet
	bne v0 1 _endif
	
	sb zero rock_active(s0)
	sb zero bullet_active(s1)
	lw t2 rocks_left
	sub t2 t2 1
	sw t2 rocks_left
	
	j _return
	
	_endif:
	add s1 s1 1
	blt s1 MAX_BULLETS _loop2
	
	_return:
	add s0 s0 1
	blt s0 MAX_ROCKS _loop1
		
leave s0 s1
# -------------------------------------------------------------------------------------------------
rock_collides_with_bullet:
enter s0 s1
	li v0, 0
	
	lb  t0, rock_active(a0)
	beq t0, 0, _return 
	lb  t0, bullet_active(a1)
	beq t0, 0, _return 
	
	mul s0 a0 4
	mul s1 a1 4
	
	lw t0 bullet_x(s1)
	lw t1 rock_x(s0)
	add t2 t1 ROCK_W
	blt t0 t1 _return #bullet_x >= rock_x
	bgt t0 t2 _return #bullet_x <= rock_x + ROCK_W
	
	lw t0 bullet_y(s1)
	lw t1 rock_y(s0)
	add t2 t1 ROCK_H
	blt t0 t1 _return #bullet_y >= rock_y
	bgt t0 t2 _return #bullet_y <= rock_y + ROCK_H
	
	li v0, 1
	_return:
leave s0 s1
# -------------------------------------------------------------------------------------------------
collide_rocks_with_player:
enter s0
	li s0 0
	_loop:
	move a0 s0
	jal rock_collides_with_player
	
	bne v0 1 _endif
	jal kill_player
	j _return

	_endif:
	add s0 s0 1
	blt s0 MAX_ROCKS _loop
	_return:
leave s0
# -------------------------------------------------------------------------------------------------
kill_player:
enter s0
	lw t0 player_lives
	sub t0 t0 1
	sw t0 player_lives
	
	li t0 PLAYER_X_START
	sw t0 player_x
	li t0 PLAYER_Y_START
	sw t0 player_y
	
	li s0 0
	_loop:
	sb zero bullet_active(s0)
	add s0 s0 1
	blt s0 MAX_BULLETS _loop
	
	li s0 0
	_loop1:
	sb zero rock_active(s0)
	add s0 s0 1
	blt s0 MAX_ROCKS _loop1
leave s0
# -------------------------------------------------------------------------------------------------
rock_collides_with_player:
enter 
	lb t0 rock_active(a0)
	beq t0, 0, _endif
	
	mul a0, a0, 4
	
	lw t0 rock_x(a0)
	lw t1 player_x
	sub t0 t0 t1
	abs t0 t0 
	bgt t0 PLAYER_W _return
	
	lw t0 rock_y(a0)
	lw t1 player_y
	sub t0 t0 t1
	abs t0 t0 
	bgt t0 PLAYER_H _return
	
	li v0 1
	_endif:
	_return:
leave 