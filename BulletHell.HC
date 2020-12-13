
// This is Bull!ts
// By @Rendello_; June 2020
// For the Temple Operating System (TempleOS)
//
// This work has been placed in the public domain.
// If you modify and re-release it, I ask that you
// change the title, and give credit to the original.
//
// Enjoy!


// Canvas
#define CANV_X_START	4
#define CANV_X_END	(GR_WIDTH-175)
#define CANV_Y_START	4
#define CANV_Y_END	(GR_HEIGHT-12)

#define CANV_X_MID	((CANV_X_END-CANV_X_START)/2)
#define CANV_Y_MID	((CANV_Y_END-CANV_Y_START)/2)


#define LOGO_HEIGHT	175

#define ENEMY_NUM	level[0]
#define FRAME_DELAY	level[1]
#define FIRE_COOLDOWN	level[2]
#define ENEMY_SWAY	level[3]

#define BULLET_RADIUS	5
#define PLAYER_RADIUS	10


#define MAX_SPAWN_HEIGHT	10000
#define MAX_BULLET_NUM		1000

#define BULLET_COLORS_NUM	22
#define WATER_COLORS_NUM	22

// Game difficulties
#define EASY	0
#define NORMAL	1
#define HARD	2
#define CHAOS	3
#define MAYHEM	4

I64 RandRange(I64 min=0, I64 max) {
  return Abs(RandI64 % (max+1 - min) + min);
}

Bool DEBUG=TRUE;

I64 i;
I64 frame=0;
I64 bullet_count=0;
Bool game_over=FALSE;

F64 match_start_time = tS;
F64 match_time;
F64 total_match_time;

I64 difficulty=CHAOS;


// The max spawn height is divided by larger
// numbers as the game progresses, compressing more
// enemies onto the screen at once.
I64 spawn_height_divisor=1;

// The two colors used for bullets will rapidly
// shift place in the palette.
static I64 bullet_colors[BULLET_COLORS_NUM]={
  0xff0033000000,0xff0041000000,0xff004f000000,0xff005d000000,
  0xff006b000000,0xff0079000000,0xff0086000000,0xff0094000000,
  0xff00a2000000,0xff00b0000000,0xff00be000000,0xff00cc000000,
  0xff00be000000,0xff00b0000000,0xff00a2000000,0xff0094000000,
  0xff0086000000,0xff0079000000,0xff006b000000,0xff005d000000,
  0xff004f000000,0xff0041000000
};

static I64 water_colors[WATER_COLORS_NUM]={
  0x00000000cc00,0x05000900d100,0x09001300d500,0x0e001c00da00,
  0x13002500df00,0x17002e00e300,0x1c003800e800,0x20004100ec00,
  0x25004a00f100,0x2a005300f600,0x2e005d00fa00,0x33006600ff00,
  0x2e005d00fa00,0x2a005300f600,0x25004a00f100,0x20004100ec00,
  0x1c003800e800,0x17002e00e300,0x13002500df00,0x0e001c00da00,
  0x09001300d500,0x05000900d100
};


// (difficulty) level:
//   0: enemy number
//   1: game speed ie. time slept between frames
//   2: enemy fire cooldown
//   3: enemy sway toggle
I64 level[4];
switch (difficulty) {
  case EASY:
    level[0]=70;
    level[1]=13;
    level[2]=100;
    level[3]=0;
    break;
  case NORMAL:
    level[0]=80;
    level[1]=12;
    level[2]=90;
    level[3]=0;
    break;
  case HARD:
    level[0]=100;
    level[1]=10;
    level[2]=80;
    level[3]=0;
    break;
  case CHAOS:
    level[0]=120;
    level[1]=9;
    level[2]=70;
    level[3]=1;
    break;
  case MAYHEM:
    level[0]=300;
    level[1]=8;
    level[2]=30;
    level[3]=1;
    break;
}

// player:
//   0: x-position
//   1: y-position
I64 player_pos[2]={10,10};

// enemy:
//   0: x-position
//   1: y-position
//   2: original x-position (for swaying enemies)
I64 enemies[ENEMY_NUM][3];
for (i=0;i<ENEMY_NUM;i++) {
  enemies[i][0] = RandRange(CANV_X_START,CANV_X_END);
  enemies[i][1] = RandRange(,MAX_SPAWN_HEIGHT)-MAX_SPAWN_HEIGHT;
  enemies[i][2] = enemies[i][0];
}

// bullet:
//   0: x-position
//   1: y-position
//   2: change in x per-frame
//   3: change in y per-frame
//
// Each new bullet occupies a new cell of the array,
// until it reaches cell MAX_BULLET_NUM, then it loops
// around to  zero, since those bullets should be off-screen
// long before then.

F64 bullets[MAX_BULLET_NUM][4];
for (i=0;i<MAX_BULLET_NUM;i++) {
  bullets[i][0]=-10;
  bullets[i][1]=0;
  bullets[i][2]=0;
  bullets[i][3]=0;
}


CDC *dc=DCAlias;


U0 DrawIt(CTask *task, CDC *) {
  I64 i;

/*
  // EYE OF THE GUARDIAN
  DCFill(dc,DKGRAY);
  for (i=CANV_X_END;i>0;i-=6) {
    dc->color=LTRED+(i&2);
    GrFillCircle(
      dc,
      Sin(tS/3)*(i&15)+CANV_X_MID,
      Sin(tS/4)*(i&15)+CANV_Y_MID,
      ,
      i
     );
  }
*/
///*
  // Palette shift water
  GrPaletteColorSet(BLUE,water_colors[ClampI64(Floor(match_time/2),0,WATER_COLORS_NUM/2)]);

  DCFill(dc,BLACK);

  // Rising sun.
  dc->color=YELLOW;
  GrFillCircle(dc,CANV_X_MID,510-(match_time/2)`2,,200);


  // Planet.
  dc->color=BLUE;
  GrFillCircle(dc,CANV_X_MID,CANV_Y_END*3+match_time,,2000);
//*/

  // Player.
  dc->color=BLUE;
  GrFillCircle(dc,player_pos[0],player_pos[1],,10);  

  // Enemies.
  for (i=0; i<ENEMY_NUM;i++) {
    dc->color=GREEN;
    GrFillCircle(dc,enemies[i][0],enemies[i][1],,20);
  }


  // Palette-shifts the bullet colors.
  GrPaletteColorSet(RED,bullet_colors[Floor(frame/8)%BULLET_COLORS_NUM]);
  GrPaletteColorSet(LTRED,bullet_colors[Floor(frame/8+7)%BULLET_COLORS_NUM]);


  for (i=0;i<MAX_BULLET_NUM;i++) {
    // The bullets consist of two colored circles, with
    // two color variations. The colors don't strictly
    // matter, as the palette definition changes.

    if (i%2==0) {
      dc->color=RED;
    } else {
      dc->color=LTRED;
    }
    GrFillCircle(dc,bullets[i][0],bullets[i][1],,BULLET_RADIUS<<1);
    if (i%2==0) {
      dc->color=LTRED;
    } else {
      dc->color=RED;
    }
    GrFillCircle(dc,bullets[i][0],bullets[i][1],,BULLET_RADIUS+1);
  }


  // Draw frame
  dc->color=LTPURPLE;
  GrRect(dc,0,0,CANV_X_END+1,CANV_Y_START); // Frame top.
  GrRect(dc,0,CANV_Y_END,CANV_X_END,GR_HEIGHT);	// Frame bottom.
  GrRect(dc,0,CANV_Y_START,CANV_X_START,CANV_Y_END); // Frame left.
  GrRect(dc,CANV_X_END,0,GR_WIDTH,GR_HEIGHT); // Sidebar (right).

  // Draw frame sheen.
  dc->color=WHITE;
  GrLine(dc,CANV_X_END,CANV_Y_START,CANV_X_END,CANV_Y_END); // Right.
  GrLine(dc,CANV_X_START,CANV_Y_END,CANV_X_END,CANV_Y_END); // Bottom.

  // Draw frame shadow.
  dc->color=BLACK;
  GrLine(dc,CANV_X_START-1,CANV_Y_START,CANV_X_START-1,CANV_Y_END); // Left.
  GrLine(dc,CANV_X_START,CANV_Y_START,CANV_X_END,CANV_Y_START); // Top.

  // Draw sidebar items 
  dc->color=BLACK;
  GrPrint(dc,CANV_X_END+10,LOGO_HEIGHT+8,"Time:%5.2f",match_time);
  GrPrint(dc,CANV_X_END+50,LOGO_HEIGHT+36,"Scores");
  if (DEBUG) {
    GrPrint(dc,CANV_X_END+50,LOGO_HEIGHT+56,"Divisor: %d",spawn_height_divisor);
    GrPrint(dc,CANV_X_END+50,LOGO_HEIGHT+76,"Dead: %d",game_over);

  }
}


U0 Main() {
  SettingsPush;
  AutoComplete;
  WinBorder;
  WinMax;
  DocCursor;
  DocClear;
  Fs->draw_it=&DrawIt;


  while (!ms.lb) {
    match_time = tS - match_start_time;

    player_pos[0] = ClampI64(ms.pos.x,CANV_X_START,CANV_X_END);
    player_pos[1] = ClampI64(ms.pos.y,CANV_Y_START,CANV_Y_END);

    for (i=0;i<ENEMY_NUM;i++) {
      if (frame%FIRE_COOLDOWN==0 &&
          20 < enemies[i][1] < GR_HEIGHT) {
        // Bullets are shot by all enemies simultaniously.
        // The bullets point towards the player's position
        // at the time of firing.  

        F64 delta_x = enemies[i][0] - player_pos[0];
        F64 delta_y = enemies[i][1] - player_pos[1];
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

        bullet_count = (bullet_count + 1) % MAX_BULLET_NUM;

        bullets[bullet_count][0] = enemies[i][0];
        bullets[bullet_count][1] = enemies[i][1];

        bullets[bullet_count][2] = (delta_x(F64)/smaller_abs)/u;
        bullets[bullet_count][3] = (delta_y(F64)/smaller_abs)/u;
      }

      if (enemies[i][1] > GR_HEIGHT+10) {
        // Reset enemy if below screen.
        enemies[i][0] = RandRange(CANV_X_START,CANV_X_END);
        enemies[i][1] = \
          (RandRange(,MAX_SPAWN_HEIGHT/spawn_height_divisor) \
          -MAX_SPAWN_HEIGHT/spawn_height_divisor)-200;
      } else {
        // Move enemy downward.
        enemies[i][1]++;

        // Sway enemies. They always sway, but much moreso
        // on later stages.
        if (ENEMY_SWAY) {
          enemies[i][0] = Sin(enemies[i][1]/40.0)*20+enemies[i][2];
        } else {
          enemies[i][0] = Sin(enemies[i][1]/40.0)*10+enemies[i][2];
        }
      }
    }

    for (i=0;i<MAX_BULLET_NUM;i++) {

      // Check collision with player.
      // It's lenient and only checks half the player's radius.
      I64 dx = bullets[i][0] - player_pos[0];
      I64 dy = bullets[i][1] - player_pos[1];
      if (Sqrt(dx * dx + dy * dy) < (BULLET_RADIUS + (PLAYER_RADIUS>>1)))
        game_over = TRUE;

      // Move bullets or reset them if out-of-bounds.
      if (bullets[i][0] < CANV_X_START-20 ||
          bullets[i][0] > CANV_X_END+20	  ||
          bullets[i][1] < CANV_Y_START-20 ||
          bullets[i][1] > CANV_Y_END+20) {
        bullets[i][0]=-10;
        bullets[i][1]=0;
        bullets[i][2]=0;
        bullets[i][3]=0;
      } else {
        bullets[i][0] += bullets[i][2];
        bullets[i][1] += bullets[i][3];
      }
    }

    // See spawn_height_divisor declaration.
    // Tying gameplay to framerate is considered very
    // good practice.
    if (frame != 0 && frame % 2500 == 0) {
      spawn_height_divisor++;
    }

    Sleep(FRAME_DELAY);
    frame++;
  }

  SettingsPop;
  DCFill;
  DCDel(dc);
}

Main;



