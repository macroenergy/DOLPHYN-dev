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
	write_ng_demand_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the natural gas balance of resources across different zones with time for each type of fuels.
"""
function write_ng_demand_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	###########################################################################################
	## Diesel balance for each zone
	dfNGBalance = Array{Any}
	rowoffset=3

	for z in 1:Z
		dfTemp1_NG = Array{Any}(nothing, T+rowoffset, 9)
		dfTemp1_NG[1,1:size(dfTemp1_NG,2)] = ["Syn_NG", "Bio_NG", "Conventional_NG", "NG_Pipeline", "NG_Demand", "Power", "H2", "CSC", "BESC"]
		dfTemp1_NG[2,1:size(dfTemp1_NG,2)] = repeat([z],size(dfTemp1_NG,2))
		for t in 1:T

			dfTemp1_NG[t+rowoffset,1] = 0
			dfTemp1_NG[t+rowoffset,2] = 0
			
			if setup["ModelSyntheticNG"] == 1
				dfTemp1_NG[t+rowoffset,1] = value.(EP[:eSyn_NG_Prod][t,z])
			end

			if setup["ModelBESC"] == 1 && setup["Bio_NG_On"] == 1
				dfTemp1_NG[t+rowoffset,2] = value.(EP[:eBioNG_produced_MMBtu_per_time_per_zone][t,z])
			end

			dfTemp1_NG[t+rowoffset,3] = value.(EP[:vConv_NG_Demand][t,z])

			dfTemp1_NG[t+rowoffset,4] = 0

			if setup["ModelNGPipelines"] == 1
				dfTemp1_NG[t+rowoffset,4] = value.(EP[:eNGPipeZoneDemand][t,z])
			end

			dfTemp1_NG[t+rowoffset,5] = -inputs["NG_D"][t,z]

			dfTemp1_NG[t+rowoffset,6] = -value.(EP[:eElectricityNetNGConsumptionByAll][t,z])

			dfTemp1_NG[t+rowoffset,7] = 0

			if setup["ModelH2"] == 1
				dfTemp1_NG[t+rowoffset,7] = -value.(EP[:eH2NetNGConsumptionByAll][t,z])
			end

			dfTemp1_NG[t+rowoffset,8] = 0

			if setup["ModelCSC"] == 1
				dfTemp1_NG[t+rowoffset,8] = -value.(EP[:eCSCNetNGConsumptionByAll][t,z])
			end

			dfTemp1_NG[t+rowoffset,9] = 0
			if setup["ModelBESC"] == 1
				dfTemp1_NG[t+rowoffset,9] = -value.(EP[:eBESCNetNGConsumptionByAll][t,z])
			end
		end

		if z==1
			dfNGBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1_NG)
		else
			dfNGBalance = hcat(dfNGBalance, dfTemp1_NG)
		end
	end

	for c in 2:size(dfNGBalance,2)
		dfNGBalance[rowoffset,c]=sum(inputs["omega"].*dfNGBalance[(rowoffset+1):size(dfNGBalance,1),c])
	end

	dfNGBalance = DataFrame(dfNGBalance, :auto)
	
	CSV.write(string(path,sep,"NG_Balance.csv"), dfNGBalance, writeheader=false)

end
