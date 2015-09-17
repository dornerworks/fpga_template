--------------------------------------------------------------------------------
--!
--! @copyright Copyright (c) 2015, DornerWorks Ltd.
--!
--------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

entity axi_gpio is
  generic (
    C_S_AXI_ADDR_WIDTH : integer := 12;
    C_S_AXI_DATA_WIDTH : integer := 32
  );
  port (
    clk_p           : in  std_logic;
    reset_p         : in  std_logic;

    s_axi_awaddr_p  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    s_axi_awvalid_p : in  std_logic;
    s_axi_awready_p : out std_logic;
    s_axi_wdata_p   : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    s_axi_wstrb_p   : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    s_axi_wvalid_p  : in  std_logic;
    s_axi_wready_p  : out std_logic;
    s_axi_bresp_p   : out std_logic_vector(1 downto 0);
    s_axi_bvalid_p  : out std_logic;
    s_axi_bready_p  : in  std_logic;
    s_axi_araddr_p  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    s_axi_arvalid_p : in  std_logic;
    s_axi_arready_p : out std_logic;
    s_axi_rdata_p   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    s_axi_rresp_p   : out std_logic_vector(1 downto 0);
    s_axi_rvalid_p  : out std_logic;
    s_axi_rready_p  : in  std_logic;

    gpio_in_p       : in  std_logic_vector(0 to 31);
    gpio_out_p      : out std_logic_vector(0 to 31);
    gpio_oe_p       : out std_logic_vector(0 to 31)
  );
end entity;

architecture rtl of axi_gpio is

  constant C_ADDR_NBITS  : integer := 1;
  constant C_ADDR_LSB    : integer := 2;
  constant C_ADDR_MSB    : integer := C_ADDR_LSB + C_ADDR_NBITS-1;

  signal s_axi_awaddr_r  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal s_axi_awvalid_r : std_logic;
  signal s_axi_awready_r : std_logic;
  signal s_axi_wdata_r   : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal s_axi_wstrb_r   : std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
  signal s_axi_wready_r  : std_logic;
  signal s_axi_bvalid_r  : std_logic;

  signal s_axi_araddr_r  : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal s_axi_arvalid_r : std_logic;
  signal s_axi_arready_r : std_logic;
  signal s_axi_rdata_r   : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal s_axi_rvalid_r  : std_logic;

  signal gpio_in_reg_r   : std_logic_vector(31 downto 0) := (others => '0');
  signal gpio_out_reg_r  : std_logic_vector(31 downto 0) := (others => '0');
  signal gpio_oe_reg_r   : std_logic_vector(31 downto 0) := (others => '0');

begin

  gpio_out_p <= gpio_out_reg_r;
  gpio_oe_p <= gpio_oe_reg_r;

  --!
  --!
  --!
  process (clk_p)
  begin
    if rising_edge(clk_p) then
      if reset_p = '1' then

        s_axi_awvalid_r <= '0';
        s_axi_awready_r <= '0';
        s_axi_wready_r <= '0';
        s_axi_bvalid_r <= '0';

      else

        if s_axi_awvalid_r = '0' and s_axi_awvalid_p = '1' and s_axi_wvalid_p = '1' then
          s_axi_awvalid_r <= '1';
        elsif s_axi_awvalid_r = '1' and s_axi_bvalid_r = '1' and s_axi_bready_p = '1' then
          s_axi_awvalid_r <= '0';
        end if;

        if s_axi_awvalid_r = '0' and s_axi_awvalid_p = '1' and s_axi_wvalid_p = '1' then
          s_axi_awready_r <= '1';
          s_axi_wready_r <= '1';
        else
          s_axi_awready_r <= '0';
          s_axi_wready_r <= '0';
        end if;

        if s_axi_bvalid_r = '0' and s_axi_awready_r = '1' then
          s_axi_bvalid_r <= '1';
        elsif s_axi_bvalid_r = '1' and s_axi_bready_p = '1' then
          s_axi_bvalid_r <= '0';
        end if;

      end if;
    end if;
  end process;

  --!
  --!
  --!
  process (clk_p)
  begin
    if rising_edge(clk_p) then
      if s_axi_awvalid_r = '0' and s_axi_awvalid_p = '1' and s_axi_wvalid_p = '1' then
        s_axi_awaddr_r <= s_axi_awaddr_p;
        s_axi_wdata_r <= s_axi_wdata_p;
        s_axi_wstrb_r <= s_axi_wstrb_p;
      end if;
    end if;
  end process;

  --!
  --!
  --!
  process (clk_p)

    --!
    --!
    --!
    procedure write_slv_reg(
      signal   reg_s  : inout std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      constant data_c : in    std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0)) is
    begin
      for i in s_axi_wstrb_r'range loop
        if s_axi_wstrb_r(i) = '1' then
          reg_s((i*8)+7 downto (i*8)) <= data_c((i*8)+7 downto (i*8));
        end if;
      end loop;
    end procedure;

    variable s_axi_waddr_v : std_logic_vector(C_ADDR_NBITS-1 downto 0);
    variable s_axi_wdata_v : std_logic_vector(31 downto 0);

  begin
    if rising_edge(clk_p) then
      if reset_p = '1' then

        gpio_out_reg_r <= (others => '0');
        gpio_oe_reg_r <= (others => '0');

      else
        
        s_axi_waddr_v := s_axi_awaddr_r(C_ADDR_MSB downto C_ADDR_LSB);
        s_axi_wdata_v := s_axi_wdata_r(31 downto 0);

        case s_axi_waddr_v is
          when b"0" =>
            write_slv_reg(gpio_out_reg_r, s_axi_wdata_v);
          
          when b"1" =>
            write_slv_reg(gpio_oe_reg_r, s_axi_wdata_v);

          when others =>
            null;
            
        end case;

      end if;
    end if;
  end process;
  --!
  --!
  --!
  process (clk_p)
  begin
    if rising_edge(clk_p) then
      if reset_p = '1' then

        s_axi_arvalid_r <= '0';
        s_axi_arready_r <= '0';
        s_axi_rvalid_r <= '0';

      else

        if s_axi_arvalid_r = '0' and s_axi_arvalid_p = '1' then
          s_axi_arvalid_r <= '1';
        elsif s_axi_arvalid_r = '1' and s_axi_rvalid_r = '1' and s_axi_rready_p = '1' then
          s_axi_arvalid_r <= '0';
        end if;

        if s_axi_arvalid_r = '0' and s_axi_arvalid_p = '1' then
          s_axi_arready_r <= '1';
        else
          s_axi_arready_r <= '0';
        end if;

        if s_axi_rvalid_r = '0' and s_axi_arready_r = '1' then
          s_axi_rvalid_r <= '1';
        elsif s_axi_rvalid_r = '1' and s_axi_rready_p = '1' then
          s_axi_rvalid_r <= '0';
        end if;
        
      end if;
    end if;
  end process;

  --!
  --!
  --!
  process (clk_p)
  begin
    if rising_edge(clk_p) then
      if s_axi_arvalid_r = '0' and s_axi_arvalid_p = '1' then
        s_axi_araddr_r <= s_axi_araddr_p;
      end if;
    end if;
  end process;

  --!
  --!
  --!
  process (clk_p)

    variable s_axi_raddr_v : std_logic_vector(C_ADDR_NBITS-1 downto 0);
    variable s_axi_rdata_v : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

  begin
    if rising_edge(clk_p) then
      if reset_p = '1' then

        s_axi_rdata_r <= (others => '0');

      else

        s_axi_raddr_v := s_axi_araddr_r(C_ADDR_MSB downto C_ADDR_LSB);

        case s_axi_raddr_v is
          when b"0" => s_axi_rdata_v := gpio_in_reg_r;
          when b"1" => s_axi_rdata_v := gpio_oe_reg_r;
          when others => null;
        end case;

        s_axi_rdata_r <= s_axi_rdata_v;

      end if;
    end if;
  end process;

  --!
  --!
  --!
  process (clk_p)
  begin
    if rising_edge(clk_p) then
      gpio_in_reg_r <= gpio_in_p;
    end if;
  end process;

end architecture;
