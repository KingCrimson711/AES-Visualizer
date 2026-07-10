// Code your design here
// Code your design here
// AES Encryption/Decryption implementation in Verilog
// Matches the given C++ code exactly, using fixed plaintext and key.
// All operations are behavioral; simulation only.

module AES;

  // State matrix: 4x4 bytes (row, column)
  reg [7:0] state [0:3][0:3];
  // Round keys: [round][row][col]
  reg [7:0] keymap [0:10][0:3][0:3];

  // S‑box and inverse S‑box (16x16 ROM)
  reg [7:0] sbox [0:15][0:15];
  reg [7:0] inv_sbox [0:15][0:15];

  // MixColumns matrices
  reg [7:0] mix [0:3][0:3];
  reg [7:0] inv_mix [0:3][0:3];

  // ------------------------------------------------------------------
  // Initialization of constants (run once at start)
  // ------------------------------------------------------------------
  initial begin
    integer i, j;
    // S‑box (row‑major, as in C++)
    sbox[0][0] = 8'h63; sbox[0][1] = 8'h7c; sbox[0][2] = 8'h77; sbox[0][3] = 8'h7b;
    sbox[0][4] = 8'hf2; sbox[0][5] = 8'h6b; sbox[0][6] = 8'h6f; sbox[0][7] = 8'hc5;
    sbox[0][8] = 8'h30; sbox[0][9] = 8'h01; sbox[0][10]= 8'h67; sbox[0][11]= 8'h2b;
    sbox[0][12]= 8'hfe; sbox[0][13]= 8'hd7; sbox[0][14]= 8'hab; sbox[0][15]= 8'h76;
    sbox[1][0] = 8'hca; sbox[1][1] = 8'h82; sbox[1][2] = 8'hc9; sbox[1][3] = 8'h7d;
    sbox[1][4] = 8'hfa; sbox[1][5] = 8'h59; sbox[1][6] = 8'h47; sbox[1][7] = 8'hf0;
    sbox[1][8] = 8'had; sbox[1][9] = 8'hd4; sbox[1][10]= 8'ha2; sbox[1][11]= 8'haf;
    sbox[1][12]= 8'h9c; sbox[1][13]= 8'ha4; sbox[1][14]= 8'h72; sbox[1][15]= 8'hc0;
    sbox[2][0] = 8'hb7; sbox[2][1] = 8'hfd; sbox[2][2] = 8'h93; sbox[2][3] = 8'h26;
    sbox[2][4] = 8'h36; sbox[2][5] = 8'h3f; sbox[2][6] = 8'hf7; sbox[2][7] = 8'hcc;
    sbox[2][8] = 8'h34; sbox[2][9] = 8'ha5; sbox[2][10]= 8'he5; sbox[2][11]= 8'hf1;
    sbox[2][12]= 8'h71; sbox[2][13]= 8'hd8; sbox[2][14]= 8'h31; sbox[2][15]= 8'h15;
    sbox[3][0] = 8'h04; sbox[3][1] = 8'hc7; sbox[3][2] = 8'h23; sbox[3][3] = 8'hc3;
    sbox[3][4] = 8'h18; sbox[3][5] = 8'h96; sbox[3][6] = 8'h05; sbox[3][7] = 8'h9a;
    sbox[3][8] = 8'h07; sbox[3][9] = 8'h12; sbox[3][10]= 8'h80; sbox[3][11]= 8'he2;
    sbox[3][12]= 8'heb; sbox[3][13]= 8'h27; sbox[3][14]= 8'hb2; sbox[3][15]= 8'h75;
    sbox[4][0] = 8'h09; sbox[4][1] = 8'h83; sbox[4][2] = 8'h2c; sbox[4][3] = 8'h1a;
    sbox[4][4] = 8'h1b; sbox[4][5] = 8'h6e; sbox[4][6] = 8'h5a; sbox[4][7] = 8'ha0;
    sbox[4][8] = 8'h52; sbox[4][9] = 8'h3b; sbox[4][10]= 8'hd6; sbox[4][11]= 8'hb3;
    sbox[4][12]= 8'h29; sbox[4][13]= 8'he3; sbox[4][14]= 8'h2f; sbox[4][15]= 8'h84;
    sbox[5][0] = 8'h53; sbox[5][1] = 8'hd1; sbox[5][2] = 8'h00; sbox[5][3] = 8'hed;
    sbox[5][4] = 8'h20; sbox[5][5] = 8'hfc; sbox[5][6] = 8'hb1; sbox[5][7] = 8'h5b;
    sbox[5][8] = 8'h6a; sbox[5][9] = 8'hcb; sbox[5][10]= 8'hbe; sbox[5][11]= 8'h39;
    sbox[5][12]= 8'h4a; sbox[5][13]= 8'h4c; sbox[5][14]= 8'h58; sbox[5][15]= 8'hcf;
    sbox[6][0] = 8'hd0; sbox[6][1] = 8'hef; sbox[6][2] = 8'haa; sbox[6][3] = 8'hfb;
    sbox[6][4] = 8'h43; sbox[6][5] = 8'h4d; sbox[6][6] = 8'h33; sbox[6][7] = 8'h85;
    sbox[6][8] = 8'h45; sbox[6][9] = 8'hf9; sbox[6][10]= 8'h02; sbox[6][11]= 8'h7f;
    sbox[6][12]= 8'h50; sbox[6][13]= 8'h3c; sbox[6][14]= 8'h9f; sbox[6][15]= 8'ha8;
    sbox[7][0] = 8'h51; sbox[7][1] = 8'ha3; sbox[7][2] = 8'h40; sbox[7][3] = 8'h8f;
    sbox[7][4] = 8'h92; sbox[7][5] = 8'h9d; sbox[7][6] = 8'h38; sbox[7][7] = 8'hf5;
    sbox[7][8] = 8'hbc; sbox[7][9] = 8'hb6; sbox[7][10]= 8'hda; sbox[7][11]= 8'h21;
    sbox[7][12]= 8'h10; sbox[7][13]= 8'hff; sbox[7][14]= 8'hf3; sbox[7][15]= 8'hd2;
    sbox[8][0] = 8'hcd; sbox[8][1] = 8'h0c; sbox[8][2] = 8'h13; sbox[8][3] = 8'hec;
    sbox[8][4] = 8'h5f; sbox[8][5] = 8'h97; sbox[8][6] = 8'h44; sbox[8][7] = 8'h17;
    sbox[8][8] = 8'hc4; sbox[8][9] = 8'ha7; sbox[8][10]= 8'h7e; sbox[8][11]= 8'h3d;
    sbox[8][12]= 8'h64; sbox[8][13]= 8'h5d; sbox[8][14]= 8'h19; sbox[8][15]= 8'h73;
    sbox[9][0] = 8'h60; sbox[9][1] = 8'h81; sbox[9][2] = 8'h4f; sbox[9][3] = 8'hdc;
    sbox[9][4] = 8'h22; sbox[9][5] = 8'h2a; sbox[9][6] = 8'h90; sbox[9][7] = 8'h88;
    sbox[9][8] = 8'h46; sbox[9][9] = 8'hee; sbox[9][10]= 8'hb8; sbox[9][11]= 8'h14;
    sbox[9][12]= 8'hde; sbox[9][13]= 8'h5e; sbox[9][14]= 8'h0b; sbox[9][15]= 8'hdb;
    sbox[10][0]= 8'he0; sbox[10][1]= 8'h32; sbox[10][2]= 8'h3a; sbox[10][3]= 8'h0a;
    sbox[10][4]= 8'h49; sbox[10][5]= 8'h06; sbox[10][6]= 8'h24; sbox[10][7]= 8'h5c;
    sbox[10][8]= 8'hc2; sbox[10][9]= 8'hd3; sbox[10][10]=8'hac; sbox[10][11]=8'h62;
    sbox[10][12]=8'h91; sbox[10][13]=8'h95; sbox[10][14]=8'he4; sbox[10][15]=8'h79;
    sbox[11][0]= 8'he7; sbox[11][1]= 8'hc8; sbox[11][2]= 8'h37; sbox[11][3]= 8'h6d;
    sbox[11][4]= 8'h8d; sbox[11][5]= 8'hd5; sbox[11][6]= 8'h4e; sbox[11][7]= 8'ha9;
    sbox[11][8]= 8'h6c; sbox[11][9]= 8'h56; sbox[11][10]=8'hf4; sbox[11][11]=8'hea;
    sbox[11][12]=8'h65; sbox[11][13]=8'h7a; sbox[11][14]=8'hae; sbox[11][15]=8'h08;
    sbox[12][0]= 8'hba; sbox[12][1]= 8'h78; sbox[12][2]= 8'h25; sbox[12][3]= 8'h2e;
    sbox[12][4]= 8'h1c; sbox[12][5]= 8'ha6; sbox[12][6]= 8'hb4; sbox[12][7]= 8'hc6;
    sbox[12][8]= 8'he8; sbox[12][9]= 8'hdd; sbox[12][10]=8'h74; sbox[12][11]=8'h1f;
    sbox[12][12]=8'h4b; sbox[12][13]=8'hbd; sbox[12][14]=8'h8b; sbox[12][15]=8'h8a;
    sbox[13][0]= 8'h70; sbox[13][1]= 8'h3e; sbox[13][2]= 8'hb5; sbox[13][3]= 8'h66;
    sbox[13][4]= 8'h48; sbox[13][5]= 8'h03; sbox[13][6]= 8'hf6; sbox[13][7]= 8'h0e;
    sbox[13][8]= 8'h61; sbox[13][9]= 8'h35; sbox[13][10]=8'h57; sbox[13][11]=8'hb9;
    sbox[13][12]=8'h86; sbox[13][13]=8'hc1; sbox[13][14]=8'h1d; sbox[13][15]=8'h9e;
    sbox[14][0]= 8'he1; sbox[14][1]= 8'hf8; sbox[14][2]= 8'h98; sbox[14][3]= 8'h11;
    sbox[14][4]= 8'h69; sbox[14][5]= 8'hd9; sbox[14][6]= 8'h8e; sbox[14][7]= 8'h94;
    sbox[14][8]= 8'h9b; sbox[14][9]= 8'h1e; sbox[14][10]=8'h87; sbox[14][11]=8'he9;
    sbox[14][12]=8'hce; sbox[14][13]=8'h55; sbox[14][14]=8'h28; sbox[14][15]=8'hdf;
    sbox[15][0]= 8'h8c; sbox[15][1]= 8'ha1; sbox[15][2]= 8'h89; sbox[15][3]= 8'h0d;
    sbox[15][4]= 8'hbf; sbox[15][5]= 8'he6; sbox[15][6]= 8'h42; sbox[15][7]= 8'h68;
    sbox[15][8]= 8'h41; sbox[15][9]= 8'h99; sbox[15][10]=8'h2d; sbox[15][11]=8'h0f;
    sbox[15][12]=8'hb0; sbox[15][13]=8'h54; sbox[15][14]=8'hbb; sbox[15][15]=8'h16;

    // Inverse S‑box
    inv_sbox[0][0] = 8'h52; inv_sbox[0][1] = 8'h09; inv_sbox[0][2] = 8'h6a; inv_sbox[0][3] = 8'hd5;
    inv_sbox[0][4] = 8'h30; inv_sbox[0][5] = 8'h36; inv_sbox[0][6] = 8'ha5; inv_sbox[0][7] = 8'h38;
    inv_sbox[0][8] = 8'hbf; inv_sbox[0][9] = 8'h40; inv_sbox[0][10]= 8'ha3; inv_sbox[0][11]= 8'h9e;
    inv_sbox[0][12]= 8'h81; inv_sbox[0][13]= 8'hf3; inv_sbox[0][14]= 8'hd7; inv_sbox[0][15]= 8'hfb;
    inv_sbox[1][0] = 8'h7c; inv_sbox[1][1] = 8'he3; inv_sbox[1][2] = 8'h39; inv_sbox[1][3] = 8'h82;
    inv_sbox[1][4] = 8'h9b; inv_sbox[1][5] = 8'h2f; inv_sbox[1][6] = 8'hff; inv_sbox[1][7] = 8'h87;
    inv_sbox[1][8] = 8'h34; inv_sbox[1][9] = 8'h8e; inv_sbox[1][10]= 8'h43; inv_sbox[1][11]= 8'h44;
    inv_sbox[1][12]= 8'hc4; inv_sbox[1][13]= 8'hde; inv_sbox[1][14]= 8'he9; inv_sbox[1][15]= 8'hcb;
    inv_sbox[2][0] = 8'h54; inv_sbox[2][1] = 8'h7b; inv_sbox[2][2] = 8'h94; inv_sbox[2][3] = 8'h32;
    inv_sbox[2][4] = 8'ha6; inv_sbox[2][5] = 8'hc2; inv_sbox[2][6] = 8'h23; inv_sbox[2][7] = 8'h3d;
    inv_sbox[2][8] = 8'hee; inv_sbox[2][9] = 8'h4c; inv_sbox[2][10]= 8'h95; inv_sbox[2][11]= 8'h0b;
    inv_sbox[2][12]= 8'h42; inv_sbox[2][13]= 8'hfa; inv_sbox[2][14]= 8'hc3; inv_sbox[2][15]= 8'h4e;
    inv_sbox[3][0] = 8'h08; inv_sbox[3][1] = 8'h2e; inv_sbox[3][2] = 8'ha1; inv_sbox[3][3] = 8'h66;
    inv_sbox[3][4] = 8'h28; inv_sbox[3][5] = 8'hd9; inv_sbox[3][6] = 8'h24; inv_sbox[3][7] = 8'hb2;
    inv_sbox[3][8] = 8'h76; inv_sbox[3][9] = 8'h5b; inv_sbox[3][10]= 8'ha2; inv_sbox[3][11]= 8'h49;
    inv_sbox[3][12]= 8'h6d; inv_sbox[3][13]= 8'h8b; inv_sbox[3][14]= 8'hd1; inv_sbox[3][15]= 8'h25;
    inv_sbox[4][0] = 8'h72; inv_sbox[4][1] = 8'hf8; inv_sbox[4][2] = 8'hf6; inv_sbox[4][3] = 8'h64;
    inv_sbox[4][4] = 8'h86; inv_sbox[4][5] = 8'h68; inv_sbox[4][6] = 8'h98; inv_sbox[4][7] = 8'h16;
    inv_sbox[4][8] = 8'hd4; inv_sbox[4][9] = 8'ha4; inv_sbox[4][10]= 8'h5c; inv_sbox[4][11]= 8'hcc;
    inv_sbox[4][12]= 8'h5d; inv_sbox[4][13]= 8'h65; inv_sbox[4][14]= 8'hb6; inv_sbox[4][15]= 8'h92;
    inv_sbox[5][0] = 8'h6c; inv_sbox[5][1] = 8'h70; inv_sbox[5][2] = 8'h48; inv_sbox[5][3] = 8'h50;
    inv_sbox[5][4] = 8'hfd; inv_sbox[5][5] = 8'hed; inv_sbox[5][6] = 8'hb9; inv_sbox[5][7] = 8'hda;
    inv_sbox[5][8] = 8'h5e; inv_sbox[5][9] = 8'h15; inv_sbox[5][10]= 8'h46; inv_sbox[5][11]= 8'h57;
    inv_sbox[5][12]= 8'ha7; inv_sbox[5][13]= 8'h8d; inv_sbox[5][14]= 8'h9d; inv_sbox[5][15]= 8'h84;
    inv_sbox[6][0] = 8'h90; inv_sbox[6][1] = 8'hd8; inv_sbox[6][2] = 8'hab; inv_sbox[6][3] = 8'h00;
    inv_sbox[6][4] = 8'h8c; inv_sbox[6][5] = 8'hbc; inv_sbox[6][6] = 8'hd3; inv_sbox[6][7] = 8'h0a;
    inv_sbox[6][8] = 8'hf7; inv_sbox[6][9] = 8'he4; inv_sbox[6][10]= 8'h58; inv_sbox[6][11]= 8'h05;
    inv_sbox[6][12]= 8'hb8; inv_sbox[6][13]= 8'hb3; inv_sbox[6][14]= 8'h45; inv_sbox[6][15]= 8'h06;
    inv_sbox[7][0] = 8'hd0; inv_sbox[7][1] = 8'h2c; inv_sbox[7][2] = 8'h1e; inv_sbox[7][3] = 8'h8f;
    inv_sbox[7][4] = 8'hca; inv_sbox[7][5] = 8'h3f; inv_sbox[7][6] = 8'h0f; inv_sbox[7][7] = 8'h02;
    inv_sbox[7][8] = 8'hc1; inv_sbox[7][9] = 8'haf; inv_sbox[7][10]= 8'hbd; inv_sbox[7][11]= 8'h03;
    inv_sbox[7][12]= 8'h01; inv_sbox[7][13]= 8'h13; inv_sbox[7][14]= 8'h8a; inv_sbox[7][15]= 8'h6b;
    inv_sbox[8][0] = 8'h3a; inv_sbox[8][1] = 8'h91; inv_sbox[8][2] = 8'h11; inv_sbox[8][3] = 8'h41;
    inv_sbox[8][4] = 8'h4f; inv_sbox[8][5] = 8'h67; inv_sbox[8][6] = 8'hdc; inv_sbox[8][7] = 8'hea;
    inv_sbox[8][8] = 8'h97; inv_sbox[8][9] = 8'hf2; inv_sbox[8][10]= 8'hcf; inv_sbox[8][11]= 8'hce;
    inv_sbox[8][12]= 8'hf0; inv_sbox[8][13]= 8'hb4; inv_sbox[8][14]= 8'he6; inv_sbox[8][15]= 8'h73;
    inv_sbox[9][0] = 8'h96; inv_sbox[9][1] = 8'hac; inv_sbox[9][2] = 8'h74; inv_sbox[9][3] = 8'h22;
    inv_sbox[9][4] = 8'he7; inv_sbox[9][5] = 8'had; inv_sbox[9][6] = 8'h35; inv_sbox[9][7] = 8'h85;
    inv_sbox[9][8] = 8'he2; inv_sbox[9][9] = 8'hf9; inv_sbox[9][10]= 8'h37; inv_sbox[9][11]= 8'he8;
    inv_sbox[9][12]= 8'h1c; inv_sbox[9][13]= 8'h75; inv_sbox[9][14]= 8'hdf; inv_sbox[9][15]= 8'h6e;
    inv_sbox[10][0]= 8'h47; inv_sbox[10][1]= 8'hf1; inv_sbox[10][2]= 8'h1a; inv_sbox[10][3]= 8'h71;
    inv_sbox[10][4]= 8'h1d; inv_sbox[10][5]= 8'h29; inv_sbox[10][6]= 8'hc5; inv_sbox[10][7]= 8'h89;
    inv_sbox[10][8]= 8'h6f; inv_sbox[10][9]= 8'hb7; inv_sbox[10][10]=8'h62; inv_sbox[10][11]=8'h0e;
    inv_sbox[10][12]=8'haa; inv_sbox[10][13]=8'h18; inv_sbox[10][14]=8'hbe; inv_sbox[10][15]=8'h1b;
    inv_sbox[11][0]= 8'hfc; inv_sbox[11][1]= 8'h56; inv_sbox[11][2]= 8'h3e; inv_sbox[11][3]= 8'h4b;
    inv_sbox[11][4]= 8'hc6; inv_sbox[11][5]= 8'hd2; inv_sbox[11][6]= 8'h79; inv_sbox[11][7]= 8'h20;
    inv_sbox[11][8]= 8'h9a; inv_sbox[11][9]= 8'hdb; inv_sbox[11][10]=8'hc0; inv_sbox[11][11]=8'hfe;
    inv_sbox[11][12]=8'h78; inv_sbox[11][13]=8'hcd; inv_sbox[11][14]=8'h5a; inv_sbox[11][15]=8'hf4;
    inv_sbox[12][0]= 8'h1f; inv_sbox[12][1]= 8'hdd; inv_sbox[12][2]= 8'ha8; inv_sbox[12][3]= 8'h33;
    inv_sbox[12][4]= 8'h88; inv_sbox[12][5]= 8'h07; inv_sbox[12][6]= 8'hc7; inv_sbox[12][7]= 8'h31;
    inv_sbox[12][8]= 8'hb1; inv_sbox[12][9]= 8'h12; inv_sbox[12][10]=8'h10; inv_sbox[12][11]=8'h59;
    inv_sbox[12][12]=8'h27; inv_sbox[12][13]=8'h80; inv_sbox[12][14]=8'hec; inv_sbox[12][15]=8'h5f;
    inv_sbox[13][0]= 8'h60; inv_sbox[13][1]= 8'h51; inv_sbox[13][2]= 8'h7f; inv_sbox[13][3]= 8'ha9;
    inv_sbox[13][4]= 8'h19; inv_sbox[13][5]= 8'hb5; inv_sbox[13][6]= 8'h4a; inv_sbox[13][7]= 8'h0d;
    inv_sbox[13][8]= 8'h2d; inv_sbox[13][9]= 8'he5; inv_sbox[13][10]=8'h7a; inv_sbox[13][11]=8'h9f;
    inv_sbox[13][12]=8'h93; inv_sbox[13][13]=8'hc9; inv_sbox[13][14]=8'h9c; inv_sbox[13][15]=8'hef;
    inv_sbox[14][0]= 8'ha0; inv_sbox[14][1]= 8'he0; inv_sbox[14][2]= 8'h3b; inv_sbox[14][3]= 8'h4d;
    inv_sbox[14][4]= 8'hae; inv_sbox[14][5]= 8'h2a; inv_sbox[14][6]= 8'hf5; inv_sbox[14][7]= 8'hb0;
    inv_sbox[14][8]= 8'hc8; inv_sbox[14][9]= 8'heb; inv_sbox[14][10]=8'hbb; inv_sbox[14][11]=8'h3c;
    inv_sbox[14][12]=8'h83; inv_sbox[14][13]=8'h53; inv_sbox[14][14]=8'h99; inv_sbox[14][15]=8'h61;
    inv_sbox[15][0]= 8'h17; inv_sbox[15][1]= 8'h2b; inv_sbox[15][2]= 8'h04; inv_sbox[15][3]= 8'h7e;
    inv_sbox[15][4]= 8'hba; inv_sbox[15][5]= 8'h77; inv_sbox[15][6]= 8'hd6; inv_sbox[15][7]= 8'h26;
    inv_sbox[15][8]= 8'he1; inv_sbox[15][9]= 8'h69; inv_sbox[15][10]=8'h14; inv_sbox[15][11]=8'h63;
    inv_sbox[15][12]=8'h55; inv_sbox[15][13]=8'h21; inv_sbox[15][14]=8'h0c; inv_sbox[15][15]=8'h7d;

    // MixColumns matrix
    mix[0][0] = 8'h02; mix[0][1] = 8'h03; mix[0][2] = 8'h01; mix[0][3] = 8'h01;
    mix[1][0] = 8'h01; mix[1][1] = 8'h02; mix[1][2] = 8'h03; mix[1][3] = 8'h01;
    mix[2][0] = 8'h01; mix[2][1] = 8'h01; mix[2][2] = 8'h02; mix[2][3] = 8'h03;
    mix[3][0] = 8'h03; mix[3][1] = 8'h01; mix[3][2] = 8'h01; mix[3][3] = 8'h02;

    // Inverse MixColumns matrix
    inv_mix[0][0] = 8'h0E; inv_mix[0][1] = 8'h0B; inv_mix[0][2] = 8'h0D; inv_mix[0][3] = 8'h09;
    inv_mix[1][0] = 8'h09; inv_mix[1][1] = 8'h0E; inv_mix[1][2] = 8'h0B; inv_mix[1][3] = 8'h0D;
    inv_mix[2][0] = 8'h0D; inv_mix[2][1] = 8'h09; inv_mix[2][2] = 8'h0E; inv_mix[2][3] = 8'h0B;
    inv_mix[3][0] = 8'h0B; inv_mix[3][1] = 8'h0D; inv_mix[3][2] = 8'h09; inv_mix[3][3] = 8'h0E;
  end

  // ------------------------------------------------------------------
  // Galois Field multiplication (GF(2^8) with reduction polynomial 0x11b)
  // ------------------------------------------------------------------
  function [7:0] gfmul;
    input [7:0] a, b;
    reg [7:0] result;
    reg [7:0] temp;
    integer i;
    begin
      result = 8'h00;
      temp = a;
      for (i = 0; i < 8; i = i + 1) begin
        if (b[i]) result = result ^ temp;
        // xtime: multiply by 0x02 with reduction
        temp = (temp[7] ? ((temp << 1) ^ 8'h1B) : (temp << 1));
      end
      gfmul = result;
    end
  endfunction

  // ------------------------------------------------------------------
  // Key expansion – matching the C++ style (inline g, explicit words)
  // ------------------------------------------------------------------
  task keyexpand;
    reg [7:0] w [0:43][0:3];           // 44 words, each 4 bytes
    reg [7:0] rcon [1:10];             // round constants
    integer round, i, c;
    integer row, k;

    // Word variables – exactly like your C++ snippet
    reg [7:0] word0 [0:3], word1 [0:3], word2 [0:3], word3 [0:3];
    reg [7:0] new_word0 [0:3], new_word1 [0:3], new_word2 [0:3], new_word3 [0:3];
    reg [7:0] g_out [0:3];
    reg [7:0] temp_word [0:3];

    begin
      // Initialize rcon for rounds 1..10 (full AES sequence)
      rcon[1] = 8'h01; rcon[2] = 8'h02; rcon[3] = 8'h04; rcon[4] = 8'h08;
      rcon[5] = 8'h10; rcon[6] = 8'h20; rcon[7] = 8'h40; rcon[8] = 8'h80;
      rcon[9] = 8'h1B; rcon[10]= 8'h36;

      // Copy initial key into w[0..3]
      for (i = 0; i < 4; i = i + 1) begin          // word index
        for (c = 0; c < 4; c = c + 1) begin        // byte index
          w[i][c] = keymap[0][c][i];
        end
      end

      // Expand for rounds 1..10
      for (round = 1; round <= 10; round = round + 1) begin
        // Load previous round words (columns) into word0..word3
        for (c = 0; c < 4; c = c + 1) begin
          word0[c] = w[(round-1)*4 + 0][c];
          word1[c] = w[(round-1)*4 + 1][c];
          word2[c] = w[(round-1)*4 + 2][c];
          word3[c] = w[(round-1)*4 + 3][c];
        end

        // ---- Compute g(word3) ----
        // RotWord: left shift
        temp_word[0] = word3[1];
        temp_word[1] = word3[2];
        temp_word[2] = word3[3];
        temp_word[3] = word3[0];
        // SubWord via sbox
        for (k = 0; k < 4; k = k + 1)
          temp_word[k] = sbox[temp_word[k] >> 4][temp_word[k] & 8'h0f];
        // XOR with rcon
        temp_word[0] = temp_word[0] ^ rcon[round];
        // store result in g_out
        for (c = 0; c < 4; c = c + 1)
          g_out[c] = temp_word[c];

        // ---- Compute new words exactly as in C++ ----
        // new_word0 = g(word3) ^ word0;
        // new_word1 = new_word0 ^ word1;
        // new_word2 = new_word1 ^ word2;
        // new_word3 = new_word2 ^ word3;
        for (c = 0; c < 4; c = c + 1) begin
          new_word0[c] = g_out[c] ^ word0[c];
          new_word1[c] = new_word0[c] ^ word1[c];
          new_word2[c] = new_word1[c] ^ word2[c];
          new_word3[c] = new_word2[c] ^ word3[c];
        end

        // Store new words into w[round*4 + 0..3]
        for (c = 0; c < 4; c = c + 1) begin
          w[round*4 + 0][c] = new_word0[c];
          w[round*4 + 1][c] = new_word1[c];
          w[round*4 + 2][c] = new_word2[c];
          w[round*4 + 3][c] = new_word3[c];
        end
      end

      // Copy expanded keys back into keymap (same storage as original)
      for (round = 0; round <= 10; round = round + 1) begin
        for (c = 0; c < 4; c = c + 1) begin
          for (row = 0; row < 4; row = row + 1) begin
            keymap[round][row][c] = w[round*4 + c][row];
          end
        end
      end
    end
  endtask

  // ------------------------------------------------------------------
  // AES round operations (modify global 'state')
  // ------------------------------------------------------------------
  task addkey;
    input integer round;
    integer i, j;
    begin
      for (i = 0; i < 4; i = i + 1)
        for (j = 0; j < 4; j = j + 1)
          state[i][j] = state[i][j] ^ keymap[round][i][j];
    end
  endtask

  task subbytes;
    integer i, j;
    begin
      for (i = 0; i < 4; i = i + 1)
        for (j = 0; j < 4; j = j + 1)
          state[i][j] = sbox[state[i][j] >> 4][state[i][j] & 8'h0f];
    end
  endtask

  task shiftrows;
    integer i, j;
    reg [7:0] temp [0:3];
    begin
      for (i = 1; i < 4; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1)
          temp[j] = state[i][(j + i) % 4];
        for (j = 0; j < 4; j = j + 1)
          state[i][j] = temp[j];
      end
    end
  endtask

  task mixcolumns;
    integer i, j, k;
    reg [7:0] ans [0:3][0:3];
    begin
      for (i = 0; i < 4; i = i + 1)
        for (j = 0; j < 4; j = j + 1) begin
          ans[i][j] = 8'h00;
          for (k = 0; k < 4; k = k + 1)
            ans[i][j] = ans[i][j] ^ gfmul(state[k][j], mix[i][k]);
        end
      for (i = 0; i < 4; i = i + 1)
        for (j = 0; j < 4; j = j + 1)
          state[i][j] = ans[i][j];
    end
  endtask

  task inv_subbytes;
    integer i, j;
    begin
      for (i = 0; i < 4; i = i + 1)
        for (j = 0; j < 4; j = j + 1)
          state[i][j] = inv_sbox[state[i][j] >> 4][state[i][j] & 8'h0f];
    end
  endtask

  task inv_shiftrows;
    integer i, j;
    reg [7:0] temp [0:3];
    begin
      for (i = 1; i < 4; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1)
          temp[j] = state[i][(j - i + 4) % 4];   // shift right by i
        for (j = 0; j < 4; j = j + 1)
          state[i][j] = temp[j];
      end
    end
  endtask

  task inv_mixcolumns;
    integer i, j, k;
    reg [7:0] ans [0:3][0:3];
    begin
      for (i = 0; i < 4; i = i + 1)
        for (j = 0; j < 4; j = j + 1) begin
          ans[i][j] = 8'h00;
          for (k = 0; k < 4; k = k + 1)
            ans[i][j] = ans[i][j] ^ gfmul(state[k][j], inv_mix[i][k]);
        end
      for (i = 0; i < 4; i = i + 1)
        for (j = 0; j < 4; j = j + 1)
          state[i][j] = ans[i][j];
    end
  endtask

  // ------------------------------------------------------------------
  // Encryption and Decryption top‑level tasks
  // (Plaintext and key are pre‑loaded by the testbench)
  // ------------------------------------------------------------------
  task encrypt;
    integer r;
    begin
      // Expand keys (uses keymap[0] set by testbench)
      keyexpand();

      // Add round key 0
      addkey(0);

      // Rounds 1..9
      for (r = 1; r <= 9; r = r + 1) begin
        subbytes();
        shiftrows();
        mixcolumns();
        addkey(r);
      end

      // Final round (no mixcolumns)
      subbytes();
      shiftrows();
      addkey(10);

      // Print ciphertext
      $display("Ciphertext:");
      for (r = 0; r < 4; r = r + 1) begin
        $write("%02h %02h %02h %02h\n", state[r][0], state[r][1], state[r][2], state[r][3]);
      end
    end
  endtask

  task decrypt;
    integer r;
    begin
      // The global 'state' already contains the ciphertext from encryption

      // Initial round (key 10)
      addkey(10);

      // Rounds 9 down to 1
      for (r = 9; r >= 1; r = r - 1) begin
        inv_shiftrows();
        inv_subbytes();
        addkey(r);
        inv_mixcolumns();
      end

      // Final round
      inv_shiftrows();
      inv_subbytes();
      addkey(0);

      // Print plaintext
      $display("Decrypted plaintext:");
      for (r = 0; r < 4; r = r + 1) begin
        $write("%02h %02h %02h %02h\n", state[r][0], state[r][1], state[r][2], state[r][3]);
      end
    end
  endtask

endmodule
