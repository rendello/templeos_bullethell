


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

CBGR48 gr_palette_std[COLORS_NUM]={
0x000000000000,0x00000000AAAA,0x0000AAAA0000,0x0000AAAAAAAA,
0xAAAA00000000,0xAAAA0000AAAA,0xAAAA55550000,0xAAAAAAAAAAAA,
0x555555555555,0x55555555FFFF,0x5555FFFF5555,0x5555FFFFFFFF,
0xFFFF55555555,0xFFFF5555FFFF,0xFFFFFFFF5555,0xFFFFFFFFFFFF};




//I64 steps=400;
I64 i;

//CBGR48 colors[steps*2-2];

/*
InterpolateColors(&colors,steps,RGBToColor(255,0,0),
	RGBToColor(0,255,255),TRUE);
*/
//InterpolateColors(&colors,steps,0xff0033000000,
//	0xff00cc000000,TRUE);



// Palette swap data
I64 steps = 700;
CBGR48 bullet_colors[steps*2-2];
InterpolateColors(&bullet_colors,steps,0xff0033000000,0xff00cc000000,TRUE);




I64 f=0;
while (!ms.lb) {
  f+=1;
//  GrPaletteColorSet(WHITE,colors[f%(steps*2-2)]);
  GrPaletteColorSet(WHITE,bullet_colors[f%(steps*2-2)]);
  Sleep(1);
}






