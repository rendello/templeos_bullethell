
$SP,"<1>",BI=1$


CDC *dc=DCAlias;

while (!(ms.lb || ms.rb)) {
  DCFill(dc);

  if (ms.pos.x > old_ms.pos.x) {
    dc->flags|=DCF_SYMMETRY|DCF_JUST_MIRROR;
    DCSymmetrySet(dc,ms.pos.x,ms.pos.y-1,ms.pos.x,ms.pos.y+1);
  } else if (ms.pos.x < old_ms.pos.x) {
    dc->flags&=~(DCF_SYMMETRY|DCF_JUST_MIRROR);
  }

  Sprite3(dc,ms.pos.x,ms.pos.y,0,$IB,"<1>",BI=1$);

  Refresh;
}

DCDel(dc);              #               