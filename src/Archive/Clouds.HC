

#define CLOUD_NUM	100
#define CLUSTER_NUM	10


I64 RandRangeI64(I64 min=0, I64 max) {
  // Fast biased integer multiplication method.
  // Described here:
  // $AN,"Efficiently Generating a Number in a Range",A="",HTML="http://www.pcg-random.org/posts/bounded-rands.html"$ (web link)

  return ((RandU32()(U64) * (max-min)) >> 32) + min;
}


I64 i;
CDC *dc = DCAlias;


class Cluster {
  I64 x_start;
  I64 x_end;
  I64 y_start;
  I64 y_end;
}

class Puff {
  I64 x;
  I64 y;
  I64 r;
};


Cluster clusters[CLUSTER_NUM];
Puff puffs[CLOUD_NUM];


for (i=0; i<CLUSTER_NUM; i++) {
  clusters[i].x_start = RandRangeI64(,GR_WIDTH);
  clusters[i].x_end = clusters[i].x_start + RandRangeI64(,500);
  clusters[i].y_start = RandRangeI64(,GR_HEIGHT);
  clusters[i].y_end = clusters[i].y_start + RandRangeI64(,10);
}



for (i=0; i<CLOUD_NUM; i++) {
  puffs[i].x = RandRangeI64(
    clusters[RandRangeI64(,CLUSTER_NUM)].x_start,
    clusters[RandRangeI64(,CLUSTER_NUM)].x_end
  );
  puffs[i].y = RandRangeI64(
    clusters[RandRangeI64(,CLUSTER_NUM)].y_start,
    clusters[RandRangeI64(,CLUSTER_NUM)].y_end
  );
  puffs[i].r = RandRangeI64(5,20);
}



SettingsPush;
WinMax;
WinBorder;
DocBorder;
while (!ScanChar && !ms.lb && !ms.rb) {
  DCFill(dc, LTBLUE);
  dc->color=WHITE;
  for (i=0; i<CLOUD_NUM; i++) {
    GrFillCircle(dc,puffs[i].x, puffs[i].y,, puffs[i].r*2);
    puffs[i].y+=1;
  }
  Refresh;
}
DCDel(dc);
SettingsPop;
DCFill;