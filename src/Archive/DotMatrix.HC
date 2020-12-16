


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


CDC *dc=DCAlias;


while (!ms.rb) {
  DCFill;


  U8 time_str[6]; // buffer
  // (Separate the float into chars)
  //StrPrint(time_str,"HELLO! %.1f",tS);

  DotMatrix(dc,ms.pos.x,ms.pos.y,ms.pos.y/15,ms.pos.x/15,"STREAMSTARTINGSOON");
  Refresh;
}
DCFill;
