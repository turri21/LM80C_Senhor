`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Original VHDL:
//
// entity ctc_counter is
// port(
//   clock     : in std_logic;
//   clock_ena : in std_logic;
//   reset     : in std_logic;
//
//   d_in      : in std_logic_vector( 7 downto 0);
//   load_data : in std_logic;
//
//   clk_trg   : in std_logic;
//
//   d_out     : out std_logic_vector(7 downto 0);
//   zc_to     : out std_logic;
//   int_pulse : out std_logic
// );
// end ctc_counter;
//
// architecture struct of ctc_counter is
//
//   signal control_word : std_logic_vector(7 downto 0);
//   signal wait_for_time_constant : std_logic;
//   signal time_constant_loaded   : std_logic;
//   signal restart_on_next_clock  : std_logic;
//   signal restart_on_next_trigger: std_logic;
//
//   signal prescale_max : std_logic_vector(7 downto 0);
//   signal prescale_in  : std_logic_vector(7 downto 0) := (others => '0');
//   signal count_max    : std_logic_vector(7 downto 0);
//   signal count_in     : std_logic_vector(7 downto 0) := (others => '0');
//
//   signal zc_to_in     : std_logic;
//   signal clk_trg_in   : std_logic;
//   signal clk_trg_r    : std_logic;
//   signal trigger      : std_logic;
//   signal count_ena    : std_logic;
//   signal load_data_r  : std_logic;
//
// begin
//
//   prescale_max <=
//       (others => '0') when control_word(6) = '1' else
//       X"0F" when control_word(6 downto 5) = "00" else
//       X"FF";
//
//   clk_trg_in <= clk_trg xor control_word(4);
//   trigger <= '1' when clk_trg_in = '0' and clk_trg_r = '1' else '0';
//
//   d_out <= count_in(7 downto 0);
//
//   zc_to <= zc_to_in;
//   int_pulse <= zc_to_in when control_word(7) = '1' else '0';
//
//   process (reset, clock)
//   begin
//     if reset = '1' then
//       count_ena <= '0';
//       wait_for_time_constant <= '0';
//       time_constant_loaded   <= '0';
//       restart_on_next_clock <= '0';
//       restart_on_next_trigger <= '0';
//       count_in  <= (others => '0');
//       zc_to_in <= '0';
//       clk_trg_r <= '0';
//     else
//       if rising_edge(clock) then
//         if clock_ena = '1' then
//
//           clk_trg_r <= clk_trg_in;
//           load_data_r <= load_data;
//
//           if (restart_on_next_trigger = '1' and trigger = '1') or
//              (restart_on_next_clock = '1') then
//             restart_on_next_clock <= '0';
//             restart_on_next_trigger <= '0';
//             count_ena <= '1';
//             count_in <= count_max;
//             prescale_in <= prescale_max;
//           end if;
//
//           if load_data = '1' and load_data_r = '0' then
//             if wait_for_time_constant = '1' then
//               wait_for_time_constant <= '0';
//               time_constant_loaded   <= '1';
//               count_max <= d_in;
//
//               if control_word(6) = '0' and count_ena = '0' then
//                 if control_word(3) = '0' then
//                   restart_on_next_clock <= '1';
//                 else
//                   restart_on_next_trigger <= '1';
//                 end if;
//               end if;
//
//               if control_word(6) = '1' then
//                 prescale_in <= (others => '0');
//                 count_in <= d_in;
//               end if;
//
//             else  -- not waiting for time constant
//
//               if d_in(0) = '1' then -- check if it's a control word
//                 control_word <= d_in;
//                 wait_for_time_constant <= d_in(2);
//                 restart_on_next_clock <= '0';
//                 restart_on_next_trigger <= '0';
//
//                 if d_in(1) = '1' then -- software reset
//                   count_ena <= '0';
//                   time_constant_loaded <= '0';
//                   zc_to_in <= '0';
//                   clk_trg_r <= clk_trg xor d_in(4);
//                 end if;
//               end if;
//
//             end if;
//           end if; -- end load_data
//
//           -- counter
//           zc_to_in <= '0';
//
//           if ((control_word(6) = '1' and trigger = '1') or
//               (control_word(6) = '0' and count_ena = '1')) and
//               time_constant_loaded = '1' then
//             if prescale_in = 0 then
//               prescale_in <= prescale_max;
//               if count_in = 1 then
//                 zc_to_in <= '1';
//                 count_in <= count_max;
//               else
//                 count_in <= count_in - '1';
//               end if;
//             else
//               prescale_in <= prescale_in - '1';
//             end if;
//           end if;
//
//         end if;
//       end if;
//     end if;
//   end process;
//
// end struct;
////////////////////////////////////////////////////////////////////////////////


module ctc_counter (
    input  wire        clock,
    input  wire        clock_ena,
    input  wire        reset,

    input  wire [7:0]  d_in,
    input  wire        load_data,

    input  wire        clk_trg,

    output wire [7:0]  d_out,
    output wire        zc_to,
    output wire        int_pulse
);

////////////////////////////////////////////////////////////////////////////////
// Internal signals (translated from the VHDL signals):
////////////////////////////////////////////////////////////////////////////////
reg  [7:0] control_word;
reg        wait_for_time_constant;
reg        time_constant_loaded;
reg        restart_on_next_clock;
reg        restart_on_next_trigger;

reg  [7:0] prescale_max;
reg  [7:0] prescale_in;  // initially all '0'
reg  [7:0] count_max;
reg  [7:0] count_in;     // initially all '0'

reg        zc_to_in;
wire       clk_trg_in;
reg        clk_trg_r;
wire       trigger;
reg        count_ena;
reg        load_data_r;

////////////////////////////////////////////////////////////////////////////////
// Combinational equivalents of VHDL concurrent statements
////////////////////////////////////////////////////////////////////////////////

// VHDL line:
// prescale_max <= (others => '0') when control_word(6)='1' else
//                 X"0F" when control_word(6 downto 5)="00" else
//                 X"FF".
//
// We'll generate this in an always @* block, or do an inline function:
always @* begin
    if (control_word[6] == 1'b1) begin
        prescale_max = 8'h00;
    end
    else if (control_word[6:5] == 2'b00) begin
        prescale_max = 8'h0F;
    end
    else begin
        prescale_max = 8'hFF;
    end
end

// VHDL line:
// clk_trg_in <= clk_trg xor control_word(4);
assign clk_trg_in = clk_trg ^ control_word[4];

// VHDL line:
// trigger <= '1' when clk_trg_in='0' and clk_trg_r='1' else '0';
assign trigger = ((clk_trg_in == 1'b0) && (clk_trg_r == 1'b1)) ? 1'b1 : 1'b0;

// VHDL line:
// d_out <= count_in(7 downto 0);
assign d_out = count_in;

// VHDL line:
// zc_to <= zc_to_in;
assign zc_to = zc_to_in;

// VHDL line:
// int_pulse <= zc_to_in when control_word(7)='1' else '0';
assign int_pulse = (control_word[7] == 1'b1) ? zc_to_in : 1'b0;

////////////////////////////////////////////////////////////////////////////////
// Clocked process
//   if reset='1' then ...
//   elsif rising_edge(clock) then ...
////////////////////////////////////////////////////////////////////////////////
always @(posedge clock or posedge reset) begin
    if (reset) begin
        // Asynchronous reset
        count_ena             <= 1'b0;
        wait_for_time_constant<= 1'b0;
        time_constant_loaded  <= 1'b0;
        restart_on_next_clock <= 1'b0;
        restart_on_next_trigger <= 1'b0;
        count_in             <= 8'h00;
        zc_to_in             <= 1'b0;
        clk_trg_r            <= 1'b0;
        load_data_r          <= 1'b0;
        control_word         <= 8'h00;
        count_max            <= 8'h00;
        prescale_in          <= 8'h00;
    end
    else begin
        if (clock_ena == 1'b1) begin
            // Latch trigger input state
            clk_trg_r   <= clk_trg_in;
            // Latch the load_data edge
            load_data_r <= load_data;

            // If a restart is scheduled
            if ((restart_on_next_trigger == 1'b1 && trigger == 1'b1) ||
                (restart_on_next_clock == 1'b1)) begin
                restart_on_next_clock   <= 1'b0;
                restart_on_next_trigger <= 1'b0;
                count_ena   <= 1'b1;
                count_in    <= count_max;
                prescale_in <= prescale_max;
            end

            // Handling load_data edges
            if ((load_data == 1'b1) && (load_data_r == 1'b0)) begin
                // We have a new data word loaded
                if (wait_for_time_constant == 1'b1) begin
                    // The second word is the time constant
                    wait_for_time_constant <= 1'b0;
                    time_constant_loaded   <= 1'b1;
                    count_max             <= d_in;

                    // If we are in timer mode (control_word(6)=0) and currently stopped
                    if ((control_word[6] == 1'b0) && (count_ena == 1'b0)) begin
                        // Check auto-start or wait for trigger
                        if (control_word[3] == 1'b0) begin
                            restart_on_next_clock <= 1'b1;
                        end
                        else begin
                            restart_on_next_trigger <= 1'b1;
                        end
                    end

                    // If we are in counter mode (control_word(6)=1), reload the counter immediately
                    if (control_word[6] == 1'b1) begin
                        prescale_in <= 8'h00;
                        count_in    <= d_in;
                    end
                end
                else begin
                    // First loaded word might be a control word
                    if (d_in[0] == 1'b1) begin
                        // It's a control word
                        control_word         <= d_in;
                        wait_for_time_constant <= d_in[2];
                        restart_on_next_clock   <= 1'b0;
                        restart_on_next_trigger <= 1'b0;

                        // Check software reset bit (d_in(1))
                        if (d_in[1] == 1'b1) begin
                            count_ena           <= 1'b0;
                            time_constant_loaded <= 1'b0;
                            zc_to_in            <= 1'b0;
                            // Re-sync trigger flip-flop if control_word(4) changed
                            clk_trg_r <= clk_trg ^ d_in[4];
                        end
                    end
                end
            end

            // Counter logic
            zc_to_in <= 1'b0;
            if ((((control_word[6] == 1'b1) && (trigger == 1'b1)) ||
                 ((control_word[6] == 1'b0) && (count_ena == 1'b1))) &&
                 (time_constant_loaded == 1'b1)) begin

                if (prescale_in == 8'h00) begin
                    prescale_in <= prescale_max;
                    if (count_in == 8'h01) begin
                        zc_to_in <= 1'b1;
                        count_in <= count_max;
                    end
                    else begin
                        count_in <= count_in - 8'h01;
                    end
                end
                else begin
                    prescale_in <= prescale_in - 8'h01;
                end
            end

        end // clock_ena
    end // not reset
end

endmodule