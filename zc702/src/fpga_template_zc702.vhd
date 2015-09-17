--------------------------------------------------------------------------------
--!
--! @copyright Copyright (c) 2015, DornerWorks Ltd.
--!
--------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

entity fpga_template_zc702 is
  port (
    ddr_addr          : inout std_logic_vector ( 14 downto 0 );
    ddr_ba            : inout std_logic_vector ( 2 downto 0 );
    ddr_cas_n         : inout std_logic;
    ddr_ck_n          : inout std_logic;
    ddr_ck_p          : inout std_logic;
    ddr_cke           : inout std_logic;
    ddr_cs_n          : inout std_logic;
    ddr_dm            : inout std_logic_vector ( 3 downto 0 );
    ddr_dq            : inout std_logic_vector ( 31 downto 0 );
    ddr_dqs_n         : inout std_logic_vector ( 3 downto 0 );
    ddr_dqs_p         : inout std_logic_vector ( 3 downto 0 );
    ddr_odt           : inout std_logic;
    ddr_ras_n         : inout std_logic;
    ddr_reset_n       : inout std_logic;
    ddr_we_n          : inout std_logic;
    fixed_io_ddr_vrn  : inout std_logic;
    fixed_io_ddr_vrp  : inout std_logic;
    fixed_io_mio      : inout std_logic_vector ( 53 downto 0 );
    fixed_io_ps_clk   : inout std_logic;
    fixed_io_ps_porb  : inout std_logic;
    fixed_io_ps_srstb : inout std_logic;
    gpio_p            : inout std_logic_vector ( 0 to 31 )
  );
end entity;

architecture rtl of fpga_template_zc702 is

  signal gpio_in_s  : std_logic_vector( 0 to 31 );
  signal gpio_oe_s  : std_logic_vector( 0 to 31 );
  signal gpio_out_s : std_logic_vector( 0 to 31 );

begin

  gpio_in_s <= gpio_p;

  g_tri: for i in gpio_p'range generate
    gpio_p(i) <= gpio_out_s(i) when gpio_oe_s(i) = '1' else 'Z';
  end generate;

  i_top: entity work.fpga_template_zc702_bd_wrapper
    port map (
      ddr_addr          => ddr_addr,
      ddr_ba            => ddr_ba,
      ddr_cas_n         => ddr_cas_n,
      ddr_ck_n          => ddr_ck_n,
      ddr_ck_p          => ddr_ck_p,
      ddr_cke           => ddr_cke,
      ddr_cs_n          => ddr_cs_n,
      ddr_dm            => ddr_dm,
      ddr_dq            => ddr_dq,
      ddr_dqs_n         => ddr_dqs_n,
      ddr_dqs_p         => ddr_dqs_p,
      ddr_odt           => ddr_odt,
      ddr_ras_n         => ddr_ras_n,
      ddr_reset_n       => ddr_reset_n,
      ddr_we_n          => ddr_we_n,
      fixed_io_ddr_vrn  => fixed_io_ddr_vrn,
      fixed_io_ddr_vrp  => fixed_io_ddr_vrp,
      fixed_io_mio      => fixed_io_mio,
      fixed_io_ps_clk   => fixed_io_ps_clk,
      fixed_io_ps_porb  => fixed_io_ps_porb,
      fixed_io_ps_srstb => fixed_io_ps_srstb,
      gpio_in_p         => gpio_in_s,
      gpio_oe_p         => gpio_oe_s,
      gpio_out_p        => gpio_out_s
    );

end architecture;
