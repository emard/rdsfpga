//-----------------------------------------------------
// one shot timer
//-----------------------------------------------------
module pll_112M5_433M92(
  in, // input
  out // output
);

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

  lattice_pll_112M5_433M92 clock433M92Hz(
    .CLK(in),
    .CLKOP(out)
    );

endmodule // End of Module counter
