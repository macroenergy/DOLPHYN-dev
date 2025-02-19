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
	write_bio_zone_bioelectricity_produced(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the bioelectricity produced across different zones with time.
"""
function write_bio_zone_bioelectricity_produced(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	## Bio electricity balance for each zone
	dfZoneBioelectricityBalance = Array{Any}
	rowoffset=3
	for z in 1:Z
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 4)
	   	dfTemp1[1,1:size(dfTemp1,2)] = ["Bioelectricity Produced", "Bio H2 Power Credit", "Bio LF Power Credit", "Bio NG Power Credit"]
	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([z],size(dfTemp1,2))

	   	for t in 1:T
			
			dfTemp1[t+rowoffset,1] = 0
			dfTemp1[t+rowoffset,2] = 0
			dfTemp1[t+rowoffset,3] = 0
			dfTemp1[t+rowoffset,4] = 0

			if setup["Bio_ELEC_On"] == 1
				dfBioELEC = inputs["dfBioELEC"]
				dfTemp1[t+rowoffset,1] = sum(value.(EP[:eBioELEC_produced_MWh_per_plant_per_time][dfBioELEC[(dfBioELEC[!,:Zone].==z),:][!,:R_ID],t]))
			end

			if setup["Bio_H2_On"] == 1
				dfBioH2 = inputs["dfBioH2"]
				dfTemp1[t+rowoffset,2] = sum(value.(EP[:eBioH2_Power_credit_produced_MWh_per_plant_per_time][dfBioH2[(dfBioH2[!,:Zone].==z),:][!,:R_ID],t]))
			end

			if setup["Bio_LF_On"] == 1
				dfBioLF = inputs["dfBioLF"]
				dfTemp1[t+rowoffset,3] = sum(value.(EP[:eBioLF_Power_credit_produced_MWh_per_plant_per_time][dfBioLF[(dfBioLF[!,:Zone].==z),:][!,:R_ID],t]))
			end

			if setup["Bio_NG_On"] == 1
				dfBioNG = inputs["dfBioNG"]
				dfTemp1[t+rowoffset,4] = sum(value.(EP[:eBioNG_Power_credit_produced_MWh_per_plant_per_time][dfBioNG[(dfBioNG[!,:Zone].==z),:][!,:R_ID],t]))
			end

	   	end

		if z==1
			dfZoneBioelectricityBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfZoneBioelectricityBalance = hcat(dfZoneBioelectricityBalance, dfTemp1)
		end
	end
	for c in 2:size(dfZoneBioelectricityBalance,2)
		dfZoneBioelectricityBalance[rowoffset,c]=sum(inputs["omega"].*dfZoneBioelectricityBalance[(rowoffset+1):size(dfZoneBioelectricityBalance,1),c])
	end
	dfZoneBioelectricityBalance = DataFrame(dfZoneBioelectricityBalance, :auto)
	CSV.write(string(path,sep,"BESC_zone_bioelectricity_produced.csv"), dfZoneBioelectricityBalance, writeheader=false)
end
