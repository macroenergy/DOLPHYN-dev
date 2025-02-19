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
	write_syn_ng_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting input and output balance of synthetic gas resources across different zones with time.
"""
function write_syn_ng_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfSyn_NG= inputs["dfSyn_NG"]
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	## SynNG balance for each zone
	dfSNGBalance = Array{Any}
	rowoffset=3
	for z in 1:Z
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 4)
	   	dfTemp1[1,1:size(dfTemp1,2)] = vcat(["CO2 In","Power In", "H2 In", "Syn NG"])
	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([z],size(dfTemp1,2))

	   	for t in 1:T
			dfTemp1[t+rowoffset,1]=value.(EP[:eSyn_NG_CO2_Cons_Per_Time_Per_Zone][t,z])
			dfTemp1[t+rowoffset,2]=value.(EP[:eSyn_NG_Power_Cons][t,z])
			dfTemp1[t+rowoffset,3]=value.(EP[:eSyn_NG_H2_Cons][t,z])
			dfTemp1[t+rowoffset,4]= sum(value.(EP[:vSyn_NG_Prod][dfSyn_NG[(dfSyn_NG[!,:Zone].==z),:][!,:R_ID],t]))
	   	end

		if z==1
			dfSNGBalance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfSNGBalance = hcat(dfSNGBalance, dfTemp1)
		end
	end

	for c in 2:size(dfSNGBalance,2)
		dfSNGBalance[rowoffset,c]=sum(inputs["omega"].*dfSNGBalance[(rowoffset+1):size(dfSNGBalance,1),c])
	end
	dfSNGBalance = DataFrame(dfSNGBalance, :auto)
	CSV.write(string(path,sep,"Syn_ng_balance.csv"), dfSNGBalance, writeheader=false)
end
