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
	write_bio_forest_supply(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the forest biomass purchased from different resources across zones with time.
"""
function write_bio_forest_supply(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfForest = inputs["dfForest"]
	H = inputs["FOREST_SUPPLY_RES_ALL"]     # Number of resources (generators, storage, DR, and DERs)
	T = inputs["T"]     # Number of time steps (hours)

	# Hydrogen injected by each resource in each time step
	# dfForestOut_annual = DataFrame(Resource = inputs["FOREST_SUPPLY_NAME"], Zone = dfForest[!,:Zone], AnnualSum = Array{Union{Missing,Float32}}(undef, H))
	dfForestOut = DataFrame(Resource = inputs["FOREST_SUPPLY_NAME"], Zone = dfForest[!,:Zone], AnnualSum = Array{Union{Missing,Float32}}(undef, H))

	forestsupply = value.(EP[:vForest_biomass_purchased])
    dfForestOut.AnnualSum .= forestsupply * inputs["omega"]

	# Load hourly values
	dfForestOut = hcat(dfForestOut, DataFrame((value.(EP[:vForest_biomass_purchased])), :auto))

	# Add labels
	auxNew_Names=[Symbol("Resource");Symbol("Zone");Symbol("AnnualSum");[Symbol("t$t") for t in 1:T]]
	rename!(dfForestOut,auxNew_Names)

	total = DataFrame(["Total" 0 sum(dfForestOut[!,:AnnualSum]) fill(0.0, (1,T))], :auto)

 	total[:,4:T+3] .= sum(forestsupply, dims=1)

	rename!(total,auxNew_Names)

	dfForestOut = vcat(dfForestOut, total)
 	CSV.write(string(path,sep,"BESC_forest_supply.csv"), dftranspose(dfForestOut, false), writeheader=false)
	
	return dfForestOut


end
