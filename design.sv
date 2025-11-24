`ifndef ROW_WIDTH
	`define ROW_WIDTH 256
`endif

`ifndef DATA_ROW_WIDTH
	`define DATA_ROW_WIDTH $clog2(`ROW_WIDTH)
`endif 

`ifndef HEIGHT
	`define HEIGHT 256
`endif

`ifndef DATA_HEIGHT
	`define DATA_HEIGHT $clog2(`HEIGHT)
`endif

`ifndef DATA_WIDTH
	`define DATA_WIDTH 8
`endif

module sobel_filter(
  input clk, rst,
  input recv_data,
  input [`DATA_WIDTH-1:0] pixel,
  output reg [10:0] gradient,
  output reg gradient_valid
);
  
  wire [`DATA_WIDTH-1:0] top_buff, middle_buff, bottom_buff;
  
  BRAM b0 (.clk(clk), .rst(rst), .pixel(pixel), .recv_data(recv_data), .top(top_buff), .middle(middle_buff), .bottom(bottom_buff));
  
  reg [`DATA_WIDTH-1:0] top0, top1, top2;
  reg [`DATA_WIDTH-1:0] middle0, middle1, middle2;
  reg [`DATA_WIDTH-1:0] bottom0, bottom1, bottom2;
  
  always@(posedge clk) begin
    if(rst) begin
      {top0, top1, top2} <= 0;
      {middle0, middle1, middle2} <= 0;
      {bottom0, bottom1, bottom2} <= 0;
    end
    else if(recv_data) begin
      top0 <= top1;
      top1 <= top2;
      top2 <= top_buff;
      middle0 <= middle1;
      middle1 <= middle2;
      middle2 <= middle_buff;
      bottom0 <= bottom1;
      bottom1 <= bottom2;
      bottom2 <= bottom_buff;
    end
  end
  
  reg [`DATA_ROW_WIDTH-1:0] col;
  reg [`DATA_HEIGHT-1:0] row;
  
  always@(posedge clk) begin
    if(rst) begin
      row <= 0;
      col <= 0;
    end
    else if(recv_data) begin
      if(col == `ROW_WIDTH-1) begin
        col <= 0;
        row <= row + 1;
      end
      else begin
        col <= col + 1;
      end
    end
  end
  
  reg signed [10:0] gx, gy;
  
  always@(posedge clk) begin
    if(rst) begin
      gx <= 0;
      gy <= 0;
      gradient <= 0;
      gradient_valid <= 1'b0;
    end
    else if(recv_data) begin
      gx = -top0 -(2*middle0) -bottom0 + top2 + (2*middle2) + bottom2;
      gy = -top0 -(2*top1) -top2 + bottom0 + (2*bottom1) + bottom2;
      
      gradient = (gx[10] ? -gx:gx) + (gy[10]? -gy:gy);
      
      if(row >= 2 && row <= `HEIGHT-2 && col >= 2 && col <= `ROW_WIDTH-2) begin
        gradient_valid <= 1'b1;
      end
      else begin
        gradient_valid <= 1'b0;
      end
    end
    else begin
      gradient_valid <= 1'b0;
    end
  end
  
endmodule

module BRAM(
  input clk, rst,
  input [`DATA_WIDTH-1:0] pixel,
  input recv_data,
  output [`DATA_WIDTH-1:0] top,
  output [`DATA_WIDTH-1:0] middle,
  output [`DATA_WIDTH-1:0] bottom
);
  
  reg [`DATA_ROW_WIDTH-1:0] index;
  
  reg [`DATA_WIDTH-1:0] top_buff [0:`ROW_WIDTH-1];
  reg [`DATA_WIDTH-1:0] middle_buff [0:`ROW_WIDTH-1];
  
  always@(posedge clk) begin
    if(rst) begin
      index <= 0;
    end
    else if(recv_data) begin
      top_buff[index] <= middle_buff[index];
      middle_buff[index] <= pixel;
      index <= (index == `ROW_WIDTH-1) ? 0:index+1;
    end
  end
  
  assign top = top_buff[index];
  assign middle = middle_buff[index];
  assign bottom = pixel;
    
endmodule
