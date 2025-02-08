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
	write_CSC_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for writing the cost for the different sectors of the carbon supply chain (DAC, Injection, Network Expansion)).
"""
function write_CSC_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	## Cost results
	dfDAC = inputs["dfDAC"]

	if setup["ModelCO2Storage"] == 1
		dfCO2Storage = inputs["dfCO2Storage"]
	end
	
	Z = inputs["Z"]     # Number of zones
	T = inputs["T"]     # Number of time steps (hours)
	
	dfCost = DataFrame(Costs = ["cTotal", "cDACFix", "cDACVar", "cCO2Injection", "cCO2NetworkExp"])
	
	cDACVar = value(EP[:eVar_OM_DAC])
	cDACFix = value(EP[:eFixed_Cost_DAC_total])

	if setup["ModelCO2Storage"] == 1
		cCO2Injection= value(EP[:eVar_OM_CO2_Injection_total])
	else
		cCO2Injection = 0
	end

	if setup["ModelCO2Pipelines"] != 0
		cCO2NetworkExpansion = value(EP[:eCCO2Pipe])
	else
		cCO2NetworkExpansion = 0
	end

	# Define total costs
	cTotal = cDACFix + cDACVar + cCO2Injection + cCO2NetworkExpansion

	# Define total column, i.e. column 2
	dfCost[!,Symbol("Total")] = [cTotal, cDACFix, cDACVar, cCO2Injection, cCO2NetworkExpansion]

	# Computing zonal cost breakdown by cost category
	for z in 1:Z
		tempCTotal = 0
		tempCDACFix = 0
		tempCDACVar = 0
		tempCCO2Injection = 0
		
		for y in dfDAC[dfDAC[!,:Zone].==z,:][!,:R_ID]

			tempCDACFix = tempCDACFix + value.(EP[:eFixed_Cost_DAC_per_type])[y]
			tempCDACVar = tempCDACVar + sum(value.(EP[:eVar_OM_DAC_per_type])[y,:])

			tempCTotal = tempCTotal + value.(EP[:eFixed_Cost_DAC_per_type])[y] + sum(value.(EP[:eVar_OM_DAC_per_type])[y,:])
		end


		if setup["ModelCO2Storage"] == 1
			for y in dfCO2Storage[dfCO2Storage[!,:Zone].==z,:][!,:R_ID]
				tempCCO2Injection = tempCCO2Injection + value.(EP[:eVar_OM_CO2_Injection_per_type])[y]
				tempCTotal = tempCTotal + value.(EP[:eVar_OM_CO2_Injection_per_type])[y]
			end
		end

		dfCost[!,Symbol("Zone$z")] = [tempCTotal, tempCDACFix, tempCDACVar, tempCCO2Injection, "-"]
	end

	CSV.write(string(path,sep,"CSC_costs.csv"), dfCost)

end
