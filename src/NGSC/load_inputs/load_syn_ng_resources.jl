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
	load_syn_ng_resources(setup::Dict, path::AbstractString, sep::AbstractString, inputs::Dict)

Function for reading input parameters related to synthetic ng resources.
"""
function load_syn_ng_resources(setup::Dict, path::AbstractString, sep::AbstractString, inputs::Dict)

	#Read in syn ng related inputs
    syn_ng_in = DataFrame(CSV.File(string(path,sep,"NGSC_Syn_NG_Resources.csv"), header=true), copycols=true)

    # Add Resource IDs after reading to prevent user errors
	syn_ng_in[!,:R_ID] = 1:size(collect(skipmissing(syn_ng_in[!,1])),1)

    # Store DataFrame of generators/resources input data for use in model
	inputs["dfSyn_NG"] = syn_ng_in

    # Index of Syn NG resources - can be either commit, no_commit 
	inputs["SYN_NG_RES_ALL"] = size(collect(skipmissing(syn_ng_in[!,:R_ID])),1)

	# Name of Synng resources resources
	inputs["SYN_NG_RESOURCES_NAME"] = collect(skipmissing(syn_ng_in[!,:Syn_NG_Resource][1:inputs["SYN_NG_RES_ALL"]]))
	
	println(" -- NGSC_Syn_NG_Resources.csv Successfully Read!")

    return inputs

end
