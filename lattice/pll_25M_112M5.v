//-----------------------------------------------------
// one shot timer
//-----------------------------------------------------
module pll_25M_112M5(
  in, // input
  out // output
); // End of port list
  //-------------Input Ports-----------------------------
  input in;
  //-------------Output Ports----------------------------
  output out;

  //-------------Input ports Data Type-------------------
  // By rule all the input ports should be wires
  wire in;
  //-------------Output Ports Data Type------------------
  // Output port can be a storage element (reg) or a wire
  wire out;
  // ------------ counter register

  lattice_pll_25M_112M5 clock112M5Hz(
    .CLK(in),
    .CLKOP(out)
    );

endmodule // End of Module counter
