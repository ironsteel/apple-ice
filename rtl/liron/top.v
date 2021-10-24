`default_nettype none

module top(
	// bus interface
	input clk_16,
	input [11:0] addr,
	input fclk, // Clock for serial communication, either 7 or 8 MHz (7 MHz on Apple II)
	input q3, // 2 MHz non-symmetric timing signal
	inout [7:0] data,
	input rw, // 1 means read, 0 means write
	input _iostrobe, // goes low during read or write to any address $C800-$CFFF
	input _iosel, // goes low during read or write to $CX00-$CXFF, where X is slot number
	input _devsel, // goes low during read or write to $C0(X+8)0-$C0(X+8)F, where X is slot number. IWM: Falling edge latches A3-A0. Rising edge of (Q3 or _devsel) qualifies write register data
	input _reset,
	// disk interface
	output wrdata,
	output [3:0] phase,
	output _wrreq,
	output _enbl1,
	inout select, // output that may be hardwired to ground when connected to a drive 
	input sense,
	input rddata,
	// level-shifting buffers
	output _en245, // bidirectional connection of data bus to FPGA
	input btn,
	inout _nmi,
	inout _irq,
	inout _inh,
	inout _rdy,
	input phi0
);

	// Leave these in high-z state so we don't interfere
	assign _nmi = 1'bz;
	assign _irq = 1'bz;
	assign _inh = 1'bz;
	assign _rdy = 1'bz;

	wire isOutputting;
	wire romExpansionActive; // 1 if the Yellowstone card's ROM is the currently selected slot ROM
	wire _romoe;

	// 50Mhz clock for more timing critical sisnals
	wire clk_50;
	pll pll_i(
		.clock_in(clk_16),
		.clock_out(clk_50)
	);

	// IMPORTANT! TO-DO
	// for select, _enbl2, _en35, these outputs may be driven externally to ground!
	// never drive these actively high. configure as inout, enable the internal pull-up, and set output value to 0 or hi-Z
	// may need to pause a few microseconds after setting these to hi-Z to let the pull-up work. It's around 50Kohm equivalent.
	// RC time constant assuming 10 pF trace capacitance is 0.5 microseconds

	wire _enbl2_from_iwm;
	assign select = 1'bZ;

	addrDecoder myAddrDecoder(
		.addr(addr),
		.fclk(fclk),
		._iostrobe(_iostrobe),
		._iosel(_iosel),
		._reset(_reset),
		._romoe(_romoe),
		.romExpansionActive(romExpansionActive)
	);

	wire [7:0] iwmDataOut;
	wire [7:0] buffer2;

	wire motor;

	iwm myIwm(
		.clk(clk_50),
		.addr(addr[3:0]),
		._devsel(_devsel),
		.fclk(fclk),
		.q3(q3),
		._reset(_reset),
		.dataIn(data_in),
		.dataOut(iwmDataOut),
		.wrdata(wrdata),
		.phase(phase),
		._wrreq(_wrreq),
		._enbl1(_enbl1),
		._enbl2(_enbl2_from_iwm),
		.sense(sense),
		.rddata(rddata)
	);

	wire [2:0] sync;
	wire underrun;
	wire [5:0] bitTimer;

	wire latch;

	wire [7:0] romOutput;

	codeROM myROM(
		.clk(fclk), // use internal clock?
		.Address(addr[11:0]),
		.Reset(0),
		.Q(romOutput)
	);

	// Delay outputting data on the bus
	// We need to put the data on the bus 200ns before the end of phi0
	// otherwise busconflicts may occur with other cards
	reg [1:0] en245Delay;
	always @(posedge fclk) begin
		en245Delay <= { en245Delay[0], (~_devsel || ~_romoe) };
	end

	assign _en245 = ~(~q3 &&(en245Delay[1:0] == 2'b11) && (~_devsel ||  ~_romoe)); // IWM selected or ROM outputting

	reg [1:0] lastDataEnable;

	always @(posedge fclk) begin
		lastDataEnable <= { lastDataEnable[0], (rw == 1 && _romoe == 0) || (rw == 1 && _devsel == 0 && addr[0] == 0) };
	end

	wire data_en = lastDataEnable[1:0] == 2'b11;

	// provide data from the card's ROM, or the IWM?
	// IWM registers are read during any operation in which A0 is 0
	wire iwm_oe = (data_en == 1 && rw == 1 && _devsel == 0 && addr[0] == 0);
	wire rom_oe = (data_en == 1 && rw == 1 && _romoe == 0);

	wire [7:0] data_out = rom_oe ? romOutput :
			     iwm_oe ? iwmDataOut : 8'b0;

	wire DE = rom_oe || iwm_oe;
	wire [7:0] data_in;
	SB_IO #(
		.PIN_TYPE(6'b 1010_01)
	) sram_data_pins [7:0] (
		.PACKAGE_PIN(data),
		.OUTPUT_ENABLE(DE),
		.D_OUT_0(data_out),
		.D_IN_0(data_in)
	);

endmodule
