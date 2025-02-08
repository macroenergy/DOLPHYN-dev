"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2022,  Massachusetts Institute of Technology
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt.  Users uncompressing this from an archive may not have
received this license file.  If not, see <http://www.gnu.org/licenses/>.
"""

################################################################################
## function output
##
## description: Writes results to multiple .csv output files in path directory
##
## returns: n/a
################################################################################
@doc raw"""
  write_liquid_fuels_outputs(EP::Model, genx_path::AbstractString, setup::Dict, inputs::Dict)

Function (entry-point) for reporting the different output files of liquid fuels supply chain. From here, onward several other functions are called, each for writing specific output files, like costs, capacities, etc.
"""
function write_liquid_fuels_outputs(EP::Model, genx_path::AbstractString, setup::Dict, inputs::Dict)

  ## Use appropriate directory separator depending on Mac or Windows config
  if Sys.isunix()
    sep = "/"
    elseif Sys.iswindows()
    sep = "\U005c"
    else
        sep = "/"
  end

  if !haskey(setup, "OverwriteResults") || setup["OverwriteResults"] == 1
    # Overwrite existing results if dir exists
    # This is the default behaviour when there is no flag, to avoid breaking existing code
    # Create directory if it does not exist
    path = joinpath(genx_path, "Results_LF");
  if !(isdir(path))
          mkpath(path)
      end
  else
    # Find closest unused ouput directory name
    path = choose_lf_output_dir(genx_path)
    # Create directory if it does not exist
    if !(isdir(path))
        mkpath(path)
    end
  end

  if setup["Liquid_Fuels_Regional_Demand"] == 1
    write_liquid_fuel_demand_balance_regional_conv_fuel(path, sep, inputs, setup, EP)
    write_liquid_fuel_emissions_regional_conv_fuel(path,sep,inputs, setup, EP)
    write_liquid_fuel_costs_regional_conv_fuel(path, sep, inputs, setup, EP)

  elseif setup["Liquid_Fuels_Regional_Demand"] == 0
    write_liquid_fuel_demand_balance_global_conv_fuel(path, sep, inputs, setup, EP)
    write_liquid_fuel_emissions_global_conv_fuel(path,sep,inputs, setup, EP)
    write_liquid_fuel_costs_global_conv_fuel(path, sep, inputs, setup, EP)

  end

  if setup["ModelSyntheticFuels"] == 1
    write_synfuel_capacity(path, sep, inputs, setup, EP)
    
    if setup["ModelFlexSyntheticFuels"] == 1
      write_synfuel_balance_flex(path, sep, inputs, setup, EP)
    else
      write_synfuel_balance(path, sep, inputs, setup, EP)
    end

    #write_synfuel_gen(path, sep, inputs, setup, EP)
  end

  write_liquid_fuel_balance_dual(path, sep, inputs, setup, EP)
  
  ## Print confirmation
  println("Wrote LF outputs to $path$sep")

end # END output()
