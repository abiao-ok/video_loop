-- Created by IP Generator (Version 2022.1 build 99559)
-- Instantiation Template
--
-- Insert the following codes into your VHDL file.
--   * Change the_instance_name to your own instance name.
--   * Change the net names in the port map.


COMPONENT DFIFO32
  PORT (
    wr_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    full : OUT STD_LOGIC;
    almost_full : OUT STD_LOGIC;
    rd_data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    rd_en : IN STD_LOGIC;
    empty : OUT STD_LOGIC;
    almost_empty : OUT STD_LOGIC;
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC
  );
END COMPONENT;


the_instance_name : DFIFO32
  PORT MAP (
    wr_data => wr_data,
    wr_en => wr_en,
    full => full,
    almost_full => almost_full,
    rd_data => rd_data,
    rd_en => rd_en,
    empty => empty,
    almost_empty => almost_empty,
    clk => clk,
    rst => rst
  );
