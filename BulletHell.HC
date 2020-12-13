
// $TX+IV,"       This Is Bull!ts       "$  ÛÛÛ   ÛÛÛ
//                               Û±±ÛÛ ÛÛÛÛÛ
// Bullet Hell game for TempleOS.Û±ÛÛÛÛÛÛÛÛÛ
// By Rendello, June 2020        ÛÛÛÛÛÛÛÛÛÛÛ  
//                               Û±ÛÛÛÛÛÛ±±Û  ±±
// This game is licensed CC-BY.   ÛÛÛÛÛÛ± ±± ±±±±
// If you modify and re-release    ÛÛÛÛÛ±±±±±±±±±
// it, please change the title      ÛÛÛÛÛ±±±±±±±
// and credit the original.          ÛÛÛ  ±±±±±
//                                    Û    ±±±
// Enjoy!                                   ±


#define DEBUG		TRUE
#define INVINCIBLE	TRUE


#define MAX_SPAWN_HEIGHT	-10000
#define BULLET_ARRAY_SIZE	1000
#define BULLET_RADIUS		5
#define PLAYER_RADIUS		10


// $TX+IV,"      Class definitions     "$

class GameMs {
  I64 x;
  I64 y;
  I64 old_x;
  I64 old_y;
  I64 delta_x;
  I64 delta_y;
}

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

  I64 start_time;
  I64 time;
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


// $TX+IV,"     Utility functions     "$

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


// $TX+IV,"     Globals     "$
// AFAIK, The only simple way to pass state to state to
// the draw callback is by having the state be global.

GameMs game_ms = {0,0,0,0,0,0};


// Palette swap data
I64 bullet_color_steps = 91;
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

// Inactive bullets are stored off-screen.
// Each fired bullet occupies a new cell of the array,
// looping to zero after BULLET_ARRAY_SIZE.
Bullet bullets[BULLET_ARRAY_SIZE];
for (i=0;i<BULLET_ARRAY_SIZE;i++) {
  bullets[i].x=-10;
  bullets[i].y=0;
  bullets[i].vel_x=0;
  bullets[i].vel_y=0;
}

I64 bullet_count;

I64 frame;

CTask *task=Fs;
CDC *dc=DCAlias;


// $TX+IV,"     Drawing callback     "$

U0 DrawIt(CTask *task, CDC *) {
  I64 i;

  DCFill;

  // $TX+IV," Palette-shift bullets "$
  // Bullets have two colors, one is always behind the other
  // by ~half the steps.

  GrPaletteColorSet(RED,bullet_colors[frame%bullet_color_num]);
  GrPaletteColorSet(LTRED,bullet_colors[Floor(frame/8+bullet_color_steps)%bullet_color_num]);

  // Enemies.
  for (i=0; i<match.enemy_num;i++) {
    dc->color=GREEN;
    GrFillCircle(dc,enemies[i].x,enemies[i].y,,20);
  }

  // $TX+UL,"Draw Player"$
  dc->color=BLUE;

  // Blink on invincibility frames (ie. player just hit)
  if (player.invincibility_frames !=0 &&
	player.invincibility_frames % 4 == 0) {
    dc->color=WHITE;
  }
  GrFillCircle(dc,player.x,player.y,,10);  
 
  for (i=0;i<BULLET_ARRAY_SIZE;i++) {
    // The bullets consist of two colored circles, with
    // two color variations. The colors don't strictly
    // matter, as the palette definition changes.

    if (i%2==0) {
      dc->color=RED;
    } else {
      dc->color=LTRED;
    }
    GrFillCircle(dc,bullets[i].x,bullets[i].y,,BULLET_RADIUS<<1);
    if (i%2==0) {
      dc->color=LTRED;
    } else {
      dc->color=RED;
    }
    GrFillCircle(dc,bullets[i].x,bullets[i].y,,BULLET_RADIUS+1);
  }


  // Draw frame
  dc->color=LTPURPLE;
  GrRect(dc,0,0,canv_x_end+1,canv_y_start); // Frame top.
  GrRect(dc,0,canv_y_end,canv_x_end,GR_HEIGHT);	// Frame bottom.
  GrRect(dc,0,canv_y_start,canv_x_start,canv_y_end); // Frame left.
  GrRect(dc,canv_x_end,0,GR_WIDTH,GR_HEIGHT); // Sidebar (right).

  // Draw frame sheen.
  dc->color=WHITE;
  GrLine(dc,canv_x_end,canv_y_start,canv_x_end,canv_y_end); // Right.
  GrLine(dc,canv_x_start,canv_y_end,canv_x_end,canv_y_end); // Bottom.

  // Draw frame shadow.
  dc->color=BLACK;
  GrLine(dc,canv_x_start-1,canv_y_start,canv_x_start-1,canv_y_end); // Left.
  GrLine(dc,canv_x_start,canv_y_start,canv_x_end,canv_y_start); // Top.

  // Draw sidebar items 
  dc->color=BLACK;
  GrPrint(dc,canv_x_end+10,logo_height+8,"Time:%5.2f",match.time);
  GrPrint(dc,canv_x_end+50,logo_height+36,"Scores");

  if (DEBUG) {
    GrPrint(dc,canv_x_end+50,logo_height+56,"Spawn height: %d",match.spawn_height);
    GrPrint(dc,canv_x_end+50,logo_height+76,"Health: %d",player.health);
    GrPrint(dc,canv_x_end+50,logo_height+96,"Inv frames: %d",player.invincibility_frames);
  }
}


///I64 steps = 21;
///CBGR48 bullet_colors[steps*2-2];
///InterpolateColors(&bullet_colors,steps,0xff0033000000,0xff00cc000000,TRUE);



U0 Main() {
  SettingsPush;
  AutoComplete;
  WinBorder;
  WinMax;
  DocCursor;
  DocClear;
  Fs->draw_it=&DrawIt;

  F64 frame_time_start;

  while (!ms.lb) {
///  GrPaletteColorSet(WHITE,bullet_colors[Floor(frame/8)%(steps*2-2)]);

    // $TX+IV," Update total match time + start frame time "$
    frame_time_start = tS;
    match.time = tS - match.start_time;

    // $TX+IV," Update relative mouse coordinates & speed "$
    game_ms.old_x = game_ms.x;
    game_ms.old_y = game_ms.y;

    game_ms.x = ms.pos.x - (task->win_left*FONT_HEIGHT);
    game_ms.y = ms.pos.y - (task->win_top*FONT_HEIGHT);

    game_ms.delta_x = game_ms.x - game_ms.old_x;
    game_ms.delta_y = game_ms.y - game_ms.old_y;

    // $TX+IV," Update player position "$
    player.x = ClampI64(game_ms.x,canv_x_start,canv_x_end);
    player.y = ClampI64(game_ms.y,canv_y_start,canv_y_end);

    for (i=0;i<match.enemy_num;i++) {
      if (frame % match.enemy_fire_cooldown == 0 &&
          canv_y_start < enemies[i].y < canv_y_end) {

        // $TX+IV," Fire towards player"$
        // Bullets are shot by all enemies simultaniously.
        // The algorithm is funky but accurate. It was
        // definitely a bug before it was a feature.

        F64 delta_x = enemies[i].x - player.x;
        F64 delta_y = enemies[i].y - player.y;
        F64 smaller_abs;
        F64 larger_abs;
        F64 u;

        if (Abs(delta_x) < Abs(delta_y)) {
          smaller_abs = -Abs(delta_x);
          larger_abs = -Abs(delta_y);
        } else {
          smaller_abs = -Abs(delta_y);
          larger_abs = -Abs(delta_x);
        }
        u=larger_abs/smaller_abs;

        bullet_count = (bullet_count + 1) % BULLET_ARRAY_SIZE;

        bullets[bullet_count].x = enemies[i].x;
        bullets[bullet_count].y = enemies[i].y;

        bullets[bullet_count].vel_x = (delta_x(F64)/smaller_abs)/u;
        bullets[bullet_count].vel_y = (delta_y(F64)/smaller_abs)/u;
      }

      if (enemies[i].y > GR_HEIGHT+10) {
        // $TX+IV," Reset enemy if below screen "$
        enemies[i].x = RandRangeI64(canv_x_start,canv_x_end);
        enemies[i].y = RandRangeI64(match.spawn_height,0);
      } else {
        // $TX+IV," Move enemy downward & sway. "$
        enemies[i].y++;

//        enemies[i].x = Sin(
//		enemies[i].y/(enemies[i].sway_multiplier(F64)))*10+enemies[i].original_x;
      }
    }

    for (i=0;i<BULLET_ARRAY_SIZE;i++) {

      // $TX+IV," Check collision with player. "$
      // It's lenient and only checks half the player's radius.
      if (bullets[i].x > 0) {
        I64 dx = bullets[i].x - player.x;
        I64 dy = bullets[i].y - player.y;
        if (Sqrt(dx * dx + dy * dy) < (BULLET_RADIUS + (PLAYER_RADIUS>>1)) &&
		player.invincibility_frames == 0) {
          player.health--;
          player.invincibility_frames = 100;
        }
      }

      if (bullets[i].x < canv_x_start-20 ||
          bullets[i].x > canv_x_end+20	 ||
          bullets[i].y < canv_y_start-20 ||
          bullets[i].y > canv_y_end+20) {
        // $TX+IV," Reset out-of-bounds bullets. "$
        bullets[i].x=-10;
        bullets[i].y=0;
        bullets[i].vel_x=0;
        bullets[i].vel_y=0;
      } else {
        // $TX+IV," Move bullets by their velocity. "$
        bullets[i].x += bullets[i].vel_x;
        bullets[i].y += bullets[i].vel_y;
      }
    }


    // (Keep frame rate independent. Bit shift and I64 conversion
    //  change from F64 sec to I64 millisec that Sleep needs.)
    //Sleep((match.frame_length - (tS - frame_time_start)<<2)(I64));
    Sleep(10);
    frame++;
    if (player.invincibility_frames != 0)
      player.invincibility_frames--;
  }

  SettingsPop;
  DCFill;
  DCDel(dc);
}

Main;
