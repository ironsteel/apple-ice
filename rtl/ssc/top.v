`timescale 1 ns / 1 ps
`default_nettype none

module top(
	input clk_16m,

	input [11:0] addr_in,
	inout [7:0] data,

	input fclk,
	input q3,

	input rw,
	input _iostrobe,
	input _iosel,
	input _devsel,
	input _reset,

	input btn,
	output _en245,

	inout _nmi,
	output _irq,
	inout _inh,
	inout _rdy,

	input rx,
	output tx,
	output irq_oe,
	output enbuf,
	output oe_dbg,
	output [7:0] test
);

assign irq_oe = 1'b0;


// Switch back to tintyfpga bootloader
SB_WARMBOOT warmboot_inst (
	.S1(1'b0),
	.S0(1'b0),
	.BOOT(~btn)
);

wire clk_1m846;
wire clk_4p77;

//assign test[0] = (addr_in[1] == 0 & addr_in[0] == 0 & rw == 1 & latch_ce_n == 0);
assign test[0] = WRITE;
/*assign test[1] = d0;
assign test[2] = phi2;
assign test[3] = latch_ce_n;
assign test[4] = ~ addr_in[3];
assign test[5] = ~addr_in[2];
assign test[6] = rx;
assign test[7] = tx;*/
 //assign test[1:7] = dat[0:6];
 assign test[7:1] = TX_REG_DEBUG[6:0];

 reg [1:0] en245Delay;
 always @(posedge fclk) begin
	 en245Delay <= { en245Delay[0], (~romen_n || latch_ce_n) };
 end


 wire WRITE;
 wire [7:0] TX_REG_DEBUG;

 wire [7:0] uart6551_dout;
 glb6551 uart_6551(
	 .RESET_N(_reset),
	 .RX_CLK_IN(clk_1m846),
	 .XTAL_CLK_IN(clk_1m846),
	 .PH_2(phi2),
	 .DI(dat),
	 .DO(uart6551_dout),
	 .IRQ(_irq),
	 .CS({~addr_in[3],~addr_in[2]}),
	 .RW_N(rw),
	 .RS({addr_in[1], addr_in[0]}),
	 .TXDATA_OUT(tx),
	 .RXDATA_IN(rx),
	 .CTS(1'b0),
	 .DCD(1'b0),
	 .DSR(1'b0),
	 .WRITE(WRITE),
	 .TX_REG_DEBUG(TX_REG_DEBUG)
 );

 pll pll_i(
	 .clock_in(clk_16m),
	 .clock_out(clk_24m)
 );

 wire clk_24m;

 reg [5:0] clk_div = 0;

 always @(posedge clk_24m) begin
	 clk_div <= clk_div + 1;
 end

 assign clk_1m846 = clk_div[3];


 //assign enbuf = (lastDataEnable == 2'b11 && latch_ce_n == 1);
 assign enbuf = clk_1m846;
 assign oe_dbg = phi2;
 //assign enbuf = romen_n;



 wire latch_ce_n, roma8, roma9, roma10, romen_n, phi2, d0;
 glue glue_i(
	 .clock(clk_16m),
	 .addr(addr_in),
	 .reset_n(_reset),
	 .rw(rw),
	 .devsel_n(_devsel),
	 .iosel_n(_iosel),
	 .io_strobe_n(_iostrobe),
	 .a3(addr_in[3]),
	 .a8(addr_in[8]),
	 .a9(addr_in[9]),
	 .a10(addr_in[10]),
	 .a11(addr_in[11]),

	 .latch_ce_n(latch_ce_n),
	 .roma8(roma8),
	 .roma9(roma9),
	 .roma10(roma10),
	 .romen_n(romen_n),
	 .phi2(phi2),
	 .d0(d0)
	 //.c8(oe_dbg)
	 );

	 wire [7:0] romout;

	 reg [10:0] rom_addr;

	 reg [7:0] dat;
	 always @(posedge clk_16m) begin
		 rom_addr <= {roma10, roma9, roma8, addr_in[7:0]};
		 dat <= data_in;
	 end



	 codeROM rom_i(
		 .clk(clk_16m),
		 .addr(rom_addr),
		 .reset(~_reset),
		 .dout(romout)
	 );

	 reg [7:0] rs_data;
	 always @(posedge clk_16m) begin
		 rs_data <= (rw & ~_devsel & ~addr_in[3]) ? {uart6551_dout[7:1], 1'b0} : uart6551_dout;
		 //rs_data <= uart6551_dout;
	 end

	 assign _en245 = ~(/*en245Delay == 2'b11 &&*/ (~romen_n || latch_ce_n));

	 assign _nmi = 1'b1;
	 assign _inh = 1'b1;
	 assign _rdy = 1'b1;

	 reg [1:0] lastDataEnable;

	 always @(posedge fclk) begin
		 lastDataEnable <= { lastDataEnable[0], romen_n == 0 || latch_ce_n == 1 };
	 end

	 //wire oe = (rw == 1 && romen_n == 0) || (rw == 1 && _devsel == 0 && addr_in[3] == 1);
	 //wire oe = (rw == 1 && romen_n == 0) || (~latch_ce_n) == 0;
	 wire oe = (/*lastDataEnable == 2'b11 &&*/ romen_n == 0) || (/*lastDataEnable == 2'b11 &&*/ latch_ce_n == 1);

	 assign data_out = (/*lastDataEnable == 2'b11 &&*/ romen_n == 0) ? romout : (/*lastDataEnable == 2'b11 &&*/ latch_ce_n ==1) ? rs_data : 8'b0;
	 //assign data_out = (rw == 1 && romen_n == 0) ? romout : (rw == 1 && _devsel == 0 && addr_in[3] == 1) ? uart6551_dout : 8'b0;
	 //assign data_out = (rw == 1 && romen_n == 0) ? romout : (~latch_ce_n) == 0 ? uart6551_dout : 8'b0;

	 wire [7:0] data_in;
	 wire [7:0] data_out;
	 SB_IO #(
		 .PIN_TYPE(6'b 1010_01)
	 ) data_pins [7:0] (
		 .PACKAGE_PIN(data),
		 .OUTPUT_ENABLE(oe),
		 .D_OUT_0(data_out),
		 .D_IN_0(data_in)
	 );

	 endmodule
	 // vim: ts=2 sw=2 sts=2 sr noet
