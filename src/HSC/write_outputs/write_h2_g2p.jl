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
	write_h2_g2p(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the different values of power generated by hydrogen to power plants in operation.
"""
function write_h2_g2p(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfH2G2P = inputs["dfH2G2P"]
	H = inputs["H2_G2P_ALL"]     # Number of resources (generators, storage, DR, and DERs)
	T = inputs["T"]     # Number of time steps (hours)

	# Power injected by each resource in each time step
	# dfH2G2POut_annual = DataFrame(Resource = inputs["H2_RESOURCES_NAME"], Zone = dfH2G2P[!,:Zone], AnnualSum = Array{Union{Missing,Float32}}(undef, H))
	dfH2G2POut = DataFrame(Resource = inputs["H2_G2P_NAME"], Zone = dfH2G2P[!,:Zone], AnnualSum = Array{Union{Missing,Float32}}(undef, H))

    for i in 1:H
        dfH2G2POut[!,:AnnualSum][i] = sum(inputs["omega"].* (value.(EP[:vH2G2P][i,:])))
    end
    # Load hourly values
    dfH2G2POut = hcat(dfH2G2POut, DataFrame((value.(EP[:vH2G2P])), :auto), copycols = false)

	# Add labels
	auxNew_Names=[Symbol("Resource");Symbol("Zone");Symbol("AnnualSum");[Symbol("t$t") for t in 1:T]]
	rename!(dfH2G2POut,auxNew_Names)

	total = DataFrame(["Total" 0 sum(dfH2G2POut[!,:AnnualSum]) fill(0.0, (1,T))], :auto)

 	CSV.write(string(path,sep,"HSC_G2P_H2_Consumption.csv"), dftranspose(dfH2G2POut, false), writeheader=false)
	return dfH2G2POut


end