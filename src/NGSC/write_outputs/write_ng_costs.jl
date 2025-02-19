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
	write_ng_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for writing the cost for the different sectors of the natural gas supply chain (Synthetic NG resources CAPEX and OPEX, conventional NG).
"""
function write_ng_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

	
	## Cost results
	Z = inputs["Z"]     # Number of zones

	if setup["ModelSyntheticNG"] == 1
        dfSyn_NG = inputs["dfSyn_NG"]
    end

	dfNGCost = DataFrame(Costs = ["cNGTotal", "cSyn_NGFix", "cSyn_NGVar","cConvNGCost"])

	cSyn_NGVar = 0
	cSyn_NGFix = 0

	if setup["ModelSyntheticNG"] == 1
		cSyn_NGVar = value(EP[:eTotalCSyn_NGProdVarOut])
		cSyn_NGFix = value(EP[:eFixed_Cost_Syn_NG_total])
	end

	cConvNGCost = value(EP[:eTotalConv_NG_VarOut])
	 
    cNGTotal = cSyn_NGVar + cSyn_NGFix + cConvNGCost

    dfNGCost[!,Symbol("Total")] = [cNGTotal, cSyn_NGFix, cSyn_NGVar, cConvNGCost]

	for z in 1:Z
		tempCTotal = 0
		tempC_Syn_NG_Fix = 0
		tempC_Syn_NG_Var = 0

		tempCNGConvFuel = sum(value.(EP[:eTotalConv_NG_VarOut_Z])[z,:])

		if setup["ModelSyntheticNG"] == 1
			for y in dfSyn_NG[dfSyn_NG[!,:Zone].==z,:][!,:R_ID]
				tempC_Syn_NG_Fix = tempC_Syn_NG_Fix +
					value.(EP[:eFixed_Cost_Syn_NG_per_type])[y]

				tempC_Syn_NG_Var = tempC_Syn_NG_Var +
					sum(value.(EP[:eCSyn_NGProdVar_out])[y,:])

				tempCTotal = tempCTotal +
						value.(EP[:eFixed_Cost_Syn_NG_per_type])[y] +
						sum(value.(EP[:eCSyn_NGProdVar_out])[y,:])
			end
		end

		tempCTotal = tempCTotal +  tempCNGConvFuel

		dfNGCost[!,Symbol("Zone$z")] = [tempCTotal, tempC_Syn_NG_Fix, tempC_Syn_NG_Var, tempCNGConvFuel]
	end
	CSV.write(string(path,sep,"NG_costs.csv"), dfNGCost)
end
