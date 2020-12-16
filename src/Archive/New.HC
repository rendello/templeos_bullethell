
// $TX+IV,"       This Is Bull!ts       "$   ÛÛÛ   ÛÛÛ
//                                Û±±ÛÛ ÛÛÛÛÛ
// Bullet Hell game for TempleOS. Û±ÛÛÛÛÛÛÛÛÛ
// By Rendello, June 2020.        ÛÛÛÛÛÛÛÛÛÛÛ  
//                                Û±ÛÛÛÛÛÛ±±Û  ±±
// Uses BSD-3 licence, see readme. ÛÛÛÛÛÛ± ±± ±±±±
// If you modify and re-release     ÛÛÛÛÛ±±±±±±±±±
// it, please change the title       ÛÛÛÛÛ±±±±±±±
// and credit the original.           ÛÛÛ  ±±±±±
//                                     Û    ±±±
// Enjoy!                                    ±


#define DEBUG		TRUE
#define INVINCIBLE	TRUE


#define MAX_SPAWN_HEIGHT	-10000
#define BULLET_ARRAY_SIZE	1000
#define BULLET_RADIUS		5
#define PLAYER_RADIUS		10
#define TOP_SCORES_NUM		10



U8 *default_score_str = "Score top_scores[10] = {
  {0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0}
};\n";


RegDft("TempleOS/Rendello/Bull!ts",default_score_str);
//RegExe("TempleOS/Rendello/Bull!ts");


// $TX+IV,"          Class definitions          "$

class GameMs {
  I64 x;
  I64 y;
  I64 old_x;
  I64 old_y;
  I64 delta_x;
  I64 delta_y;
};

class Difficulty {
  I64 enemy_num;
  I64 frame_delay;
  I64 enemy_fire_cooldown;
  Bool enemy_sway;
};

class Match {
  I64 spawn_height;
  I64 enemy_num;
  I64 enemy_fire_cooldown;
  I64 frame_length;

  I64 enemy_sway_lower_bound;
  I64 enemy_sway_upper_bound;

  F64 start_time;
  F64 time;
};

class Score {
  F64 match_time;
  U8 date[11];	//YYYY-MM-DD
};

class Player {
  I64 x;
  I64 y;
  I64 health;
  I64 invincibility_frames;
};

class Enemy {
  I64 x;
  I64 y;
  I64 original_x;
  I64 sway_multiplier;
};

class Bullet {
  F64 x;
  F64 y;
  F64 vel_x;
  F64 vel_y;
};


// $TX+IV,"          Utility functions          "$

I64 RandRangeI64(I64 min=0, I64 max) {
  // Fast biased integer multiplication method.
  // Described here:
  // $AN,"Efficiently Generating a Number in a Range",A="",HTML="http://www.pcg-random.org/posts/bounded-rands.html"$ (web link)

  return ((RandU32()(U64) * (max-min)) >> 32) + min;
}


CBGR48 RGBToColor(I16 red, I16 green, I16 blue) {
  // Standard 0-255 RGB values to TempleOS color value.

  // 0xRRPPGGPPBBPP
  // Where RGB and P are red, green, blue, and pad.

  CBGR48 color_val=red << 16;
  color_val=(color_val | green) << 16;
  color_val=(color_val | blue) << 8;

  return color_val;
}


U0 ColorToRGB(I64 *buf,CBGR48 color) {
  // Fills three-value buffer with R,G, and B vals
  // from 0-255.

  buf[0] = color >> 40 & 0xFF;
  buf[1] = color >> 24 & 0xFF;
  buf[2] = color >> 8  & 0xFF;
}


U0 InterpolateColors(CBGR48 *buf,I64 steps,CBGR48 color_1,
	CBGR48 color_2,	Bool walk_back=FALSE) {
  // Fills a buffer by linearly interpolating two colors
  // through n steps in RGB space.
  //
  // Generally, steps must equal the size of the buffer.
  //
  // If walk_back is enabled, it will step back to original color,
  // in which case buffer must be of size (steps*2)-2

  I64 i;

  I64 color_1_rgb[3];
  I64 color_2_rgb[3];

  // (Fill RGB buffers)
  ColorToRGB(&color_1_rgb,color_1);
  ColorToRGB(&color_2_rgb,color_2);

  for (i=0;i<steps;i++) {
    buf[i] = RGBToColor(
      (color_2_rgb[0] - color_1_rgb[0]) * i / steps + color_1_rgb[0],
      (color_2_rgb[1] - color_1_rgb[1]) * i / steps + color_1_rgb[1],
      (color_2_rgb[2] - color_1_rgb[2]) * i / steps + color_1_rgb[2]
    );
  }
  if (walk_back) {
    for (i=0;i<steps-2;i++) {
      buf[steps+i] = buf[steps-i-2];
    }
  }
}

U0 DotMatrix(CDC *dc=gr.dc,I64 x, I64 y, I64 dot_diameter,
	I64 dot_spacing, U8 *string) {

  I64 i;
  I64 j;
  I64 k;

  I64 g; // matrix graphics data


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
      default:  g=0b00000000000000000000000000000000000;
    }
    for (j=6; j>=0; j--) {
      for (k=4; k>=0; k--) {
        if ((g >> ((j*5)+k))&1) {
          GrFillCircle(dc,(x-k*dot_spacing)+(i*dot_spacing*6), \
		y-j*dot_spacing,,dot_diameter);
        }
      }
    }
  }
}


I64 ScoreCompare(Score *s1, Score *s2) {
  // For QSort.

  if (s1->match_time < s2->match_time)
    return 1;
  else if (s1->match_time == s2->match_time)
    return 0;
  else
    return -1;
}


// $TX+IV,"          Globals          "$
// AFAIK, The only simple way to pass state to state to
// the draw callback is by having the state be global.

GameMs game_ms = {0,0,0,0,0,0};

U8 scoreboard_string[6];

Difficulty difficulties[5] = {
  {70,13,100,5},	// Easy.
  {80,12,90,6},		// Medium.
  {100,10,80,9},	// Hard.
  {120,9,70,15},	// Chaos.
  {300,8,30,25}		// Mayhem.
};

// Palette swap data
I64 bullet_color_steps = 81;
I64 bullet_color_num = (bullet_color_steps*2)-2;
CBGR48 bullet_colors[bullet_color_num];

InterpolateColors(&bullet_colors,bullet_color_steps,0xff0033000000,
	0xff00cc000000,TRUE);


I64 i;

// $TX+UL,"UI dimensions"$
I64 canv_x_start = 4;
I64 canv_x_end = GR_WIDTH-175;
I64 canv_x_mid = (canv_x_end-canv_x_start)/2;
I64 canv_y_start = 4;
I64 canv_y_end = GR_HEIGHT-12;
I64 canv_y_mid = (canv_x_end-canv_x_start)/2;
I64 logo_height = 175;

Match match = {MAX_SPAWN_HEIGHT,100,100,10,10,15,tS,tS};

Player player = {100,100,3,0};


// $TX+IV," Initialize enemies "$
I64 enemy_num = 100; 
Enemy enemies[enemy_num];
enemies[0].x=1;

for (i=0;i<enemy_num;i++) {
  enemies[i].x = RandRangeI64(canv_x_start,canv_x_end);
  enemies[i].y = RandRangeI64(MAX_SPAWN_HEIGHT,0);
  enemies[i].original_x = enemies[i].x;
  enemies[i].sway_multiplier = RandRangeI64(
	match.enemy_sway_lower_bound, match.enemy_sway_upper_bound);
}


// $TX+IV," Initialize bullets "$
// Inactive bullets are stored off-screen.
// Each fired bullet increases the bullet_count
// and occupies its index in the array. bullet_count
// loops back to 0 after hitting BULLET_ARRAY_SIZE.

I64 bullet_count;
Bullet bullets[BULLET_ARRAY_SIZE];
for (i=0;i<BULLET_ARRAY_SIZE;i++) {
  bullets[i].x=-10;
  bullets[i].y=0;
  bullets[i].vel_x=0;
  bullets[i].vel_y=0;
}


// $TX+IV," Initialize top scores "$
// The top_scores array is of size TOP_SCORES_NUM + 1
// as at the end of a match, the current score is
// appended and the array is once again QSorted.
// The new top ten scores are stored to the save file.

CDateStruct ds;
Score current_score={match.time,"2018-01-01"};
Score top_scores[TOP_SCORES_NUM];
for (i=0;i<TOP_SCORES_NUM;i++) {
  Date2Struct($ER$TX+IV,"          Drawing callback          "$ER$TX+IV," Draw enemies "$ER$TX+IV," Draw player "$ER$TX+IV," Palette-shift bullets "$ER$TX+IV," Draw bullet "$ER$TX+IV," Draw frame "$ER$TX+IV," Draw frame sheen "$ER$TX+IV," Draw frame shadow "$ER$TX+IV," Draw dot-matrix timer "$ER$TX+IV," Draw sidebar items "$ER$TX+IV," Draw scoreboard with current score "$ER$TX+IV," Update total match time + start frame time "$ER$TX+IV," Update relative mouse coordinates & speed "$ER$TX+IV," Update player position "$ER$TX+IV," Fire towards player"$ER$TX+IV," Reset enemy if below screen "$ER$TX+IV," Sway enemy & move it downward "$ER$TX+IV," Check collision with player "$ER$TX+IV," Reset out-of-bounds bullets "$ER$TX+IV," Move bullets by their velocity "$ER$TX+IV," Update score "$ER$TX+IV," Overwrite scores in registry "