
module  deep1_fifo#(
    parameter DATA_WIDTH = 8
) (
    input                       wclk,
    input                       wrstn,
    input [DATA_WIDTH - 1 : 0]  data_in,
    input                       wput,
    output                      wrdy,

    input                       rclk,
    input                       rrstn,
    input                       rget,
    output [DATA_WIDTH - 1 : 0] data_out,
    output                      rrdy
);
    
    wire wfire;
    wire rfire;

    assign wfire = wput && wrdy;
    assign rfire = rget && rrdy;

    reg wptr;
    reg wptr_r1;
    reg wptr_r2;
    always @(posedge wclk or negedge wrstn) begin
        if(!wrstn) begin
            wptr <= 'b0;
        end
        else if (wfire) begin
            wptr <= ~wptr;
        end
    end

    always @(posedge rclk or negedge rrstn) begin
        if(!rrstn) begin
            {wptr_r2,wptr_r1} <= 'b0;
        end
        else begin
            {wptr_r2,wptr_r1} <= {wptr_r1,wptr};
        end
    end

    assign rrdy = rptr ^ wptr_r2;

    reg rptr;
    reg rptr_r1;
    reg rptr_r2;
    always @(posedge rclk or negedge rrstn) begin
        if(!rrstn) begin
            rptr <= 'b0;
        end
        else if (rfire) begin
            rptr <= ~rptr;
        end
    end

    always @(posedge wclk or negedge wrstn) begin
        if(!wrstn) begin
            {rptr_r2,rptr_r1} <= 'b0;
        end
        else begin
            {rptr_r2,rptr_r1} <= {rptr_r1,rptr};
        end
    end

    assign wrdy = wptr ~^ rptr_r2;

    //data
    reg [DATA_WIDTH - 1 : 0] mem;

    always @(posedge wclk or negedge wrstn) begin
        if(!wrstn) begin
            mem <= {DATA_WIDTH{1'b0}};
        end
        else if(wfire) begin
            mem <= data_in;
        end
    end

    reg [DATA_WIDTH - 1 : 0] r_data_out;
    assign data_out = r_data_out;
    always @(posedge rclk or negedge rrstn) begin
        if(!rrstn) begin
            r_data_out <= {DATA_WIDTH{1'b0}};
        end
        else if(rfire) begin
            r_data_out <= mem;
        end
    end

endmodule