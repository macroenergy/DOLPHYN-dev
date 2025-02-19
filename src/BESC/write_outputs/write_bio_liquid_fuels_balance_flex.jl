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
	write_bio_liquid_fuels_balance_flex(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting input and output balance of synthetic fuels resources across different zones with time.
"""
function write_bio_liquid_fuels_balance_flex(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfBioLF= inputs["dfBioLF"]
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	## BioFuel balance for each zone
	dfBioLFBalance = Array{Any}
	rowoffset=3
	for z in 1:Z
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 15)
	   	dfTemp1[1,1:size(dfTemp1,2)] = vcat(["Biomass_In","Power_In", "NG_In","Bio_Gasoline_Original","Bio_Jetfuel_Original","Bio_Diesel_Original","Bio_Gasoline_to_Jetfuel","Bio_Gasoline_to_Diesel","Bio_Jetfuel_to_Gasoline","Bio_Jetfuel_to_Diesel","Bio_Diesel_to_Gasoline","Bio_Diesel_to_Jetfuel","Bio_Gasoline_Final","Bio_Jetfuel_Final","Bio_Diesel_Final"])
	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([z],size(dfTemp1,2))

	   	for t in 1:T
			dfTemp1[t+rowoffset,1]= sum(value.(EP[:vBiomass_consumed_per_plant_per_time_LF][dfBioLF[(dfBioLF[!,:Zone].==z),:][!,:R_ID],t]))
			dfTemp1[t+rowoffset,2]= value.(EP[:eBio_LF_Plant_Power_consumption_per_time_per_zone][t,z])

			dfTemp1[t+rowoffset,3]= value.(EP[:eBio_LF_Plant_NG_consumption_per_time_per_zone][t,z])
			
			dfTemp1[t+rowoffset,4]= sum(value.(EP[:eBiogasoline_original_produced_MMBtu_per_plant_per_time][dfBioLF[(dfBioLF[!,:Zone].==z),:][!,:R_ID],t]))
			dfTemp1[t+rowoffset,5]= sum(value.(EP[:eBiojetfuel_original_produced_MMBtu_per_plant_per_time][dfBioLF[(dfBioLF[!,:Zone].==z),:][!,:R_ID],t]))
			dfTemp1[t+rowoffset,6]= sum(value.(EP[:eBiodiesel_original_produced_MMBtu_per_plant_per_time][dfBioLF[(dfBioLF[!,:Zone].==z),:][!,:R_ID],t]))

			dfTemp1[t+rowoffset,7]= sum(value.(EP[:vBioGasoline_To_Jetfuel][dfBioLF[(dfBioLF[!,:Zone].==z),:][!,:R_ID],t]))
			dfTemp1[t+rowoffset,8]= sum(value.(EP[:vBioGasoline_To_Diesel][dfBioLF[(dfBioLF[!,:Zone].==z),:][!,:R_ID],t]))

			dfTemp1[t+rowoffset,9]= sum(value.(EP[:vBioJetfuel_To_Gasoline][dfBioLF[(dfBioLF[!,:Zone].==z),:][!,:R_ID],t]))
			dfTemp1[t+rowoffset,10]= sum(value.(EP[:vBioJetfuel_To_Diesel][dfBioLF[(dfBioLF[!,:Zone].==z),:][!,:R_ID],t]))

			dfTemp1[t+rowoffset,11]= sum(value.(EP[:vBioDiesel_To_Gasoline][dfBioLF[(dfBioLF[!,:Zone].==z),:][!,:R_ID],t]))
			dfTemp1[t+rowoffset,12]= sum(value.(EP[:vBioDiesel_To_Jetfuel][dfBioLF[(dfBioLF[!,:Zone].==z),:][!,:R_ID],t]))

			dfTemp1[t+rowoffset,13]= sum(value.(EP[:eBiogasoline_produced_MMBtu_per_plant_per_time][dfBioLF[(dfBioLF[!,:Zone].==z),:][!,:R_ID],t]))
			dfTemp1[t+rowoffset,14]= sum(value.(EP[:eBiojetfuel_produced_MMBtu_per_plant_per_time][dfBioLF[(dfBioLF[!,:Zone].==z),:][!,:R_ID],t]))
			dfTemp1[t+rowoffset,15]= sum(value.(EP[:eBiodiesel_produced_MMBtu_per_plant_per_time][dfBioLF[(dfBioLF[!,:Zone].==z),:][!,:R_ID],t]))

	   	end

		if z==1
			dfBioLFBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfBioLFBalance = hcat(dfBioLFBalance, dfTemp1)
		end
	end

	for c in 2:size(dfBioLFBalance,2)
		dfBioLFBalance[rowoffset,c]=sum(inputs["omega"].*dfBioLFBalance[(rowoffset+1):size(dfBioLFBalance,1),c])
	end
	dfBioLFBalance = DataFrame(dfBioLFBalance, :auto)
	CSV.write(string(path,sep,"BESC_Bio_liquid_fuels_balance.csv"), dfBioLFBalance, writeheader=false)
end
