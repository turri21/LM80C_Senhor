`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Original VHDL:
//
// entity ctc_controler is
// port(
//   clock        : in std_logic;
//   clock_ena    : in std_logic;
//   reset        : in std_logic;
//
//   d_in         : in std_logic_vector(7 downto 0);
//   load_data    : in std_logic;
//   int_ack      : in std_logic;
//   int_end      : in std_logic; -- RETI detected
//
//   int_pulse_0  : in std_logic;
//   int_pulse_1  : in std_logic;
//   int_pulse_2  : in std_logic;
//   int_pulse_3  : in std_logic;
//
//   d_out        : out std_logic_vector(7 downto 0);
//   int_n        : out std_logic
// );
// end ctc_controler;
//
// architecture struct of ctc_controler is
//
//   signal int_vector             : std_logic_vector(4 downto 0);
//   signal wait_for_time_constant : std_logic;
//   signal load_data_r            : std_logic;
//   signal int_reg_0              : std_logic;
//   signal int_reg_1              : std_logic;
//   signal int_reg_2              : std_logic;
//   signal int_reg_3              : std_logic;
//   signal int_in_service         : std_logic_vector(3 downto 0);
//   signal int_ack_r              : std_logic;
//   signal int_end_r              : std_logic;
//
// begin
//
//   int_n <= '0' when (int_reg_0 or int_reg_1 or int_reg_2 or int_reg_3) = '1' else '1';
//
//   d_out <= int_vector & "000" when int_reg_0 = '1' else
//            int_vector & "010" when int_reg_1 = '1' else
//            int_vector & "100" when int_reg_2 = '1' else
//            int_vector & "110" when int_reg_3 = '1' else (others => '0');
//
//   process (reset, clock)
//   begin
//     if reset = '1' then
//       wait_for_time_constant <= '0';
//       int_reg_0 <= '0';
//       int_reg_1 <= '0';
//       int_reg_2 <= '0';
//       int_reg_3 <= '0';
//       int_in_service <= (others => '0');
//       load_data_r <= '0';
//       int_vector <= (others => '0');
//     else
//       if rising_edge(clock) then
//         if clock_ena = '1' then
//           load_data_r <= load_data;
//           int_ack_r <= int_ack;
//           int_end_r <= int_end;
//
//           if load_data = '1' and load_data_r = '0' then
//             if wait_for_time_constant = '1' then
//               wait_for_time_constant <= '0';
//             else
//               if d_in(0) = '1' then
//                 wait_for_time_constant <= d_in(2);
//               else
//                 int_vector <= d_in(7 downto 3);
//               end if;
//             end if;
//           end if;
//
//           if int_pulse_0 = '1' and int_in_service(0) = '0' then int_reg_0 <= '1'; end if;
//           if int_pulse_1 = '1' and int_in_service(1 downto 0) = "00" then int_reg_1 <= '1'; end if;
//           if int_pulse_2 = '1' and int_in_service(2 downto 0) = "000" then int_reg_2 <= '1'; end if;
//           if int_pulse_3 = '1' and int_in_service(3 downto 0) = "0000" then int_reg_3 <= '1'; end if;
//
//           if int_ack_r = '0' and int_ack = '1' then
//             if    int_reg_0 = '1' then int_reg_0 <= '0'; int_in_service(0) <= '1';
//             elsif int_reg_1 = '1' then int_reg_1 <= '0'; int_in_service(1) <= '1';
//             elsif int_reg_2 = '1' then int_reg_2 <= '0'; int_in_service(2) <= '1';
//             elsif int_reg_3 = '1' then int_reg_3 <= '0'; int_in_service(3) <= '1';
//             end if;
//           end if;
//
//           if int_end_r = '0' and int_end = '1' then
//             if    int_in_service(0) = '1' then int_in_service(0) <= '0';
//             elsif int_in_service(1) = '1' then int_in_service(1) <= '0';
//             elsif int_in_service(2) = '1' then int_in_service(2) <= '0';
//             elsif int_in_service(3) = '1' then int_in_service(3) <= '0';
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

module ctc_controler (
    input  wire         clock,
    input  wire         clock_ena,
    input  wire         reset,

    input  wire [7:0]   d_in,
    input  wire         load_data,
    input  wire         int_ack,
    input  wire         int_end,   // RETI detected

    input  wire         int_pulse_0,
    input  wire         int_pulse_1,
    input  wire         int_pulse_2,
    input  wire         int_pulse_3,

    output wire [7:0]   d_out,
    output wire         int_n
);

////////////////////////////////////////////////////////////////////////////////
// Internal signals (converted from VHDL signals):
////////////////////////////////////////////////////////////////////////////////

// 5-bit interrupt vector
reg  [4:0] int_vector;

// 1-bit flags
reg        wait_for_time_constant;
reg        load_data_r;
reg        int_reg_0;
reg        int_reg_1;
reg        int_reg_2;
reg        int_reg_3;

// 4-bit vector for in-service flags
reg  [3:0] int_in_service;

// Latching int_ack and int_end signals
reg        int_ack_r;
reg        int_end_r;

////////////////////////////////////////////////////////////////////////////////
// int_n <= '0' when (int_reg_0 or int_reg_1 or int_reg_2 or int_reg_3) = '1'
//        else '1';
//
// That’s logically: int_n = ! (int_reg_0 || int_reg_1 || int_reg_2 || int_reg_3)
////////////////////////////////////////////////////////////////////////////////
assign int_n = ~ (int_reg_0 || int_reg_1 || int_reg_2 || int_reg_3);

////////////////////////////////////////////////////////////////////////////////
// d_out <= int_vector & "000" when int_reg_0 = '1' else
//          int_vector & "010" when int_reg_1 = '1' else
//          int_vector & "100" when int_reg_2 = '1' else
//          int_vector & "110" when int_reg_3 = '1' else (others => '0');
//
// We can implement this as a chained conditional assignment in Verilog:
////////////////////////////////////////////////////////////////////////////////
assign d_out = (int_reg_0 == 1'b1) ? {int_vector, 3'b000} :
               (int_reg_1 == 1'b1) ? {int_vector, 3'b010} :
               (int_reg_2 == 1'b1) ? {int_vector, 3'b100} :
               (int_reg_3 == 1'b1) ? {int_vector, 3'b110} :
                                     8'b00000000;

////////////////////////////////////////////////////////////////////////////////
// Process (reset, clock)
//   if reset = '1' then
//     ...
//   elsif rising_edge(clock) then
//     if clock_ena = '1' then
//       ...
//     end if;
//   end if;
////////////////////////////////////////////////////////////////////////////////
always @(posedge clock or posedge reset) begin
    if (reset) begin
        // Asynchronous reset
        wait_for_time_constant <= 1'b0;
        int_reg_0             <= 1'b0;
        int_reg_1             <= 1'b0;
        int_reg_2             <= 1'b0;
        int_reg_3             <= 1'b0;
        int_in_service        <= 4'b0000;
        load_data_r           <= 1'b0;
        int_vector            <= 5'b00000;
    end
    else begin
        // Rising edge of clock
        if (clock_ena == 1'b1) begin

            // Latch incoming control signals
            load_data_r <= load_data;
            int_ack_r   <= int_ack;
            int_end_r   <= int_end;

            // If load_data just went high this cycle
            if ((load_data == 1'b1) && (load_data_r == 1'b0)) begin
                if (wait_for_time_constant == 1'b1) begin
                    wait_for_time_constant <= 1'b0;
                end
                else begin
                    // Check if d_in(0) == '1' => a control word
                    if (d_in[0] == 1'b1) begin
                        // Wait for time constant is bit d_in(2)
                        wait_for_time_constant <= d_in[2];
                    end
                    else begin
                        // It’s an interrupt vector => store top 5 bits
                        // d_in(7 downto 3) => d_in[7:3]
                        int_vector <= d_in[7:3];
                    end
                end
            end

            // Trigger interrupt requests if pulses arrive AND conditions match
            if ((int_pulse_0 == 1'b1) && (int_in_service[0] == 1'b0))   int_reg_0 <= 1'b1;
            if ((int_pulse_1 == 1'b1) && (int_in_service[1:0] == 2'b00))int_reg_1 <= 1'b1;
            if ((int_pulse_2 == 1'b1) && (int_in_service[2:0] == 3'b000))int_reg_2 <= 1'b1;
            if ((int_pulse_3 == 1'b1) && (int_in_service[3:0] == 4'b0000))int_reg_3 <= 1'b1;

            // If CPU signals INT ACK rising from 0->1:
            if ((int_ack_r == 1'b0) && (int_ack == 1'b1)) begin
                // Priority check:
                if      (int_reg_0 == 1'b1) begin
                    int_reg_0 <= 1'b0;
                    int_in_service[0] <= 1'b1;
                end
                else if (int_reg_1 == 1'b1) begin
                    int_reg_1 <= 1'b0;
                    int_in_service[1] <= 1'b1;
                end
                else if (int_reg_2 == 1'b1) begin
                    int_reg_2 <= 1'b0;
                    int_in_service[2] <= 1'b1;
                end
                else if (int_reg_3 == 1'b1) begin
                    int_reg_3 <= 1'b0;
                    int_in_service[3] <= 1'b1;
                end
            end

            // If RETI (int_end) rising from 0->1:
            if ((int_end_r == 1'b0) && (int_end == 1'b1)) begin
                // Clear in-service in the same priority order
                if      (int_in_service[0] == 1'b1) int_in_service[0] <= 1'b0;
                else if (int_in_service[1] == 1'b1) int_in_service[1] <= 1'b0;
                else if (int_in_service[2] == 1'b1) int_in_service[2] <= 1'b0;
                else if (int_in_service[3] == 1'b1) int_in_service[3] <= 1'b0;
            end

        end // clock_ena
    end // not reset
end // always

endmodule