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
	write_liquid_fuel_emissions_regional_conv_fuel(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting CO2 emissions of different liquid fuel types across different zones.
"""
function write_liquid_fuel_emissions_regional_conv_fuel(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	

	## Emission balance for each zone
	dfLFEmissionBalance = Array{Any}

	if setup["ModelSyntheticFuels"] == 1
		NSFByProd = inputs["NSFByProd"]
	else
		NSFByProd = 0
	end

	rowoffset=3
	for z in 1:Z
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 12 + NSFByProd)
		byprodHead = "ByProd_Cons_Emissions_" .* string.(collect(1:NSFByProd))
	   	dfTemp1[1,1:size(dfTemp1,2)] = vcat(["CO2_In","SF_Prod_Emissions", "SF_Prod_Captured", "Syn_Diesel_Emissions", "Bio_Diesel_Emissions", "Conventional_Diesel_Emissions","Syn_Jetfuel_Emissions", "Bio_Jetfuel_Emissions", "Conventional_Jetfuel_Emissions", "Syn_Gasoline_Emissions", "Bio_Gasoline_Emissions", "Conventional_Gasoline_Emissions"], byprodHead)
	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([z],size(dfTemp1,2))

		for t in 1:T
			if setup["ModelSyntheticFuels"] == 1
				dfTemp1[t+rowoffset,1] = value.(EP[:eSyn_Fuel_CO2_Cons_Per_Time_Per_Zone][t,z])
				dfTemp1[t+rowoffset,2] = value.(EP[:eSynfuels_Production_CO2_Emissions_By_Zone][z,t])
				dfTemp1[t+rowoffset,3] = value.(EP[:eSyn_Fuels_CO2_Capture_Per_Zone_Per_Time][z,t])
				dfTemp1[t+rowoffset,4] = value.(EP[:eSyn_Diesel_CO2_Emissions_By_Zone][z,t])
			else
				dfTemp1[t+rowoffset,1] = 0
				dfTemp1[t+rowoffset,2] = 0
				dfTemp1[t+rowoffset,3] = 0
				dfTemp1[t+rowoffset,4] = 0
			end

			if setup["ModelBESC"] == 1 && setup["Bio_LF_On"] == 1
				dfTemp1[t+rowoffset,5] = value.(EP[:eBio_Diesel_CO2_Emissions_By_Zone][z,t])
			else
				dfTemp1[t+rowoffset,5] = 0
			end

			if setup["Liquid_Fuels_Hourly_Demand"] == 1
				dfTemp1[t+rowoffset,6] = value.(EP[:eConv_Diesel_CO2_Emissions][z,t])
			else
				dfTemp1[t+rowoffset,6] = 0
			end

			if setup["ModelSyntheticFuels"] == 1
				dfTemp1[t+rowoffset,7] = value.(EP[:eSyn_Jetfuel_CO2_Emissions_By_Zone][z,t])
			else
				dfTemp1[t+rowoffset,7] = 0
			end

			if setup["ModelBESC"] == 1 && setup["Bio_LF_On"] == 1
				dfTemp1[t+rowoffset,8] = value.(EP[:eBio_Jetfuel_CO2_Emissions_By_Zone][z,t])
			else
				dfTemp1[t+rowoffset,8] = 0
			end

			if setup["Liquid_Fuels_Hourly_Demand"] == 1
				dfTemp1[t+rowoffset,9] = value.(EP[:eConv_Jetfuel_CO2_Emissions][z,t])
			else
				dfTemp1[t+rowoffset,9] = 0
			end

			if setup["ModelSyntheticFuels"] == 1
				dfTemp1[t+rowoffset,10] = value.(EP[:eSyn_Gasoline_CO2_Emissions_By_Zone][z,t])
			else
				dfTemp1[t+rowoffset,10] = 0
			end

			if setup["ModelBESC"] == 1 && setup["Bio_LF_On"] == 1
				dfTemp1[t+rowoffset,11] = value.(EP[:eBio_Gasoline_CO2_Emissions_By_Zone][z,t])
			else
				dfTemp1[t+rowoffset,11] = 0
			end

			if setup["Liquid_Fuels_Hourly_Demand"] == 1
				dfTemp1[t+rowoffset,12] = value.(EP[:eConv_Gasoline_CO2_Emissions][z,t])
			else
				dfTemp1[t+rowoffset,12] = 0
			end

			if setup["ModelSyntheticFuels"] == 1
				for b in 1:NSFByProd
					dfTemp1[t+rowoffset, 12 + b] = sum(value.(EP[:eByProdConsCO2EmissionsByZoneB][b,z,t]))
				end
			end
		end

		#Calculate annual values
		if setup["ModelSyntheticFuels"] == 1
			dfTemp1[rowoffset,1]= sum(inputs["omega"][t] * value.(EP[:eSyn_Fuel_CO2_Cons_Per_Time_Per_Zone][t,z]) for t in 1:T)
			dfTemp1[rowoffset,2]= sum(inputs["omega"][t] * value.(EP[:eSynfuels_Production_CO2_Emissions_By_Zone][z,t]) for t in 1:T)
			dfTemp1[rowoffset,3]= sum(inputs["omega"][t] * value.(EP[:eSyn_Fuels_CO2_Capture_Per_Zone_Per_Time][z,t]) for t in 1:T)
			dfTemp1[rowoffset,4]= sum(inputs["omega"][t] * value.(EP[:eSyn_Diesel_CO2_Emissions_By_Zone][z,t]) for t in 1:T)
		else
			dfTemp1[rowoffset,1] = 0
			dfTemp1[rowoffset,2] = 0
			dfTemp1[rowoffset,3] = 0
			dfTemp1[rowoffset,4] = 0
		end

		if setup["ModelBESC"] == 1 && setup["Bio_LF_On"] == 1
			dfTemp1[rowoffset,5] = sum(inputs["omega"][t] * value.(EP[:eBio_Diesel_CO2_Emissions_By_Zone][z,t]) for t in 1:T)
		else
			dfTemp1[rowoffset,5] =0
		end
		
		if setup["Liquid_Fuels_Hourly_Demand"] == 1
			dfTemp1[rowoffset,6] = sum(inputs["omega"][t] * value.(EP[:eConv_Diesel_CO2_Emissions][z,t]) for t in 1:T)
		else
			dfTemp1[rowoffset,6] = value.(EP[:eConv_Diesel_CO2_Emissions][z])
		end
		
		if setup["ModelSyntheticFuels"] == 1
			dfTemp1[rowoffset,7] = sum(inputs["omega"][t] * value.(EP[:eSyn_Jetfuel_CO2_Emissions_By_Zone][z,t]) for t in 1:T)
		else
			dfTemp1[rowoffset,7] = 0
		end

		
		if setup["ModelBESC"] == 1 && setup["Bio_LF_On"] == 1
			dfTemp1[rowoffset,8] = sum(inputs["omega"][t] * value.(EP[:eBio_Jetfuel_CO2_Emissions_By_Zone][z,t]) for t in 1:T)
		else
			dfTemp1[rowoffset,8] = 0
		end

		if setup["Liquid_Fuels_Hourly_Demand"] == 1
			dfTemp1[rowoffset,9] = sum(inputs["omega"][t] * value.(EP[:eConv_Jetfuel_CO2_Emissions][z,t]) for t in 1:T)
		else
			dfTemp1[rowoffset,9] = value.(EP[:eConv_Jetfuel_CO2_Emissions][z])
		end
		
		if setup["ModelSyntheticFuels"] == 1
			dfTemp1[rowoffset,10] = sum(inputs["omega"][t] * value.(EP[:eSyn_Gasoline_CO2_Emissions_By_Zone][z,t]) for t in 1:T)
		else
			dfTemp1[rowoffset,10] = 0
		end

		if setup["ModelBESC"] == 1 && setup["Bio_LF_On"] == 1
			dfTemp1[rowoffset,11] = sum(inputs["omega"][t] * value.(EP[:eBio_Gasoline_CO2_Emissions_By_Zone][z,t]) for t in 1:T)
		else
			dfTemp1[rowoffset,11] = 0
		end

		if setup["Liquid_Fuels_Hourly_Demand"] == 1
			dfTemp1[rowoffset,12] = sum(inputs["omega"][t] * value.(EP[:eConv_Gasoline_CO2_Emissions][z,t]) for t in 1:T)
		else
			dfTemp1[rowoffset,12] = value.(EP[:eConv_Gasoline_CO2_Emissions][z])
		end

		if setup["ModelSyntheticFuels"] == 1
			for b in 1:NSFByProd
				dfTemp1[rowoffset, 12 + b] = sum(inputs["omega"][t] * sum(value.(EP[:eByProdConsCO2EmissionsByZoneB][b,z,t])) for t in 1:T)
			end
		end


		if z==1
			dfLFEmissionBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfLFEmissionBalance = hcat(dfLFEmissionBalance, dfTemp1)
		end
	end

	dfLFEmissionBalance = DataFrame(dfLFEmissionBalance, :auto)
	CSV.write(string(path,sep,"LF_Emissions_Balance.csv"), dfLFEmissionBalance, writeheader=false)
end
