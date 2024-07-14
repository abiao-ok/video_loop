-- Created by IP Generator (Version 2022.1 build 99559)
-- Instantiation Template
--
-- Insert the following codes into your VHDL file.
--   * Change the_instance_name to your own instance name.
--   * Change the net names in the port map.


COMPONENT matrix_ram24_zoom_hdmi
  PORT (
    wr_data : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    addr : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    rd_data : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
  );
END COMPONENT;


the_instance_name : matrix_ram24_zoom_hdmi
  PORT MAP (
    wr_data => wr_data,
    addr => addr,
    wr_en => wr_en,
    clk => clk,
    rst => rst,
    rd_data => rd_data
  );
