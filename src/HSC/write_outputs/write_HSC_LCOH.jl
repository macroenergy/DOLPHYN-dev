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
write_HSC_green_h2(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
"""
function write_HSC_LCOH(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

	dfH2Gen = inputs["dfH2Gen"]
	H2_ELECTROLYZER = inputs["H2_ELECTROLYZER"]
	BLUE_H2 = inputs["BLUE_H2"]
	GREY_H2 = inputs["GREY_H2"]
	H2_STOR_ALL = inputs["H2_STOR_ALL"]

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	################################################################################################################################
	################################################################################################################################
	# Blue H2 LCOH
	dfCost = DataFrame(Costs = ["Blue_H2_Generation", "Fixed_Cost", "Var_Cost", "Fuel_Cost", "Electricity_Cost", "Blue_H2_CO2_MAC", "Blue_H2_CO2_Stor_Cost", "Blue_H2_CO2_Pipeline_Cost", "Total_Cost", "LCOH"])

	################################################################################################################################
	# Computing zonal cost breakdown by cost category
	Blue_H2_Generation_Zone = zeros(size(1:Z))
	Blue_H2_Fixed_Cost_Zone = zeros(size(1:Z))
	Blue_H2_Var_Cost_Zone = zeros(size(1:Z))
	Blue_H2_Fuel_Cost_Zone = zeros(size(1:Z))
	Blue_H2_Electricity_Cost_Zone = zeros(size(1:Z))
	Blue_H2_CO2_MAC = zeros(size(1:Z))

	Blue_H2_LCOH_Zone = zeros(size(1:Z))

	haskey(inputs, "NCO2Cap") ? num_co2_caps = inputs["NCO2Cap"] : num_co2_caps = 0

	for z in 1:Z
		tempBlue_H2_Generation = 0
		tempBlue_H2_Fixed_Cost = 0
		tempBlue_H2_Var_Cost = 0
		tempBlue_H2_Fuel_Cost = 0
		tempBlue_H2_Electricity_Cost = 0 
		tempBlue_H2_CO2_MAC = 0
		tempBlue_H2_CO2_Emission = 0
		

		for y in intersect(BLUE_H2, dfH2Gen[dfH2Gen[!,:Zone].==z,:R_ID])
			tempBlue_H2_Generation = tempBlue_H2_Generation + sum(inputs["omega"].* (value.(EP[:vH2Gen])[y,:]))
			tempBlue_H2_Fixed_Cost = tempBlue_H2_Fixed_Cost + value.(EP[:eH2GenCFix])[y]
			tempBlue_H2_Var_Cost = tempBlue_H2_Var_Cost + sum(inputs["omega"].* (dfH2Gen[!,:Var_OM_Cost_p_MWh][y].* (value.(EP[:vH2Gen])[y,:])))
			tempBlue_H2_Fuel_Cost = tempBlue_H2_Fuel_Cost + sum(inputs["omega"].* inputs["fuel_costs"][dfH2Gen[!,:Fuel][y]].* dfH2Gen[!,:etaFuel_MMBtu_p_MWh][y].* (value.(EP[:vH2Gen])[y,:]))
			tempBlue_H2_Electricity_Cost = tempBlue_H2_Electricity_Cost + sum(value.(EP[:vP2G])[y,:].* dual.(EP[:cPowerBalance])[:,z])
			tempBlue_H2_CO2_Emission = tempBlue_H2_CO2_Emission + sum(inputs["omega"].* (value.(EP[:eH2EmissionsByPlant])[y,:]))
		end

		if has_duals(EP) == 1 && num_co2_caps > 0
			tempCO2Price = zeros(num_co2_caps)
			for cap in 1:num_co2_caps
				for z in findall(x->x==1, inputs["dfCO2CapZones"][:,cap])
					tempCO2Price[cap] = dual.(EP[:cCO2Emissions_systemwide])[cap]
				end
			end
			tempCO2Price_z = sum(tempCO2Price)
		else
			tempCO2Price_z = 0
		end

		tempBlue_H2_CO2_MAC = abs(tempCO2Price_z) * tempBlue_H2_CO2_Emission

		tempBlue_H2_CTotal = tempBlue_H2_Fixed_Cost + tempBlue_H2_Electricity_Cost + tempBlue_H2_Var_Cost + tempBlue_H2_Fuel_Cost + tempBlue_H2_CO2_MAC
		tempBlue_H2_LCOH = tempBlue_H2_CTotal/tempBlue_H2_Generation

		Blue_H2_Generation_Zone[z] = tempBlue_H2_Generation
		Blue_H2_Fixed_Cost_Zone[z] = tempBlue_H2_Fixed_Cost
		Blue_H2_Var_Cost_Zone[z] = tempBlue_H2_Var_Cost
		Blue_H2_Fuel_Cost_Zone[z] = tempBlue_H2_Fuel_Cost
		Blue_H2_Electricity_Cost_Zone[z] = tempBlue_H2_Electricity_Cost
		Blue_H2_CO2_MAC[z] = tempBlue_H2_CO2_MAC

		Blue_H2_LCOH_Zone[z] = tempBlue_H2_LCOH

		dfCost[!,Symbol("Zone$z")] = [tempBlue_H2_Generation, tempBlue_H2_Fixed_Cost, tempBlue_H2_Var_Cost, tempBlue_H2_Fuel_Cost, tempBlue_H2_Electricity_Cost, tempBlue_H2_CO2_MAC, "-", "-", tempBlue_H2_CTotal, tempBlue_H2_LCOH]
	end

	Blue_H2_Generation_Total = sum(Blue_H2_Generation_Zone)
	Blue_H2_Fixed_Cost_Total = sum(Blue_H2_Fixed_Cost_Zone)
	Blue_H2_Var_Cost_Total = sum(Blue_H2_Var_Cost_Zone)
	Blue_H2_Fuel_Cost_Total = sum(Blue_H2_Fuel_Cost_Zone)
	Blue_H2_Electricity_Cost_Total = sum(Blue_H2_Electricity_Cost_Zone)
	Blue_H2_CO2_MAC_Total = sum(Blue_H2_CO2_MAC)

	if setup["ModelCSC"] == 1
		Power_CCS = sum(sum(inputs["omega"].* (value.(EP[:ePower_CO2_captured_per_zone_per_time])[z,:])) for z in 1:Z)

		if setup["ModelH2"] == 1
			H2_CCS = sum(sum(inputs["omega"].* (value.(EP[:eHydrogen_CO2_captured_per_zone_per_time])[z,:])) for z in 1:Z)
		else
			H2_CCS = 0
		end
	
		DAC_Capture =  sum(sum(inputs["omega"].* (value.(EP[:eDAC_CO2_Captured_per_zone_per_time])[z,:])) for z in 1:Z)
		DAC_Fuel_CCS = sum(sum(inputs["omega"].* (value.(EP[:eDAC_Fuel_CO2_captured_per_zone_per_time])[z,:])) for z in 1:Z)
	
		if setup["ModelBIO"] == 1
			Biorefinery_Capture = sum(sum(inputs["omega"].* (value.(EP[:eBIO_CO2_captured_per_zone_per_time])[z,:])) for z in 1:Z)
		else
			Biorefinery_Capture = 0
		end
	
		if setup["ModelLiquidFuels"] == 1
			Synfuel_Production_Capture = sum(sum(inputs["omega"].* (value.(EP[:eSyn_Fuels_CO2_Capture_Per_Zone_Per_Time])[z,:])) for z in 1:Z)
		else
			Synfuel_Production_Capture = 0
		end

		Total_CO2_Stored = Power_CCS + H2_CCS + DAC_Capture + DAC_Fuel_CCS + Biorefinery_Capture + Synfuel_Production_Capture
		Fraction_H2_CCS = H2_CCS/Total_CO2_Stored

		cCO2Stor = value(EP[:eFixed_Cost_CO2_Storage_total])
		cCO2Injection = value(EP[:eVar_OM_CO2_Injection_total])

		if setup["ModelCO2Pipelines"] == 1
			cCO2NetworkExpansion = value(EP[:eCCO2Pipe])
		else
			cCO2NetworkExpansion = 0
		end

		Blue_H2_CO2_Stor_Cost = (cCO2Injection + cCO2Stor) * Fraction_H2_CCS
		Blue_H2_CO2_Pipeline_Cost = cCO2NetworkExpansion * Fraction_H2_CCS

	else
		Blue_H2_CO2_Stor_Cost = 0
		Blue_H2_CO2_Pipeline_Cost = 0
	end

	# Define total costs
	cBlue_H2_Total = Blue_H2_Fixed_Cost_Total + Blue_H2_Var_Cost_Total + Blue_H2_Fuel_Cost_Total + Blue_H2_Electricity_Cost_Total + Blue_H2_CO2_MAC_Total + Blue_H2_CO2_Stor_Cost + Blue_H2_CO2_Pipeline_Cost

	Blue_H2_LCOH_Total = cBlue_H2_Total/Blue_H2_Generation_Total

	# Define total column, i.e. column 2
	dfCost[!,Symbol("Total")] = [Blue_H2_Generation_Total, Blue_H2_Fixed_Cost_Total, Blue_H2_Var_Cost_Total, Blue_H2_Fuel_Cost_Total, Blue_H2_Electricity_Cost_Total, Blue_H2_CO2_MAC_Total, Blue_H2_CO2_Stor_Cost, Blue_H2_CO2_Pipeline_Cost, cBlue_H2_Total, Blue_H2_LCOH_Total]


	CSV.write(string(path,sep,"HSC_LCOH_blue_h2.csv"), dfCost)

	################################################################################################################################
	################################################################################################################################
	# Green H2 LCOH
	dfCost = DataFrame(Costs = ["Green_H2_Generation", "Fixed_Cost", "Electricity_Cost", "Storage_Cost", "Pipeline_Cost", "Total_Cost", "LCOH"])

	################################################################################################################################
	# Computing zonal cost breakdown by cost category
	Green_H2_Generation_Zone = zeros(size(1:Z))
	Green_H2_Fixed_Cost_Zone = zeros(size(1:Z))
	Green_H2_Electricity_Cost_Zone = zeros(size(1:Z))
	Green_H2_Storage_Cost_Zone = zeros(size(1:Z))
	Green_H2_LCOH_Zone = zeros(size(1:Z))

	for z in 1:Z
		tempGreen_H2_Generation = 0
		tempGreen_H2_Fixed_Cost = 0
		tempGreen_H2_Electricity_Cost = 0 
		tempGreen_H2_Storage_Cost = 0
		

		for y in intersect(H2_ELECTROLYZER, dfH2Gen[dfH2Gen[!,:Zone].==z,:R_ID])
			tempGreen_H2_Generation = tempGreen_H2_Generation + sum(inputs["omega"].* (value.(EP[:vH2Gen])[y,:]))
			tempGreen_H2_Fixed_Cost = tempGreen_H2_Fixed_Cost + value.(EP[:eH2GenCFix])[y]
			tempGreen_H2_Electricity_Cost = tempGreen_H2_Electricity_Cost + sum(value.(EP[:vP2G])[y,:].* dual.(EP[:cPowerBalance])[:,z])
		end

		for y in intersect(H2_STOR_ALL, dfH2Gen[dfH2Gen[!,:Zone].==z,:R_ID])
			tempGreen_H2_Storage_Cost = tempGreen_H2_Storage_Cost + value.(EP[:eCFixH2Energy])[y] + value.(EP[:eCFixH2Charge])[y]
		end

		tempGreen_H2_CTotal = tempGreen_H2_Fixed_Cost + tempGreen_H2_Electricity_Cost + tempGreen_H2_Storage_Cost
		tempGreen_H2_LCOH = tempGreen_H2_CTotal/tempGreen_H2_Generation

		Green_H2_Generation_Zone[z] = tempGreen_H2_Generation
		Green_H2_Fixed_Cost_Zone[z] = tempGreen_H2_Fixed_Cost
		Green_H2_Electricity_Cost_Zone[z] = tempGreen_H2_Electricity_Cost
		Green_H2_Storage_Cost_Zone[z] = tempGreen_H2_Storage_Cost
		Green_H2_LCOH_Zone[z] = tempGreen_H2_LCOH

		dfCost[!,Symbol("Zone$z")] = [tempGreen_H2_Generation, tempGreen_H2_Fixed_Cost, tempGreen_H2_Electricity_Cost, tempGreen_H2_Storage_Cost, "-", tempGreen_H2_CTotal, tempGreen_H2_LCOH]
	end

	Green_H2_Generation_Total = sum(Green_H2_Generation_Zone)
	Green_H2_Fixed_Cost_Total = sum(Green_H2_Fixed_Cost_Zone)
	Green_H2_Electricity_Cost_Total = sum(Green_H2_Electricity_Cost_Zone)
	Green_H2_Storage_Cost_Total = sum(Green_H2_Storage_Cost_Zone)

	if Z > 1
		if setup["ModelH2Pipelines"] == 1
			Green_H2_Pipeline_Cost_Total = value(EP[:eCH2Pipe])
		else
			Green_H2_Pipeline_Cost_Total = 0
		end
	else
		Green_H2_Pipeline_Cost_Total = 0 
	end


	# Define total costs
	cGreen_H2_Total = Green_H2_Fixed_Cost_Total + Green_H2_Electricity_Cost_Total + Green_H2_Storage_Cost_Total + Green_H2_Pipeline_Cost_Total

	Green_H2_LCOH_Total = cGreen_H2_Total/Green_H2_Generation_Total

	# Define total column, i.e. column 2
	dfCost[!,Symbol("Total")] = [Green_H2_Generation_Total, Green_H2_Fixed_Cost_Total, Green_H2_Electricity_Cost_Total, Green_H2_Storage_Cost_Total, Green_H2_Pipeline_Cost_Total, cGreen_H2_Total, Green_H2_LCOH_Total]


	CSV.write(string(path,sep,"HSC_LCOH_green_h2.csv"), dfCost)

	################################################################################################################################
	################################################################################################################################
	# Grey H2 LCOH
	dfCost = DataFrame(Costs = ["Grey_H2_Generation", "Fixed_Cost", "Var_Cost", "Fuel_Cost", "Electricity_Cost", "Grey_H2_CO2_MAC", "Total_Cost", "LCOH"])

	################################################################################################################################
	# Computing zonal cost breakdown by cost category
	Grey_H2_Generation_Zone = zeros(size(1:Z))
	Grey_H2_Fixed_Cost_Zone = zeros(size(1:Z))
	Grey_H2_Var_Cost_Zone = zeros(size(1:Z))
	Grey_H2_Fuel_Cost_Zone = zeros(size(1:Z))
	Grey_H2_Electricity_Cost_Zone = zeros(size(1:Z))
	Grey_H2_CO2_MAC = zeros(size(1:Z))

	Grey_H2_LCOH_Zone = zeros(size(1:Z))

	for z in 1:Z
		tempGrey_H2_Generation = 0
		tempGrey_H2_Fixed_Cost = 0
		tempGrey_H2_Var_Cost = 0
		tempGrey_H2_Fuel_Cost = 0
		tempGrey_H2_Electricity_Cost = 0
		tempGrey_H2_CO2_MAC = 0
		tempGrey_H2_CO2_Emission = 0
		

		for y in intersect(GREY_H2, dfH2Gen[dfH2Gen[!,:Zone].==z,:R_ID])
			tempGrey_H2_Generation = tempGrey_H2_Generation + sum(inputs["omega"].* (value.(EP[:vH2Gen])[y,:]))
			tempGrey_H2_Fixed_Cost = tempGrey_H2_Fixed_Cost + value.(EP[:eH2GenCFix])[y]
			tempGrey_H2_Var_Cost = tempGrey_H2_Var_Cost + sum(inputs["omega"].* (dfH2Gen[!,:Var_OM_Cost_p_MWh][y].* (value.(EP[:vH2Gen])[y,:])))
			tempGrey_H2_Fuel_Cost = tempGrey_H2_Fuel_Cost + sum(inputs["omega"].* inputs["fuel_costs"][dfH2Gen[!,:Fuel][y]].* dfH2Gen[!,:etaFuel_MMBtu_p_MWh][y].* (value.(EP[:vH2Gen])[y,:]))
			tempGrey_H2_Electricity_Cost = tempGrey_H2_Electricity_Cost + sum(value.(EP[:vP2G])[y,:].* dual.(EP[:cPowerBalance])[:,z])
			tempGrey_H2_CO2_Emission = tempGrey_H2_CO2_Emission + sum(inputs["omega"].* (value.(EP[:eH2EmissionsByPlant])[y,:]))
		end

		if has_duals(EP) == 1 && num_co2_caps > 0
			tempCO2Price = zeros(num_co2_caps)
			for cap in 1:num_co2_caps
				for z in findall(x->x==1, inputs["dfCO2CapZones"][:,cap])
					tempCO2Price[cap] = dual.(EP[:cCO2Emissions_systemwide])[cap]
				end
			end
			tempCO2Price_z = sum(tempCO2Price)
		else
			tempCO2Price_z = 0
		end

		tempGrey_H2_CO2_MAC = abs(tempCO2Price_z) * tempGrey_H2_CO2_Emission

		tempGrey_H2_CTotal = tempGrey_H2_Fixed_Cost + tempGrey_H2_Electricity_Cost + tempGrey_H2_Var_Cost + tempGrey_H2_Fuel_Cost + tempGrey_H2_CO2_MAC
		tempGrey_H2_LCOH = tempGrey_H2_CTotal/tempGrey_H2_Generation

		Grey_H2_Generation_Zone[z] = tempGrey_H2_Generation
		Grey_H2_Fixed_Cost_Zone[z] = tempGrey_H2_Fixed_Cost
		Grey_H2_Var_Cost_Zone[z] = tempGrey_H2_Var_Cost
		Grey_H2_Fuel_Cost_Zone[z] = tempGrey_H2_Fuel_Cost
		Grey_H2_Electricity_Cost_Zone[z] = tempGrey_H2_Electricity_Cost
		Grey_H2_CO2_MAC[z] = tempGrey_H2_CO2_MAC

		Grey_H2_LCOH_Zone[z] = tempGrey_H2_LCOH

		dfCost[!,Symbol("Zone$z")] = [tempGrey_H2_Generation, tempGrey_H2_Fixed_Cost, tempGrey_H2_Var_Cost, tempGrey_H2_Fuel_Cost, tempGrey_H2_Electricity_Cost, tempGrey_H2_CO2_MAC, tempGrey_H2_CTotal, tempGrey_H2_LCOH]
	end

	Grey_H2_Generation_Total = sum(Grey_H2_Generation_Zone)
	Grey_H2_Fixed_Cost_Total = sum(Grey_H2_Fixed_Cost_Zone)
	Grey_H2_Var_Cost_Total = sum(Grey_H2_Var_Cost_Zone)
	Grey_H2_Fuel_Cost_Total = sum(Grey_H2_Fuel_Cost_Zone)
	Grey_H2_Electricity_Cost_Total = sum(Grey_H2_Electricity_Cost_Zone)
	Grey_H2_CO2_MAC_Total = sum(Grey_H2_CO2_MAC)

	# Define total costs
	cGrey_H2_Total = Grey_H2_Fixed_Cost_Total + Grey_H2_Var_Cost_Total + Grey_H2_Fuel_Cost_Total + Grey_H2_Electricity_Cost_Total + Grey_H2_CO2_MAC_Total

	Grey_H2_LCOH_Total = cGrey_H2_Total/Grey_H2_Generation_Total

	# Define total column, i.e. column 2
	dfCost[!,Symbol("Total")] = [Grey_H2_Generation_Total, Grey_H2_Fixed_Cost_Total, Grey_H2_Var_Cost_Total, Grey_H2_Fuel_Cost_Total, Grey_H2_Electricity_Cost_Total, Grey_H2_CO2_MAC_Total, cGrey_H2_Total, Grey_H2_LCOH_Total]


	CSV.write(string(path,sep,"HSC_LCOH_grey_h2.csv"), dfCost)

	################################################################################################################################
	################################################################################################################################
	# Combined H2 LCOH
	dfCost = DataFrame(Costs = ["H2_Generation", "Fixed_Cost", "Var_Cost", "Fuel_Cost", "Electricity_Cost", "CO2_MAC", "H2_Storage_Cost", "H2_Pipeline_Cost", "CO2_Stor_Cost", "CO2_Pipeline_Cost", "Total_Cost", "LCOH"])
	dfCost[!,Symbol("Green_H2")] = [Green_H2_Generation_Total, Green_H2_Fixed_Cost_Total, "-", "-", Green_H2_Electricity_Cost_Total, "-", Green_H2_Storage_Cost_Total, Green_H2_Pipeline_Cost_Total, "-", "-", cGreen_H2_Total, Green_H2_LCOH_Total]
	dfCost[!,Symbol("Blue_H2")] = [Blue_H2_Generation_Total, Blue_H2_Fixed_Cost_Total, Blue_H2_Var_Cost_Total, Blue_H2_Fuel_Cost_Total, Blue_H2_Electricity_Cost_Total, Blue_H2_CO2_MAC_Total, "-", "-", Blue_H2_CO2_Stor_Cost, Blue_H2_CO2_Pipeline_Cost, cBlue_H2_Total, Blue_H2_LCOH_Total]
	dfCost[!,Symbol("Grey_H2")] = [Grey_H2_Generation_Total, Grey_H2_Fixed_Cost_Total, Grey_H2_Var_Cost_Total, Grey_H2_Fuel_Cost_Total, Grey_H2_Electricity_Cost_Total, Grey_H2_CO2_MAC_Total, "-", "-", "-", "-", cGrey_H2_Total, Grey_H2_LCOH_Total]
	CSV.write(string(path,sep,"HSC_LCOH.csv"), dfCost)

end