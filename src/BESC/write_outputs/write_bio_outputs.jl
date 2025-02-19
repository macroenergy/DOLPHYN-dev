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
  write_bio_outputs(EP::Model, genx_path::AbstractString, setup::Dict, inputs::Dict)

Function (entry-point) for reporting the different output files of bioenergy supply chain. From here, onward several other functions are called, each for writing specific output files, like costs, capacities, etc.
"""
function write_bio_outputs(EP::Model, genx_path::AbstractString, setup::Dict, inputs::Dict)

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
    path = joinpath(genx_path, "Results_BESC");
    if !(isdir(path))
        mkpath(path)
    end
  else
    # Find closest unused ouput directory name
    path = choose_besc_output_dir(genx_path)
    # Create directory if it does not exist
    if !(isdir(path))
        mkpath(path)
    end
  end

    write_BESC_costs(path, sep, inputs, setup, EP)

    if setup["Energy_Crops_Herb_Supply"] == 1
      write_bio_herb_supply(path, sep, inputs, setup, EP)
      write_bio_herb_supply_dual(path, sep, inputs, setup, EP)
    end

    if setup["Energy_Crops_Wood_Supply"] == 1
      write_bio_wood_supply(path, sep, inputs, setup, EP)
      write_bio_wood_supply_dual(path, sep, inputs, setup, EP)
    end

    if setup["Agri_Res_Supply"] == 1
      write_bio_agri_res_supply(path, sep, inputs, setup, EP)
      write_bio_agri_res_supply_dual(path, sep, inputs, setup, EP)
    end

    if setup["Agri_Process_Waste_Supply"] == 1
      write_bio_agri_process_waste_supply(path, sep, inputs, setup, EP)
      write_bio_agri_process_waste_supply_dual(path, sep, inputs, setup, EP)
    end

    if setup["Agri_Forest_Supply"] == 1
      write_bio_forest_supply(path, sep, inputs, setup, EP)
      write_bio_forest_supply_dual(path, sep, inputs, setup, EP)
    end


    write_bio_zone_bioelectricity_produced(path, sep, inputs, setup, EP)
    
    if setup["Bio_ELEC_On"] == 1
      write_bio_electricity_plant_capacity(path, sep, inputs, setup, EP)
    end

    if setup["Bio_H2_On"] == 1
      write_bio_zone_biohydrogen_produced(path, sep, inputs, setup, EP)
      write_bio_hydrogen_plant_capacity(path, sep, inputs, setup, EP)
    end

    if setup["Bio_NG_On"] == 1
      write_bio_zone_bionaturalgas_produced(path, sep, inputs, setup, EP)
      write_bio_natural_gas_plant_capacity(path, sep, inputs, setup, EP)
    end

    if setup["Bio_LF_On"] == 1

      #write_bio_liquid_fuels_plant_capacity_part_a(path, sep, inputs, setup, EP)
      
      if setup["ModelFlexBioLiquidFuels"] == 1
        write_bio_liquid_fuels_balance_flex(path, sep, inputs, setup, EP)
      else
        write_bio_liquid_fuels_balance(path, sep, inputs, setup, EP)
      end

      #write_bio_zone_biodiesel_produced(path, sep, inputs, setup, EP)
      #write_bio_zone_biojetfuel_produced(path, sep, inputs, setup, EP)
      #write_bio_zone_biogasoline_produced(path, sep, inputs, setup, EP)
      write_bio_liquid_fuels_plant_capacity(path, sep, inputs, setup, EP)

    end
  
  ## Print confirmation
  println("Wrote BESC outputs to $path$sep")

end # END output()
