//-----------------------------------------------------
// Tone generator with FM output
// to change default frequency (100MHz)
// modify fmgen.vhd constant cw_freq
//-----------------------------------------------------
module main(
  clk_25MHz, // Clock input ot the design
  led,  // leds output
  p_ring, p_tip, // stereo jack output
  pin_23, // antenna output
  btn_up, btn_down, btn_left, btn_right, btn_center  // keys input
); // End of port list
//-------------Input Ports-----------------------------
  input clk_25MHz;
  input btn_up, btn_down, btn_left, btn_right, btn_center;
//-------------Output Ports----------------------------
  output led;
  output p_ring;
  output [3:0] p_tip;
  output pin_23;
//-------------Input ports Data Type-------------------
// By rule all the input ports should be wires
  wire clk_25MHz;
  wire btn_up, btn_down, btn_left, btn_right, btn_center;
  wire p_ring;
  wire [3:0] p_tip;
//-------------Output Ports Data Type------------------
// Output port can be a storage element (reg) or a wire
  wire [7:0] led;
  wire pin_23;
  reg direction = 1'b1;
// ------------ counter register
  reg [31:0] cnt;
//------------Code Starts Here-------------------------
// Since this counter is a positive edge trigged one,
// We trigger the below block with respect to positive
// edge of the clock.

  /* keyboard to midi conversion */  
  wire [6:0] midi;
  enkoder key2midi(
    .enc_left(btn_left),
    .enc_right(btn_right),
    .enc_up(btn_up),
    .enc_down(btn_down),
    .enc_center(btn_center),
    .code(midi)
  );
  assign led[6:0] = midi; // display midi with the leds
  
  /* convert midi code to PWM tone output */
  wire signed [15:0] tone_out_pcm;
  tonegen midi2tone(
    .clk_25m(clk_25MHz),
    .code(midi),
    .volume(2'd2),
    .pcm_out(tone_out_pcm)
  );
  
  /* 250 MHz clock needed for the transmitter */
  wire clk_250MHz;
  lattice_pll_25MHz_250MHz(
    .CLK(clk_25MHz),
    .CLKOP(clk_250MHz)
  );

  /* transmit pwm tone to FM radio */  
  wire antenna;
  fmgen fm_tx(
    .clk_25m(clk_25MHz),
    .clk_250m(clk_250MHz),
    .pcm_in(tone_out_pcm),
    .cw_freq(108000000),
    .fm_out(antenna)
  );
  
  /* connect external antenna to pin 23 */
  assign pin_23 = antenna;
  
endmodule // End of Module main
