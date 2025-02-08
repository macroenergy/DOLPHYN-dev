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
	write_bio_zone_biohydrogen_produced(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the biohydrogen produced across different zones with time.
"""
function write_bio_zone_biohydrogen_produced(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfBioH2 = inputs["dfBioH2"]
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	## Carbon balance for each zone
	dfZoneBiohydrogenBalance = Array{Any}
	rowoffset=3
	for z in 1:Z
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 1)
	   	dfTemp1[1,1:size(dfTemp1,2)] = ["Biohydrogen Produced"]
	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([z],size(dfTemp1,2))

	   	for t in 1:T
			dfTemp1[t+rowoffset,1]= sum(value.(EP[:eBioH2_produced_mwh_per_plant_per_time][dfBioH2[(dfBioH2[!,:Zone].==z),:][!,:R_ID],t]))
	   	end

		if z==1
			dfZoneBiohydrogenBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfZoneBiohydrogenBalance = hcat(dfZoneBiohydrogenBalance, dfTemp1)
		end
	end
	for c in 2:size(dfZoneBiohydrogenBalance,2)
		dfZoneBiohydrogenBalance[rowoffset,c]=sum(inputs["omega"].*dfZoneBiohydrogenBalance[(rowoffset+1):size(dfZoneBiohydrogenBalance,1),c])
	end
	dfZoneBiohydrogenBalance = DataFrame(dfZoneBiohydrogenBalance, :auto)
	CSV.write(string(path,sep,"BESC_zone_biohydrogen_produced.csv"), dfZoneBiohydrogenBalance, writeheader=false)
end
