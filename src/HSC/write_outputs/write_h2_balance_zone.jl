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
    write_h2_balance_zone(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
"""
function write_h2_balance_zone(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

	dfH2Gen = inputs["dfH2Gen"]
	H2_ELECTROLYZER = inputs["H2_ELECTROLYZER"]
	BLUE_H2 = inputs["BLUE_H2"]
	GREY_H2 = inputs["GREY_H2"]
	H2_STOR_ALL = inputs["H2_STOR_ALL"]
	

	if setup["ModelH2G2P"] == 1
		dfH2G2P = inputs["dfH2G2P"]
		H2_G2P_ALL = inputs["H2_G2P_ALL"]
	end

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	
	dfCost = DataFrame(Costs = ["Green_H2_Generation", "Blue_H2_Generation", "Grey_H2_Generation", "Bio_H2", "Storage_Discharging", "Storage_Charging", "Nonserved_Energy", "H2_Pipeline_Import_Export", "H2_Truck_Import_Export","Truck_Consumption","H2G2P","Demand","Synfuel_Consumption","Syn_NG_Consumption","Total"])

	#Try this form of summing otherwise just create z dimensions and sum later
	
	if !isempty(inputs["H2_ELECTROLYZER"])
		Green_H2_Generation = sum(sum(inputs["omega"].* value.(EP[:vH2Gen])[y,:] for y in H2_ELECTROLYZER))
	else
		Green_H2_Generation = 0
	end

	if !isempty(inputs["BLUE_H2"])
		Blue_H2_Generation = sum(sum(inputs["omega"].* value.(EP[:vH2Gen])[y,:] for y in BLUE_H2))
	else
		Blue_H2_Generation = 0
	end

	if !isempty(inputs["GREY_H2"])
		Grey_H2_Generation = sum(sum(inputs["omega"].* value.(EP[:vH2Gen])[y,:] for y in GREY_H2))
	else
		Grey_H2_Generation = 0
	end
	
	if setup["ModelBESC"] == 1 && setup["Bio_H2_On"] == 1
		Bio_H2 = sum(sum(inputs["omega"].* (value.(EP[:eBioH2_produced_mwh_per_time_per_zone])[:,z])) for z in 1:Z)
	else
		Bio_H2 = 0
	end

	if !isempty(inputs["H2_STOR_ALL"])
		Storage_Discharging = sum(sum(inputs["omega"].* value.(EP[:vH2Gen])[y,:] for y in H2_STOR_ALL))
		Storage_Charging = sum(sum(inputs["omega"].* value.(EP[:vH2_CHARGE_STOR])[y,:] for y in H2_STOR_ALL))
	else
		Storage_Discharging = 0
		Storage_Charging = 0
	end

	Nonserved_Energy = sum(sum(inputs["omega"].* value.(EP[:eH2BalanceNse])[:,z] for z in 1:Z))

	if setup["ModelH2Pipelines"] == 1
		H2_Pipeline_Import_Export = sum(sum(inputs["omega"].* value.(EP[:ePipeZoneDemand])[:,z] for z in 1:Z))
	else
		H2_Pipeline_Import_Export = 0
	end

	if setup["ModelH2Trucks"] == 1
		H2_Truck_Import_Export = sum(sum(inputs["omega"].* value.(EP[:eH2TruckFlow])[:,z] for z in 1:Z))
		Truck_Consumption = sum(sum(inputs["omega"].* value.(EP[:eH2TruckTravelConsumption])[:,z] for z in 1:Z))
	else
		H2_Truck_Import_Export = 0
		Truck_Consumption = 0
	end

	if setup["ModelH2G2P"] == 1
		H2G2P = - sum(sum(inputs["omega"].* value.(EP[:vH2G2P])[y,:] for y in 1:H2_G2P_ALL))
	else
		H2G2P = 0
	end

	Demand = - sum(sum(inputs["omega"].* (inputs["H2_D"][:,z]) for z in 1:Z))

	if setup["ModelLFSC"] == 1 && setup["ModelSyntheticFuels"] == 1
		Synfuel_Consumption = - sum(sum(inputs["omega"].* value.(EP[:eSyn_Fuel_H2_Cons])[:,z] for z in 1:Z))
	else
		Synfuel_Consumption = 0 
	end

	if setup["ModelNGSC"] == 1 && setup["ModelSyntheticNG"] == 1
		SynNG_Consumption = - sum(sum(inputs["omega"].* value.(EP[:eSyn_NG_H2_Cons])[:,z] for z in 1:Z))
	else
		SynNG_Consumption = 0 
	end

	# Define total costs
	cTotal = Green_H2_Generation + Blue_H2_Generation + Grey_H2_Generation + Bio_H2 + Nonserved_Energy + H2_Pipeline_Import_Export + H2_Truck_Import_Export + Truck_Consumption + H2G2P + Demand + Synfuel_Consumption + SynNG_Consumption

	# Define total column, i.e. column 2
	dfCost[!,Symbol("Total")] = [Green_H2_Generation, Blue_H2_Generation, Grey_H2_Generation, Bio_H2, Storage_Discharging, Storage_Charging, Nonserved_Energy, H2_Pipeline_Import_Export, H2_Truck_Import_Export, Truck_Consumption, H2G2P, Demand, Synfuel_Consumption, SynNG_Consumption, cTotal]

	################################################################################################################################
	# Computing zonal cost breakdown by cost category
	for z in 1:Z
		tempGreen_H2_Generation = 0
		tempBlue_H2_Generation = 0
		tempGrey_H2_Generation = 0
		tempBio_H2 = 0
		tempStorage_Discharging = 0
		tempStorage_Charging = 0
		tempNonserved_Energy = 0
		tempH2_Pipeline_Import_Export = 0
		tempH2_Truck_Import_Export = 0
		tempTruck_Consumption = 0
		tempH2G2P = 0
		tempDemand = 0
		tempSynfuel_Consumption = 0
		tempSynNG_Consumption = 0

		for y in intersect(H2_ELECTROLYZER, dfH2Gen[dfH2Gen[!,:Zone].==z,:R_ID])
			tempGreen_H2_Generation = tempGreen_H2_Generation + sum(inputs["omega"].* (value.(EP[:vH2Gen])[y,:]))
		end

		for y in intersect(BLUE_H2, dfH2Gen[dfH2Gen[!,:Zone].==z,:R_ID])
			tempBlue_H2_Generation = tempBlue_H2_Generation + sum(inputs["omega"].* (value.(EP[:vH2Gen])[y,:]))
		end

		for y in intersect(GREY_H2, dfH2Gen[dfH2Gen[!,:Zone].==z,:R_ID])
			tempGrey_H2_Generation = tempGrey_H2_Generation + sum(inputs["omega"].* (value.(EP[:vH2Gen])[y,:]))
		end


		if setup["ModelBESC"] == 1 && setup["Bio_H2_On"] == 1
			tempBio_H2 = tempBio_H2 + sum(inputs["omega"].* (value.(EP[:eBioH2_produced_mwh_per_time_per_zone])[:,z]))
		end

		for y in intersect(H2_STOR_ALL, dfH2Gen[dfH2Gen[!,:Zone].==z,:R_ID])
			tempStorage_Discharging = tempStorage_Discharging + sum(inputs["omega"].* (value.(EP[:vH2Gen])[y,:]))
			tempStorage_Charging = tempStorage_Charging + sum(inputs["omega"].* (value.(EP[:vH2_CHARGE_STOR])[y,:]))
		end

		tempNonserved_Energy = tempNonserved_Energy + sum(inputs["omega"].* (value.(EP[:eH2BalanceNse])[:,z]))

		if setup["ModelH2Pipelines"] == 1
			tempH2_Pipeline_Import_Export = tempH2_Pipeline_Import_Export + sum(inputs["omega"].* (value.(EP[:ePipeZoneDemand])[:,z]))
		end

		if setup["ModelH2Trucks"] == 1
			tempH2_Truck_Import_Export = sum(inputs["omega"].* (value.(EP[:eH2TruckFlow])[:,z]))
			tempTruck_Consumption = sum(inputs["omega"].* (value.(EP[:eH2TruckTravelConsumption])[:,z]))
		end

		if setup["ModelH2G2P"] == 1
			for y in intersect(1:H2_G2P_ALL, dfH2G2P[dfH2G2P[!,:Zone].==z,:R_ID])
				tempH2G2P = tempH2G2P - sum(inputs["omega"].* value.(EP[:vH2G2P])[y,:])
			end
		end

		tempDemand = tempDemand - sum(inputs["omega"].* (inputs["H2_D"][:,z]))

		if setup["ModelLFSC"] == 1 && setup["ModelSyntheticFuels"] == 1
			tempSynfuel_Consumption = tempSynfuel_Consumption - sum(inputs["omega"].* (value.(EP[:eSyn_Fuel_H2_Cons])[:,z]))
		end

		if setup["ModelNGSC"] == 1 && setup["ModelSyntheticNG"] == 1
			tempSynNG_Consumption = tempSynNG_Consumption - sum(inputs["omega"].* (value.(EP[:eSyn_NG_H2_Cons])[:,z]))
		end

		tempCTotal = tempGreen_H2_Generation + tempBlue_H2_Generation + tempGrey_H2_Generation + tempBio_H2 + tempNonserved_Energy + tempH2_Pipeline_Import_Export + tempH2_Truck_Import_Export + tempTruck_Consumption + tempH2G2P + tempDemand + tempSynfuel_Consumption + tempSynNG_Consumption


		dfCost[!,Symbol("Zone$z")] = [tempGreen_H2_Generation, tempBlue_H2_Generation, tempGrey_H2_Generation, tempBio_H2, tempStorage_Discharging, tempStorage_Charging, tempNonserved_Energy, tempH2_Pipeline_Import_Export, tempH2_Truck_Import_Export, tempTruck_Consumption, tempH2G2P, tempDemand, tempSynfuel_Consumption, tempSynNG_Consumption, tempCTotal]
	end

	CSV.write(string(path,sep,"HSC_balance_zone.csv"), dfCost)

end
