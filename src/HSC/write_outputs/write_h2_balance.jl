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
	write_h2_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting hydrogen balance.
"""
function write_h2_balance(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	dfH2Gen = inputs["dfH2Gen"]

	if setup["ModelH2G2P"] == 1
		dfH2G2P = inputs["dfH2G2P"]
	end

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	H2_SEG = inputs["H2_SEG"] # Number of load curtailment segments
	H2_FLEX = inputs["H2_FLEX"] # Set of demand flexibility resources
	H2_STOR_ALL = inputs["H2_STOR_ALL"] # Set of H2 storage resources
	## Hydrogen balance for each zone
	dfH2Balance = Array{Any}
	rowoffset=3
	for z in 1:Z
	   	dfTemp1 = Array{Any}(nothing, T+rowoffset, 17)
	   	dfTemp1[1,1:size(dfTemp1,2)] = ["Generation", #1
	           "Flexible_Demand_Defer", #2
			   "Flexible_Demand_Satisfy", # 3
			   "Storage Discharging",#4
			    "Storage Charging", #5
               "Nonserved_Energy",#6
			   "H2_Pipeline_Import/Export", # 7
			   "H2_Truck_Import/Export",# 8
			   "Truck Consumption", #9
			   "H2G2P", # 10
	           "Demand",#11 
			   "Liquid_Generation",# 12 
			   "Liquid_Demand", #13
			   "Evaporation",# 14 
			   "Biohydrogen",#15 
			   "Synfuel Consumption", #16
			   "SynNG Consumption"] # 17] 

	   	dfTemp1[2,1:size(dfTemp1,2)] = repeat([z],size(dfTemp1,2))
	   	for t in 1:T
			if !isempty(inputs["H2_GEN_COMMIT"])
				dfTemp1[t+rowoffset,1]= value.(EP[:eH2GenCommit][t,z]) + value.(EP[:eH2GenNoCommit][t,z])
			else
				dfTemp1[t+rowoffset,1]= value.(EP[:eH2GenNoCommit][t,z])
			end
			
	     	dfTemp1[t+rowoffset,2] = 0
            dfTemp1[t+rowoffset,3] = 0
			dfTemp1[t+rowoffset,4] = 0
            dfTemp1[t+rowoffset,5] = 0

	     	if !isempty(intersect(dfH2Gen[dfH2Gen.Zone.==z,:R_ID],H2_FLEX))
	     	    dfTemp1[t+rowoffset,2] = sum(value.(EP[:vH2_CHARGE_FLEX][y,t]) for y in intersect(dfH2Gen[dfH2Gen.Zone.==z,:R_ID],H2_FLEX))
                dfTemp1[t+rowoffset,3] = -sum(value.(EP[:vH2Gen][dfH2Gen[(dfH2Gen[!,:H2_FLEX].>=1) .&  (dfH2Gen[!,:Zone].==z),:][!,:R_ID],t]))
	     	end

			if !isempty(intersect(dfH2Gen[dfH2Gen.Zone.==z,:R_ID],H2_STOR_ALL))
				dfTemp1[t+rowoffset,4] = sum(value.(EP[:vH2Gen][y,t]) for y in intersect(dfH2Gen[dfH2Gen.Zone.==z,:R_ID],H2_STOR_ALL))
			   	dfTemp1[t+rowoffset,5] = -sum(value.(EP[:vH2_CHARGE_STOR][y,t]) for y in intersect(dfH2Gen[dfH2Gen.Zone.==z,:R_ID],H2_STOR_ALL))
			end

	     	dfTemp1[t+rowoffset,6] = value(EP[:eH2BalanceNse][t,z])

			dfTemp1[t+rowoffset,7] = 0

			if setup["ModelH2Pipelines"] == 1
			 	dfTemp1[t+rowoffset,7] = value.(EP[:ePipeZoneDemand][t,z])
			end

			dfTemp1[t+rowoffset,8] = 0
			dfTemp1[t+rowoffset,9] = 0

			if setup["ModelH2Trucks"] == 1
				dfTemp1[t+rowoffset,8] = value.(EP[:eH2TruckFlow][t,z])
				dfTemp1[t+rowoffset,9] = -value.(EP[:eH2TruckTravelConsumption][t,z])
			end

			dfTemp1[t+rowoffset,10] = 0

			if setup["ModelH2G2P"] == 1
				dfTemp1[t+rowoffset,10] = - sum(value.(EP[:vH2G2P][dfH2G2P[(dfH2G2P[!,:Zone].==z),:][!,:R_ID],t]))	
			end

			dfTemp1[t+rowoffset,11] = -inputs["H2_D"][t,z]

			dfTemp1[t+rowoffset,12] = 0
			dfTemp1[t+rowoffset,13] = 0
			dfTemp1[t+rowoffset,14] = 0

            if setup["ModelH2Liquid"] == 1
                dfTemp1[t+rowoffset,12] = sum(value.(EP[:vH2Gen][dfH2Gen[(dfH2Gen[!,:H2_LIQ].>0) .&  (dfH2Gen[!,:H2_LIQ].<3) .& (dfH2Gen[!,:Zone].==z),:][!,:R_ID],t]))
				dfTemp1[t+rowoffset,13] = -inputs["H2_D_L"][t,z]
				dfTemp1[t+rowoffset,14] = sum(value.(EP[:vH2Gen][dfH2Gen[(dfH2Gen[!,:H2_LIQ].>2) .&  (dfH2Gen[!,:Zone].==z),:][!,:R_ID],t]))
			end

			dfTemp1[t+rowoffset,15] = 0

			if setup["ModelBESC"] == 1 && setup["Bio_H2_On"] == 1
				dfTemp1[t+rowoffset,15] = value.(EP[:eBioH2_produced_tonne_per_time_per_zone][t,z])
			end 

			dfTemp1[t+rowoffset,16] = 0

			if setup["ModelLFSC"] == 1 && setup["ModelSyntheticFuels"] == 1
				dfTemp1[t+rowoffset,16] = - value.(EP[:eSyn_Fuel_H2_Cons][t,z])
			end

			dfTemp1[t+rowoffset,17] = 0

			if setup["ModelNGSC"] == 1 && setup["ModelSyntheticNG"] == 1
				dfTemp1[t+rowoffset,17] = - value.(EP[:eSyn_NG_H2_Cons][t,z])
			end

	   	end

		if z==1
			dfH2Balance =  hcat(vcat(["", "Zone", "AnnualSum"], ["t$t" for t in 1:T]), dfTemp1)
		else
		    dfH2Balance = hcat(dfH2Balance, dfTemp1)
		end
	end

	for c in 2:size(dfH2Balance,2)
		dfH2Balance[rowoffset,c]=sum(inputs["omega"].*dfH2Balance[(rowoffset+1):size(dfH2Balance,1),c])
	end

	dfH2Balance = DataFrame(dfH2Balance, :auto)
	CSV.write(string(path,sep,"HSC_h2_balance.csv"), dfH2Balance, writeheader=false)
end
