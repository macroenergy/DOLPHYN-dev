"""
DOLPHYN: Decision Optimization for Low-carbon Power and Electricity Networks
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
write_bio_electricity_plant_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for writing the diferent capacities for biorefinery resources.
"""
function write_bio_electricity_plant_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	# Capacity_tonne_biomass_per_h decisions
	dfBioELEC = inputs["dfBioELEC"]

	capbioenergy_ELEC = zeros(size(1:inputs["BIO_ELEC_RES_ALL"]))
	capbioelectricity = zeros(size(1:inputs["BIO_ELEC_RES_ALL"]))
	AnnualBioElectricity = zeros(size(1:inputs["BIO_ELEC_RES_ALL"]))
	MaxBiomassConsumption = zeros(size(1:inputs["BIO_ELEC_RES_ALL"]))
	AnnualBiomassConsumption = zeros(size(1:inputs["BIO_ELEC_RES_ALL"]))
	CapFactor = zeros(size(1:inputs["BIO_ELEC_RES_ALL"]))
	AnnualCO2Biomass = zeros(size(1:inputs["BIO_ELEC_RES_ALL"]))
	AnnualCO2Captured = zeros(size(1:inputs["BIO_ELEC_RES_ALL"]))
	AnnualCO2Emission = zeros(size(1:inputs["BIO_ELEC_RES_ALL"]))

	for i in 1:inputs["BIO_ELEC_RES_ALL"]

		if value(EP[:vCapacity_BIO_ELEC_per_type][i]) > 0.01
		
			capbioenergy_ELEC[i] = value(EP[:vCapacity_BIO_ELEC_per_type][i])
			capbioelectricity[i] = value(EP[:vCapacity_BIO_ELEC_per_type][i]) * dfBioELEC[!,:Biomass_energy_MMBtu_per_tonne][i] * dfBioELEC[!,:Biorefinery_efficiency][i] * dfBioELEC[!,:BioElectricity_fraction][i] * MMBtu_to_MWh
			AnnualBioElectricity[i] = sum(inputs["omega"].* (value.(EP[:eBioELEC_produced_MWh_per_plant_per_time])[i,:]))
			MaxBiomassConsumption[i] = value.(EP[:vCapacity_BIO_ELEC_per_type])[i] * 8760
			AnnualBiomassConsumption[i] = sum(inputs["omega"].* (value.(EP[:vBiomass_consumed_per_plant_per_time_ELEC])[i,:]))
			AnnualCO2Biomass[i] = sum(inputs["omega"].* (value.(EP[:eBiomass_CO2_per_plant_per_time_ELEC])[i,:]))
			AnnualCO2Captured[i] = sum(inputs["omega"].* (value.(EP[:eBio_ELEC_CO2_captured_per_plant_per_time])[i,:]))
			AnnualCO2Emission[i] = sum(inputs["omega"].* (value.(EP[:eBio_ELEC_CO2_emissions_per_plant_per_time])[i,:]))
			CapFactor[i] = AnnualBiomassConsumption[i]/MaxBiomassConsumption[i]

		else

			capbioenergy_ELEC[i] = 0
			capbioelectricity[i] = 0
			AnnualBioElectricity[i] = 0
			MaxBiomassConsumption[i] = 0
			AnnualBiomassConsumption[i] = 0
			AnnualCO2Biomass[i] = 0
			AnnualCO2Captured[i] = 0
			AnnualCO2Emission[i] = 0
			CapFactor[i] = 0

		end
		
	end

	dfCap = DataFrame(
		Resource = inputs["BIO_ELEC_RESOURCES_NAME"], Zone = dfBioELEC[!,:Zone],
		Capacity_tonne_biomass_per_h = capbioenergy_ELEC[:],
		Capacity_Bioelectricity_tonne_per_h = capbioelectricity[:],
		Annual_Bioelectricity_Production = AnnualBioElectricity[:],
		Max_Annual_Biomass_Consumption = MaxBiomassConsumption[:],
		Annual_Biomass_Consumption = AnnualBiomassConsumption[:],
		CapacityFactor = CapFactor[:],
		Annual_CO2_Biomass = AnnualCO2Biomass[:],
		Annual_CO2_Captured = AnnualCO2Captured[:],
		Annual_CO2_Emission = AnnualCO2Emission[:]
	)

	total = DataFrame(
			Resource = "Total", Zone = "n/a",
			Capacity_tonne_biomass_per_h = sum(dfCap[!,:Capacity_tonne_biomass_per_h]),
			Capacity_Bioelectricity_tonne_per_h = sum(dfCap[!,:Capacity_Bioelectricity_tonne_per_h]),
			Annual_Bioelectricity_Production = sum(dfCap[!,:Annual_Bioelectricity_Production]),
			Max_Annual_Biomass_Consumption = sum(dfCap[!,:Max_Annual_Biomass_Consumption]), 
			Annual_Biomass_Consumption = sum(dfCap[!,:Annual_Biomass_Consumption]),
			CapacityFactor = "-",
			Annual_CO2_Biomass = sum(dfCap[!,:Annual_CO2_Emission]),
			Annual_CO2_Captured = sum(dfCap[!,:Annual_CO2_Captured]),
			Annual_CO2_Emission = sum(dfCap[!,:Annual_CO2_Emission]),
		)

	dfCap = vcat(dfCap, total)
	CSV.write(string(path,sep,"BESC_Bio_Electricity_capacity.csv"), dfCap)

	return dfCap
end