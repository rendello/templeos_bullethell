
// Bullet
// By @Rendello_; June 2020
// For the Temple Operating System (TempleOS)
//
// This work has been placed in the public domain.
// If you modify and re-release it, I ask that you
// change the title, and provide credit to the original.
//
// Enjoy!


// Canvas
#define CANV_X_START	4
#define CANV_X_END	(GR_WIDTH-150)
#define CANV_Y_START	4
#define CANV_Y_END	(GR_HEIGHT-12)

#define LOGO_HEIGHT	150

#define ENEMY_NUM		level[0]
#define FRAME_DELAY		level[1]
#define FIRE_COOLDOWN		level[2]

#define MAX_SPAWN_HEIGHT	10000
#define MAX_BULLET_NUM		1000

// Game difficulties
#define EASY	0
#define NORMAL	1
#define HARD	2
#define MADNESS	3
#define HELLISH	4

I64 RandRange(I64 min=0, I64 max) {
  return Abs(RandI64 % (max+1 - min) + min);
}


I64 i;
I64 frame=0;
I64 bullet_count=0;

F64 match_start_time = tS;
F64 match_time;

I64 difficulty=EASY;

// (difficulty) level:
//   0: enemy number
//   1: game speed ie. time slept between frames
//   2: enemy fire cooldown
//   3: enemy sway toggle
switch (difficulty) {
  case EASY:	I64 level[4]={70,15,100,0}; break;
  case NORMAL:	I64 level[4]={80,12,90,0};  break;
  case HARD:	I64 level[4]={100,10,80,0}; break;
  case MADNESS: I64 level[4]={120,9,70,1};  break;
  case HELLISH:	I64 level[4]={300,8,40,1};  break;
}

// player:
//   0: x-position
//   1: y-position
I64 player_pos[2]={10,10};

// enemy:
//   0: x-position
//   1: y-position
I64 enemies[ENEMY_NUM][2];
for (i=0;i<ENEMY_NUM;i++) {
  enemies[i][0] = RandRange(CANV_X_START,CANV_X_END);
  enemies[i][1] = RandRange(,MAX_SPAWN_HEIGHT)-MAX_SPAWN_HEIGHT;
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

  DCFill(dc,LTCYAN);

  dc->color=BLUE;
  GrFillCircle(dc,player_pos[0],player_pos[1],,10);  
  for (i=0; i<ENEMY_NUM;i++) {
    dc->color=BLACK;
    GrFillCircle(dc,enemies[i][0],enemies[i][1],,20);
  }
  dc->color=RED;
  for (i=0;i<MAX_BULLET_NUM;i++) {
    GrFillCircle(dc,bullets[i][0],bullets[i][1],,10);
  }


  // Draw frame
  dc->color=LTPURPLE;
  GrRect(dc,0,0,CANV_X_END+1,CANV_Y_START); // Frame top.
  GrRect(dc,0,CANV_Y_END,CANV_X_END,GR_HEIGHT);	// Frame bottom.
  GrRect(dc,0,CANV_Y_START,CANV_X_START,CANV_Y_END); // Frame left.
  GrRect(dc,CANV_X_END,0,GR_WIDTH,GR_HEIGHT); // Sidebar (right).

  // Draw frame sheen.
  dc->color=WHITE;
  GrLine(dc,CANV_X_END,CANV_Y_START,CANV_X_END,CANV_Y_END);
  GrLine(dc,CANV_X_START,CANV_Y_END,CANV_X_END,CANV_Y_END);

  // Draw frame shadow.
  dc->color=BLACK;
  GrLine(dc,CANV_X_START-1,CANV_Y_START,CANV_X_START-1,CANV_Y_END);
  GrLine(dc,CANV_X_START,CANV_Y_START,CANV_X_END,CANV_Y_START);

  // Draw sidebar items 
  dc->color=BLACK;
  GrPrint(dc,CANV_X_END+10,LOGO_HEIGHT+8,"Time:%5.2f",match_time);
  GrPrint(dc,CANV_X_END+50,LOGO_HEIGHT+36,"Scores");
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
        enemies[i][0] = RandRange(,GR_WIDTH);
        enemies[i][1] = (RandRange(,MAX_SPAWN_HEIGHT/5)-MAX_SPAWN_HEIGHT/5)-200;
      } else {
        // Move enemy downward.
        enemies[i][1]++;
      }
    }

    for (i=0;i<MAX_BULLET_NUM;i++) {
      if (bullets[i][0] < CANV_X_START-20 ||
          bullets[i][0] > CANV_X_END+20	  ||
          bullets[i][1] < CANV_Y_START-20 ||
          bullets[i][1] > CANV_Y_END+20) {
        // Reset off-screen bullet.
        bullets[i][0]=-10;
        bullets[i][1]=0;
        bullets[i][2]=0;
        bullets[i][3]=0;
      } else {
        // Move bullet by its proper velocity.
        bullets[i][0] += bullets[i][2];
        bullets[i][1] += bullets[i][3];
      }
    }

    Sleep(FRAME_DELAY);
    frame++;
  }

  SettingsPop;
  DCFill;
  DCDel(dc);
}

Main;



