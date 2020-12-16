


I64 RandRange(I64 min=0, I64 max) {
  return Abs(RandI64 % (max+1 - min) + min);
}


I64 i;
I64 j;

I64 y=GR_HEIGHT/2;

CDC *dc=DCAlias;

I64 line_width=4;
I64 inc_number;



for (i=-1000;i<0;i++) {
  for (j=0;j<GR_WIDTH;j+=line_width) {

    y = ClampI64(y+RandRange(,10)-5,0,GR_HEIGHT);

    dc->color=WHITE;
    GrRect(dc,j+i,0,line_width,y);

    dc->color=GREEN;
    GrRect(dc,j+i,y,line_width,ClampI64((GR_WIDTH-j)/30,2,200));
  }
}


while (!ms.lb) {
  Refresh;
  Sleep(10);
}
DCFill;