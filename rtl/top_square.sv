module top_square #
(
 parameter CORDW=10 // coordinate width
)
(
   input wire               logic clk_pix, // pixel clock
   input wire               logic rst, // reset
   output logic [CORDW-1:0] sx, // horizontal screen pos
   output logic [CORDW-1:0] sy, // vertical screen pos
   output logic             de, // data enable
   output logic [7:0]       sdl_r, // 8-bit red
   output logic [7:0]       sdl_g, // 8-bit green
   output logic [7:0]       sdl_b  // 8-bit blue
);

// display sync signals and coordinates
simple_480p display_inst(
   .clk_pix(clk_pix),
   .rst(rst),
   .sx(sx),
   .sy(sy),
   .hsync(),
   .vsync(),
   .de(de)
);


// 32 x 32 pixel square
   logic                    q_draw;

   always_comb begin
      q_draw = (sx < 32 && sy < 32) ? 1 : 0;
   end

   always_ff @ (posedge clk_pix) begin
      sdl_r <= !de ? 8'h00 : (q_draw ? 8'h55 : 8'h00);
      sdl_g <= !de ? 8'h00 : (q_draw ? 8'h88 : 8'h88);
      sdl_b <= !de ? 8'h00 : (q_draw ? 8'h00 : 8'hff);
   end

 endmodule
