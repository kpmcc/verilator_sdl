`timescale 1ns/1ns

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

   localparam               DISP_WIDTH = 640;
   localparam               DISP_HEIGHT = 480;


   logic                    hsync;
   logic                    vsync;

   logic[3:0] color_memory[0:DISP_HEIGHT-1][0:DISP_WIDTH-1];

   logic [7:0] r_map[0:15];
   logic [7:0] g_map[0:15];
   logic [7:0] b_map[0:15];

   initial begin
      r_map[ 0] = 255;
      r_map[ 1] = 170;
      r_map[ 2] = 85;
      r_map[ 3] = 0;
      r_map[ 4] = 255;
      r_map[ 5] = 0;
      r_map[ 6] = 85;
      r_map[ 7] = 255;
      r_map[ 8] = 170;
      r_map[ 9] = 170;
      r_map[10] = 170;
      r_map[11] = 255;
      r_map[12] = 85;
      r_map[13] = 0;
      r_map[14] = 0;
      r_map[15] = 85;

      g_map[ 0] = 255;
      g_map[ 1] = 170;
      g_map[ 2] = 85;
      g_map[ 3] = 0;
      g_map[ 4] = 255;
      g_map[ 5] = 170;
      g_map[ 6] = 255;
      g_map[ 7] = 85;
      g_map[ 8] = 0;
      g_map[ 9] = 85;
      g_map[10] = 0;
      g_map[11] = 85;
      g_map[12] = 255;
      g_map[13] = 170;
      g_map[14] = 0;
      g_map[15] = 85;

      b_map[ 0] = 255;
      b_map[ 1] = 170;
      b_map[ 2] = 85;
      b_map[ 3] = 0;
      b_map[ 4] = 85;
      b_map[ 5] = 0;
      b_map[ 6] = 85;
      b_map[ 7] = 85;
      b_map[ 8] = 0;
      b_map[ 9] = 0;
      b_map[10] = 170;
      b_map[11] = 255;
      b_map[12] = 255;
      b_map[13] = 170;
      b_map[14] = 170;
      b_map[15] = 255;
      end

   integer i;
   integer j;
   integer x;

   initial begin
      for (i = 0; i < 640; i=i+1) begin
         for (j = 0; j < 480; j=j+1) begin
            x = 4*(j/120) + (i/160);
            color_memory[j][i] = x[3:0];
         end
      end
   end



// display sync signals and coordinates
simple_480p display_inst(
   .clk_pix(clk_pix),
   .rst(rst),
   .sx(sx),
   .sy(sy),
   .hsync(hsync),
   .vsync(vsync),
   .de(de)
);

   // logic[7:0] pixel_values []


// 32 x 32 pixel square
   logic                    q_draw;
   logic [3:0]              pixel_color_val;
   logic [CORDW-2:0]        sy_small;



   always_comb begin
      sy_small = sy[8:0];
      q_draw = (sx < 32 && sy < 32) ? 1 : 0;
      pixel_color_val = color_memory[sy_small][sx];

   end


   always_ff @ (posedge clk_pix) begin
      //sdl_r <= !de ? 8'h00 : (q_draw ? 8'h55 : 8'h00);
      //sdl_g <= !de ? 8'h00 : (q_draw ? 8'h88 : 8'h88);
      //sdl_b <= !de ? 8'h00 : (q_draw ? 8'h00 : 8'hff);
      sdl_r <= r_map[pixel_color_val];
      sdl_g <= g_map[pixel_color_val];
      sdl_b <= b_map[pixel_color_val];
   end


 endmodule
