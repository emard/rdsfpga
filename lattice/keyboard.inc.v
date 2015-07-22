//-----------------------------------------------------
// this instantiates keyboard, should be included from main.v
//-----------------------------------------------------

  wire key_press;
  wire [24:0] key_code;

  keycode key1(
    .on(  {btn_right & btn_center,  btn_right & ~btn_center, btn_up } ), // 3 bits {3, 2, 1}
    .off( {btn_left  & btn_center,  btn_left  & ~btn_center, btn_down} ),  // 3 bits {3, 2, 1}
    // .on(  { 1'b0, ~btn_up ,  1'b0 } ), // 3 bits {3, 2, 1}
    // .off( { 1'b0, ~btn_down, 1'b0 } ), // 3 bits {3, 2, 1}
    .group( {sw_2, sw_1} ),
    // .group( {1'b0, 1'b0} ),
    .press(key_press),
    .code(key_code)
  );
