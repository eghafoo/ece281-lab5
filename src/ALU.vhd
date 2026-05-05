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
use IEEE.NUMERIC_STD.ALL;

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

begin

alu : process(i_A, i_B, i_op)
    variable A : unsigned(8 downto 0);
    variable B : unsigned(8 downto 0);
    variable notB : unsigned(8 downto 0);
    variable v_result_9 : std_logic_vector(8 downto 0);
    variable v_result_8 : std_logic_vector(7 downto 0);
    variable v_N : std_logic;
    variable v_Z : std_logic;
    variable v_C : std_logic;
    variable v_V : std_logic;
    begin
        A := unsigned('0' & i_A);
        B := unsigned('0' & i_B);
        notB := unsigned(not('0' & i_B));
        
        case i_op is    
            when "000" => v_result_9 := std_logic_vector(A + B);
            when "001" => v_result_9 := std_logic_vector(A + notB + to_unsigned(1, 9));
            when "010" => v_result_9 := '0' & (i_A and i_B);
            when "011" => v_result_9 := '0' & (i_A or i_B);
            when others => v_result_9 := '0' & i_A;
        end case;

        v_result_8 := v_result_9(7 downto 0);

        v_N := v_result_8(7);

        if v_result_8 = x"00" then
            v_Z := '1';
        else
            v_Z := '0';
        end if;

        v_C := v_result_9(8);

        case i_op is
            when "000" => v_V := (not (i_A(7) xor i_B(7))) and (i_A(7) xor v_result_8(7));
            when "001" => v_V := (i_A(7) xor i_B(7)) and (i_A(7) xor v_result_8(7));
            when others => v_V := '0';
        end case;

        o_result <= v_result_8;
        o_flags <= v_N & v_Z & v_C & v_V;

    end process alu;

end Behavioral;