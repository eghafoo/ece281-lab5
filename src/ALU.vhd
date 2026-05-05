----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is

signal result_9 : STD_LOGIC_VECTOR(8 downto 0);
signal result_8 : STD_LOGIC_VECTOR(7 downto 0);

 signal flag_N : STD_LOGIC;
 signal flag_Z : STD_LOGIC;
 signal flag_C : STD_LOGIC;
 signal flag_V : STD_LOGIC;

begin

alu : process(i_A, i_B, i_op)
    variable A : unsigned(8 downto 0);
    variable B : unsigned(8 downto 0);
    variable notB : unsigned(8 downto 0);
    variable v_result_9 : std_logic_vector(8 downto 0);
    variable v_result_8 : std_logic_vector(7 downto 0);
    begin
        A := unsigned('0' & i_A);
        B := unsigned('0' & i_B);
        notB := unsigned(not('0' & i_B));
        
        case i_op is    
            when "000" => result_9 <= std_logic_vector(A+B); --add
            when "001" => result_9 <= std_logic_vector(A + notB + 1); --subtract
            when "010" => result_9 <= '0' & (i_A and i_B); --and
            when "011" => result_9 <= '0' & (i_A or i_B); --or
            when others => result_9 <= '0' & i_A;
        end case; 
        v_result_8 := v_result_9(7 downto 0);

    flag_N <= v_result_8(7);

    if v_result_8 = x"00" then
        flag_Z <= '1';
    else
        flag_Z <= '0';
    end if;

    flag_C <= v_result_9(8);
    case i_op is
        when "000" => flag_V <= (not (i_A(7) xor i_B(7))) and (i_A(7) xor v_result_8(7));
        when "001" => flag_V <= (i_A(7) xor i_B(7)) and (i_A(7) xor v_result_8(7));
        when others => flag_V <= '0';
    end case;
    result_9 <= v_result_9;
    result_8 <= v_result_8;
end process alu;
result_8 <= result_9 (7 downto 0);

o_result <= result_8;
o_flags <= flag_N & flag_Z & flag_C & flag_V;

end Behavioral;
