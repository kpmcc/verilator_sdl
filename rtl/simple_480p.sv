module simple_480p (
  input wire logic clk_pix,
  input wire logic rst,
  output     logic [9:0] sx,
  output     logic [9:0] sy,
  output logic hsync,
  output logic vsync,
  output logic de
);

// horizontal timings
   localparam HA_END = 639;
   localparam HS_STA = HA_END + 16;
   localparam HS_END = HS_STA + 96;
   localparam LINE = 799;

// vertical timings
   localparam VA_END = 479;
   localparam VS_STA = VA_END + 10;
   localparam VS_END = VS_STA + 2;
   localparam SCREEN = 524;

   always_comb begin
      hsync = ~(sx >= HS_STA && sx < HS_END);
      vsync = ~(sy >= VS_STA && sy < VS_END);
      de = (sx <= HA_END && sy <= VA_END);
    end

   always_ff @ (posedge clk_pix) begin
      if (rst) begin
         sx <= 0;
         sy <= 0;
      end else begin
         if (sx == LINE) begin
            sx <= 0;
            sy <= (sy == SCREEN) ? 0 : sy + 1;
         end else begin
            sx <= sx + 1;
         end
      end
    end
endmodule
