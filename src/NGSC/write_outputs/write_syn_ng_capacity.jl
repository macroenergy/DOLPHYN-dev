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
	write_syn_ng_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for writing the diferent capacities for synthetic gas resources.
"""
function write_syn_ng_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	# Capacity decisions
	dfSyn_NG = inputs["dfSyn_NG"]
	
	cap_syn_ng_prod_co2_input = zeros(size(inputs["SYN_NG_RESOURCES_NAME"]))
	for i in 1:inputs["SYN_NG_RES_ALL"]
		cap_syn_ng_prod_co2_input[i] = value(EP[:vCapacity_Syn_NG_per_type][i])
	end

	cap_syn_ng_prod = zeros(size(inputs["SYN_NG_RESOURCES_NAME"]))
	AnnualSynNG = zeros(size(1:inputs["SYN_NG_RES_ALL"]))
	MaxCO2Consumption = zeros(size(1:inputs["SYN_NG_RES_ALL"]))
	AnnualCO2Consumption = zeros(size(1:inputs["SYN_NG_RES_ALL"]))
	CapFactor = zeros(size(1:inputs["SYN_NG_RES_ALL"]))
	

	for i in 1:inputs["SYN_NG_RES_ALL"]
		cap_syn_ng_prod[i] = value(EP[:vCapacity_Syn_NG_per_type][i]) * dfSyn_NG[!,:mmbtu_syn_ng_p_tonne_co2][i]
		AnnualSynNG[i] = sum(inputs["omega"].* (value.(EP[:vSyn_NG_Prod])[i,:]))
		MaxCO2Consumption[i] = value.(EP[:vCapacity_Syn_NG_per_type])[i] * 8760
		AnnualCO2Consumption[i] = sum(inputs["omega"].* (value.(EP[:vSyn_NG_CO2in])[i,:]))
		
		if MaxCO2Consumption[i] == 0
			CapFactor[i] = 0
		else
			CapFactor[i] = AnnualCO2Consumption[i]/MaxCO2Consumption[i]
		end

	end

	dfCap = DataFrame(
		Resource = inputs["SYN_NG_RESOURCES_NAME"], 
		Zone = dfSyn_NG[!,:Zone],
		Capacity_tonne_CO2_per_h = cap_syn_ng_prod_co2_input[:],
		Capacity_SNG_MMBtu_per_h = cap_syn_ng_prod[:],
		Annual_SNG_Production = AnnualSynNG[:],
		Max_Annual_CO2_Consumption = MaxCO2Consumption[:],
		Annual_CO2_Consumption = AnnualCO2Consumption[:],
		CapacityFactor = CapFactor[:]
	)


	total = DataFrame(
			Resource = "Total", Zone = "n/a",
			Capacity_tonne_CO2_per_h = sum(dfCap[!,:Capacity_tonne_CO2_per_h]),
			Capacity_SNG_MMBtu_per_h = sum(dfCap[!,:Capacity_SNG_MMBtu_per_h]),
			Annual_SNG_Production = sum(dfCap[!,:Annual_SNG_Production]),
			Max_Annual_CO2_Consumption = sum(dfCap[!,:Max_Annual_CO2_Consumption]),
			Annual_CO2_Consumption = sum(dfCap[!,:Annual_CO2_Consumption]),
			CapacityFactor = "-"
		)

	dfCap = vcat(dfCap, total)
	CSV.write(string(path,sep,"Syn_ng_capacity.csv"), dfCap)
	return dfCap
end
