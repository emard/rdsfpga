//-----------------------------------------------------
// (c) Davor Jadrijevic
// License=BSD
// Tone generator with FM output
// to change default frequency (100.0MHz)
// edit this file, see fmgen instance
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
  
  /* convert midi code to PCM tone output */
  wire signed [15:0] tone_pcm_left;
  tonegen midi2tone_left(
    .clk_25m(clk_25MHz),
    .code(midi),
    .pcm_out(tone_pcm_left)
  );

  /* different tone midi+1 for right channel */
  wire signed [15:0] tone_pcm_right;
  tonegen midi2tone_right(
    .clk_25m(clk_25MHz),
    .code(midi+1),
    .pcm_out(tone_pcm_right)
  );

  /* RAM storage for RDS message */
  wire [8:0] rds_msg_addr;
  wire [7:0] rds_msg_data;
  wire [7:0] cpu_writes_data;
  assign cpu_writes_data = 0;
  wire [7:0] cpu_reads_data;

  bram_rds msg_store(
    .clk(clk_25MHz),
    .imem_addr(rds_msg_addr),
    .imem_data_out(rds_msg_data)
    /*
    .dmem_addr(0),
    .dmem_byte_sel(0),
    .dmem_data_in(cpu_writes_data),
    .dmem_data_out(cpu_reads_data),
    .dmem_write(0)
    */
  );

  wire signed [15:0] mix_rds_pcm;
  rds
  #(
    .c_rds_msg_len(260), // bytes circular message (default 260, max 512)
    // multiply/divide 25 MHz to produce 1.824 MHz
    .c_rds_clock_multiply(228),
    .c_rds_clock_divide(3125)
  )
  mixer
  (
    .clk(clk_25MHz),
    .addr(rds_msg_addr),
    .data(rds_msg_data),
    .pcm_in_left(tone_pcm_left),
    .pcm_in_right(tone_pcm_right),  // use 16'd0 as zero input
    .pcm_out(mix_rds_pcm)
  );
  
  /* 250 MHz clock needed for the transmitter */
  wire clk_250MHz;
  lattice_pll_25MHz_250MHz(
    .CLK(clk_25MHz),
    .CLKOP(clk_250MHz)
  );

  /* transmit PCM signal to FM radio */
  wire antenna;
  fmgen
  #(
    .c_fdds(250000000.0)
  )
  fm_tx
  (
    .clk_pcm(clk_25MHz),
    .clk_dds(clk_250MHz),
    .pcm_in(mix_rds_pcm),
    .cw_freq(107900000), // Hz
    .fm_out(antenna)
  );
  
  /* connect external antenna to pin 23 */
  assign pin_23 = antenna;
  
endmodule // End of Module main
