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
    write_HSC_outputs(EP::Model, path::AbstractString, setup::Dict, inputs::Dict)

Function (entry-point) for reporting the different output files of hydrogen supply chain. From here, onward several other functions are called, each for writing specific output files, like costs, capacities, etc.
"""
function write_HSC_outputs(EP::Model, genx_path::AbstractString, setup::Dict, inputs::Dict)

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
        path = joinpath(genx_path, "Results_HSC");
	if !(isdir(path))
            mkpath(path)
        end
	else
        # Find closest unused ouput directory name
        path = choose_h2_output_dir(genx_path)
            # Create directory if it does not exist
        if !(isdir(path))
            mkpath(path)
        end
    end

    write_h2_capacity(path, sep, inputs, setup, EP)
    write_h2_gen(path, sep, inputs, setup, EP)
    write_h2_nse(path, sep, inputs, setup, EP)
    write_h2_costs(path, sep, inputs, setup, EP)
    write_h2_balance(path, sep, inputs, setup, EP)
    write_h2_balance_zone(path, sep, inputs, setup, EP)
    write_h2_balance_dual(path, sep, inputs, setup, EP)
    #write_HSC_LCOH(path, sep, inputs, setup, EP)
    write_h2_emissions(path, sep, inputs, setup, EP)
    write_h2_charge(path, sep, inputs, setup, EP)
    write_h2_storage(path, sep, inputs, setup, EP)
    if !isempty(inputs["H2_STOR_LONG_DURATION"])
        write_h2_opwrap_lds_dstor(path, sep, inputs, setup, EP)
        write_h2_opwrap_lds_stor_init(path, sep, inputs, setup, EP)
    end

    if has_duals(EP) == 1
        write_h2_elec_costs(path, sep, inputs, setup, EP)
    end

    if setup["ModelH2G2P"] == 1
        write_h2_g2p(path, sep, inputs, setup, EP)
        write_p_g2p(path, sep, inputs, setup, EP)
        write_g2p_capacity(path, sep, inputs, setup, EP)
    end

    if setup["ModelH2Pipelines"] == 1
        write_h2_pipeline_flow(path, sep, inputs, setup, EP)
        write_h2_pipeline_expansion(path, sep, inputs, setup, EP)
        write_h2_pipeline_level(path, sep, inputs, setup, EP)
    end

    if setup["ModelH2Trucks"] == 1
        write_h2_truck_capacity(path, sep, inputs, setup, EP)
        write_h2_truck_flow(path, sep, inputs, setup, EP)
    end

    if ((setup["ModelH2Pipelines"] == 1) | (setup["ModelH2Trucks"] == 1)) 
        write_h2_transmission_flow(path, sep, inputs, setup, EP)
    end

    if setup["TimeMatchingRequirement"] >0
         write_h2_tmr_prices(path, sep, inputs, setup, EP)      
    end

    ## Print confirmation
    print_and_log("Wrote HSC outputs to $path$sep")

end # END output()
