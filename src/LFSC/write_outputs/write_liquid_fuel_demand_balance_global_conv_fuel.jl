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
	write_liquid_fuel_demand_balance_global_conv_fuel(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the liquid fuels balance of resources across different zones with time for each type of fuels.
"""
function write_liquid_fuel_demand_balance_global_conv_fuel(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
		
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	#######################################
	## Diesel balance for each zone
	dfSFDieselBalance = Array{Any}
	rowoffset=3

	for z in 1:Z
	   	dfTemp1_Diesel = Array{Any}(nothing, T+rowoffset, 2)
	   	dfTemp1_Diesel[1,1:size(dfTemp1_Diesel,2)] = ["Syn_Diesel", "Bio_Diesel"]
	   	dfTemp1_Diesel[2,1:size(dfTemp1_Diesel,2)] = repeat([z],size(dfTemp1_Diesel,2))
	   	for t in 1:T
			if setup["ModelSyntheticFuels"] == 1
	     		dfTemp1_Diesel[t+rowoffset,1] = value.(EP[:eSynFuelProd_Diesel][t,z])
			else
				dfTemp1_Diesel[t+rowoffset,1] = 0
			end

			if setup["ModelBESC"] == 1 && setup["Bio_LF_On"] == 1
				dfTemp1_Diesel[t+rowoffset,2]= value.(EP[:eBiodiesel_produced_MMBtu_per_time_per_zone][t,z])
			else
				dfTemp1_Diesel[t+rowoffset,2]= 0
			end
	   	end

		#Calculate annual values
		if setup["ModelSyntheticFuels"] == 1
			dfTemp1_Diesel[rowoffset,1] = sum(inputs["omega"][t] * value.(EP[:eSynFuelProd_Diesel][t,z]) for t in 1:T)
		else
			dfTemp1_Diesel[rowoffset,1] = 0 
		end

		if setup["ModelBESC"] == 1 && setup["Bio_LF_On"] == 1
			dfTemp1_Diesel[rowoffset,2] = sum(inputs["omega"][t] * value.(EP[:eBiodiesel_produced_MMBtu_per_time_per_zone][t,z]) for t in 1:T)
		else
			dfTemp1_Diesel[rowoffset,2] = 0
		end

		if z==1
			dfSFDieselBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1_Diesel)
		else
		    dfSFDieselBalance = hcat(dfSFDieselBalance, dfTemp1_Diesel)
		end

	end

	############
	#Global Syn and Bio Diesel
	dfTemp1_Global_SB_Diesel = Array{Any}(nothing, T+rowoffset, 2)
	dfTemp1_Global_SB_Diesel[1,1:size(dfTemp1_Global_SB_Diesel,2)] = ["Syn_Diesel", "Bio_Diesel"]
	dfTemp1_Global_SB_Diesel[2,1:size(dfTemp1_Global_SB_Diesel,2)] = repeat(["Global"],size(dfTemp1_Global_SB_Diesel,2))
	
	for t in 1:T
	
		if setup["ModelSyntheticFuels"] == 1
			dfTemp1_Global_SB_Diesel[t+rowoffset,1] = sum(value.(EP[:eSynFuelProd_Diesel][t,z]) for z = 1:Z)
		else
			dfTemp1_Global_SB_Diesel[t+rowoffset,1] = 0
		end


		if setup["ModelBESC"] == 1 && setup["Bio_LF_On"] == 1
			dfTemp1_Global_SB_Diesel[t+rowoffset,2] = sum(value.(EP[:eBiodiesel_produced_MMBtu_per_time_per_zone][t,z]) for z = 1:Z)
		else
			dfTemp1_Global_SB_Diesel[t+rowoffset,2] = 0
		end
	end

	#Calculate annual values
	if setup["ModelSyntheticFuels"] == 1
		dfTemp1_Global_SB_Diesel[rowoffset,1] = sum(sum(inputs["omega"][t] * value.(EP[:eSynFuelProd_Diesel][t,z] for z in 1:Z)) for t in 1:T)
	else
		dfTemp1_Global_SB_Diesel[rowoffset,1] = 0 
	end

	if setup["ModelBESC"] == 1 && setup["Bio_LF_On"] == 1
		dfTemp1_Global_SB_Diesel[rowoffset,2] = sum(sum(inputs["omega"][t] * value.(EP[:eBiodiesel_produced_MMBtu_per_time_per_zone][t,z]) for z in 1:Z) for t in 1:T)
	else
		dfTemp1_Global_SB_Diesel[rowoffset,2] = 0
	end
	
	dfSFDieselBalance =  hcat(dfSFDieselBalance,dfTemp1_Global_SB_Diesel)

	############
	#Global Conventional Diesel
	dfTemp1_Global_C_Diesel = Array{Any}(nothing, T+rowoffset, 1)
	dfTemp1_Global_C_Diesel[1,1:size(dfTemp1_Global_C_Diesel,2)] = ["Conventional_Diesel"]
	dfTemp1_Global_C_Diesel[2,1:size(dfTemp1_Global_C_Diesel,2)] = repeat(["Global"],size(dfTemp1_Global_C_Diesel,2))
	
	
	for t in 1:T
		if setup["Liquid_Fuels_Hourly_Demand"] == 1
			dfTemp1_Global_C_Diesel[t+rowoffset,1] = value.(EP[:vConvLFDieselDemand][t])

		elseif setup["Liquid_Fuels_Hourly_Demand"] == 0
			dfTemp1_Global_C_Diesel[t+rowoffset,1] = "-"
		end
	end

	#Calculate annual values
	if setup["Liquid_Fuels_Hourly_Demand"] == 1
		dfTemp1_Global_C_Diesel[rowoffset,1] = sum(inputs["omega"][t] * value.(EP[:vConvLFDieselDemand][t]) for t in 1:T)

	elseif setup["Liquid_Fuels_Hourly_Demand"] == 0
		dfTemp1_Global_C_Diesel[rowoffset,1] = value.(EP[:vConvLFDieselDemand])
	end

	dfSFDieselBalance =  hcat(dfSFDieselBalance,dfTemp1_Global_C_Diesel)

	############
	#Global Diesel Demand
	dfTemp1_Global_Demand = Array{Any}(nothing, T+rowoffset, 1)
	dfTemp1_Global_Demand[1,1:size(dfTemp1_Global_Demand,2)] = ["Diesel_Demand"]
	dfTemp1_Global_Demand[2,1:size(dfTemp1_Global_Demand,2)] = repeat(["Global"],size(dfTemp1_Global_Demand,2))
	
	for t in 1:T
		if setup["Liquid_Fuels_Hourly_Demand"] == 1
			dfTemp1_Global_Demand[t+rowoffset,1] = -sum(inputs["Liquid_Fuels_Diesel_D"][t,z] for z = 1:Z)
		else
			dfTemp1_Global_Demand[t+rowoffset,1] = "-"
		end
	end
	
	#Calculate annual values
	dfTemp1_Global_Demand[rowoffset,1] = -sum(sum(inputs["omega"][t] * inputs["Liquid_Fuels_Diesel_D"][t,z] for z in 1:Z) for t in 1:T)

	dfSFDieselBalance =  hcat(dfSFDieselBalance,dfTemp1_Global_Demand)

	dfSFDieselBalance = DataFrame(dfSFDieselBalance, :auto)
	CSV.write(string(path,sep,"LF_Diesel_balance.csv"), dfSFDieselBalance, writeheader=false)


	###################################################################################################
	## Jetfuel balance for each zone
	dfSFJetfuelBalance = Array{Any}
	rowoffset=3

	for z in 1:Z
	   	dfTemp1_Jetfuel = Array{Any}(nothing, T+rowoffset, 2)
	   	dfTemp1_Jetfuel[1,1:size(dfTemp1_Jetfuel,2)] = ["Syn_Jetfuel", "Bio_Jetfuel"]
	   	dfTemp1_Jetfuel[2,1:size(dfTemp1_Jetfuel,2)] = repeat([z],size(dfTemp1_Jetfuel,2))
	   	for t in 1:T
			if setup["ModelSyntheticFuels"] == 1
	     		dfTemp1_Jetfuel[t+rowoffset,1] = value.(EP[:eSynFuelProd_Jetfuel][t,z])
			else
				dfTemp1_Jetfuel[t+rowoffset,1] = 0
			end

			if setup["ModelBESC"] == 1 && setup["Bio_LF_On"] == 1
				dfTemp1_Jetfuel[t+rowoffset,2]= value.(EP[:eBiojetfuel_produced_MMBtu_per_time_per_zone][t,z])
			else
				dfTemp1_Jetfuel[t+rowoffset,2]= 0
			end

	   	end

		#Calculate annual values
		if setup["ModelSyntheticFuels"] == 1
			dfTemp1_Jetfuel[rowoffset,1] = sum(inputs["omega"][t] * value.(EP[:eSynFuelProd_Jetfuel][t,z]) for t in 1:T)
		else
			dfTemp1_Jetfuel[rowoffset,1] = 0 
		end

		if setup["ModelBESC"] == 1 && setup["Bio_LF_On"] == 1
			dfTemp1_Jetfuel[rowoffset,2] = sum(inputs["omega"][t] * value.(EP[:eBiojetfuel_produced_MMBtu_per_time_per_zone][t,z]) for t in 1:T)
		else
			dfTemp1_Jetfuel[rowoffset,2] = 0
		end

		if z==1
			dfSFJetfuelBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1_Jetfuel)
		else
		    dfSFJetfuelBalance = hcat(dfSFJetfuelBalance, dfTemp1_Jetfuel)
		end

	end

	############
	#Global Syn and Bio Jetfuel
	dfTemp1_Global_SB_Jetfuel = Array{Any}(nothing, T+rowoffset, 2)
	dfTemp1_Global_SB_Jetfuel[1,1:size(dfTemp1_Global_SB_Jetfuel,2)] = ["Syn_Jetfuel", "Bio_Jetfuel"]
	dfTemp1_Global_SB_Jetfuel[2,1:size(dfTemp1_Global_SB_Jetfuel,2)] = repeat(["Global"],size(dfTemp1_Global_SB_Jetfuel,2))
	
	for t in 1:T
	
		if setup["ModelSyntheticFuels"] == 1
			dfTemp1_Global_SB_Jetfuel[t+rowoffset,1] = sum(value.(EP[:eSynFuelProd_Jetfuel][t,z]) for z = 1:Z)
		else
			dfTemp1_Global_SB_Jetfuel[t+rowoffset,1] = 0
		end


		if setup["ModelBESC"] == 1 && setup["Bio_LF_On"] == 1
			dfTemp1_Global_SB_Jetfuel[t+rowoffset,2] = sum(value.(EP[:eBiojetfuel_produced_MMBtu_per_time_per_zone][t,z]) for z = 1:Z)
		else
			dfTemp1_Global_SB_Jetfuel[t+rowoffset,2] = 0
		end
	end

	#Calculate annual values
	if setup["ModelSyntheticFuels"] == 1
		dfTemp1_Global_SB_Jetfuel[rowoffset,1] = sum(sum(inputs["omega"][t] * value.(EP[:eSynFuelProd_Jetfuel][t,z] for z in 1:Z)) for t in 1:T)
	else
		dfTemp1_Global_SB_Jetfuel[rowoffset,1] = 0 
	end

	if setup["ModelBESC"] == 1 && setup["Bio_LF_On"] == 1
		dfTemp1_Global_SB_Jetfuel[rowoffset,2] = sum(sum(inputs["omega"][t] * value.(EP[:eBiojetfuel_produced_MMBtu_per_time_per_zone][t,z]) for z in 1:Z) for t in 1:T)
	else
		dfTemp1_Global_SB_Jetfuel[rowoffset,2] = 0
	end
	
	dfSFJetfuelBalance =  hcat(dfSFJetfuelBalance,dfTemp1_Global_SB_Jetfuel)

	############
	#Global Conventional Jetfuel
	dfTemp1_Global_C_Jetfuel = Array{Any}(nothing, T+rowoffset, 1)
	dfTemp1_Global_C_Jetfuel[1,1:size(dfTemp1_Global_C_Jetfuel,2)] = ["Conventional_Jetfuel"]
	dfTemp1_Global_C_Jetfuel[2,1:size(dfTemp1_Global_C_Jetfuel,2)] = repeat(["Global"],size(dfTemp1_Global_C_Jetfuel,2))
	
	
	for t in 1:T
		if setup["Liquid_Fuels_Hourly_Demand"] == 1
			dfTemp1_Global_C_Jetfuel[t+rowoffset,1] = value.(EP[:vConvLFJetfuelDemand][t])

		elseif setup["Liquid_Fuels_Hourly_Demand"] == 0
			dfTemp1_Global_C_Jetfuel[t+rowoffset,1] = "-"
		end
	end

	#Calculate annual values
	if setup["Liquid_Fuels_Hourly_Demand"] == 1
		dfTemp1_Global_C_Jetfuel[rowoffset,1] = sum(inputs["omega"][t] * value.(EP[:vConvLFJetfuelDemand][t]) for t in 1:T)

	elseif setup["Liquid_Fuels_Hourly_Demand"] == 0
		dfTemp1_Global_C_Jetfuel[rowoffset,1] = value.(EP[:vConvLFJetfuelDemand])
	end

	dfSFJetfuelBalance =  hcat(dfSFJetfuelBalance,dfTemp1_Global_C_Jetfuel)

	############
	#Global Jetfuel Demand
	dfTemp1_Global_Demand = Array{Any}(nothing, T+rowoffset, 1)
	dfTemp1_Global_Demand[1,1:size(dfTemp1_Global_Demand,2)] = ["Jetfuel_Demand"]
	dfTemp1_Global_Demand[2,1:size(dfTemp1_Global_Demand,2)] = repeat(["Global"],size(dfTemp1_Global_Demand,2))
	
	for t in 1:T
		if setup["Liquid_Fuels_Hourly_Demand"] == 1
			dfTemp1_Global_Demand[t+rowoffset,1] = -sum(inputs["Liquid_Fuels_Jetfuel_D"][t,z] for z = 1:Z)
		else
			dfTemp1_Global_Demand[t+rowoffset,1] = "-"
		end
	end
	
	#Calculate annual values
	dfTemp1_Global_Demand[rowoffset,1] = -sum(sum(inputs["omega"][t] * inputs["Liquid_Fuels_Jetfuel_D"][t,z] for z in 1:Z) for t in 1:T)

	dfSFJetfuelBalance =  hcat(dfSFJetfuelBalance,dfTemp1_Global_Demand)

	dfSFJetfuelBalance = DataFrame(dfSFJetfuelBalance, :auto)
	CSV.write(string(path,sep,"LF_Jetfuel_balance.csv"), dfSFJetfuelBalance, writeheader=false)

	###################################################################################################
	## Gasoline balance for each zone
	dfSFGasolineBalance = Array{Any}
	rowoffset=3

	for z in 1:Z
	   	dfTemp1_Gasoline = Array{Any}(nothing, T+rowoffset, 2)
	   	dfTemp1_Gasoline[1,1:size(dfTemp1_Gasoline,2)] = ["Syn_Gasoline", "Bio_Gasoline"]
	   	dfTemp1_Gasoline[2,1:size(dfTemp1_Gasoline,2)] = repeat([z],size(dfTemp1_Gasoline,2))
	   	for t in 1:T
			if setup["ModelSyntheticFuels"] == 1
	     		dfTemp1_Gasoline[t+rowoffset,1] = value.(EP[:eSynFuelProd_Gasoline][t,z])
			else
				dfTemp1_Gasoline[t+rowoffset,1] = 0
			end

			if setup["ModelBESC"] == 1 && setup["Bio_LF_On"] == 1
				dfTemp1_Gasoline[t+rowoffset,2]= value.(EP[:eBiogasoline_produced_MMBtu_per_time_per_zone][t,z])
			else
				dfTemp1_Gasoline[t+rowoffset,2]= 0
			end

	   	end

		#Calculate annual values
		if setup["ModelSyntheticFuels"] == 1
			dfTemp1_Gasoline[rowoffset,1] = sum(inputs["omega"][t] * value.(EP[:eSynFuelProd_Gasoline][t,z]) for t in 1:T)
		else
			dfTemp1_Gasoline[rowoffset,1] = 0 
		end

		if setup["ModelBESC"] == 1 && setup["Bio_LF_On"] == 1
			dfTemp1_Gasoline[rowoffset,2] = sum(inputs["omega"][t] * value.(EP[:eBiogasoline_produced_MMBtu_per_time_per_zone][t,z]) for t in 1:T)
		else
			dfTemp1_Gasoline[rowoffset,2] = 0
		end

		if z==1
			dfSFGasolineBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1_Gasoline)
		else
		    dfSFGasolineBalance = hcat(dfSFGasolineBalance, dfTemp1_Gasoline)
		end

	end

	############
	#Global Syn and Bio Gasoline
	dfTemp1_Global_SB_Gasoline = Array{Any}(nothing, T+rowoffset, 2)
	dfTemp1_Global_SB_Gasoline[1,1:size(dfTemp1_Global_SB_Gasoline,2)] = ["Syn_Gasoline", "Bio_Gasoline"]
	dfTemp1_Global_SB_Gasoline[2,1:size(dfTemp1_Global_SB_Gasoline,2)] = repeat(["Global"],size(dfTemp1_Global_SB_Gasoline,2))
	
	for t in 1:T
	
		if setup["ModelSyntheticFuels"] == 1
			dfTemp1_Global_SB_Gasoline[t+rowoffset,1] = sum(value.(EP[:eSynFuelProd_Gasoline][t,z]) for z = 1:Z)
		else
			dfTemp1_Global_SB_Gasoline[t+rowoffset,1] = 0
		end


		if setup["ModelBESC"] == 1 && setup["Bio_LF_On"] == 1
			dfTemp1_Global_SB_Gasoline[t+rowoffset,2] = sum(value.(EP[:eBiogasoline_produced_MMBtu_per_time_per_zone][t,z]) for z = 1:Z)
		else
			dfTemp1_Global_SB_Gasoline[t+rowoffset,2] = 0
		end
	end

	#Calculate annual values
	if setup["ModelSyntheticFuels"] == 1
		dfTemp1_Global_SB_Gasoline[rowoffset,1] = sum(sum(inputs["omega"][t] * value.(EP[:eSynFuelProd_Gasoline][t,z] for z in 1:Z)) for t in 1:T)
	else
		dfTemp1_Global_SB_Gasoline[rowoffset,1] = 0 
	end

	if setup["ModelBESC"] == 1 && setup["Bio_LF_On"] == 1
		dfTemp1_Global_SB_Gasoline[rowoffset,2] = sum(sum(inputs["omega"][t] * value.(EP[:eBiogasoline_produced_MMBtu_per_time_per_zone][t,z]) for z in 1:Z) for t in 1:T)
	else
		dfTemp1_Global_SB_Gasoline[rowoffset,2] = 0
	end
	
	dfSFGasolineBalance =  hcat(dfSFGasolineBalance,dfTemp1_Global_SB_Gasoline)

	############
	#Global Conventional Gasoline
	dfTemp1_Global_C_Gasoline = Array{Any}(nothing, T+rowoffset, 1)
	dfTemp1_Global_C_Gasoline[1,1:size(dfTemp1_Global_C_Gasoline,2)] = ["Conventional_Gasoline"]
	dfTemp1_Global_C_Gasoline[2,1:size(dfTemp1_Global_C_Gasoline,2)] = repeat(["Global"],size(dfTemp1_Global_C_Gasoline,2))
	
	
	for t in 1:T
		if setup["Liquid_Fuels_Hourly_Demand"] == 1
			dfTemp1_Global_C_Gasoline[t+rowoffset,1] = value.(EP[:vConvLFGasolineDemand][t])

		elseif setup["Liquid_Fuels_Hourly_Demand"] == 0
			dfTemp1_Global_C_Gasoline[t+rowoffset,1] = "-"
		end
	end

	#Calculate annual values
	if setup["Liquid_Fuels_Hourly_Demand"] == 1
		dfTemp1_Global_C_Gasoline[rowoffset,1] = sum(inputs["omega"][t] * value.(EP[:vConvLFGasolineDemand][t]) for t in 1:T)

	elseif setup["Liquid_Fuels_Hourly_Demand"] == 0
		dfTemp1_Global_C_Gasoline[rowoffset,1] = value.(EP[:vConvLFGasolineDemand])
	end

	dfSFGasolineBalance =  hcat(dfSFGasolineBalance,dfTemp1_Global_C_Gasoline)

	############
	#Global Gasoline Demand
	dfTemp1_Global_Demand = Array{Any}(nothing, T+rowoffset, 1)
	dfTemp1_Global_Demand[1,1:size(dfTemp1_Global_Demand,2)] = ["Gasoline_Demand"]
	dfTemp1_Global_Demand[2,1:size(dfTemp1_Global_Demand,2)] = repeat(["Global"],size(dfTemp1_Global_Demand,2))
	
	for t in 1:T
		if setup["Liquid_Fuels_Hourly_Demand"] == 1
			dfTemp1_Global_Demand[t+rowoffset,1] = -sum(inputs["Liquid_Fuels_Gasoline_D"][t,z] for z = 1:Z)
		else
			dfTemp1_Global_Demand[t+rowoffset,1] = "-"
		end
	end
	
	#Calculate annual values
	dfTemp1_Global_Demand[rowoffset,1] = -sum(sum(inputs["omega"][t] * inputs["Liquid_Fuels_Gasoline_D"][t,z] for z in 1:Z) for t in 1:T)

	dfSFGasolineBalance =  hcat(dfSFGasolineBalance,dfTemp1_Global_Demand)

	dfSFGasolineBalance = DataFrame(dfSFGasolineBalance, :auto)
	CSV.write(string(path,sep,"LF_Gasoline_balance.csv"), dfSFGasolineBalance, writeheader=false)

end
