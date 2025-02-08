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
	write_bio_herb_supply(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the herb biomass purchased from different resources across zones with time.
"""
function write_bio_herb_supply(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfHerb = inputs["dfHerb"]
	H = inputs["HERB_SUPPLY_RES_ALL"]     # Number of resources (generators, storage, DR, and DERs)
	T = inputs["T"]     # Number of time steps (hours)

	# Hydrogen injected by each resource in each time step
	# dfHerbOut_annual = DataFrame(Resource = inputs["HERB_SUPPLY_NAME"], Zone = dfHerb[!,:Zone], AnnualSum = Array{Union{Missing,Float32}}(undef, H))
	dfHerbOut = DataFrame(Resource = inputs["HERB_SUPPLY_NAME"], Zone = dfHerb[!,:Zone], AnnualSum = Array{Union{Missing,Float32}}(undef, H))

	herbsupply = value.(EP[:vHerb_biomass_purchased])
    dfHerbOut.AnnualSum .= herbsupply * inputs["omega"]

	# Load hourly values
	dfHerbOut = hcat(dfHerbOut, DataFrame((value.(EP[:vHerb_biomass_purchased])), :auto))

	# Add labels
	auxNew_Names=[Symbol("Resource");Symbol("Zone");Symbol("AnnualSum");[Symbol("t$t") for t in 1:T]]
	rename!(dfHerbOut,auxNew_Names)

	total = DataFrame(["Total" 0 sum(dfHerbOut[!,:AnnualSum]) fill(0.0, (1,T))], :auto)

 	total[:,4:T+3] .= sum(herbsupply, dims=1)

	rename!(total,auxNew_Names)

	dfHerbOut = vcat(dfHerbOut, total)
 	CSV.write(string(path,sep,"BESC_herb_supply.csv"), dftranspose(dfHerbOut, false), writeheader=false)
	
	return dfHerbOut


end
