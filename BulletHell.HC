
// Bullet
// By @Rendello_; June 2020
// For the Temple Operating System (TempleOS)
//
// This work has been placed in the public domain.
// If you modify and re-release it, I ask that you
// change the title, and provide credit to the original.
//
// Enjoy!


#define ENEMY_NUM 100
#define MAX_SPAWN_HEIGHT 10000
#define MAX_BULLET_NUM 1000


I64 RandRange(I64 min=0, I64 max) {
  return Abs(RandI64 % (max+1 - min) + min);
}


I64 i;
I64 frame=0;
I64 bullet_count=0;
I64 player_pos[2]={10,10};

F64 match_start_time = tS;
F64 match_time;

// enemy:
//   0: x-position,
//   1: y-position,
I64 enemies[ENEMY_NUM][2];
for (i=0;i<ENEMY_NUM;i++) {
  enemies[i][0] = RandRange(,GR_WIDTH);
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

  DCFill;

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

  GrPrint(dc,10,5+FONT_HEIGHT,"%3.2f",match_time);
}


U0 Main() {
  SettingsPush;
  AutoComplete;
  WinBorder;
  WinMax;
  DocCursor;
  DocClear;
  Fs->draw_it=&DrawIt;


  while (!ms.lb) {
    match_time = tS - match_start_time;

    player_pos[0] = ms.pos.x;
    player_pos[1] = ms.pos.y;

    for (i=0;i<ENEMY_NUM;i++) {
      if (frame%80==0 &&
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
      if (-20 > bullets[i][0] > GR_WIDTH+10 ||
          -20 > bullets[i][1] > GR_HEIGHT+10) {
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

    Sleep(10);
    frame++;
  }

  SettingsPop;
  DCFill;
  DCDel(dc);
}

Main;



