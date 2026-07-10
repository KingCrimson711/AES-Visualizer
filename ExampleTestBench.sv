// Code your testbench here
// or browse Examples
// Code your testbench here
// or browse Examples
// Testbench for AES module
// Provides plaintext and key, then calls encryption and decryption.
`timescale 1ns / 1ps

module tb_aes;

  // Instantiate the AES module
  AES aes_inst();

  initial begin
    // ----- Set plaintext (state) -----
    aes_inst.state[0][0] = 8'h01;
    aes_inst.state[0][1] = 8'h89;
    aes_inst.state[0][2] = 8'hfe;
    aes_inst.state[0][3] = 8'h76;
    aes_inst.state[1][0] = 8'h23;
    aes_inst.state[1][1] = 8'hab;
    aes_inst.state[1][2] = 8'hdc;
    aes_inst.state[1][3] = 8'h54;
    aes_inst.state[2][0] = 8'h45;
    aes_inst.state[2][1] = 8'hcd;
    aes_inst.state[2][2] = 8'hba;
    aes_inst.state[2][3] = 8'h32;
    aes_inst.state[3][0] = 8'h67;
    aes_inst.state[3][1] = 8'hef;
    aes_inst.state[3][2] = 8'h98;
    aes_inst.state[3][3] = 8'h10;

    // ----- Set initial key (keymap[0]) -----
    aes_inst.keymap[0][0][0] = 8'h0f;
    aes_inst.keymap[0][0][1] = 8'h47;
    aes_inst.keymap[0][0][2] = 8'h0c;
    aes_inst.keymap[0][0][3] = 8'haf;
    aes_inst.keymap[0][1][0] = 8'h15;
    aes_inst.keymap[0][1][1] = 8'hd9;
    aes_inst.keymap[0][1][2] = 8'hb7;
    aes_inst.keymap[0][1][3] = 8'h7f;
    aes_inst.keymap[0][2][0] = 8'h71;
    aes_inst.keymap[0][2][1] = 8'he8;
    aes_inst.keymap[0][2][2] = 8'had;
    aes_inst.keymap[0][2][3] = 8'h67;
    aes_inst.keymap[0][3][0] = 8'hc9;
    aes_inst.keymap[0][3][1] = 8'h59;
