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
	write_synfuel_emissions(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting CO2 emissions of different liquid fuel types across different zones.
"""
function write_synfuel_emissions(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfSynFuels= inputs["dfSynFuels"]
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	NSFByProd = inputs["NSFByProd"]

	## SynFuel balance for each zone
	dfSFBalance = Array{Any}
	rowoffset=3
	for z in 1:Z
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 12 + NSFByProd)
		byprodHead = "ByProd_Cons_Emissions_" .* string.(collect(1:NSFByProd))
	   	dfTemp1[1,1:size(dfTemp1,2)] = vcat(["CO2_In","SF_Prod_Emissions", "SF_Prod_Captured", "SF_Diesel_Cons_Emissions", "Bio_Diesel_Cons_Emissions", "Conv_Diesel_Cons_Emissions","SF_Jetfuel_Cons_Emissions", "Bio_Jetfuel_Cons_Emissions", "Conv_Jetfuel_Cons_Emissions", "SF_Gasoline_Cons_Emissions", "Bio_Gasoline_Cons_Emissions", "Conv_Gasoline_Cons_Emissions"], byprodHead)
	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([z],size(dfTemp1,2))

	   	for t in 1:T
			dfTemp1[t+rowoffset,1]=value.(EP[:eSynFuelCO2Cons_Per_Time_Per_Zone][t,z])
			dfTemp1[t+rowoffset,2]=value.(EP[:eSyn_Fuels_CO2_Emissions_By_Zone][z,t])
			dfTemp1[t+rowoffset,3]=value.(EP[:eSyn_Fuels_CO2_Capture_Per_Zone_Per_Time][z,t])
			dfTemp1[t+rowoffset,4]=value.(EP[:eSyn_Fuels_Diesel_Cons_CO2_Emissions_By_Zone][z,t])
			dfTemp1[t+rowoffset,5] = 0
			
			if setup["BIO_Diesel_On"] == 1
				dfTemp1[t+rowoffset,5]=value.(EP[:eBio_Fuels_Con_Diesel_CO2_Emissions_By_Zone][z,t])
			end

			dfTemp1[t+rowoffset,6]=value.(EP[:eLiquid_Fuels_Con_Diesel_CO2_Emissions_By_Zone][z,t])
			dfTemp1[t+rowoffset,7]=value.(EP[:eSyn_Fuels_Jetfuel_Cons_CO2_Emissions_By_Zone][z,t])

			dfTemp1[t+rowoffset,8] = 0
			if setup["BIO_Jetfuel_On"] == 1
				dfTemp1[t+rowoffset,8]=value.(EP[:eBio_Fuels_Con_Jetfuel_CO2_Emissions_By_Zone][z,t])*ModelScalingFactor
			end

			dfTemp1[t+rowoffset,9]=value.(EP[:eLiquid_Fuels_Con_Jetfuel_CO2_Emissions_By_Zone][z,t])
			dfTemp1[t+rowoffset,10]=value.(EP[:eSyn_Fuels_Gasoline_Cons_CO2_Emissions_By_Zone][z,t])
			dfTemp1[t+rowoffset,11] = 0
			
			if setup["BIO_Gasoline_On"] == 1
				dfTemp1[t+rowoffset,11]=value.(EP[:eBio_Fuels_Con_Gasoline_CO2_Emissions_By_Zone][z,t])
			end

			dfTemp1[t+rowoffset,12]=value.(EP[:eLiquid_Fuels_Con_Gasoline_CO2_Emissions_By_Zone][z,t])

			for b in 1:NSFByProd
				dfTemp1[t+rowoffset, 12 + b] = sum(value.(EP[:eByProdConsCO2EmissionsByZoneB][b,z,t]))
			end

	   	end

		if z==1
			dfSFBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfSFBalance = hcat(dfSFBalance, dfTemp1)
		end
	end
	for c in 2:size(dfSFBalance,2)
		dfSFBalance[rowoffset,c]=sum(inputs["omega"].*dfSFBalance[(rowoffset+1):size(dfSFBalance,1),c])
	end
	dfSFBalance = DataFrame(dfSFBalance, :auto)
	CSV.write(string(path,sep,"Syn_Fuel_Emissions_Balance.csv"), dfSFBalance, writeheader=false)
end
