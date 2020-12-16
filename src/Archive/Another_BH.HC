
// $TX+IV,"       This Is Bull!ts       "$   ÛÛÛ   ÛÛÛ
//                                Û±±ÛÛ ÛÛÛÛÛ
// Bullet Hell game for TempleOS. Û±ÛÛÛÛÛÛÛÛÛ
// By Rendello, September 2020.   ÛÛÛÛÛÛÛÛÛÛÛ  
//                                Û±ÛÛÛÛÛÛ±±Û  ±±
// Under BSD-3 licence, see readme.ÛÛÛÛÛÛ± ±± ±±±±
// If you modify and re-release     ÛÛÛÛÛ±±±±±±±±±
// it, please change the title       ÛÛÛÛÛ±±±±±±±
// and credit the original.           ÛÛÛ  ±±±±±
//                                     Û    ±±±
// Enjoy!                                    ±



// $TX+IV,"      General options     "$

#define FANCY_GRAPHICS	ON
#define DRAW_JET	ON

#define DEBUG		ON
#define GRAPH		ON
#define PROFILER	OFF


//       ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
//       º Don't modify options / code below  º
// - - - º if you want to submit high scores. º - - -
//       ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍ¼ÄÄÄ¿
//                               ³Unless you want ³
//                               ³to cheat I guess³
//                               ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

// $TX+IV,"      Game parameters     "$
#define MAX_HEALTH		3
#define REGEN_TIME		20
#define PLAYER_RADIUS		10
#define BULLET_DIAMETER		5
#define INIT_SPAWN_HEIGHT	9000
#define ENEMY_DOWN_SPEED	1.1
#define ENEMY_NUM		100
#define ENEMY_FIRE_COOLDOWN	100
#define ENEMY_SWAY_LOWER_BOUND	1
#define ENEMY_SWAY_UPPER_BOUND	35
#define FRAME_LENGTH		10

// (Changing these likely to break things.)
#define TOP_SCORES_NUM		10
#define BULLET_ARRAY_SIZE	300


// $TX+IV,"      New color definitions     "$
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
| Is used?
| | Dynamically Palette shifts?
| | | Old name New name
- - - -------- -----------
0 X   BLACK
1     BLUE
2     GREEN
3     CYAN
4 X X RED      SB_IMG_BG
5 X X PURPLE   BUL_BG_1
6 X X BROWN    LTGRAY_NS
7 X X LTGRAY   SB_IMG_GRAY
8     DKGRAY
9     LTBLUE
A     LTGREEN
B     LTCYAN
C     LTRED
D X X LTPURPLE BUL_BG_2
E X X YELLOW   TODO
F X X WHITE    TODO

*/

#define SB_IMG_BG	RED
#define BUL_BG_1	PURPLE
#define LTGRAY_NS	BROWN
#define SB_IMG_GRAY	LTGRAY
#define BUL_BG_2	LTPURPLE



// $TX+IV,"      Class definitions     "$

class Match {
  I64 spawn_height;
  I64 spawn_tolerence;

  F64 start_time;
  F64 time;

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

// $TX+IV,"     Utility functions     "$

I64 RandRangeI64(I64 min=0, I64 max) {
  // Fast biased integer multiplication method.
  // Described here:
  // $AN,"Efficiently Generating a Number in a Range",A="",HTML="http://www.pcg-random.org/posts/bounded-rands.html"$ (web link)

  return ((RandU32()(U64) * (max-min)) >> 32) + min;
}


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
      case ' ': 0; break;
      default:  g=0b01110100011000100010001000000000100;
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

  // (height is reduced by one since GrRect3 is one pixel off).
  // Left.
  dc->color = c1;
  GrRect3(dc, x, y, 0, border_width, height-1);

  // Right.
  dc->color = c2;
  GrRect3(dc, x+width-border_width, y, 0, border_width, height-1);

  // (The top and bottom are drawn as angling lines)

  for (i=0; i<border_width; i++) {
    // Top.
    dc->color = c1;
    GrLine3(dc, x+i, y+(i-1), 0, x+width-(i+1), y+(i-1), 0);

    // Bottom.
    dc->color = c2;
    GrLine3(dc, x+i, y+height-(i+1), 0, x+width-(i+1),y+height-(i+1), 0);
  }
}


U0 LightningDraw(CDC *dc, I64 x, I64 y1, I64 y2, I64 bound) {
  // Draws a vertical electric arc with lines.

  I64 i;
  I64 last_y = y1;
  I64 last_x = x;
  I64 new_x;

  dc->color=WHITE;
  for (i=y1; i<y2; i+=(y2-y1)>>6) {

    new_x = x + RandRangeI64(-bound, bound);

    GrLine(dc, last_x, last_y, new_x, i);
    last_x = new_x;
    last_y = i;
  }
}

U0 JetDraw(CDC *dc,I64 x,I64 y, F64 rotation) {

  // (Keep jet slighty rotated so the tail is
  // visible at rest.)
  if (-0.1 < rotation < 0.1) rotation = 0.2;

  dc->flags|=DCF_TRANSFORMATION;
  DCDepthBufAlloc(dc);

  DCDepthBufRst(dc);
  Mat4x4IdentEqu(dc->r);
  Mat4x4RotY(dc->r,ã+rotation);

  dc->x=x;
  dc->y=y+40;
  dc->z=GR_Z_ALL;

  Sprite3(dc,0,-25,0,$IB,"<jet>",BI=1$);
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
  // (NO-OP; Don't draw anything.)
}

U0 Graph(CDC *dc=gr.dc, I64 *buf, I64 x=0, I64 y=0, I64 frame, I64 draw_time) {
  // Graphing function for draw times. Requires a zeroed buffer of 255.

  // See $LK,"AndNotMod.HC.Z",A="FI:::/Demo/Lectures/AndNotMod.HC.Z"$ for speed comparison
  // between & and % operators.
  buf[frame&255] = draw_time;

  I64 i;
  for (i=0;i<255;i++) {
    dc->color=BLACK;
    GrLine(dc,x+i,y,x+i,y-buf[i]);
  }
}

// $TX+IV,"     Sprites     "$


$SP,"",BI=2$




































$SP,"<jet>",BI=1$





// $TX+IV,"     Globals     "$
// AFAIK, The only simple way to pass state to state to
// the draw callback is by having the state be global.

U8 scoreboard_string[6];

// $TX+IV," Bullet palette-swap data "$
I64 bullet_color_steps = 85;
I64 bullet_color_num = (bullet_color_steps*2)-2;
CBGR48 bullet_colors[bullet_color_num];

InterpolateColors(bullet_colors,bullet_color_steps,0xff0033000000,
	0xff00cc000000,TRUE);


// $TX+IV," New palette "$
// See new color #defines at the top of file.

GrPaletteColorSet(LTGRAY_NS,GrPaletteColorGet(LTGRAY));


// $TX+IV," Sidebar image palette-swap data "$
CBGR48 ltgray_color=0xd400cf00c700;
GrPaletteColorSet(SB_IMG_GRAY,ltgray_color);

I64 frame_color_steps = 85;
I64 frame_color_num = (frame_color_steps*2)-2;
CBGR48 frame_colors[frame_color_num];


InterpolateColors(frame_colors,frame_color_steps,ltgray_color,
	0xff0022001100,TRUE);


I64 i;
I64 j;


// $TX+UL,"UI dimensions"$
I64 canv_x_start = 4;
I64 canv_x_end = GR_WIDTH-175;
I64 canv_x_mid = (canv_x_end-canv_x_start)/2;
I64 canv_y_start = 4;
I64 canv_y_end = GR_HEIGHT-12;
I64 canv_y_mid = (canv_x_end-canv_x_start)/2;
I64 logo_height = 175;

Match match = {INIT_SPAWN_HEIGHT,INIT_SPAWN_HEIGHT-1000,tS,tS,30};

Player player = {100,100,MAX_HEALTH,0,0};


if (PROFILER) { Prof; }


// $TX+IV," Initialize enemies "$
I64 enemy_num = 100; 
Enemy enemies[enemy_num];
enemies[0].x=1;

for (i=0;i<enemy_num;i++) {
  enemies[i].x = RandRangeI64(canv_x_start,canv_x_end);
  enemies[i].y = RandRangeI64(INIT_SPAWN_HEIGHT,0);
  enemies[i].original_x = enemies[i].x;
  enemies[i].sway_multiplier = RandRangeI64(
	ENEMY_SWAY_LOWER_BOUND, ENEMY_SWAY_UPPER_BOUND);
}


// $TX+IV," Initialize bullets "$
// Inactive bullets are stored off-screen.
// Each fired bullet increases the bullet_count
// and occupies its index in the array. bullet_count
// loops back to 0 after hitting BULLET_ARRAY_SIZE.

I64 bullet_count=0;
Bullet bullets[BULLET_ARRAY_SIZE];
for (i=0;i<BULLET_ARRAY_SIZE;i++) {
  ResetBullet(bullets,i);
}


// $TX+IV," Initialize top scores "$
// The top_scores array is of size TOP_SCORES_NUM + 1
// as at the end of a match, the current score is
// appended and the array is once again QSorted.
// The new top ten scores are stored to the save file.

// (for strings, 0 == NULL == "")
RegDft("Rendello/Bull!ts",\
	"Score top_scores[11]={{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0}}");

RegExe("Rendello/Bull!ts");

Score current_score={match.time,"Right now!"};

CTask *task=Fs;
CDC *dc=DCAlias;
#if (DRAW_JET)
  CDC *dc_2=DCAlias;
  F64 old_ms_x=ms.pos.x; // (For ship rotation.)
  F64 rotation=0; // (For ship rotation.)
#endif
#if (GRAPH)
  I64 graph_buf[255];
  for (i=0;i<255;i++) {
    graph_buf[i] = 0;
  }
#endif

Bool current_score_drawn;
I64 frame = 0;
I64 draw_frame = 0;

CDateStruct ds;

dc->flags|=DCF_TRANSFORMATION;


// $TX+IV,"                          "$
// $TX+IV,"     Drawing callback     "$
// $TX+IV,"                          "$

F64 draw_time_start;

U0 DrawIt(CTask *task, CDC *) {
  draw_time_start=tS;

  DCFill;

  // $TX+IV," Palette-shift bullets "$
  // Bullets have two colors, one is always behind the other
  // by approx. half the steps.

  # if (FANCY_GRAPHICS)
    GrPaletteColorSet(PURPLE,bullet_colors[frame%bullet_color_num]);
    GrPaletteColorSet(LTPURPLE,bullet_colors[(frame+bullet_color_steps)%bullet_color_num]);
  # endif

  // $TX+IV," Palette-shift sidebar image "$
  if (player.health >= 3) {
    GrPaletteColorSet(SB_IMG_BG,0xff00cc000000);
  } else {
    GrPaletteColorSet(SB_IMG_BG,GrPaletteColorGet(PURPLE));
    GrPaletteColorSet(SB_IMG_GRAY,ltgray_color);
  }

  if (player.health <= 1) {
    GrPaletteColorSet(SB_IMG_GRAY,frame_colors[frame%frame_color_num]);
  }


 /*
  DCFill(dc,DKGRAY);
  for (i=canv_x_end;i>0;i-=6) {
    if (!(i&2)) {
      dc->color=BUL_BG_1;
    } else {
      dc->color=YELLOW;
    }
    GrFillCircle(
      dc,
      Sin(tS/3)*(i&15)+canv_x_mid,
      Sin(tS/4)*(i&15)+canv_x_mid,
      ,
      ToI64(i+match.time)
     );
  }
  */


  // $TX+IV," Screen-shake on hit "$
  if (player.invincibility_frames > 50) {
    dc->x=RandRangeI64(-5,5);
    dc->y=RandRangeI64(-5,5);
  } else {
    dc->x=0;
    dc->y=0;
  }

  // $TX+IV," Draw enemies "$
  for (i=0; i<ENEMY_NUM;i++) {
    if (enemies[i].y > -10) {
      dc->color=GREEN;
      GrFillCircle(dc,enemies[i].x,enemies[i].y,,20);
    }
  }

  // $TX+IV," Update player position "$
  // NOTE: Updating state inside the draw loop
  // isn't great, but the player position will
  // lag by one frame if updated in the main loop,
  // which is bad for this type of game.
  player.x = Clamp(ms.pos.x,ToF64(canv_x_start),ToF64(canv_x_end-10));
  player.y = Clamp(ms.pos.y,canv_y_start,canv_y_end);

  if (ms.pos.x > canv_x_end) gr.fp_draw_ms=&DrawStdMs;
  else gr.fp_draw_ms=&MsDrawNothing;

  // $TX+IV," Draw jet "$
  #if (DRAW_JET)
    // Calculate jet rotation
    if (ms.pos.x-old_ms_x != 0) {
      rotation=Clamp(rotation+ToF64(ms.pos.x-old_ms_x)/100,-1,1);
    } else {
      rotation-=rotation/10;
    }
    JetDraw(dc_2,player.x+4,player.y-4,rotation);
  #endif

  // $TX+IV," Draw player dot(s) "$
  dc->color=BLUE;
  // Blink on invincibility frames
  if (player.invincibility_frames !=0 &&
	player.invincibility_frames % 4 == 0) {
    // (NO-OP; Don't draw player).
  } else {
     // (Keep player dot legible w/ or w/o jet.)
     #if (DRAW_JET)
       dc->color = WHITE;
     #else
       dc->color = BLUE;
     #endif
     GrFillCircle(dc,player.x+4,player.y-4,,10);
     dc->color = LTBLUE;
     GrFillCircle(dc,player.x+4,player.y-4,,6);

  }

  for (i=0;i<BULLET_ARRAY_SIZE;i++) {
    // $TX+IV," Draw bullet "$
    // Two colored circles, see palette-shift above.
    // Half of the bullets have a 'dark' middle and 'light' border,
    // the other half is the opposite. It gives the palette-shifting
    // bullets more visual variety.

    if (bullets[i].x > -10) {
      if (i%2==0) {
        dc->color=BUL_BG_1;
      } else {
        dc->color=BUL_BG_2;
      }
      GrFillCircle(dc,bullets[i].x,bullets[i].y,,bullets[i].diameter<<1);
      if (i%2==0) {
        dc->color=BUL_BG_2;
      } else {
        dc->color=BUL_BG_1;
      }
      GrFillCircle(dc,bullets[i].x,bullets[i].y,,bullets[i].diameter+1);
    }
  }

  // $TX+IV," Show stats when player left- or right-clicks "$
  dc->color=BLACK;
  if (ms.lb) {
    GrPrint(dc,player.x-48,player.y-4,"%5.1f",match.time);
  }
  if (ms.rb) {
    dc->color=LTBLUE;
    GrPrint(dc,player.x+8,player.y-4,"%d",player.health);
    if (player.health < 3) {
      dc->color=GREEN;
      GrPrint(dc,player.x+8,player.y+5,"%-3.1f",REGEN_TIME - (match.time - player.last_hit_time));
    }
  }

  // $TX+IV," Draw sidebar background "$
  dc->color=DKGRAY;
  GrRect3(dc,canv_x_end,0,0,GR_WIDTH,GR_HEIGHT); // Sidebar (right).


  // $TX+IV," Draw frame "$
  BorderDraw(dc, 0, 0, canv_x_start+canv_x_end-2,
	canv_y_start+canv_y_end, 5, LTGRAY_NS, DKGRAY);


  // $TX+IV," Draw sidebar image "$
  Sprite3(dc,canv_x_end+3,4,0,$IB,"<2>",BI=2$,TRUE);

  // $TX+IV," Draw dot-matrix timer "$
  if (player.invincibility_frames > 0) {
    if (player.invincibility_frames&0b1000==0) {
      StrPrint(scoreboard_string,"OUCH!");
    } else {
      StrPrint(scoreboard_string,"");
    }
  } else if (player.health > 0) {
    StrPrint(scoreboard_string,"%5.1f",match.time);
  } else {
    if (ToI64(tS*100)&0b10000 != 0) {
    if (Blink(0.3)) {
      if (!Blink(0.6)) {
         StrPrint(scoreboard_string,"GAME");
       } else {
        StrPrint(scoreboard_string,"OVER!");
      }
    } else {
      StrPrint(scoreboard_string,"%5.1f",match.time);
    }
    } else {
      StrPrint(scoreboard_string,"");
    }
  }

  dc->color=BLACK;
  GrRect3(dc,canv_x_end+5,255,0,166,40);

  dc->color=LTGRAY_NS;
  DotMatrix(dc,canv_x_end+20,260,6,5,scoreboard_string);

  // $TX+IV," Draw health "$
  dc->color=LTGRAY_NS;
  GrPrint3(dc,canv_x_end+6,300,0,"PWR");


  CBGR48 sheen_color;
  for (i=0;i<MAX_HEALTH;i++) {
    if (i < player.health) {
      dc->color=GREEN;
      sheen_color=LTGREEN;
    } else {
      dc->color=LTPURPLE;
      sheen_color=YELLOW;
    }
    GrRect3(dc,canv_x_end+6,310+(i*19),0,30,13);
    BorderDraw(dc, canv_x_end+6, 310+(i*19),30,14,2,sheen_color,LTGRAY_NS);
  }

  // $TX+IV," Draw regen status "$
  if (player.health != 3) {
    dc->color=BLACK;
    GrRect3(dc,canv_x_end+40,310,0,10,REGEN_TIME);  

    dc->color=GREEN;
    GrRect3(dc,canv_x_end+40,310,0,10,match.time - player.last_hit_time);
  } else {
    // TODO Remove this hack
    dc->color=BLUE;
    GrRect3(dc,canv_x_end+40,310,0,10,REGEN_TIME);
  }

  // $TX+IV," Draw top scores table "$
  // Current score shown in PURPLE, knocks lower scores off
  // the board.

  dc->color=LTGRAY_NS;
  GrPrint3(dc,canv_x_end+130,300,0,"TOP");

  dc->color=BLACK;
  GrRect3(dc,canv_x_end+128,308,0,44,102);

  current_score_drawn=FALSE;
  for (i=0;i<TOP_SCORES_NUM;i++) {
    if (top_scores[i].match_time < current_score.match_time &&
	!current_score_drawn) {
      dc->color=PURPLE;
      GrPrint3(dc,canv_x_end+130,311+(i*10),0,"%5.1f", \
		current_score.match_time, current_score.date);
      current_score_drawn=TRUE;
    }
    dc->color=GREEN;
    if (!(current_score_drawn && i==TOP_SCORES_NUM-1)) {
      GrPrint3(dc,canv_x_end+130,311+((current_score_drawn+i)*10),0, \
		"%5.1f",top_scores[i].match_time,top_scores[i].date);
    }
  }

  // $TX+IV," Draw game info "$
  dc->color=LTGRAY_NS;
  GrPrint3(dc,canv_x_end+5,461,0,"TiB 1.0.0b   Rendello");

  // $TX+IV," Draw game border "$
  BorderDraw(dc, canv_x_end+3, 254, 167, 43, 2, LTGRAY,BLUE);

  // $TX+IV," Draw debug "$
  #if (DEBUG)
    dc->color=BLUE;
    GrPrint(dc,canv_x_start+10,canv_y_start+10,
	"Max spawn height (pix): %d",match.spawn_height);
    GrPrint(dc,canv_x_start+10,canv_y_start+20,
	"Approx. draw time (ms): %6.3f",(tS-draw_time_start)*1000);
    GrPrint(dc,canv_x_start+10,canv_y_start+30,
	"Big bullet ratio: úúúúú 1:%d",match.big_bullet_interval-1);
    #if (DRAW_JET)
      GrPrint(dc,canv_x_start+10,canv_y_start+40,
	"Jet rotation: úúúúúúúúú %5.3f",rotation);
    #endif
  #endif

  // $TX+IV," Draw graph "$
  #if (GRAPH)
    Graph(dc, graph_buf, 10, 100, draw_frame, (tS-draw_time_start)*3000);
  #endif

  #if (DRAW_JET)
    old_ms_x = ms.pos.x; // For ship rotation.
  #endif
//  LightningDraw(dc, 500, 300, 420, 10);
  draw_frame++;
}


// $TX+IV,"              "$
// $TX+IV,"     Main     "$
// $TX+IV,"              "$

U0 Main() {
  AutoComplete;
  WinBorder;
  WinMax;
  DocCursor;
  DocClear;
  Fs->draw_it=&DrawIt;

  F64 frame_time_start;

  F64 dx;
  F64 dy;

  I64 ch,sc; // char, scan code

  F64 esc_timer_start=0;
  match.start_time=tS;

  // For setting bullet velocity
  F64 speed;
  F64 distance;

  while (TRUE) {
    // $TX+IV," NOTE! "$
    // Player position update code is in the draw loop.


    // $TX+IV," Exit on Esc "$
    // It also occurs on double left or right click,
    // which are synonymous with esc and shift-esc.
    // This is a TempleOS thing.

    if (ScanKey(&ch,&sc)) {
      switch (ch) {
	case 0:
	  switch (sc.u8[0]) {
	    case SC_CURSOR_LEFT:
	      ms.pos.x-=10;
	      break;
	    case SC_CURSOR_RIGHT:
	      ms.pos.x+=10;
	      break;
	    case SC_CURSOR_UP:
              ms.pos.y-=10;
	      break;
	    case SC_CURSOR_DOWN:
              ms.pos.y+=10;
	      break;
	  }
	  break;
	case '\n':
	  break; // Todo new match
	case CH_SHIFT_ESC:
	case CH_ESC:
	  goto main_loop_end;
        default: break;
      }
    }

    // $TX+IV," Update total match time + start frame time "$
    frame_time_start = tS;
    if (player.health > 0) {
      match.time = tS - match.start_time;
    }
    current_score.match_time = match.time;

    // $TX+IV," Fire towards player"$
    // Bullets are shot by all enemies simultaniously.
    for (i=0;i<ENEMY_NUM;i++) {
      if (frame % ENEMY_FIRE_COOLDOWN == 0 &&
          canv_y_start < enemies[i].y < canv_y_end) {


        bullets[bullet_count].x = enemies[i].x;
        bullets[bullet_count].y = enemies[i].y;

        if (bullet_count % match.big_bullet_interval == 0) {
          bullets[bullet_count].diameter = BULLET_DIAMETER*2.5;
          speed=1.3;
        } else {
          bullets[bullet_count].diameter = BULLET_DIAMETER;
          speed=1.5;
        }

        distance = Sqrt((player.x - enemies[i].x)`2 +
		(player.y - enemies[i].y)`2);

        bullets[bullet_count].vel_x = speed*((player.x-enemies[i].x)/distance);
        bullets[bullet_count].vel_y = speed*((player.y-enemies[i].y)/distance);
      
        // (Simple circular buffer, see init.)
        bullet_count = (bullet_count + 1) % BULLET_ARRAY_SIZE;
      }

      if (enemies[i].y > GR_HEIGHT+10) {

        // $TX+IV," Reset enemy if below screen "$
        enemies[i].x = RandRangeI64(canv_x_start,canv_x_end);
        enemies[i].y = RandRangeI64(-match.spawn_height,0);
      } else {

        // $TX+IV," Sway enemy (if onscreen) & move it downward "$
        if (enemies[i].y > -10) {
          enemies[i].x = Sin(enemies[i].y/40.0)*enemies[i].sway_multiplier \
		+enemies[i].original_x;
        }
        enemies[i].y+=ENEMY_DOWN_SPEED;
      }
    }

    for (i=0;i<BULLET_ARRAY_SIZE;i++) {

      // $TX+IV," Check collision with player "$
      // It's lenient and only checks half the player's radius.
      if (bullets[i].x > 0) {
        dx = bullets[i].x - player.x;
        dy = bullets[i].y - player.y;

        if (Sqrt(dx * dx + dy * dy) < (bullets[i].diameter + (PLAYER_RADIUS>>1)) &&
		player.invincibility_frames == 0) {
          ResetBullet(bullets,i);
          player.health--;
          player.invincibility_frames = 100;
          player.last_hit_time = match.time;
        }
      }

      if (bullets[i].x < canv_x_start-20 ||
          bullets[i].x > canv_x_end+20	 ||
          bullets[i].y < canv_y_start-20 ||
          bullets[i].y > canv_y_end+20) {
        // $TX+IV," Reset out-of-bounds bullets "$
        ResetBullet(bullets,i);
      } else {
        // $TX+IV," Move bullets by their velocity "$
        bullets[i].x += bullets[i].vel_x;
        bullets[i].y += bullets[i].vel_y;
      }
    }

    // $TX+IV," Decrement invincibility frames "$
    if (player.invincibility_frames != 0) {
      player.invincibility_frames--;
    }

    // $TX+IV," Reduce enemy spawn height "$
    // The spawn height refers to how high the
    // enemies can spawn above the playfield. The higher
    // it is, the less dense the enemy formations are.
    //
    // It is reduced to make gameplay harder as a match
    // goes on. To make the difficulty more 'dynamic' and
    // less 'brick wall', it will jump back up at random
    // points, if it's below the current 'tolerence'.

    match.spawn_height = ClampI64(match.spawn_height-1, 3000, 12000);

    if (match.spawn_height < match.spawn_tolerence
	&& RandRangeI64(-100,100)==0) {
      match.spawn_height += RandRangeI64(500,1000);
      match.spawn_tolerence -= 400;
    }

    // $TX+IV," Regen player health "$
    if ((player.health < 3) && (match.time - player.last_hit_time > REGEN_TIME)) {
      player.health++;
      // (Not technically hit, but regen is gradual)
      player.last_hit_time = match.time;
    }

    if (frame%1000==0)
      match.big_bullet_interval=ClampI64(match.big_bullet_interval-2,4,100);

    // $TX+IV," Sleep until next frame "$
    Sleep(FRAME_LENGTH - ToI64((tS - frame_time_start)*1000));
    frame++;
  }
  
  main_loop_end:


  // $TX+IV," Update score "$
  // Adds match's score to unused array cell and QSorts the
  // whole thing, storing top TOP_SCORES_NUM. See initialization.

  top_scores[TOP_SCORES_NUM].match_time = current_score.match_time;
  top_scores[TOP_SCORES_NUM].date = current_score.date;



  // $TX+IV," Put date for the new score "$
  Date2Struct(&ds,Now);

  U8 date_str[11];
  StrPrint(date_str,"%d-%02d-%02d",ds.year,ds.mon,ds.day_of_mon);
  StrCpy(current_score.date, date_str);


  // $TX+IV," Sort and write scores to registry "$
  QSort(top_scores,TOP_SCORES_NUM+1,sizeof(Score),&ScoreCompare);

  RegWrite("Rendello/Bull!ts", \
	"Score top_scores[11]={{%-5.1f,\"%s\"},{%-5.1f,\"%s\"},
	{%-5.1f,\"%s\"},{%-5.1f,\"%s\"},{%-5.1f,\"%s\"},{%-5.1f,\"%s\"},
	{%-5.1f,\"%s\"},{%-5.1f,\"%s\"},{%-5.1f,\"%s\"},{%-5.1f,\"%s\"},{0,0}};",
	top_scores[0].match_time,top_scores[0].date,
	top_scores[1].match_time,top_scores[1].date,
	top_scores[2].match_time,top_scores[2].date,
	top_scores[3].match_time,top_scores[3].date,
	top_scores[4].match_time,top_scores[4].date,
	top_scores[5].match_time,top_scores[5].date,
	top_scores[6].match_time,top_scores[6].date,
	top_scores[7].match_time,top_scores[7].date,
	top_scores[8].match_time,top_scores[8].date,
	top_scores[9].match_time,top_scores[9].date
  );

  DCFill(dc);
  DCDel(dc);

  #if (DRAW_JET)
    DCDel(dc_2);
  #endif

}

SettingsPush;
Main;
SettingsPop;
gr.fp_draw_ms=&DrawStdMs;


if (PROFILER) { DocMax; ProfRep; WinMax; }        â©             ª   ÷                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         	                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          	                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            Ôÿÿÿ    ôÿÿÿ                   åÿÿÿïÿÿÿ       ðÿÿÿ    ûÿÿÿìÿÿÿ        ûÿÿÿ       ìÿÿÿ        ûÿÿÿ    ûÿÿÿûÿÿÿ       ûÿÿÿ        çÿÿÿûÿÿÿ    þÿÿÿ        øÿÿÿ                      ùÿÿÿ   öÿÿÿ    èÿÿÿöÿÿÿ    ñÿÿÿ                       üÿÿÿüÿÿÿ         	            
                              	            
         0        
   0  	         0        
   0        	   0              	            
            	   
                                0            