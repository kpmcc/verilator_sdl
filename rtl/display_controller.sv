
`timescale 1ns/1ns

module display_controller #
(
 parameter DISP_HEIGHT = 480,
 parameter DISP_WIDTH = 640
)
(
 input logic        clk,

 input logic        display_flip,

 input logic        wr_en,
 input logic [8:0]  wr_x,
 input logic [8:0]  wr_y,
 input logic [3:0]  wr_c,

 input logic        rd_en,
 input logic [8:0]  rd_x,
 input logic [8:0]  rd_y,
 output logic [3:0] rd_c,
 output logic       rd_vld,
 );

   logic           memory_select = 0;

   logic[3:0] color_memory_a[0:DISP_HEIGHT-1][0:DISP_WIDTH-1];
   logic[3:0] color_memory_b[0:DISP_HEIGHT-1][0:DISP_WIDTH-1];


   integer    i;
   integer    j;

   initial begin
      for (i = 0; i < DISP_HEIGHT; i=i+1) begin
         for (j = 0; j < DISP_WIDTH; j=j+1) begin
            color_memory_a[i][j] = 0;
            color_memory_b[i][j] = 1;
            end
        end
    end

   localparam WRITE_A = 0;
   localparam WRITE_B = 1;

   always_ff @ (posedge clk) begin
      case (memory_select)
        WRITE_A: begin
           color_memory_a[wr_y][wr_x] <= wr_c;
        end
        WRITE_B: begin
           color_memory_b[wr_y][wr_x] <= wr_c;
        end
      endcase
   end

   always_ff @ (posedge clk) begin
      case (memory_select)
        WRITE_A: begin
           rd_c <= color_memory_b[rd_y][rd_x];
        end
        WRITE_B: begin
           rd_c <= color_memory_a[rd_y][rd_x];
        end
      endcase
    end

   always_ff @ (posedge clk) begin
      if (display_flip) begin
         memory_select <= ~memory_select;
      end
    end

   initial begin
      $dumpvars(1, display_controller);
      $dumpvars(1, color_memory_a[5][5]);
      $dumpvars(1, color_memory_b[5][5]);
    end

endmodule
