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
	write_BESC_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for writing the cost for the different sectors of the bioenergy supply chain (Biorefinery resources CAPEX and OPEX, herb and wood biomass supply).
"""
function write_BESC_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	## Cost results
	
	Z = inputs["Z"]     # Number of zones
	
	dfCost = DataFrame(Costs = ["cTotal", "cBiorefineryFix_ELEC", "cBiorefineryVar_ELEC", "cBiorefineryFix_H2", "cBiorefineryVar_H2", "cBiorefineryFix_LF", "cBiorefineryVar_LF", "cBiorefineryFix_NG", "cBiorefineryVar_NG", "cHerb", "cWood", "cAgriRes", "cAgriProcessWaste", "cForest"])

	cHerb = 0
	cWood = 0
	cAgriRes = 0
	cAgriProcessWaste = 0
	cForest = 0

	if setup["Energy_Crops_Herb_Supply"] == 1
		cHerb = value(EP[:eEnergy_Crops_Herb_Biomass_Supply_cost])
	end

	if setup["Energy_Crops_Wood_Supply"] == 1
		cWood = value(EP[:eEnergy_Crops_Wood_Biomass_Supply_cost])
	end

	if setup["Agri_Res_Supply"] == 1
		cAgriRes = value(EP[:eAgri_Res_Biomass_Supply_cost])
	end

	if setup["Agri_Process_Waste_Supply"] == 1
		cAgriProcessWaste = value(EP[:eAgri_Process_Waste_Biomass_Supply_cost])
	end

	if setup["Agri_Forest_Supply"] == 1
		cForest = value(EP[:eForest_Biomass_Supply_cost])
	end

	
	cBiorefineryVar_ELEC = 0
	cBiorefineryFix_ELEC = 0
	cBiorefineryVar_H2 = 0
	cBiorefineryFix_H2 = 0
	cBiorefineryVar_LF = 0
	cBiorefineryFix_LF = 0
	cBiorefineryVar_NG = 0
	cBiorefineryFix_NG = 0

	if setup["Bio_ELEC_On"] == 1
		dfBioELEC = inputs["dfBioELEC"]
		cBiorefineryVar_ELEC = value(EP[:eVar_Cost_BIO_ELEC])
		cBiorefineryFix_ELEC = value(EP[:eFixed_Cost_BIO_ELEC_total])
	end

	if setup["Bio_H2_On"] == 1
		dfBioH2 = inputs["dfBioH2"]
		cBiorefineryVar_H2 = value(EP[:eVar_Cost_BIO_H2])
		cBiorefineryFix_H2 = value(EP[:eFixed_Cost_BIO_H2_total])
	end
	
	if setup["Bio_LF_On"] == 1
		dfBioLF = inputs["dfBioLF"]
		cBiorefineryVar_LF = value(EP[:eVar_Cost_BIO_LF])
		cBiorefineryFix_LF = value(EP[:eFixed_Cost_BIO_LF_total])
	end

	if setup["Bio_NG_On"] == 1
		dfBioNG = inputs["dfBioNG"]
		cBiorefineryVar_NG = value(EP[:eVar_Cost_BIO_NG])
		cBiorefineryFix_NG = value(EP[:eFixed_Cost_BIO_NG_total])
	end

	# Define total costs
	cTotal = cBiorefineryFix_ELEC + cBiorefineryVar_ELEC + cBiorefineryFix_H2 + cBiorefineryVar_H2 + cBiorefineryFix_LF + cBiorefineryVar_LF + cBiorefineryFix_NG + cBiorefineryVar_NG + cHerb + cWood + cAgriRes + cAgriProcessWaste + cForest

	# Define total column, i.e. column 2
	dfCost[!,Symbol("Total")] = [cTotal, cBiorefineryFix_ELEC, cBiorefineryVar_ELEC, cBiorefineryFix_H2, cBiorefineryVar_H2, cBiorefineryFix_LF, cBiorefineryVar_LF, cBiorefineryFix_NG, cBiorefineryVar_NG, cHerb, cWood, cAgriRes, cAgriProcessWaste, cForest]

	# Computing zonal cost breakdown by cost category
	for z in 1:Z
		tempCTotal = 0
		tempCBIOFixELEC = 0
		tempCBIOVarELEC = 0
		tempCBIOFixH2 = 0
		tempCBIOVarH2 = 0
		tempCBIOFixLF = 0
		tempCBIOVarLF = 0
		tempCBIOFixNG = 0
		tempCBIOVarNG = 0
		tempCBIOHerb = 0
		tempCBIOWood = 0
		tempCBIOAgriRes = 0
		tempCBIOAgriProcessWaste = 0
		tempCBIOForest = 0

		if setup["Bio_ELEC_On"] == 1
			for y in dfBioELEC[dfBioELEC[!,:Zone].==z,:][!,:R_ID]
				tempCBIOFixELEC = tempCBIOFixELEC + value.(EP[:eFixed_Cost_BIO_ELEC_per_type])[y]
				tempCBIOVarELEC = tempCBIOVarELEC + sum(value.(EP[:eVar_Cost_BIO_ELEC_per_plant])[y,:])
				tempCTotal = tempCTotal + value.(EP[:eFixed_Cost_BIO_ELEC_per_type])[y] + sum(value.(EP[:eVar_Cost_BIO_ELEC_per_plant])[y,:])
			end
		end

		if setup["Bio_H2_On"] == 1
			for y in dfBioH2[dfBioH2[!,:Zone].==z,:][!,:R_ID]
				tempCBIOFixH2 = tempCBIOFixH2 + value.(EP[:eFixed_Cost_BIO_H2_per_type])[y]
				tempCBIOVarH2 = tempCBIOVarH2 + sum(value.(EP[:eVar_Cost_BIO_H2_per_plant])[y,:])
				tempCTotal = tempCTotal + value.(EP[:eFixed_Cost_BIO_H2_per_type])[y] + sum(value.(EP[:eVar_Cost_BIO_H2_per_plant])[y,:])
			end
		end

		if setup["Bio_LF_On"] == 1
			for y in dfBioLF[dfBioLF[!,:Zone].==z,:][!,:R_ID]
				tempCBIOFixLF = tempCBIOFixLF + value.(EP[:eFixed_Cost_BIO_LF_per_type])[y]
				tempCBIOVarLF = tempCBIOVarLF + sum(value.(EP[:eVar_Cost_BIO_LF_per_plant])[y,:])
				tempCTotal = tempCTotal + value.(EP[:eFixed_Cost_BIO_LF_per_type])[y] + sum(value.(EP[:eVar_Cost_BIO_LF_per_plant])[y,:])
			end
		end
		
		if setup["Bio_NG_On"] == 1
			for y in dfBioNG[dfBioNG[!,:Zone].==z,:][!,:R_ID]
				tempCBIOFixNG = tempCBIOFixNG + value.(EP[:eFixed_Cost_BIO_NG_per_type])[y]
				tempCBIOVarNG = tempCBIOVarNG + sum(value.(EP[:eVar_Cost_BIO_NG_per_plant])[y,:])
				tempCTotal = tempCTotal + value.(EP[:eFixed_Cost_BIO_NG_per_type])[y] + sum(value.(EP[:eVar_Cost_BIO_NG_per_plant])[y,:])
			end
		end

		if setup["Energy_Crops_Herb_Supply"] == 1
			tempCBIOHerb = tempCBIOHerb + value.(EP[:eEnergy_Crops_Herb_Biomass_Supply_cost_per_zone][z])
			tempCTotal = tempCTotal + value.(EP[:eEnergy_Crops_Herb_Biomass_Supply_cost_per_zone][z])
		end

		if setup["Energy_Crops_Wood_Supply"] == 1
			tempCBIOWood = tempCBIOWood + value.(EP[:eEnergy_Crops_Wood_Biomass_Supply_cost_per_zone][z])
			tempCTotal = tempCTotal + value.(EP[:eEnergy_Crops_Wood_Biomass_Supply_cost_per_zone][z])
		end

		if setup["Agri_Res_Supply"] == 1
			tempCBIOAgriRes = tempCBIOAgriRes + value.(EP[:eAgri_Res_Biomass_Supply_cost_per_zone][z])
			tempCTotal = tempCTotal + value.(EP[:eAgri_Res_Biomass_Supply_cost_per_zone][z])
		end

		if setup["Agri_Process_Waste_Supply"] == 1
			tempCBIOAgriProcessWaste = tempCBIOAgriProcessWaste + value.(EP[:eAgri_Process_Waste_Biomass_Supply_cost_per_zone][z])
			tempCTotal = tempCTotal + value.(EP[:eAgri_Process_Waste_Biomass_Supply_cost_per_zone][z])
		end

		if setup["Agri_Forest_Supply"] == 1
			tempCBIOForest = tempCBIOForest + value.(EP[:eForest_Biomass_Supply_cost_per_zone][z])
			tempCTotal = tempCTotal + value.(EP[:eForest_Biomass_Supply_cost_per_zone][z])
		end

		dfCost[!,Symbol("Zone$z")] = [tempCTotal, tempCBIOFixELEC, tempCBIOVarELEC, tempCBIOFixH2, tempCBIOVarH2, tempCBIOFixLF, tempCBIOVarLF, tempCBIOFixNG, tempCBIOVarNG, tempCBIOHerb, tempCBIOWood, tempCBIOAgriRes, tempCBIOAgriProcessWaste, tempCBIOForest]
	end

	CSV.write(string(path,sep,"BESC_costs.csv"), dfCost)

end
