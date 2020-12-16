

#define MAX_BUTTON_NUM	100


CDC *dc=DCAlias;

class MouseRelPos {
  I64 x;
  I64 y;
};


class Button {
  I16 x;
  I16 y;
  I16 width;
  I16 height;
  I8 text_color;
  I8 bg_color;
  I8 border_width;
  U8 string[100];
  Bool hovered;
  Bool clicked;
};


U0 border_draw(CDC *dc, I64 x, I64 y, I64 width, I64 height,
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

U0 button_draw(CDC *dc, Button *b) {
  I64 i;
  I64 light_color=WHITE;
  I64 shadow_color=DKGRAY;
  I64 swap;

  // Swap shadow and light sheen for clicked effect.
  if (b->clicked) {
    swap = light_color;
    light_color=shadow_color;
    shadow_color=swap;
  }

  dc->color = b->bg_color;

  // Draw button body.
  GrRect(
    dc,
    b->x,
    b->y,
    b->width,
    b->height
  );

  // Draw border.
  // It appears to angle inward, like an old keycap.
  // Some of the border appears in light, some in shadow.
  dc->color = CYAN;

  // (The border sides are drawn as simple rectangles)

  // Left.
  dc->color = light_color;
  GrRect(
    dc,
    b->x,
    b->y,
    b->border_width,
    b->height
  );

  // Right.
  dc->color = shadow_color;
  GrRect(
    dc,
    b->x + b->width - b->border_width,
    b->y,
    b->border_width,
    b->height
  );

  // (The top and bottom are drawn as angling lines)
  for (i=0; i<b->border_width;i++) {
    // Top.
    dc->color = light_color;
    GrLine(
      dc,
      b->x + i,
      b->y + (i-1),
      b->x+b->width - (i+1),
      b->y + (i-1)
    );

    // Bottom.
    dc->color = shadow_color;
    GrLine(
      dc,
      b->x + i,
      b->y + b->height - (i+1),
      b->x+b->width - (i+1),
      b->y + b->height - (i+1)
    );
  }

  // Draw centered text.
  dc->color = b->text_color;
  GrPrint(
    dc,
    b->x+(b->width-StrLen(b->string)<<3)>>1,
    b->y+b->height>>1-4,
    b->string
  );
}

U0 button_update(Button *b, CTask *task=NULL, MouseRelPos *ms_rel_pos) {
  if (!task) task=Fs;

  if (ms_rel_pos->x > b->x &&
      ms_rel_pos->y > b->y &&
      ms_rel_pos->x < b->x + b->width &&
      ms_rel_pos->y < b->y + b->height
  ) {

    b->hovered=TRUE;

    if (ms.lb) {
      b->clicked=TRUE;
    } else {
      b->clicked=FALSE;
    }
  } else {
    b->hovered=FALSE;
  }
}

Button buttons[4] = {
  {10,10,150,30,BLACK,LTGRAY,2,"Resume",FALSE,FALSE}
  {10,50,150,30,BLACK,LTGRAY,1,"Options",FALSE,FALSE}
  {10,81,150,30,BLACK,LTGRAY,1,"Difficulty",FALSE,FALSE}
  {10,112,150,30,BLACK,LTGRAY,1,"Controls",FALSE,FALSE}
};



I64 i;

MouseRelPos ms_rel_pos = {0,0};

WinMax;

//WinBorder;

CTask *task=Fs;

while (!ms.rb) {
  ms_rel_pos.x = ms.pos.x - (task->win_left*FONT_HEIGHT);
  ms_rel_pos.y = ms.pos.y - (task->win_top*FONT_HEIGHT);


  DCFill;
  GrPrint(,300,50,"%d",task->win_top);

  DCFill(dc,GREEN);

  for (i=0;i<4;i++) {
    button_update(&buttons[i],,&ms_rel_pos);
    button_draw(dc, &buttons[i]);
  }

  dc->color=RED;
  GrCircle(dc,ms_rel_pos.x,ms_rel_pos.y,10);


  border_draw(dc, 200, 75, 100, 50, 5);

  Refresh;
}

DCFill;
