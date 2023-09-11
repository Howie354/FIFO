// general control
`define DATA_WIDTH 4
`define DATA_DEPTH 8
`define ADDR_WIDTH 3

module async_fifo_power (
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
    
    wire [`ADDR_WIDTH - 1 : 0] wr_ptr_gray,rd_ptr_gray;
    wire [`ADDR_WIDTH - 1 : 0] wr_addr,rd_addr;

    memory u_memory(
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .wr_rstn(wr_rstn),
        .rd_rstn(rd_rstn),
        .wr_data(wr_data),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .rd_addr(rd_addr),
        .rd_en(rd_en),
        .rd_data(rd_data),
        .full(full),
        .empty(empty)
        );

    write_logic u_write_logic(
        .wr_clk(wr_clk),
        .wr_rstn(wr_rstn),
        .wr_en(wr_en),
        .wr_ptr_gray(wr_ptr_gray),
        .wr_addr(wr_addr),
        .full(full)
        );

    read_logic u_read_logic(
        .rd_clk(rd_clk),
        .rd_rstn(rd_rstn),
        .rd_en(rd_en),
        .rd_ptr_gray(rd_ptr_gray),
        .rd_addr(rd_addr),
        .empty(empty)
        );
    
    jud_dir u_jud_dir(
        .wr_ptr_gray(wr_ptr_gray),
        .rd_ptr_gray(rd_ptr_gray),
        .wr_clk(wr_clk),
        .wr_rstn(wr_rstn),
        .rd_clk(rd_clk),
        .empty(empty),
        .full(full)
        );

endmodule

//memory

module memory(
    input                        wr_clk,
    input                        rd_clk,
    input                        wr_rstn,
    input                        rd_rstn,
    input [`DATA_WIDTH - 1 : 0]  wr_data,
    input                        wr_en,
    input [`ADDR_WIDTH - 1 : 0]  wr_addr,
    input [`ADDR_WIDTH - 1 : 0]  rd_addr,
    input                        rd_en,
    input                        full,
    input                        empty,
    output [`DATA_WIDTH - 1 : 0] rd_data
    );

    reg [`DATA_WIDTH - 1 : 0] mem [`DATA_DEPTH - 1 : 0];
    reg [`DATA_WIDTH - 1 : 0] rd_data;
    integer                   i;

    always @(posedge wr_clk or negedge wr_rstn) begin
        if(!wr_rstn) begin
        end
        else if(wr_en && !full) begin
            mem[wr_addr] <= wr_data;
        end
    end

    always @(posedge rd_clk or negedge rd_rstn) begin
        if(!rd_rstn) begin
        end
        else if(rd_en && !empty) begin
            rd_data <= mem[rd_addr];
        end
    end

endmodule

//write_logic

module write_logic (
    input                        wr_clk,
    input                        wr_rstn,
    input                        wr_en,
    input                        full,
    output [`ADDR_WIDTH - 1 : 0] wr_ptr_gray,
    output [`ADDR_WIDTH - 1 : 0] wr_addr
);

    reg [`ADDR_WIDTH - 1 : 0] wr_ptr;

    assign wr_addr     = wr_ptr[`ADDR_WIDTH - 1 : 0];
    assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);

    always @(posedge wr_clk or negedge wr_rstn) begin
        if(!wr_rstn) begin
            wr_ptr <= 'b0;
        end
        else if (wr_en && !full) begin
            wr_ptr <= wr_ptr + 1'b1;
        end
    end
    
endmodule

//read_logic

module read_logic (
    input                        rd_clk,
    input                        rd_rstn,
    input                        rd_en,
    input                        empty,
    output [`ADDR_WIDTH - 1 : 0] rd_ptr_gray,
    output [`ADDR_WIDTH - 1 : 0] rd_addr
);
    
    reg [`ADDR_WIDTH - 1 : 0] rd_ptr;

    assign rd_addr     = rd_ptr[`ADDR_WIDTH - 1 : 0];
    assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1 );

    always @(posedge rd_clk or negedge rd_rstn) begin
        if(rd_rstn) begin
            rd_ptr <= 'b0;
        end
        else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

endmodule

//judge_direction,set 0 --> almost empty,set 1 --> almost full

module jud_dir (
    input [`ADDR_WIDTH - 1 : 0] wr_ptr_gray,
    input [`ADDR_WIDTH - 1 : 0] rd_ptr_gray,
    input                       wr_rstn,
    input                       wr_clk,
    input                       rd_clk,
    output                      empty,
    output                      full
    );
    
    reg  dir; // dir = 0,going empty ; dir = 1,going full
    wire dir_rst,dir_set;
    wire a_empty,a_full;
    wire cmp;
    reg  empty_r1,empty_r2;
    reg  full_r1,full_r2;
    wire clk;

    assign dir_rst = (~((~wr_ptr_gray[`ADDR_WIDTH - 1] ^ rd_ptr_gray[`ADDR_WIDTH - 2]) && (wr_ptr_gray[`ADDR_WIDTH - 2] ^ rd_ptr_gray[`ADDR_WIDTH - 1]) || ~wr_rstn));
    assign dir_set = (~((~rd_ptr_gray[`ADDR_WIDTH - 1] ^ wr_ptr_gray[`ADDR_WIDTH - 2]) && (rd_ptr_gray[`ADDR_WIDTH - 2] ^ wr_ptr_gray[`ADDR_WIDTH - 1])));

    assign clk = 1;

    always @(posedge clk or negedge dir_rst or negedge dir_set) begin
        if(!dir_rst) begin
            dir <= 1'b0;
        end
        else if(!dir_set) begin
            dir <= 1'b1;
        end
    end

    assign cmp      = (wr_ptr_gray == rd_ptr_gray);
    assign a_empty  = ~(~dir && cmp);
    assign a_full   = ~(dir && cmp);
    assign empty    = empty_r2;
    assign full     = full_r2;

    always @(posedge rd_clk or negedge a_empty) begin
        if(!a_empty) begin
            empty_r1 <= 1'b1;
            empty_r2 <= 1'b1;
        end
        else begin
            empty_r1 <= ~a_empty;
            empty_r2 <= empty_r1;
        end
    end

    always @(posedge wr_clk or negedge wr_rstn or negedge a_full) begin
        if(!wr_rstn) begin
            full_r1 <= 1'b0;
            full_r2 <= 1'b0;
        end
        else if(!a_full) begin
            full_r1 <= 1'b1;
            full_r2 <= 1'b1;
        end
        else begin
            full_r1 <= ~a_full;
            full_r2 <= full_r1;
        end
    end

    
endmodule