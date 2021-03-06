


// $TX+IV,"      Game parameters     "$
#define MAX_HEALTH		3	// x
#define REGEN_TIME		20	// x
#define BULLET_DIAMETER		6	// x
#define INIT_SPAWN_HEIGHT	9000	// x
#define ENEMY_DOWN_SPEED	1	// x
#define ENEMY_NUM		100	// x
#define ENEMY_FIRE_COOLDOWN	100	// x
#define ENEMY_SWAY_LOWER_BOUND	1	// x
#define ENEMY_SWAY_UPPER_BOUND	35	// x

#define FRAME_LENGTH		10
#define PLAYER_DIAMETER		10
#define INVINCIBILITY_FRAMES	100
#define TOP_SCORES_NUM		10
#define BULLET_ARRAY_SIZE	300
#define EXPLOSION_ARRAY_SIZE	10



// $TX+IV,"      Canvas positions     "$
//#define CANV_X_START	4
//#define CANV_X_MID	232
//#define CANV_X_END	465

//#define CANV_Y_START	4
//#define CANV_Y_MID	234
//#define CANV_Y_END	468

// Square in the center of screen minus
// border width. Account for top bar.
#define CANV_X_START	80
#define CANV_X_END	560

#define CANV_Y_START	1
#define CANV_Y_END	469


// $TX+IV," HP indicator constants "$
#define HP_WIDTH	41
#define HP_HEIGHT	14
#define HP_Y_OFF	19

// $TX+IV,"      Color definitions     "$
// A lot of the colors aren't used
// in their original form, so new
// names are given. A lot of these
// palette entries shift color values
// during play.
/*

SB_IMG	= Sidebar image
BG	= Background
BUL	= Bullet
NS	= No-(palette)shift

Number (Hex)
| Is used explicitly?
| | Is used implicitly? (sprites, top bar, dithering)
| | | Dynamically Palette shifts?
| | | | Old name New name
- - - - -------- -----------
0 X X   BLACK
1 X     BLUE     DKGRAY_2
2   X   GREEN
3   X   CYAN
4 X X X RED      SB_IMG_BG
5 X   X PURPLE   BUL_BG_1
6   X   BROWN
7 X   X LTGRAY
8   X   DKGRAY
9 X     LTBLUE
A   X   LTGREEN
B   X   LTCYAN
C       LTRED
D X   X LTPURPLE BUL_BG_2
E X     YELLOW
F X     WHITE    TODO

*/

#define DKGRAY_2	BLUE
#define SB_IMG_BG	RED
#define BUL_BG_1	PURPLE
#define BUL_BG_2	LTGREEN
//#define BUL_BG_2	LTPURPLE


// $TX+IV," Player movement (with keys) "$

#define DOWN	+1
#define UP	-1
#define RIGHT	+1
#define LEFT	-1


// $TX+IV,"      Class definitions     "$

class Match {
  I64 spawn_height;
  I64 spawn_tolerence;

  F64 start_time;
  F64 time;

  I64 big_bullet_interval;
  Bool is_over;
};

class Level {
  F64 down_speed;
  I64 max_health;
  F64 regen_time;
  I64 enemy_num;
  I64 enemy_spawn_high_bound;
  I64 enemy_sway_low_bound;
  I64 enemy_sway_high_bound;
  I64 bullet_diameter;
  I64 big_bullet_interval;
};

class Score {
  F64 match_time;
  U8 *date;
};

class Player {
  F64 x;
  F64 y;
  I64 health;
  I64 invincibility_frames;
  F64 last_hit_time;
};

class Enemy {
  F64 x;
  F64 y;
  I64 original_x;
  I64 sway_multiplier;
};

class Bullet {
  F64 x;
  F64 y;
  F64 vel_x;
  F64 vel_y;
  I64 diameter;
};

class Explosion {
  I64 x;
  I64 y;
  I64 diameter;
  I64 frame;  // -1 is inactive
};


// $TX+IV,"     Utility functions     "$

I64 RandRangeI64(I64 min=0, I64 max) {
  // Fast biased integer multiplication method.
  // Described here:
  // $AN,"Efficiently Generating a Number in a Range",A="",HTML="http://www.pcg-random.org/posts/bounded-rands.html"$ (web link)

  return ((RandU32()(U64) * (max-min)) >> 32) + min;
}

Bool Toggle(Bool value) {
  // Flip a Bool.
  if (value != 0) return FALSE;
  else return TRUE;
}

/*
I64 Checksum() {
  U8 *bytes = FileRead(__FILE__);
  U8 *pt;

  I64 i;

  I64 one_count=0;
  I64 zero_count=0;

  for (pt=bytes;*pt != \0; pt++) {
    for (i=0; i<8; i++) {
      if ((*pt) >> (7-i)&1) {
        one_count++;
      } else {
        zero_count++;
      }
    }
  }
  return zero_count-one_count;
}
*/


U0 InterpolateColors(CBGR48 *buf, I16 steps, CBGR48 c1, CBGR48 c2,
	Bool walk_back=FALSE) {
  // Fills a buffer by linearly interpolating two colors
  // through n steps in RGB space.
  //
  // Generally, the size of the buffer must equal the steps.
  //
  // If walk_back is enabled, it will walk back to the original
  // color, in which case buffer must be of size (steps*2)-2

  I16 i;

  for (i=0;i<steps;i++) {
    buf[i].pad = 0;
    buf[i].r = (c2.r - c1.r) * i / steps + c1.r;
    buf[i].g = (c2.g - c1.g) * i / steps + c1.g;
    buf[i].b = (c2.b - c1.b) * i / steps + c1.b;
  }
  if (walk_back) {
    for (i=0;i<steps-2;i++) {
      buf[steps+i] = buf[steps-i-2];
    }
  }
}


U0 DotMatrix(CDC *dc=gr.dc,I64 x, I64 y, I64 dot_diameter,
	I64 dot_spacing, U8 *string) {
  I64 i,j,k;
  I64 g; // matrix character graphic data


  // Character graphics data is stored in the 35 least significant
  // bits of an I64. It's a simple 5x7 1-bit-per-pixel format.

  for (i=0;i<StrLen(string);i++) {

    switch (string[i]) {
      case 'A': g=0b01110100011000111111100011000110001; break;
      case 'B': g=0b11110100011000111110100011000111110; break;
      case 'C': g=0b01110100011000010000100001000101110; break;
      case 'D': g=0b11110100011000110001100011000111110; break;
      case 'E': g=0b11111100001000011110100001000011111; break;
      case 'F': g=0b11111100001000011110100001000010000; break;
      case 'G': g=0b01110100011000010000101111000101110; break;
      case 'H': g=0b10001100011000111111100011000110001; break;
      case 'I': g=0b01110001000010000100001000010001110; break;
      case 'J': g=0b00001000010000100001000011000101110; break;
      case 'K': g=0b10001100101010011000101001001010001; break;
      case 'L': g=0b10000100001000010000100001000011111; break;
      case 'M': g=0b10001110111010110001100011000110001; break;
      case 'N': g=0b10001110011010110011100011000110001; break;
      case 'O': g=0b01110100011000110001100011000101110; break;
      case 'P': g=0b11110100011000111110100001000010000; break;
      case 'Q': g=0b01110100011000110001101011001001101; break;
      case 'R': g=0b11110100011000111110101001001010001; break;
      case 'S': g=0b01110100011000001110000011000101110; break;
      case 'T': g=0b11111001000010000100001000010000100; break;
      case 'U': g=0b10001100011000110001100011000101110; break;
      case 'V': g=0b10001100011000110001100010101000100; break;
      case 'W': g=0b10001100011000110001101011101110001; break;
      case 'X': g=0b10001100010101000100010101000110001; break;
      case 'Y': g=0b10001100010101000100001000010000100; break;
      case 'Z': g=0b11111000010001000100010001000011111; break;
      case '!': g=0b00100001000010000100001000000000100; break;
      case '.': g=0b00000000000000000000000000000000100; break;
      case '?': g=0b01110100010000100010001000000000100; break;
      case '0': g=0b01110100011001110101110011000101110; break;
      case '1': g=0b01100001000010000100001000010000100; break;
      case '2': g=0b01110100010000100010001000100011111; break;
      case '3': g=0b01110100010000100110000011000101110; break;
      case '4': g=0b00010001100101010010111110001000010; break;
      case '5': g=0b11111100001111000001000011000101110; break;
      case '6': g=0b01110100011000011110100011000101110; break;
      case '7': g=0b11111000010001000100010001000010000; break;
      case '8': g=0b01110100011000101110100011000101110; break;
      case '9': g=0b01110100011000101110000011000101110; break;
      case ' ': g=0; break;
      default:  g=0b01110100011000100010001000000000100; // "?"
    }

    for (j=0; j<7; j++) {
      for (k=0; k<5; k++) {
        if (g >> (34-(j*5+k))&1) {
          GrFillCircle(dc,(x+k*dot_spacing)+(i*dot_spacing*6),
		y+j*dot_spacing,,dot_diameter);
        }
      }
    }
  }
}



U0 BorderDraw(CDC *dc, I64 x, I64 y, I64 width, I64 height,
	I64 border_width, CBGR48 c1=WHITE, CBGR48 c2=DKGRAY) {
  // Draws an angling border with two colors (acting as shadow
  // and light).

  I64 i;

  // Left.
  dc->color = c1;
  GrRect(dc, x, y, border_width, height);

  // Right.
  dc->color = c2;
  GrRect(dc, x+width-border_width, y, border_width, height);

  // (The top and bottom are drawn as angling lines)

  for (i=0; i<border_width; i++) {
    // Top.
    dc->color = c1;
    GrLine(dc, x+i, y+(i-1), x+width-(i+1), y+(i-1), 0);

    // Bottom.
    dc->color = c2;
    GrLine(dc, x+i, y+height-(i+1), x+width-(i+1),y+height-(i+1), 0);
  }
}


I64 ScoreCompare(Score *s1, Score *s2) {
  // For QSort.

  if (s1->match_time < s2->match_time) {
    return 1;
  } else if (s1->match_time == s2->match_time) {
    return 0;
  } else {
    return -1;
  }
}


U0 ResetBullet(Bullet *bullets, I64 i) {
  bullets[i].x=-10;
  bullets[i].y=0;
  bullets[i].vel_x=0.0;
  bullets[i].vel_y=0.0;
}

U0 MsDrawNothing(CDC dc, I64 x, I64 y) {
  // Don't draw anything. Used as a mouse callback.
}

U0 Graph(CDC *dc=gr.dc, I64 *buf, I64 x=0, I64 y=0, I64 frame, I64 time, U8 *label) {
  // Graphing function for draw times. Requires a zeroed buffer of 255.

  // See $LK,"AndNotMod.HC.Z",A="FI:::/Demo/Lectures/AndNotMod.HC.Z"$ for speed comparison
  // between & and % operators.
  buf[frame&255] = time;

  I64 i;

  dc->color = LTGRAY;
  for (i=0;i<255;i++) {
    if (i==frame&255) dc->color = DKGRAY;
    GrLine(dc,x+i,y,x+i,y-buf[i]);
  }
  dc->color = LTBLUE;
  GrPrint(dc, x, y+4, label);
}


// $TX+IV,"     Sprite / anim functions     "$

U0 Target(F64 obj_x, F64 obj_y, F64 targ_x, F64 targ_y,
	F64 *obj_�, Bool *obj_is_flipped) {
  // Sets the orientation of a sprite.
  //   �: It's angle in radians.
  //   is_flipped: If the sprite needs to flip.

  F64 delta_x = obj_x - targ_x;
  F64 delta_y = obj_y - targ_y;

  F64 hyp = Sqrt(delta_x`2 + delta_y`2);
  F64 � = ASin(delta_y / hyp);
  Bool is_flipped=FALSE;

  if (targ_x > obj_x) {
    is_flipped = TRUE;
  }

  // (Handle player being directly below sprite.)
  if (targ_y > obj_y && 1.57 < � < 1.58) � = -1.571;

  *obj_� = �;
  *obj_is_flipped = is_flipped;
}


U0 ChangeRelative(F64 *x_ptr, F64 *y_ptr, F64 x_off, F64 �,
	 Bool is_flipped) {
  // Changes position by x offset relative to the object's angle.

  if (is_flipped)
    *x_ptr -= Cos(�)*x_off;
  else
    *x_ptr += Cos(�)*x_off;

  *y_ptr += Sin(�)*x_off;
}


// $TX+IV,"     Sprites     "$



$SP,"<skull>",BI=1$











        R                  �     ��       � �� �� � �� �� �       �   �   ��     ��� � � �� 