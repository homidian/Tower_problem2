`timescale 1ns / 1ps

module problem2(
    Rst,
    Clk,
    InBus_DataRead,
    InBus_DataEmpty,
    InBus_DataValid,
    InBus_Enable,
    InBus_Data,
    OutBus_Valid,
    OutBus_Sart_Msg,
    OutBus_End_Msg,
    OutBus_Mod,
    OutBus_Data
    );

    localparam START=0, S0=1, S1=2,
               S2=3, S3=4, S4=5;
    reg [2:0] state,    // Current state
              nextState; // Next state

    // constants
    parameter DATA_WIDTH = 64;

    input Rst;
    input Clk;
    output reg InBus_DataRead;
    input InBus_DataEmpty;
    input InBus_DataValid;
    input [(DATA_WIDTH/8)-1:0] InBus_Enable;
    input [DATA_WIDTH-1:0] InBus_Data;
    output OutBus_Valid;
    output reg OutBus_Sart_Msg;
    output reg OutBus_End_Msg;
    output reg [$clog2(DATA_WIDTH/8):0] OutBus_Mod;
    output [DATA_WIDTH-1:0] OutBus_Data;

    wire [DATA_WIDTH/8-1:0] in_fifo_wr_cs;
    wire [DATA_WIDTH/8-1:0] in_fifo_rd_cs;
    wire [DATA_WIDTH-1:0] in_fifo_data_in;
    wire [DATA_WIDTH/8-1:0] in_fifo_rd_en_aligned;
    reg [DATA_WIDTH/8-1:0] in_fifo_rd_en;
    wire [DATA_WIDTH/8-1:0] in_fifo_wr_en;
    wire [DATA_WIDTH-1:0] in_fifo_data_out;
    wire [DATA_WIDTH/8-1:0] in_fifo_empty;
    wire [DATA_WIDTH/8-1:0] in_fifo_full;

    wire [DATA_WIDTH/8-1:0] InBus_Enable_registered;
    wire [DATA_WIDTH/8-1:0] enable_in_fifo_empty;
    wire [DATA_WIDTH/8-1:0] enable_in_fifo_full;


    wire out_fifo_wr_cs;
    wire [DATA_WIDTH/8-1:0] out_fifo_rd_cs;
    wire [DATA_WIDTH-1:0] out_fifo_data_in;
    reg [DATA_WIDTH/8-1:0] out_fifo_rd_en;
    reg [DATA_WIDTH/8-1:0] out_fifo_wr_en;
    wire [DATA_WIDTH-1:0] out_fifo_data_out;
    wire [DATA_WIDTH/8-1:0] out_fifo_empty;
    wire [DATA_WIDTH/8-1:0] out_fifo_full;

    wire [DATA_WIDTH-1:0] out_fifo_data_in_tmp;

    wire in_fifo_full_check;
    wire in_fifo_empty_check;

    wire [DATA_WIDTH-1:0] align_net_data_out;

    reg [15:0] length;
    wire [15:0] length_w;
    reg [15:0] length_previous;
    reg length_minus_8_flag;
    reg [$clog2(DATA_WIDTH/8)-1:0] start_align_point;
    reg [$clog2(DATA_WIDTH/8)-1:0] start_align_point_next;
    reg start_packet;
    reg end_packet;

    wire [2:0] encode;
    reg first_read = 0;

    reg [(DATA_WIDTH/8)-1:0] Align_Net_Enable_Override;
    wire [(DATA_WIDTH/8)-1:0] InBus_Enable_aligned;
    wire [(DATA_WIDTH/8)-1:0] Align_Net_Enable;


    enc encoder(InBus_Enable, encode);

    assign length_w = align_net_data_out[DATA_WIDTH-1:DATA_WIDTH-16];

    assign Align_Net_Enable = Align_Net_Enable_Override & InBus_Enable_aligned;

    assign in_fifo_data_in = InBus_Data;
    genvar i;
    generate
    for ( i = 0 ; i < DATA_WIDTH/8 ; i=i+1 )
        begin
            //assign in_fifo_data_in = InBus_Data;

            syn_fifo IN_FIFO(
                .clk(Clk),
                .rst(Rst),
                .wr_cs(InBus_DataValid),
                .rd_cs(1'b1),
                .data_in(in_fifo_data_in[((DATA_WIDTH/8)*(i+1)-1):(DATA_WIDTH/8)*i]),
                .rd_en(in_fifo_rd_en_aligned[i]),
                .wr_en(InBus_Enable[i]),
                .data_out(in_fifo_data_out[((DATA_WIDTH/8)*(i+1)-1):(DATA_WIDTH/8)*i]),
                .empty(in_fifo_empty[i]),
                .full(in_fifo_full[i])
            );
        end
    endgenerate

    wire InBus_Enable_atleast_one_is_high;
    assign InBus_Enable_atleast_one_is_high = | InBus_Enable;

    generate
    for ( i = 0 ; i < DATA_WIDTH/8 ; i=i+1 )
        begin
            //assign in_fifo_data_in = InBus_Data;

            syn_fifo ENABLE_IN_FIFO(
                .clk(Clk),
                .rst(Rst),
                .wr_cs(InBus_DataValid),
                .rd_cs(1'b1),
                .data_in(InBus_Enable[i]),
                .rd_en(in_fifo_rd_en_aligned[i]),
                .wr_en(InBus_Enable[i]),
                .data_out(InBus_Enable_registered[i]),
                .empty(enable_in_fifo_empty[i]),
                .full(enable_in_fifo_full[i])
            );
        end
    endgenerate

    assign out_fifo_data_in_tmp = align_net_data_out;

    reg [DATA_WIDTH/8-1:0] out_fifo_data_en;
    generate
    for ( i = 0 ; i < DATA_WIDTH/8 ; i=i+1 )
        begin
            assign out_fifo_data_in[((DATA_WIDTH/8)*(i+1)-1):(DATA_WIDTH/8)*i] = out_fifo_data_en[i] ? out_fifo_data_in_tmp[((DATA_WIDTH/8)*(i+1)-1):(DATA_WIDTH/8)*i] : 8'b00000000;
        end
    endgenerate

    generate
    for ( i = 0 ; i < DATA_WIDTH/8 ; i=i+1 )
        begin
            syn_fifo OUT_FIFO(
                .clk(Clk),
                .rst(Rst),
                .wr_cs(1'b1),
                .rd_cs(1'b1),
                .data_in(out_fifo_data_in[((DATA_WIDTH/8)*(i+1)-1):(DATA_WIDTH/8)*i]),
                .rd_en(out_fifo_rd_en[i]),
                .wr_en(out_fifo_wr_en[i]),
                .data_out(out_fifo_data_out[((DATA_WIDTH/8)*(i+1)-1):(DATA_WIDTH/8)*i]),
                .empty(out_fifo_empty[i]),
                .full(out_fifo_full[i])
            );
        end
    endgenerate


    assign in_fifo_full_check = |in_fifo_full;
    assign in_fifo_empty_check = &in_fifo_empty;

    alignment_network data_align_net(
        .InBuf(in_fifo_data_out),
        .reverse(1'b0),
        .align_start(start_align_point),
        .OutBuf(align_net_data_out)
    );

    alignment_network #(.DATA_WIDTH(8), .WORD_WIDTH(1)) rd_en_align_net(
        .InBuf(in_fifo_rd_en),
        .reverse(1'b1),
        .align_start(start_align_point),
        .OutBuf(in_fifo_rd_en_aligned)
    );

    alignment_network #(.DATA_WIDTH(8), .WORD_WIDTH(1)) InBus_Enable_align_net(
        .InBuf(InBus_Enable_registered),
        .reverse(1'b1),
        .align_start(start_align_point),
        .OutBuf(InBus_Enable_aligned)
    );

    //assign OutBus_Data = align_net_data_out;
    assign OutBus_Data = out_fifo_data_in;

    reg [DATA_WIDTH-1:0] data_buf;

    always @(negedge Clk)
    begin
        length_previous = length_w;
    end

    always @(posedge Clk)
    begin
        if ( Rst )
        begin
            InBus_DataRead = 1;
            data_buf = 0;
            //OutBus_Valid =0;
            OutBus_Sart_Msg = 0;
            OutBus_End_Msg = 0;
            OutBus_Mod = 0;
            //OutBus_Data = 0;
            length = 0;
            start_packet = 0;
            end_packet = 0;
            start_align_point = 0;
            start_align_point_next = 0;
            in_fifo_rd_en = 0;
            out_fifo_data_en = 8'hFF;
            Align_Net_Enable_Override = 8'hFF;
            length_minus_8_flag = 0;
            state = START;
            nextState = START;
            out_fifo_wr_en = 8'h00;
            OutBus_Mod =0;
            //in_fifo_rd_en = 8'hFF;
        end
        else
        begin
            state = nextState;
            start_align_point = start_align_point_next;
            if ( first_read )
                //length = align_net_data_out[DATA_WIDTH-1:DATA_WIDTH-16];
                length = length_previous - 8;
            else if ( length_minus_8_flag )
                length = length - 8;
        end
    end

    always @(*)
    begin
        case(state)
        START:
        begin
            //Waiting here to get the first data
            start_align_point = 0;
            InBus_DataRead = 1;
            //nextState = S1;

            if ( !in_fifo_empty_check )
            begin
                in_fifo_rd_en = 8'hFF;
                first_read = 0;
                nextState = S0;
            end
        end
        S0:
        begin
            if ( length_w != 8'h00 )
            begin
                OutBus_Sart_Msg = 1;

                if ( length_w <= 8 )
                begin
                    OutBus_End_Msg = 1;
                    case (length_w)
                        4:
                        begin
                            in_fifo_rd_en = 8'hF0;
                            start_align_point_next = 8 - (start_align_point + 4);
                            out_fifo_data_en = 8'hF0;
                            OutBus_Mod = 4;
                        end
                        5:
                        begin
                            in_fifo_rd_en = 8'hF8;
                            start_align_point_next = 8 - (start_align_point + 5);
                            out_fifo_data_en = 8'hF8;
                            OutBus_Mod = 5;
                        end
                        6:
                        begin
                            in_fifo_rd_en = 8'hFC;
                            start_align_point_next = 8 - (start_align_point + 6);
                            out_fifo_data_en = 8'hFC;
                            OutBus_Mod = 6;
                        end
                        7:
                        begin
                            in_fifo_rd_en = 8'hFE;
                            start_align_point_next = 8 - (start_align_point + 7);
                            out_fifo_data_en = 8'hFE;
                            OutBus_Mod = 7;
                        end
                        8:
                        begin
                            in_fifo_rd_en = 8'hFF;
                            start_align_point_next = 8 - (start_align_point + 0);
                            out_fifo_data_en = 8'hFF;
                            OutBus_Mod = 8;
                        end
                    endcase
                    first_read = 0;
                    length_minus_8_flag = 0;
                    nextState = S0;
                end else begin
                    OutBus_End_Msg = 0;
                    first_read = 1;
                    in_fifo_rd_en = 8'hFF;
                    nextState = S1;
                    length_minus_8_flag = 1;
                    OutBus_Mod = 8;
                end
                out_fifo_wr_en = 8'hFF;

            end
            else
            begin
                in_fifo_rd_en = 8'hFF;
            end
        end
        S1:
        begin
            OutBus_Sart_Msg = 0;
            first_read = 0;
            if ( length <= 8 )
            begin
                OutBus_End_Msg = 1;
                case (length)
                    4:
                    begin
                        in_fifo_rd_en = 8'hF0;
                        start_align_point_next = 8 - (start_align_point + 4);
                        out_fifo_data_en = 8'hF0;
                        OutBus_Mod = 4;
                    end
                    5:
                    begin
                        in_fifo_rd_en = 8'hF8;
                        start_align_point_next = 8 - (start_align_point + 5);
                        out_fifo_data_en = 8'hF8;
                        OutBus_Mod = 5;
                    end
                    6:
                    begin
                        in_fifo_rd_en = 8'hFC;
                        start_align_point_next = 8 - (start_align_point + 6);
                        out_fifo_data_en = 8'hFC;
                        OutBus_Mod = 6;
                    end
                    7:
                    begin
                        in_fifo_rd_en = 8'hFE;
                        start_align_point_next = 8 - (start_align_point + 7);
                        out_fifo_data_en = 8'hFE;
                        OutBus_Mod = 7;
                    end
                    8:
                    begin
                        in_fifo_rd_en = 8'hFF;
                        start_align_point_next = 8 - (start_align_point + 0);
                        out_fifo_data_en = 8'hFF;
                        OutBus_Mod = 8;
                    end
                endcase
                first_read = 0;
                length_minus_8_flag = 0;
                nextState = S0;
            end else begin
                OutBus_End_Msg = 0;
                first_read = 0;
                in_fifo_rd_en = 8'hFF;
                nextState = S1;
                length_minus_8_flag = 1;
                OutBus_Mod = 8;
            end
            out_fifo_wr_en = 8'hFF;
        end
        S2:
        begin
            first_read = 1;
            nextState = S1;
            in_fifo_rd_en = 8'h00;
        end

        endcase

    end


endmodule

module enc (
    input wire [7:0] in,
    output reg [2:0] out
  );
  integer i;
  always @* begin
    out = 0; // default value if 'in' is all 0's
    for (i=0; i<8; i=i+1)
        if (in[i]) out = i;
  end
endmodule

module en_tb();
    reg [7:0] in;
    wire [2:0] out;
    enc encoder(in,out);
    always #5 in = in + 1;
    initial begin
        in = 0;
    end
endmodule

module problem2_tb();

    // constants
    parameter DATA_WIDTH = 64;

    reg Rst;
    reg Clk;
    wire InBus_DataRead;
    reg InBus_DataEmpty;
    reg InBus_DataValid;
    reg [(DATA_WIDTH/8)-1:0] InBus_Enable;
    reg [DATA_WIDTH-1:0] InBus_Data;
    wire OutBus_Valid;
    wire OutBus_Sart_Msg;
    wire OutBus_End_Msg;
    wire [3:0] OutBus_Mod;
    wire [DATA_WIDTH-1:0] OutBus_Data;

    problem2 p(
        Rst,
        Clk,
        InBus_DataRead,
        InBus_DataEmpty,
        InBus_DataValid,
        InBus_Enable,
        InBus_Data,
        OutBus_Valid,
        OutBus_Sart_Msg,
        OutBus_End_Msg,
        OutBus_Mod,
        OutBus_Data
    );

    always #5 Clk = ~Clk;


    initial begin
        $dumpfile("problem2_tb.vcd");
        $dumpvars(0,problem2_tb);
        Clk = 0;
        Rst = 0;
        InBus_DataEmpty = 0;
        InBus_Enable = 0;
        InBus_DataValid = 0;
        InBus_Data = 64'h0000000000000000;
        #7 Rst = 1;
        #15 Rst = 0;
        InBus_Enable = 255;
        InBus_DataValid = 1;
        InBus_DataValid = 1;
        InBus_Data = 64'h0014426262626262;
        #10
        InBus_Data = 64'h6262626262626262;
        #10
        InBus_Data = 64'h6262626200054464;
        #10
        InBus_Data = 64'h6400044161000441;
        #10
        InBus_Enable = 128;
        InBus_Data = 64'h6100000000000000;
        #10
        InBus_DataValid = 0;
        InBus_Enable = 0;
        InBus_Data = 64'h0000000000000000;

        #100 $finish;
    end

endmodule
