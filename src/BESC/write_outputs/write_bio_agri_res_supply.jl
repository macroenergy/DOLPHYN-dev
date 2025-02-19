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
write_bio_agri_res_supply(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the AgriRes biomass purchased from different resources across zones with time.
"""
function write_bio_agri_res_supply(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfAgri_Res = inputs["dfAgri_Res"]
	H = inputs["AGRI_RES_SUPPLY_RES_ALL"]     # Number of resources (generators, storage, DR, and DERs)
	T = inputs["T"]     # Number of time steps (hours)

	# Hydrogen injected by each resource in each time step
	# dfAgri_ResOut_annual = DataFrame(Resource = inputs["AGRI_RES_SUPPLY_NAME"], Zone = dfAgri_Res[!,:Zone], AnnualSum = Array{Union{Missing,Float32}}(undef, H))
	dfAgri_ResOut = DataFrame(Resource = inputs["AGRI_RES_SUPPLY_NAME"], Zone = dfAgri_Res[!,:Zone], AnnualSum = Array{Union{Missing,Float32}}(undef, H))

	AgriRessupply = value.(EP[:vAgri_Res_biomass_purchased])
    dfAgri_ResOut.AnnualSum .= AgriRessupply * inputs["omega"]

	# Load hourly values
	dfAgri_ResOut = hcat(dfAgri_ResOut, DataFrame((value.(EP[:vAgri_Res_biomass_purchased])), :auto))

	# Add labels
	auxNew_Names=[Symbol("Resource");Symbol("Zone");Symbol("AnnualSum");[Symbol("t$t") for t in 1:T]]
	rename!(dfAgri_ResOut,auxNew_Names)

	total = DataFrame(["Total" 0 sum(dfAgri_ResOut[!,:AnnualSum]) fill(0.0, (1,T))], :auto)

 	total[:,4:T+3] .= sum(AgriRessupply, dims=1)

	rename!(total,auxNew_Names)

	dfAgri_ResOut = vcat(dfAgri_ResOut, total)
 	CSV.write(string(path,sep,"BESC_Agri_Res_supply.csv"), dftranspose(dfAgri_ResOut, false), writeheader=false)
	
	return dfAgri_ResOut


end
