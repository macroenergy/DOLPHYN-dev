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

@doc raw"""
	load_liquid_fuels_inputs(inputs::Dict,setup::Dict,path::AbstractString)

Loads various data inputs from multiple input .csv files in path directory and stores variables in a Dict (dictionary) object for use in model() function

inputs:
setup - dict object containing setup parameters
path - string path to working directory

returns: Dict (dictionary) object containing all data inputs of the liquid fuels supply chain.
"""
function load_liquid_fuels_inputs(inputs::Dict,setup::Dict,path::AbstractString)

	## Use appropriate directory separator depending on Mac or Windows config
	if Sys.isunix()
		sep = "/"
    elseif Sys.iswindows()
		sep = "\U005c"
    else
        sep = "/"
	end

	data_directory = data_directory = joinpath(path, setup["TimeDomainReductionFolder"])

	## Read input files
	println("Reading Liquid Fuels Input CSV Files")

	if setup["ModelSyntheticFuels"] == 1
    	inputs = load_syn_fuels_resources(setup, path, sep, inputs)
	end
	
	inputs = load_liquid_fuels_demand(setup, path, sep, inputs)
	inputs = load_conventional_fuel_prices(setup, path, sep, inputs)

	println("LFSC Input CSV Files Successfully Read In From $path$sep")

	return inputs
end
