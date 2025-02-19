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
	write_ng_emissions(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting CO2 emissions of natural gas types across different zones.
"""
function write_ng_emissions(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	## Emission balance for each zone
	dfNGEmissionBalance = Array{Any}

	rowoffset=3
	for z in 1:Z
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 9)
	   	dfTemp1[1,1:size(dfTemp1,2)] = vcat(["CO2 In","Syn NG Plant Emissions", "Syn NG Plant Captured", "Syn NG Emissions", "Bio NG Emissions", "Conventional NG Emissions", "Reduction from Power CCS", "Reduction from H2 CCS", "Reduction from DAC CCS"])
	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([z],size(dfTemp1,2))

		for t in 1:T

			dfTemp1[t+rowoffset,1] = 0
			dfTemp1[t+rowoffset,2] = 0
			dfTemp1[t+rowoffset,3] = 0
			dfTemp1[t+rowoffset,4] = 0
			dfTemp1[t+rowoffset,5] = 0

			if setup["ModelSyntheticNG"] == 1
				dfTemp1[t+rowoffset,1] = value.(EP[:eSyn_NG_CO2_Cons_Per_Time_Per_Zone][t,z])
				dfTemp1[t+rowoffset,2] = value.(EP[:eSyn_NG_Production_CO2_Emissions_By_Zone][z,t])
				dfTemp1[t+rowoffset,3] = value.(EP[:eSyn_NG_CO2_Capture_Per_Zone_Per_Time][z,t])
				dfTemp1[t+rowoffset,4] = value.(EP[:eSyn_NG_CO2_Emissions_By_Zone][z,t])
			end

			if setup["ModelBESC"] == 1 && setup["Bio_NG_On"] == 1
				dfTemp1[t+rowoffset,5] = value.(EP[:eBio_NG_CO2_Emissions_By_Zone][z,t])
			end

			dfTemp1[t+rowoffset,6] = value.(EP[:eConv_NG_CO2_Emissions][z,t])
			dfTemp1[t+rowoffset,7] = -value.(EP[:ePower_NG_CO2_captured_per_zone_per_time][z,t])

			dfTemp1[t+rowoffset,8] = 0

			if setup["ModelH2"] == 1
				dfTemp1[t+rowoffset,8] = -value.(EP[:eHydrogen_NG_CO2_captured_per_zone_per_time][z,t])
			end
			
			dfTemp1[t+rowoffset,9] = 0
			
			if setup["ModelCSC"] == 1
				dfTemp1[t+rowoffset,9] = -value.(EP[:eDAC_NG_CO2_captured_per_zone_per_time][z,t])
			end

		end

		if z==1
			dfNGEmissionBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfNGEmissionBalance = hcat(dfNGEmissionBalance, dfTemp1)
		end
	end

	for c in 2:size(dfNGEmissionBalance,2)
		dfNGEmissionBalance[rowoffset,c]=sum(inputs["omega"].*dfNGEmissionBalance[(rowoffset+1):size(dfNGEmissionBalance,1),c])
	end

	dfNGEmissionBalance = DataFrame(dfNGEmissionBalance, :auto)
	CSV.write(string(path,sep,"NG_Emissions_Balance.csv"), dfNGEmissionBalance, writeheader=false)

end