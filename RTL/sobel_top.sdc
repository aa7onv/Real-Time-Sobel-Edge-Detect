
# Base 50 MHz (period 20ns)
create_clock -name {CLOCK_50} -period 20.000 [get_ports {CLOCK_50}]

# PLL-generated 25.175 MHz pixel clock
derive_pll_clocks

#  default clock uncertainty
# including the derived PLL output.
derive_clock_uncertainty

# async RESET_N
set_false_path -from [get_ports {RESET_N}] -to [all_registers]
