//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,
	output        HDMI_BLACKOUT,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;  

assign VGA_F1 = 0;
assign VGA_SCALER  = 0;
assign VGA_DISABLE = 0;
assign HDMI_FREEZE = 0;
assign HDMI_BLACKOUT = 0;

assign AUDIO_S = 0;
assign AUDIO_L = 0;
assign AUDIO_R = 0;
assign AUDIO_MIX = 0;

assign LED_DISK = 0;
assign LED_POWER = 0;
assign BUTTONS = 0;

//////////////////////////////////////////////////////////////////

wire [1:0] ar = status[122:121];

assign VIDEO_ARX = (!ar) ? 12'd4 : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? 12'd3 : 12'd0;

`include "build_id.v" 
localparam CONF_STR = {
	"LM80C;;",
	"-;",
	"O[122:121],Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"O[2],TV Mode,NTSC,PAL;",
	"O[4:3],Noise,White,Red,Green,Blue;",
	"-;",
	"P1,Test Page 1;",
	"P1-;",
	"P1-, -= Options in page 1 =-;",
	"P1-;",
	"P1O[5],Option 1-1,Off,On;",
	"d0P1F1,BIN;",
	"H0P1O[10],Option 1-2,Off,On;",
	"-;",
	"P2,Test Page 2;",
	"P2-;",
	"P2-, -= Options in page 2 =-;",
	"P2-;",
	"P2S0,DSK;",
	"P2O[7:6],Option 2,1,2,3,4;",
	"-;",
	"-;",
	"T[0],Reset;",
	"R[0],Reset and close OSD;",
	"v,0;", // [optional] config version 0-99. 
	        // If CONF_STR options are changed in incompatible way, then change version number too,
			  // so all options will get default values on first start.
	"V,v",`BUILD_DATE 
};

wire        forced_scandoubler;
wire        direct_video;
wire [21:0] gamma_bus;

wire   [1:0] buttons;
wire [127:0] status;
wire  [10:0] ps2_key;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),

	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),

	.buttons(buttons),
	.status(status),
	.status_menumask({status[5]}),
	
	.ps2_key(ps2_key),

	.ioctl_download(ioctl_download),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_wr(ioctl_wr),
	.ioctl_index(ioctl_index)
);

///////////////////////   CLOCKS   ///////////////////////////////

wire clk_sys;
wire pll_locked;
pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys),
	.outclk_1(clk_cpu),
	.locked(pll_locked)
);

wire [1:0] col = status[4:3];

wire [5:0] rgb_r;
wire [5:0] rgb_g;
wire [5:0] rgb_b;

///////////////////   VIDEO   ////////////////////
wire hblank, vblank;
wire hs, vs;
wire rotate_ccw = 1;
wire no_rotate = 1'b1;
wire flip = ~no_rotate;
wire video_rotated;

//screen_rotate screen_rotate (.*);
/*
arcade_video #(256,24) arcade_video
(
	.*,
	.clk_video(vdp_clock),
	.RGB_in({ {2'b00, rgb_r}, {2'b00, rgb_g}, {2'b00, rgb_b} }),
	.HBlank(HBlank),
	.VBlank(VBlank),
	.HSync(hs),
	.VSync(vs),
	.fx(0)
);
*/

/******************************************************************************************/
/******************************************************************************************/
/***************************************** @ena *******************************************/
/******************************************************************************************/
/******************************************************************************************/

wire ce_pix = vdp_ena;

assign cpu_clock = clk_cpu;
assign sys_clock = clk_sys;
assign vdp_clock = clk_sys;

// vdp

reg [1:0] cnt_vdp;
always @(posedge vdp_clock)
	cnt_vdp <= cnt_vdp + 1;
	
wire vdp_ena = cnt_vdp == 0;

// cpu

wire cpu_clock = clk_div[2];
reg [3:0] clk_div;
always @(posedge sys_clock)
	clk_div <= clk_div + 3'd1;

wire z80_ena = clk_div == 0 || clk_div == 8;
wire psg_ena = clk_div == 0;   

/******************************************************************************************/
/******************************************************************************************/
/***************************************** @reset *****************************************/
/******************************************************************************************/
/******************************************************************************************/

// RESET goes into: t80a, vdp, psg, ctc

// reset while booting or when the physical reset key is pressed
wire reset = ~ROM_loaded | RESET | reset_key | eraser_busy | status[0] | buttons[1]; 

// stops the cpu when booting, downloading or erasing
wire WAIT = ~ROM_loaded | is_downloading;

assign LED = ~(WAIT | PIO_data_B[1]);

/******************************************************************************************/
/******************************************************************************************/
/***************************************** @lm80c *****************************************/
/******************************************************************************************/
/******************************************************************************************/

// audio
wire [7:0] CHANNEL_L;
wire [7:0] CHANNEL_R;

// keyboard
wire [7:0] row_select;
wire [7:0] column_bits;

// ram interface
wire [15:0] cpu_addr;
wire [7:0]  cpu_dout;
wire        cpu_rd;
wire        cpu_wr;

// PIO
wire [7:0] PIO_data_A;
wire [7:0] PIO_data_B;

wire ROM_ENABLED = PIO_data_B[0];   // bit 0 of PIO B is used to switch between ROM and RAM

lm80c lm80c
(
	.RESET(reset),
	.WAIT(WAIT),
	
    // clocks
	.sys_clock(sys_clock),		
	.vdp_clock(vdp_clock),	
	
	.vdp_ena(vdp_ena),
	.z80_ena(z80_ena),	
	.psg_ena(psg_ena),
		
	// video
	.R  ( rgb_r  ),
	.G  ( rgb_g  ),
	.B  ( rgb_b  ),
	.HS ( hs ),
	.VS ( vs ),
    .VBlank ( VBlank ),
    .HBlank ( HBlank ),
	
	// audio
	.CHANNEL_L(CHANNEL_L), 
    .CHANNEL_R(CHANNEL_R), 
	
	// keyboard	
	.KM(KM),
	
	// RAM interface
	.ram_addr (cpu_addr),
	.ram_din  (cpu_dout),
	.ram_dout (sdram_dout),
	.ram_rd   (cpu_rd),
	.ram_wr   (cpu_wr),
	
	// parallel port
	.PIO_data_A  (PIO_data_A),
	.PIO_data_B  (PIO_data_B)	
);

/******************************************************************************************/
/******************************************************************************************/
/***************************************** @keyboard **************************************/
/******************************************************************************************/
/******************************************************************************************/
		 
wire ps2_kbd_clk;
wire ps2_kbd_data;

wire        key_valid;
wire [15:0] key;
wire        key_status;

wire reset_key;
wire [7:0] KM[7:0];

reg         key_strobe;
wire        key_pressed;
wire        key_extended;
wire  [7:0] key_code;
wire        upcase;

assign key_extended = ps2_key[8];
assign key_pressed  = ps2_key[9];
assign key_code     = ps2_key[7:0];

always @(posedge clk_cpu) begin
    reg old_state;
    old_state <= ps2_key[10];

    if(old_state != ps2_key[10]) begin
       key_strobe <= ~key_strobe;
    end
end

lm80c_ps2keyboard_adapter kbd
(
	.reset    ( reset ),
	.clk      ( sys_clock    ),
	
	// input
	.valid      ( key_strobe    ),
	.key        ( ps2_key       ),
	.key_status ( key_pressed   ),
	
	// output
	.KM       ( KM           ),	
	.resetkey ( reset_key    )
);


/******************************************************************************************/
/******************************************************************************************/
/***************************************** @downloader ************************************/
/******************************************************************************************/
/******************************************************************************************/

wire        is_downloading;
wire [24:0] download_addr;
wire [7:0]  download_data;
wire        download_wr;
wire        ROM_loaded;

// ROM download helper
downloader 
#(
    .BOOT_INDEX (0),
	.PRG_INDEX  (2),
	.ROM_INDEX  (3),	
	.ROM_START_ADDR  (25'h00000), // start of ROM (bank 0 of SDRAM)
	.PRG_START_ADDR  (25'h15608), // start of BASIC program in free RAM: print hex$(deek(BASTXT))
	.PTR_PROGND      (25'h155e4)  // pointer to end of basic program
)
downloader (
	
	// new SPI interface
    //.SPI_DO ( SPI_DO  ),
	//.SPI_DI ( SPI_DI  ),
    //.SPI_SCK( SPI_SCK ),
    //.SPI_SS2( SPI_SS2 ),
    //.SPI_SS3( SPI_SS3 ),
    //.SPI_SS4( SPI_SS4 ),
	
    .ioctl_download(ioctl_download),  // signal indicating an active rom download
	.ioctl_index(ioctl_index),     // 0=rom download, 1=prg dowload
    .ioctl_addr(ioctl_addr),
    .ioctl_dout(ioctl_dout),
	.ioctl_wr(ioctl_wr),

    // signal indicating an active rom download
    .downloading ( is_downloading  ),
    .ROM_done    ( ROM_loaded      ),	
	         
    // external ram interface
    .clk     ( sys_clock     ),
    .clk_ena ( 1             ),
    .wr      ( download_wr   ),
    .addr    ( download_addr ),
    .data    ( download_data )	
);

/******************************************************************************************/
/******************************************************************************************/
/***************************************** @eraser ****************************************/
/******************************************************************************************/
/******************************************************************************************/

wire eraser_busy;
wire eraser_wr;
wire [24:0] eraser_addr;
wire [7:0]  eraser_data;

eraser eraser(
	.clk      ( sys_clock     ),
	.ena      ( z80_ena       ),
	.trigger  ( st_menu_reset ),	
	.erasing  ( eraser_busy   ),
	.wr       ( eraser_wr     ),
	.addr     ( eraser_addr   ),
	.data     ( eraser_data   )
);

/******************************************************************************************/
/******************************************************************************************/
/***************************************** @sdram *****************************************/
/******************************************************************************************/
/******************************************************************************************/
			
// SDRAM control signals
assign SDRAM_CLK = ~sys_clock;

reg [24:0] sdram_addr;
reg  [7:0] sdram_din;
reg        sdram_wr;
reg        sdram_rd;
reg [7:0]  sdram_dout;

always @(*) begin
	if(is_downloading && download_wr) begin
		sdram_addr   <= download_addr;
		sdram_din    <= download_data;
		sdram_wr     <= download_wr;
		sdram_rd     <= 1'b1;			
	end	
	else if(eraser_busy) begin		
		sdram_addr   <= eraser_addr;
		sdram_din    <= eraser_data;
		sdram_wr     <= eraser_wr;
		sdram_rd     <= 1'b1;		
	end	
	else begin
		sdram_addr   <= { 8'd0, RAM_OFFSET, cpu_addr[15:0] };
		sdram_din    <= cpu_dout;		
		sdram_wr     <= cpu_wr;
		sdram_rd     <= cpu_rd;
	end	
end

// SDRAM is organized the following way:
// from 0-0000 to 0-7FFF LM80C 32K ROM
// from 0-8000 to 0-FFFF unused 
// from 1-0000 to 1-FFFF LM80C 64K RAM
// from 2-0000 to max    unused

wire RAM_OFFSET = ~ROM_ENABLED | (cpu_addr[15:0] > 'h7fff);

// 96K x 8 bits rom + ram

/*
dpram #(8, 24) sdram
(
	.clock_a(sys_clock),
	.address_a(sdram_addr),
	.wren_a(sdram_wr),
	.data_a(sdram_din),
	.q_a(sdram_dout),

	.clock_b(),
	.wren_b(),
	.address_b(),
	.data_b(),
	.q_b()
);
*/

sdram sdram
(
   .*,
   .init(~pll_locked),
   .clk(sys_clock),

   .wtbt(0),
   .addr(sdram_addr),
   .rd(sdram_rd),
   .dout(sdram_dout),
   .din(sdram_din),
   .we(sdram_wr),
   .ready()
);

endmodule
