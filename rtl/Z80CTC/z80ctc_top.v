`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Original VHDL:
//
// library ieee;
// use ieee.std_logic_1164.all;
// use ieee.std_logic_unsigned.all;
// use ieee.numeric_std.all;
//
// entity z80ctc_top is
// port(
//  clock     : in  std_logic;
//  clock_ena : in  std_logic;
//  reset     : in  std_logic;
//
//  din       : in  std_logic_vector(7 downto 0);
//  dout      : out std_logic_vector(7 downto 0);
//  cpu_din   : in  std_logic_vector(7 downto 0);
//
//  ce_n      : in  std_logic;
//  cs        : in  std_logic_vector(1 downto 0);
//  m1_n      : in  std_logic;
//  iorq_n    : in  std_logic;
//  rd_n      : in  std_logic;
//  int_n     : out std_logic;
//
//  trg0      : in  std_logic;
//  to0       : out std_logic;
//
//  trg1      : in  std_logic;
//  to1       : out std_logic;
//
//  trg2      : in  std_logic;
//  to2       : out std_logic;
//
//  trg3      : in  std_logic
// );
// end z80ctc_top;
//
// architecture struct of z80ctc_top is
////////////////////////////////////////////////////////////////////////////////

module z80ctc_top (
    input  wire        clock,
    input  wire        clock_ena,
    input  wire        reset,

    input  wire [7:0]  din,
    output reg  [7:0]  dout,
    input  wire [7:0]  cpu_din,

    input  wire        ce_n,
    input  wire [1:0]  cs,
    input  wire        m1_n,
    input  wire        iorq_n,
    input  wire        rd_n,
    output wire        int_n,

    input  wire        trg0,
    output wire        to0,

    input  wire        trg1,
    output wire        to1,

    input  wire        trg2,
    output wire        to2,

    input  wire        trg3
);

////////////////////////////////////////////////////////////////////////////////
// -- signal cpu_int_ack_n     : std_logic;
// -- signal ctc_controler_we  : std_logic;
// -- signal ctc_controler_do  : std_logic_vector(7 downto 0);
// -- signal ctc_int_ack       : std_logic;
// -- signal ctc_int_ack_phase : std_logic_vector(1 downto 0);
//
// -- signal ctc_counter_0_we  : std_logic;
// -- signal ctc_counter_0_do  : std_logic_vector(7 downto 0);
// -- signal ctc_counter_0_int : std_logic;
//
// -- signal ctc_counter_1_we  : std_logic;
// -- signal ctc_counter_1_do  : std_logic_vector(7 downto 0);
// -- signal ctc_counter_1_int : std_logic;
//
// -- signal ctc_counter_2_we  : std_logic;
// -- signal ctc_counter_2_do  : std_logic_vector(7 downto 0);
// -- signal ctc_counter_2_int : std_logic;
//
// -- signal ctc_counter_3_we  : std_logic;
// -- signal ctc_counter_3_do  : std_logic_vector(7 downto 0);
// -- signal ctc_counter_3_int : std_logic;
////////////////////////////////////////////////////////////////////////////////

// In Verilog, we declare these as regs or wires as needed.
// Outputs from submodules are typically wires. Internal "control" signals
// can be wires driven by assign statements or always blocks.

reg        cpu_int_ack_n;
wire       ctc_controler_we;  // or reg, depending on style (we can assign it via combinational logic)
wire [7:0] ctc_controler_do;
wire       ctc_int_ack;       // can be assigned combinationally
reg  [1:0] ctc_int_ack_phase;

wire       ctc_counter_0_we;
wire [7:0] ctc_counter_0_do;
wire       ctc_counter_0_int;

wire       ctc_counter_1_we;
wire [7:0] ctc_counter_1_do;
wire       ctc_counter_1_int;

wire       ctc_counter_2_we;
wire [7:0] ctc_counter_2_do;
wire       ctc_counter_2_int;

wire       ctc_counter_3_we;
wire [7:0] ctc_counter_3_do;
wire       ctc_counter_3_int;

////////////////////////////////////////////////////////////////////////////////
// VHDL process:
//
// process (clock, reset)
// begin
//   if reset = '1' then
//     ctc_int_ack_phase <= "00";
//   elsif rising_edge(clock) then
//     -- decode ED4D (reti)
//     if clock_ena = '1' and rd_n = '0' and m1_n = '0' then
//       case ctc_int_ack_phase is
//       when "00" => if cpu_din = x"ED" then ctc_int_ack_phase <= "01"; end if;
//       when "01" => if cpu_din = x"4D" then ctc_int_ack_phase <= "11";
//                    elsif cpu_din /= x"ED" then ctc_int_ack_phase <= "00"; end if;
//       when "11" => if cpu_din = x"ED" then ctc_int_ack_phase <= "01";
//                    elsif cpu_din /= x"4D" then ctc_int_ack_phase <= "00"; end if;
//       when others => ctc_int_ack_phase <= "00";
//       end case;
//     end if;
//   end if;
// end process;
////////////////////////////////////////////////////////////////////////////////

always @(posedge clock or posedge reset) begin
    if (reset) begin
        ctc_int_ack_phase <= 2'b00;
    end
    else begin
        if (clock_ena == 1'b1 && rd_n == 1'b0 && m1_n == 1'b0) begin
            case (ctc_int_ack_phase)
                2'b00: begin
                    if (cpu_din == 8'hED)
                        ctc_int_ack_phase <= 2'b01;
                end
                2'b01: begin
                    if (cpu_din == 8'h4D)
                        ctc_int_ack_phase <= 2'b11;
                    else if (cpu_din != 8'hED)
                        ctc_int_ack_phase <= 2'b00;
                end
                2'b11: begin
                    if (cpu_din == 8'hED)
                        ctc_int_ack_phase <= 2'b01;
                    else if (cpu_din != 8'h4D)
                        ctc_int_ack_phase <= 2'b00;
                end
                default: ctc_int_ack_phase <= 2'b00;
            endcase
        end
    end
end

////////////////////////////////////////////////////////////////////////////////
// -- ctc_int_ack <= '1' when ctc_int_ack_phase = "11" else '0';
// -- cpu_int_ack_n <= iorq_n or m1_n;
////////////////////////////////////////////////////////////////////////////////

// In Verilog, we can do these as continuous assigns:

assign ctc_int_ack   = (ctc_int_ack_phase == 2'b11);
always @* begin
    cpu_int_ack_n = iorq_n | m1_n;
end

////////////////////////////////////////////////////////////////////////////////
// -- ctc_controler_we <= '1' when ce_n = '0' and iorq_n = '0' and m1_n = '1' and
// --                      rd_n = '1' and cs = "00" else '0';
//
// -- ctc_counter_0_we <= '1' when ce_n = '0' and iorq_n = '0' and m1_n = '1' and
// --                     rd_n = '1' and cs = "00" else '0';
//
// -- ctc_counter_1_we <= '1' when ce_n = '0' and iorq_n = '0' and m1_n = '1' and
// --                     rd_n = '1' and cs = "01" else '0';
//
// -- ctc_counter_2_we <= '1' when ce_n = '0' and iorq_n = '0' and m1_n = '1' and
// --                     rd_n = '1' and cs = "10" else '0';
//
// -- ctc_counter_3_we <= '1' when ce_n = '0' and iorq_n = '0' and m1_n = '1' and
// --                     rd_n = '1' and cs = "11" else '0';
////////////////////////////////////////////////////////////////////////////////

assign ctc_controler_we = (ce_n == 1'b0 && iorq_n == 1'b0 && m1_n == 1'b1 &&
                           rd_n == 1'b1 && cs == 2'b00);

assign ctc_counter_0_we = (ce_n == 1'b0 && iorq_n == 1'b0 && m1_n == 1'b1 &&
                           rd_n == 1'b1 && cs == 2'b00);

assign ctc_counter_1_we = (ce_n == 1'b0 && iorq_n == 1'b0 && m1_n == 1'b1 &&
                           rd_n == 1'b1 && cs == 2'b01);

assign ctc_counter_2_we = (ce_n == 1'b0 && iorq_n == 1'b0 && m1_n == 1'b1 &&
                           rd_n == 1'b1 && cs == 2'b10);

assign ctc_counter_3_we = (ce_n == 1'b0 && iorq_n == 1'b0 && m1_n == 1'b1 &&
                           rd_n == 1'b1 && cs == 2'b11);

////////////////////////////////////////////////////////////////////////////////
// -- dout <= ctc_controler_do when cpu_int_ack_n = '0' else
// --         ctc_counter_0_do when iorq_n = '0' and m1_n = '1' and rd_n = '0' and cs = "00" else
// --         ctc_counter_1_do when iorq_n = '0' and m1_n = '1' and rd_n = '0' and cs = "01" else
// --         ctc_counter_2_do when iorq_n = '0' and m1_n = '1' and rd_n = '0' and cs = "10" else
// --         ctc_counter_3_do when iorq_n = '0' and m1_n = '1' and rd_n = '0' and cs = "11" else
// --         x"FF";
////////////////////////////////////////////////////////////////////////////////

always @* begin
    if (cpu_int_ack_n == 1'b0) begin
        dout = ctc_controler_do;
    end
    else if (iorq_n == 1'b0 && m1_n == 1'b1 && rd_n == 1'b0 && cs == 2'b00) begin
        dout = ctc_counter_0_do;
    end
    else if (iorq_n == 1'b0 && m1_n == 1'b1 && rd_n == 1'b0 && cs == 2'b01) begin
        dout = ctc_counter_1_do;
    end
    else if (iorq_n == 1'b0 && m1_n == 1'b1 && rd_n == 1'b0 && cs == 2'b10) begin
        dout = ctc_counter_2_do;
    end
    else if (iorq_n == 1'b0 && m1_n == 1'b1 && rd_n == 1'b0 && cs == 2'b11) begin
        dout = ctc_counter_3_do;
    end
    else begin
        dout = 8'hFF;
    end
end

////////////////////////////////////////////////////////////////////////////////
// -- ctc_controler : entity work.ctc_controler
// -- port map(
// --   clock     => clock,
// --   clock_ena => clock_ena,
// --   reset     => reset,
// --
// --   d_in      => din,
// --   load_data => ctc_controler_we,
// --   int_ack   => cpu_int_ack_n,
// --   int_end   => ctc_int_ack,
// --
// --   int_pulse_0 => ctc_counter_0_int,
// --   int_pulse_1 => ctc_counter_1_int,
// --   int_pulse_2 => ctc_counter_2_int,
// --   int_pulse_3 => ctc_counter_3_int,
// --
// --   d_out     => ctc_controler_do,
// --   int_n     => int_n
// -- );
////////////////////////////////////////////////////////////////////////////////

// Instantiate your ctc_controler module (which you must define separately in Verilog).
// The port order/widths must match your actual ctc_controler design.

ctc_controler ctc_controler_inst (
    .clock        (clock),
    .clock_ena    (clock_ena),
    .reset        (reset),

    .d_in         (din),
    .load_data    (ctc_controler_we),
    .int_ack      (cpu_int_ack_n),
    .int_end      (ctc_int_ack),

    .int_pulse_0  (ctc_counter_0_int),
    .int_pulse_1  (ctc_counter_1_int),
    .int_pulse_2  (ctc_counter_2_int),
    .int_pulse_3  (ctc_counter_3_int),

    .d_out        (ctc_controler_do),
    .int_n        (int_n)
);

////////////////////////////////////////////////////////////////////////////////
// -- ctc_counter_0 : entity work.ctc_counter
// -- port map(
// --   clock     => clock,
// --   clock_ena => clock_ena,
// --   reset     => reset,
// --
// --   d_in      => din,
// --   load_data => ctc_counter_0_we,
// --
// --   clk_trg   => trg0,
// --
// --   d_out     => ctc_counter_0_do,
// --   zc_to     => to0,
// --   int_pulse => ctc_counter_0_int
// -- );
////////////////////////////////////////////////////////////////////////////////

ctc_counter ctc_counter_0_inst (
    .clock     (clock),
    .clock_ena (clock_ena),
    .reset     (reset),

    .d_in      (din),
    .load_data (ctc_counter_0_we),

    .clk_trg   (trg0),

    .d_out     (ctc_counter_0_do),
    .zc_to     (to0),
    .int_pulse (ctc_counter_0_int)
);

////////////////////////////////////////////////////////////////////////////////
// Repeat for ctc_counter_1, ctc_counter_2, ctc_counter_3
////////////////////////////////////////////////////////////////////////////////

ctc_counter ctc_counter_1_inst (
    .clock     (clock),
    .clock_ena (clock_ena),
    .reset     (reset),

    .d_in      (din),
    .load_data (ctc_counter_1_we),

    .clk_trg   (trg1),

    .d_out     (ctc_counter_1_do),
    .zc_to     (to1),
    .int_pulse (ctc_counter_1_int)
);

ctc_counter ctc_counter_2_inst (
    .clock     (clock),
    .clock_ena (clock_ena),
    .reset     (reset),

    .d_in      (din),
    .load_data (ctc_counter_2_we),

    .clk_trg   (trg2),

    .d_out     (ctc_counter_2_do),
    .zc_to     (to2),
    .int_pulse (ctc_counter_2_int)
);

ctc_counter ctc_counter_3_inst (
    .clock     (clock),
    .clock_ena (clock_ena),
    .reset     (reset),

    .d_in      (din),
    .load_data (ctc_counter_3_we),

    .clk_trg   (trg3),

    .d_out     (ctc_counter_3_do),
    .zc_to     (),                // 'open' in VHDL → unconnected in Verilog
    .int_pulse (ctc_counter_3_int)
);

endmodule