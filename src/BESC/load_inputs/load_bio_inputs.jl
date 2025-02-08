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
	load_bio_inputs(inputs::Dict,setup::Dict,path::AbstractString)

Loads various data inputs from multiple input .csv files in path directory and stores variables in a Dict (dictionary) object for use in model() function

inputs:
inputs - dict object containing input data
setup - dict object containing setup parameters
path - string path to working directory

returns: Dict (dictionary) object containing all data inputs of bioenergy supply chain.
"""
function load_bio_inputs(inputs::Dict,setup::Dict,path::AbstractString)

	## Use appropriate directory separator depending on Mac or Windows config
	if Sys.isunix()
		sep = "/"
    elseif Sys.iswindows()
		sep = "\U005c"
    else
        sep = "/"
	end

	data_directory = chop(replace(path, pwd() => ""), head = 1, tail = 0)

	## Read input files
	println("Reading Bioenergy Input CSV Files")
	## Declare Dict (dictionary) object used to store parameters

	inputs = load_bio_supply(setup, path, sep, inputs)

	if setup["Bio_ELEC_On"] == 1
    	inputs = load_bio_electricity(setup, path, sep, inputs)
	end

	if setup["Bio_H2_On"] == 1
    	inputs = load_bio_hydrogen(setup, path, sep, inputs)
	end

	if setup["Bio_LF_On"] == 1
    	inputs = load_bio_liquid_fuels(setup, path, sep, inputs)
	end

	if setup["Bio_NG_On"] == 1
    	inputs = load_bio_natural_gas(setup, path, sep, inputs)
	end
    
	println("BESC Input CSV Files Successfully Read In From $path$sep")

	return inputs
end
