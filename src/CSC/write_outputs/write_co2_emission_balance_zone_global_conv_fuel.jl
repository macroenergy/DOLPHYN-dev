"""
GenX: An Configurable Capacity Expansion Model
Copyright (C) 2021,  Massachusetts Institute of Technology
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
	write_co2_emission_balance_zone_global_conv_fuel(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting CO2 balance of resources across different zones.
"""
function write_co2_emission_balance_zone_global_conv_fuel(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	## CO2 balance for each zone
	dfCO2Balance = Array{Any}
	rowoffset=3
	for z in 1:Z
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 29)
	   	dfTemp1[1,1:size(dfTemp1,2)] = ["Power Emissions", "H2 Emissions", "DAC Emissions", "DAC Capture", "CO2 Pipeline Loss", "Bio Elec Plant Emissions", "Biomass CO2 for Bio Elec", "Bio H2 Plant Emissions", "Biomass CO2 for Bio H2", "Bio LF Plant Emissions", "Biomass CO2 for Bio LF",  "Bio NG Plant Emissions",  "Biomass CO2 for Bio NG", "Bioresource Emissions", "Synfuel Plant Emissions","Synfuel Byproducts Emissions","Syn Gasoline","Syn Jetfuel","Syn Diesel","Bio Gasoline", "Bio Jetfuel", "Bio Diesel", "Syn NG Plant Emissions", "Synthetic NG", "Bio NG", "Conventional NG", "NG Reduction from Power CCS", "NG Reduction from H2 CCS", "NG Reduction from DAC CCS"]
	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([z],size(dfTemp1,2))
	   	for t in 1:T
			if setup["ModelNGSC"] == 1
				dfTemp1[t+rowoffset,1] = value(EP[:ePower_NG_CO2_emission_per_zone_per_time][z,t])
			else
				dfTemp1[t+rowoffset,1] = value(EP[:eEmissionsByZone][z,t])
			end
	     	
			dfTemp1[t+rowoffset,2] = 0

			if setup["ModelH2"] == 1
				if setup["ModelNGSC"] == 1
					dfTemp1[t+rowoffset,2] = value(EP[:eHydrogen_NG_CO2_emission_per_zone_per_time][z,t])
				else
					dfTemp1[t+rowoffset,2] = value(EP[:eH2EmissionsByZone][z,t])
				end
			end

			dfTemp1[t+rowoffset,3] = value(EP[:eDAC_Emissions_per_zone_per_time][z,t])
			dfTemp1[t+rowoffset,4]= - value(EP[:eDAC_CO2_Captured_per_zone_per_time][z,t])

			dfTemp1[t+rowoffset,5] = 0

			if setup["ModelCO2Pipelines"] == 1 && setup["CO2Pipeline_Loss"] == 1
				dfTemp1[t+rowoffset,5] = value(EP[:eCO2Loss_Pipes_zt][z,t])
			end

			dfTemp1[t+rowoffset,6] = 0
			dfTemp1[t+rowoffset,7] = 0
			dfTemp1[t+rowoffset,8] = 0
			dfTemp1[t+rowoffset,9] = 0
			dfTemp1[t+rowoffset,10] = 0
			dfTemp1[t+rowoffset,11] = 0
			dfTemp1[t+rowoffset,12] = 0
			dfTemp1[t+rowoffset,13] = 0
			dfTemp1[t+rowoffset,14] = 0
			
			if setup["ModelBESC"] == 1

				if setup["Bio_ELEC_On"] == 1
					dfTemp1[t+rowoffset,6] = value(EP[:eBio_ELEC_CO2_emissions_per_zone_per_time][z,t])
					dfTemp1[t+rowoffset,7] = - value(EP[:eBiomass_CO2_per_zone_per_time_ELEC][z,t])
				end
				
				if setup["ModelH2"] == 1 && setup["Bio_H2_On"] == 1
					dfTemp1[t+rowoffset,8] = value(EP[:eBio_H2_CO2_emissions_per_zone_per_time][z,t])
					dfTemp1[t+rowoffset,9] = - value(EP[:eBiomass_CO2_per_zone_per_time_H2][z,t])
				end

				if setup["ModelLFSC"] == 1 && setup["Bio_LF_On"] == 1
					dfTemp1[t+rowoffset,10] = value(EP[:eBio_LF_Plant_CO2_emissions_per_zone_per_time][z,t])
					dfTemp1[t+rowoffset,11] = - value(EP[:eBiomass_CO2_per_zone_per_time_LF][z,t])
				end

				if setup["ModelNGSC"] == 1 && setup["Bio_NG_On"] == 1
					dfTemp1[t+rowoffset,12] = value(EP[:eBio_NG_Plant_CO2_emissions_per_zone_per_time][z,t])
					dfTemp1[t+rowoffset,13] = - value(EP[:eBiomass_CO2_per_zone_per_time_NG][z,t])
				end

				if setup["Energy_Crops_Herb_Supply"] == 1
					dfTemp1[t+rowoffset,14] += value(EP[:eHerb_biomass_emission_per_zone_per_time][z,t])
				end
	
				if setup["Energy_Crops_Wood_Supply"] == 1
					dfTemp1[t+rowoffset,14] += value(EP[:eWood_biomass_emission_per_zone_per_time][z,t])
				end
	
				if setup["Agri_Res_Supply"] == 1
					dfTemp1[t+rowoffset,14] += value(EP[:eAgri_Res_biomass_emission_per_zone_per_time][z,t])
				end
	
				if setup["Agri_Process_Waste_Supply"] == 1
					dfTemp1[t+rowoffset,14] += value(EP[:eAgri_Process_Waste_biomass_emission_per_zone_per_time][z,t])
				end
	
				if setup["Agri_Forest_Supply"] == 1
					dfTemp1[t+rowoffset,14] += value(EP[:eForest_biomass_emission_per_zone_per_time][z,t])
				end
			end

		
			dfTemp1[t+rowoffset,15] = 0
			dfTemp1[t+rowoffset,16] = 0
			dfTemp1[t+rowoffset,17] = 0
			dfTemp1[t+rowoffset,18] = 0
			dfTemp1[t+rowoffset,19] = 0
			dfTemp1[t+rowoffset,20] = 0
			dfTemp1[t+rowoffset,21] = 0
			dfTemp1[t+rowoffset,22] = 0

			if setup["ModelLFSC"] == 1

				if setup["ModelSyntheticFuels"] == 1
					dfTemp1[t+rowoffset,15] = value(EP[:eSynfuels_Production_CO2_Emissions_By_Zone][z,t])
					dfTemp1[t+rowoffset,16] = value(EP[:eByProdConsCO2EmissionsByZone][z,t])
					dfTemp1[t+rowoffset,17] = value(EP[:eSyn_Gasoline_CO2_Emissions_By_Zone][z,t])
					dfTemp1[t+rowoffset,18] = value(EP[:eSyn_Jetfuel_CO2_Emissions_By_Zone][z,t])
					dfTemp1[t+rowoffset,19] = value(EP[:eSyn_Diesel_CO2_Emissions_By_Zone][z,t])
				end

				if setup["ModelBESC"] == 1 && setup["Bio_LF_On"] == 1
					dfTemp1[t+rowoffset,20] = value(EP[:eBio_Gasoline_CO2_Emissions_By_Zone][z,t])
					dfTemp1[t+rowoffset,21] = value(EP[:eBio_Jetfuel_CO2_Emissions_By_Zone][z,t])
					dfTemp1[t+rowoffset,22] = value(EP[:eBio_Diesel_CO2_Emissions_By_Zone][z,t])
				end

			end

			dfTemp1[t+rowoffset,23] = 0
			dfTemp1[t+rowoffset,24] = 0
			dfTemp1[t+rowoffset,25] = 0
			dfTemp1[t+rowoffset,26] = 0
			dfTemp1[t+rowoffset,27] = 0
			dfTemp1[t+rowoffset,28] = 0
			dfTemp1[t+rowoffset,29] = 0

			if setup["ModelNGSC"] == 1

				if setup["ModelSyntheticNG"] == 1
					dfTemp1[t+rowoffset,23] = value(EP[:eSyn_NG_Production_CO2_Emissions_By_Zone][z,t])
					dfTemp1[t+rowoffset,24] = value(EP[:eSyn_NG_CO2_Emissions_By_Zone][z,t])
				end

				if setup["ModelBESC"] == 1 && setup["Bio_NG_On"] == 1
					dfTemp1[t+rowoffset,25] = value(EP[:eBio_NG_CO2_Emissions_By_Zone][z,t])
				end

				#Power sector and HSC NG raw emissions (before CCS) are displayed in "Power Emissions" and "H2 Emissions" columns
				dfTemp1[t+rowoffset,26] = value(EP[:eConv_NG_CO2_Emissions][z,t]) - value(EP[:ePower_NG_CO2_emission_per_zone_per_time][z,t]) - value(EP[:eHydrogen_NG_CO2_emission_per_zone_per_time][z,t])

				dfTemp1[t+rowoffset,27] = -value(EP[:ePower_NG_CO2_captured_per_zone_per_time][z,t])

				if setup["ModelH2"] == 1
					dfTemp1[t+rowoffset,28] = -value(EP[:eHydrogen_NG_CO2_captured_per_zone_per_time][z,t])
				end

				if setup["ModelCSC"] == 1
					dfTemp1[t+rowoffset,29] = -value(EP[:eDAC_NG_CO2_captured_per_zone_per_time][z,t])
				end

			end

	   	end

		## Annual values
		if setup["ModelNGSC"] == 1
			dfTemp1[rowoffset,1] = sum(inputs["omega"][t] * value.(EP[:ePower_NG_CO2_emission_per_zone_per_time][z,t]) for t in 1:T)
		else
			dfTemp1[rowoffset,1] = sum(inputs["omega"][t] * value.(EP[:eEmissionsByZone][z,t]) for t in 1:T)
		end
	     	
		dfTemp1[rowoffset,2] = 0

		if setup["ModelH2"] == 1
			if setup["ModelNGSC"] == 1
				dfTemp1[rowoffset,2] = sum(inputs["omega"][t] * value.(EP[:eHydrogen_NG_CO2_emission_per_zone_per_time][z,t]) for t in 1:T)
			else
				dfTemp1[rowoffset,2] = sum(inputs["omega"][t] * value.(EP[:eH2EmissionsByZone][z,t]) for t in 1:T)
			end
		end

		dfTemp1[rowoffset,3] = sum(inputs["omega"][t] * value.(EP[:eDAC_Emissions_per_zone_per_time][z,t]) for t in 1:T)
		dfTemp1[rowoffset,4]= - sum(inputs["omega"][t] * value.(EP[:eDAC_CO2_Captured_per_zone_per_time][z,t]) for t in 1:T)

		if setup["ModelCO2Pipelines"] == 1 && setup["CO2Pipeline_Loss"] == 1
			dfTemp1[rowoffset,5] = sum(inputs["omega"][t] * value.(EP[:eCO2Loss_Pipes_zt][z,t]) for t in 1:T)
		else
			dfTemp1[rowoffset,5] = 0
		end

		dfTemp1[rowoffset,6] = 0
		dfTemp1[rowoffset,7] = 0
		dfTemp1[rowoffset,8] = 0
		dfTemp1[rowoffset,9] = 0
		dfTemp1[rowoffset,10] = 0
		dfTemp1[rowoffset,11] = 0
		dfTemp1[rowoffset,12] = 0
		dfTemp1[rowoffset,13] = 0
		dfTemp1[rowoffset,14] = 0

		if setup["ModelBESC"] == 1

			if setup["Bio_ELEC_On"] == 1
				dfTemp1[rowoffset,6] = sum(inputs["omega"][t] * value.(EP[:eBio_ELEC_CO2_emissions_per_zone_per_time][z,t]) for t in 1:T)
				dfTemp1[rowoffset,7] = - sum(inputs["omega"][t] * value.(EP[:eBiomass_CO2_per_zone_per_time_ELEC][z,t]) for t in 1:T)
			end
			
			if setup["ModelH2"] == 1 && setup["Bio_H2_On"] == 1
				dfTemp1[rowoffset,8] = sum(inputs["omega"][t] * value.(EP[:eBio_H2_CO2_emissions_per_zone_per_time][z,t]) for t in 1:T)
				dfTemp1[rowoffset,9] = - sum(inputs["omega"][t] * value.(EP[:eBiomass_CO2_per_zone_per_time_H2][z,t]) for t in 1:T)
			end

			if setup["ModelLFSC"] == 1 && setup["Bio_LF_On"] == 1
				dfTemp1[rowoffset,10] = sum(inputs["omega"][t] * value.(EP[:eBio_LF_Plant_CO2_emissions_per_zone_per_time][z,t]) for t in 1:T)
				dfTemp1[rowoffset,11] = - sum(inputs["omega"][t] * value.(EP[:eBiomass_CO2_per_zone_per_time_LF][z,t]) for t in 1:T)
			end

			if setup["ModelNGSC"] == 1 && setup["Bio_NG_On"] == 1
				dfTemp1[rowoffset,12] = sum(inputs["omega"][t] * value.(EP[:eBio_NG_Plant_CO2_emissions_per_zone_per_time][z,t]) for t in 1:T)
				dfTemp1[rowoffset,13] = - sum(inputs["omega"][t] * value.(EP[:eBiomass_CO2_per_zone_per_time_NG][z,t]) for t in 1:T)
			end

			if setup["Energy_Crops_Herb_Supply"] == 1
				dfTemp1[rowoffset,14] += sum(inputs["omega"][t] * (value.(EP[:eHerb_biomass_emission_per_zone_per_time][z,t])) for t in 1:T)
			end

			if setup["Energy_Crops_Wood_Supply"] == 1
				dfTemp1[rowoffset,14] += sum(inputs["omega"][t] * (value.(EP[:eWood_biomass_emission_per_zone_per_time][z,t])) for t in 1:T)
			end

			if setup["Agri_Res_Supply"] == 1
				dfTemp1[rowoffset,14] += sum(inputs["omega"][t] * (value.(EP[:eAgri_Res_biomass_emission_per_zone_per_time][z,t])) for t in 1:T)
			end

			if setup["Agri_Process_Waste_Supply"] == 1
				dfTemp1[rowoffset,14] += sum(inputs["omega"][t] * (value.(EP[:eAgri_Process_Waste_biomass_emission_per_zone_per_time][z,t])) for t in 1:T)
			end

			if setup["Agri_Forest_Supply"] == 1
				dfTemp1[rowoffset,14] += sum(inputs["omega"][t] * (value.(EP[:eForest_biomass_emission_per_zone_per_time][z,t])) for t in 1:T)
			end
		end
		
		dfTemp1[rowoffset,15] = 0
		dfTemp1[rowoffset,16] = 0
		dfTemp1[rowoffset,17] = 0
		dfTemp1[rowoffset,18] = 0
		dfTemp1[rowoffset,19] = 0
		dfTemp1[rowoffset,20] = 0
		dfTemp1[rowoffset,21] = 0
		dfTemp1[rowoffset,22] = 0

		if setup["ModelLFSC"] == 1

			if setup["ModelSyntheticFuels"] == 1
				dfTemp1[rowoffset,15] = sum(inputs["omega"][t] * value.(EP[:eSynfuels_Production_CO2_Emissions_By_Zone][z,t]) for t in 1:T)
				dfTemp1[rowoffset,16] = sum(inputs["omega"][t] * value.(EP[:eByProdConsCO2EmissionsByZone][z,t]) for t in 1:T)
				dfTemp1[rowoffset,17] = sum(inputs["omega"][t] * value.(EP[:eSyn_Gasoline_CO2_Emissions_By_Zone][z,t]) for t in 1:T)
				dfTemp1[rowoffset,18] = sum(inputs["omega"][t] * value.(EP[:eSyn_Jetfuel_CO2_Emissions_By_Zone][z,t]) for t in 1:T)
				dfTemp1[rowoffset,19] = sum(inputs["omega"][t] * value.(EP[:eSyn_Diesel_CO2_Emissions_By_Zone][z,t]) for t in 1:T)
			end

			if setup["ModelBESC"] == 1 && setup["Bio_LF_On"] == 1
				dfTemp1[rowoffset,20] = sum(inputs["omega"][t] * value.(EP[:eBio_Gasoline_CO2_Emissions_By_Zone][z,t]) for t in 1:T)
				dfTemp1[rowoffset,21] = sum(inputs["omega"][t] * value.(EP[:eBio_Jetfuel_CO2_Emissions_By_Zone][z,t]) for t in 1:T)
				dfTemp1[rowoffset,22] = sum(inputs["omega"][t] * value.(EP[:eBio_Diesel_CO2_Emissions_By_Zone][z,t]) for t in 1:T)
			end

		end

		dfTemp1[rowoffset,23] = 0
		dfTemp1[rowoffset,24] = 0
		dfTemp1[rowoffset,25] = 0
		dfTemp1[rowoffset,26] = 0
		dfTemp1[rowoffset,27] = 0
		dfTemp1[rowoffset,28] = 0
		dfTemp1[rowoffset,29] = 0

		if setup["ModelNGSC"] == 1
				
			if setup["ModelSyntheticNG"] == 1
				dfTemp1[rowoffset,23] = sum(inputs["omega"][t] * value.(EP[:eSyn_NG_Production_CO2_Emissions_By_Zone][z,t]) for t in 1:T)
				dfTemp1[rowoffset,24] = sum(inputs["omega"][t] * value.(EP[:eSyn_NG_CO2_Emissions_By_Zone][z,t]) for t in 1:T)
			end

			if setup["ModelBESC"] == 1 && setup["Bio_NG_On"] == 1
				dfTemp1[rowoffset,25] = sum(inputs["omega"][t] * value.(EP[:eBio_NG_CO2_Emissions_By_Zone][z,t]) for t in 1:T)
			end

			#Power sector and HSC NG raw emissions (before CCS) are displayed in "Power Emissions" and "H2 Emissions" columns
			dfTemp1[rowoffset,26] = sum(inputs["omega"][t] * value.(EP[:eConv_NG_CO2_Emissions][z,t]) for t in 1:T) - sum(inputs["omega"][t] * value.(EP[:ePower_NG_CO2_emission_per_zone_per_time][z,t]) for t in 1:T) - sum(inputs["omega"][t] * value.(EP[:eHydrogen_NG_CO2_emission_per_zone_per_time][z,t]) for t in 1:T)

			dfTemp1[rowoffset,27] = -sum(inputs["omega"][t] * value.(EP[:ePower_NG_CO2_captured_per_zone_per_time][z,t]) for t in 1:T)

			if setup["ModelH2"] == 1
				dfTemp1[rowoffset,28] = -sum(inputs["omega"][t] * value.(EP[:eHydrogen_NG_CO2_captured_per_zone_per_time][z,t]) for t in 1:T)
			end

			if setup["ModelCSC"] == 1
				dfTemp1[rowoffset,29] = -sum(inputs["omega"][t] * value.(EP[:eDAC_NG_CO2_captured_per_zone_per_time][z,t]) for t in 1:T)
			end

		end


		if z==1
			dfCO2Balance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfCO2Balance = hcat(dfCO2Balance, dfTemp1)
		end
	end

	#############################################################
	dfCO2Balance_Conv_Fuels = Array{Any}(nothing, T+rowoffset, 3)
	dfCO2Balance_Conv_Fuels[1,1:size(dfCO2Balance_Conv_Fuels,2)] = ["Conventional Gasoline","Conventional Jetfuel","Conventional Diesel"]
	dfCO2Balance_Conv_Fuels[2,1:size(dfCO2Balance_Conv_Fuels,2)] = repeat(["Global"],size(dfCO2Balance_Conv_Fuels,2))

	for t in 1:T
		if setup["ModelLFSC"] == 1
			if setup["Liquid_Fuels_Hourly_Demand"] == 1
				dfCO2Balance_Conv_Fuels[t+rowoffset,1] = value.(EP[:eConv_Gasoline_CO2_Emissions][t])
				dfCO2Balance_Conv_Fuels[t+rowoffset,2] = value.(EP[:eConv_Jetfuel_CO2_Emissions][t])
				dfCO2Balance_Conv_Fuels[t+rowoffset,3] = value.(EP[:eConv_Diesel_CO2_Emissions][t])
			else
				dfCO2Balance_Conv_Fuels[t+rowoffset,1] = "-"
				dfCO2Balance_Conv_Fuels[t+rowoffset,2] = "-"
				dfCO2Balance_Conv_Fuels[t+rowoffset,3] = "-"
			end
		else
			dfCO2Balance_Conv_Fuels[t+rowoffset,1] = 0
			dfCO2Balance_Conv_Fuels[t+rowoffset,2] = 0
			dfCO2Balance_Conv_Fuels[t+rowoffset,3] = 0
		end
	end

	
	## Annual values
	if setup["ModelLFSC"] == 1
		if setup["Liquid_Fuels_Hourly_Demand"] == 1
			dfCO2Balance_Conv_Fuels[rowoffset,1] = sum(inputs["omega"][t] * value.(EP[:eConv_Gasoline_CO2_Emissions][t]) for t in 1:T)

			dfCO2Balance_Conv_Fuels[rowoffset,2] = sum(inputs["omega"][t] * value.(EP[:eConv_Jetfuel_CO2_Emissions][t]) for t in 1:T)

			dfCO2Balance_Conv_Fuels[rowoffset,3] = sum(inputs["omega"][t] * value.(EP[:eConv_Diesel_CO2_Emissions][t]) for t in 1:T)

		else
			dfCO2Balance_Conv_Fuels[rowoffset,1] = value.(EP[:eConv_Gasoline_CO2_Emissions])
			dfCO2Balance_Conv_Fuels[rowoffset,2] = value.(EP[:eConv_Jetfuel_CO2_Emissions])
			dfCO2Balance_Conv_Fuels[rowoffset,3] = value.(EP[:eConv_Diesel_CO2_Emissions])
		end
	else
		dfCO2Balance_Conv_Fuels[rowoffset,1] = 0
		dfCO2Balance_Conv_Fuels[rowoffset,2] = 0
		dfCO2Balance_Conv_Fuels[rowoffset,3] = 0
	end

	dfCO2Balance =  hcat(dfCO2Balance,dfCO2Balance_Conv_Fuels)

	dfCO2Balance = DataFrame(dfCO2Balance, :auto)
	CSV.write(string(path,sep,"Zone_CO2_emission_balance.csv"), dfCO2Balance, writeheader=false)
end
