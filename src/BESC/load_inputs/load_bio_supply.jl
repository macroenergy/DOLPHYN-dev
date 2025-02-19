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
	load_bio_supply(setup::Dict, path::AbstractString, sep::AbstractString, inputs_bio_supply::Dict)

Function for reading input parameters related to biomass supply in the bioenergy supply chain.
"""
function load_bio_supply(setup::Dict, path::AbstractString, sep::AbstractString, inputs_bio_supply::Dict)

	if setup["Energy_Crops_Herb_Supply"] == 1
		#Read in herb biomass related inputs
		Herb_biomass_supply = DataFrame(CSV.File(string(path,sep,"BESC_Supply_Energy_Crops_Herb.csv"), header=true), copycols=true)

		# Add Resource IDs after reading to prevent user errors
		Herb_biomass_supply[!,:R_ID] = 1:size(collect(skipmissing(Herb_biomass_supply[!,1])),1)

		# Store DataFrame of resources input data for use in model
		inputs_bio_supply["dfHerb"] = Herb_biomass_supply

		# Index of supply resources
		inputs_bio_supply["HERB_SUPPLY_RES_ALL"] = size(collect(skipmissing(Herb_biomass_supply[!,:R_ID])),1)

		# Name of supply resources
		inputs_bio_supply["HERB_SUPPLY_NAME"] = collect(skipmissing(Herb_biomass_supply[!,:Biomass_Supply][1:inputs_bio_supply["HERB_SUPPLY_RES_ALL"]]))

		# Set of supply resources
		inputs_bio_supply["BESC_HERB_SUPPLY"] = Herb_biomass_supply[!,:R_ID]

		println(" -- BESC_Supply_Energy_Crops_Herb.csv Successfully Read!")
	end

	####################################################

	if setup["Energy_Crops_Wood_Supply"] == 1
		#Read in wood biomass related inputs
		Wood_biomass_supply = DataFrame(CSV.File(string(path,sep,"BESC_Supply_Energy_Crops_Wood.csv"), header=true), copycols=true)

		# Add Resource IDs after reading to prevent user errors
		Wood_biomass_supply[!,:R_ID] = 1:size(collect(skipmissing(Wood_biomass_supply[!,1])),1)

		# Store DataFrame of resources input data for use in model
		inputs_bio_supply["dfWood"] = Wood_biomass_supply

		# Index of supply resources
		inputs_bio_supply["WOOD_SUPPLY_RES_ALL"] = size(collect(skipmissing(Wood_biomass_supply[!,:R_ID])),1)

		# Name of supply resources
		inputs_bio_supply["WOOD_SUPPLY_NAME"] = collect(skipmissing(Wood_biomass_supply[!,:Biomass_Supply][1:inputs_bio_supply["WOOD_SUPPLY_RES_ALL"]]))

		# Set of supply resources
		inputs_bio_supply["BESC_WOOD_SUPPLY"] = Wood_biomass_supply[!,:R_ID]

		println(" -- BESC_Supply_Energy_Crops_Wood.csv Successfully Read!")
	end

	####################################################

	if setup["Agri_Res_Supply"] == 1
		#Read in agricultural residue biomass related inputs
		Agri_Res_biomass_supply = DataFrame(CSV.File(string(path,sep,"BESC_Supply_Agri_Residue.csv"), header=true), copycols=true)

		# Add Resource IDs after reading to prevent user errors
		Agri_Res_biomass_supply[!,:R_ID] = 1:size(collect(skipmissing(Agri_Res_biomass_supply[!,1])),1)

		# Store DataFrame of resources input data for use in model
		inputs_bio_supply["dfAgri_Res"] = Agri_Res_biomass_supply

		# Index of supply resources
		inputs_bio_supply["AGRI_RES_SUPPLY_RES_ALL"] = size(collect(skipmissing(Agri_Res_biomass_supply[!,:R_ID])),1)

		# Name of supply resources
		inputs_bio_supply["AGRI_RES_SUPPLY_NAME"] = collect(skipmissing(Agri_Res_biomass_supply[!,:Biomass_Supply][1:inputs_bio_supply["AGRI_RES_SUPPLY_RES_ALL"]]))

		# Set of supply resources
		inputs_bio_supply["BESC_AGRI_RES_SUPPLY"] = Agri_Res_biomass_supply[!,:R_ID]

		println(" -- BESC_Supply_Agri_Residue.csv Successfully Read!")
	end

	####################################################

	if setup["Agri_Process_Waste_Supply"] == 1
		#Read in agricultural process waste biomass related inputs
		Agri_Process_Waste_biomass_supply = DataFrame(CSV.File(string(path,sep,"BESC_Supply_Agri_Process_Waste.csv"), header=true), copycols=true)

		# Add Resource IDs after reading to prevent user errors
		Agri_Process_Waste_biomass_supply[!,:R_ID] = 1:size(collect(skipmissing(Agri_Process_Waste_biomass_supply[!,1])),1)

		# Store DataFrame of resources input data for use in model
		inputs_bio_supply["dfAgri_Process_Waste"] = Agri_Process_Waste_biomass_supply

		# Index of supply resources
		inputs_bio_supply["AGRI_PROCESS_WASTE_SUPPLY_RES_ALL"] = size(collect(skipmissing(Agri_Process_Waste_biomass_supply[!,:R_ID])),1)

		# Name of supply resources
		inputs_bio_supply["AGRI_PROCESS_WASTE_SUPPLY_NAME"] = collect(skipmissing(Agri_Process_Waste_biomass_supply[!,:Biomass_Supply][1:inputs_bio_supply["AGRI_PROCESS_WASTE_SUPPLY_RES_ALL"]]))

		# Set of supply resources
		inputs_bio_supply["BESC_AGRI_PROCESS_WASTE_SUPPLY"] = Agri_Process_Waste_biomass_supply[!,:R_ID]

		println(" -- BESC_Supply_Agri_Process_Waste.csv Successfully Read!")
	end

	####################################################

	if setup["Agri_Forest_Supply"] == 1
		#Read in forest biomass related inputs
		Forest_biomass_supply = DataFrame(CSV.File(string(path,sep,"BESC_Supply_Forestry.csv"), header=true), copycols=true)

		# Add Resource IDs after reading to prevent user errors
		Forest_biomass_supply[!,:R_ID] = 1:size(collect(skipmissing(Forest_biomass_supply[!,1])),1)

		# Store DataFrame of resources input data for use in model
		inputs_bio_supply["dfForest"] = Forest_biomass_supply

		# Index of supply resources
		inputs_bio_supply["FOREST_SUPPLY_RES_ALL"] = size(collect(skipmissing(Forest_biomass_supply[!,:R_ID])),1)

		# Name of supply resources
		inputs_bio_supply["FOREST_SUPPLY_NAME"] = collect(skipmissing(Forest_biomass_supply[!,:Biomass_Supply][1:inputs_bio_supply["FOREST_SUPPLY_RES_ALL"]]))

		# Set of supply resources
		inputs_bio_supply["BESC_FOREST_SUPPLY"] = Forest_biomass_supply[!,:R_ID]

		println(" -- BESC_Supply_Forestry.csv Successfully Read!")
	end

    return inputs_bio_supply

end

