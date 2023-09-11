// general control
`define DATA_WIDTH 4
`define DATA_DEPTH 8
`define ADDR_WIDTH 3

module async_fifo (
    input [`DATA_WIDTH - 1 : 0]  wr_data,
    input                        wr_en,
    input                        wr_clk,
    input                        wr_rstn,
    output [`DATA_WIDTH - 1 : 0] rd_data,
    input                        rd_en,
    input                        rd_clk,
    input                        rd_rstn,
    output                       full,
    output                       empty
);
    
reg [`ADDR_WIDTH : 0]      wr_ptr,rd_ptr; //binary
wire [`ADDR_WIDTH : 0]     wr_ptr_gray,rd_ptr_gray; //gray
wire [`ADDR_WIDTH - 1 : 0] wr_true_ptr,rd_true_ptr;//binary

assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);
assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);

assign wr_true_ptr = wr_ptr[`ADDR_WIDTH - 1 : 0];
assign rd_true_ptr = rd_ptr[`ADDR_WIDTH - 1 : 0];

reg [`ADDR_WIDTH : 0] wr_ptr_gray_r1,wr_ptr_gray_r2;
reg [`ADDR_WIDTH : 0] rd_ptr_gray_r1,rd_ptr_gray_r2;

//sync
always @(posedge wr_clk or negedge wr_rstn) begin
    if(!wr_rstn) begin
        rd_ptr_gray_r1 <= 'b0;
        rd_ptr_gray_r2 <= 'b0;
    end
    else begin
        rd_ptr_gray_r1 <= rd_ptr_gray;
        rd_ptr_gray_r2 <= rd_ptr_gray_r1;
    end
end

always @(posedge rd_clk or negedge rd_rstn) begin
    if(!rd_rstn) begin
        wr_ptr_gray_r1 <= 'b0;
        wr_ptr_gray_r2 <= 'b0;
    end
    else begin
        wr_ptr_gray_r1 <= wr_ptr_gray;
        wr_ptr_gray_r2 <= wr_ptr_gray_r1;
    end
end

//cmp
assign full  = {~wr_ptr_gray[`ADDR_WIDTH : `ADDR_WIDTH - 1],wr_ptr_gray[`ADDR_WIDTH - 2 : 0]} == rd_ptr_gray_r2;
assign empty = wr_ptr_gray_r2 == rd_ptr_gray;

//ptr increase
always @(posedge wr_clk or negedge wr_rstn) begin
    if(!wr_rstn) begin
        wr_ptr <= 'b0;
    end
    else if(!full && wr_en) begin
        wr_ptr <= wr_ptr + 1'b1;
    end
end

always @(posedge rd_clk or negedge rd_rstn) begin
    if(!rd_rstn) begin
        rd_ptr <= 'b0;
    end
    else if(!empty && rd_en) begin
        rd_ptr <= rd_ptr + 1'b1;
    end
end


//data
reg [`DATA_WIDTH - 1 : 0] mem [`DATA_DEPTH - 1 : 0];
always @(posedge wr_clk or negedge wr_rstn) begin
    if(!wr_rstn) begin
    end
    else if(!full && wr_en) begin
        mem[wr_true_ptr] <= wr_data;
    end
end

reg r_rd_data;
assign rd_data = r_rd_data;
always @(posedge rd_clk or negedge rd_rstn) begin
    if(!rd_rstn) begin
    end
    else if(!empty && rd_en) begin
        r_rd_data <= mem[rd_true_ptr];
    end
end



endmodule