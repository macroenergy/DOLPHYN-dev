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
write_bio_liquid_fuels_plant_capacity_part_a(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for writing the diferent capacities for biorefinery resources.
"""
function write_bio_liquid_fuels_plant_capacity_part_a(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	# Capacity_tonne_biomass_per_h decisions
	dfBioLF = inputs["dfBioLF"]
	AnnualBiomassConsumption = zeros(size(1:inputs["BIO_LF_RES_ALL"]))


	for i in 1:inputs["BIO_LF_RES_ALL"]
		if value(EP[:vCapacity_BIO_LF_per_type][i]) > 0.01
			AnnualBiomassConsumption[i] = sum(inputs["omega"].* (value.(EP[:vBiomass_consumed_per_plant_per_time_LF])[i,:]))	
		else
			AnnualBiomassConsumption[i] = 0
		end
	end

	dfCap = DataFrame(
		Resource = inputs["BIO_LF_RESOURCES_NAME"], Zone = dfBioLF[!,:Zone],
		Annual_Biomass_Consumption = AnnualBiomassConsumption[:]
	)

	total = DataFrame(
			Resource = "Total", Zone = "n/a",
			Annual_Biomass_Consumption = sum(dfCap[!,:Annual_Biomass_Consumption])
		)

	dfCap = vcat(dfCap, total)
	CSV.write(string(path,sep,"BESC_Bio_LF_capacity_part_a.csv"), dfCap)

	return dfCap
end