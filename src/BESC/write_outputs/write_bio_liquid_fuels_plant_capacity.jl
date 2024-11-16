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
	write_bio_LF_plant_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for writing the diferent capacities for biorefinery resources.
"""
function write_bio_liquid_fuels_plant_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	# Capacity_tonne_biomass_per_h decisions
	dfBioLF = inputs["dfBioLF"]

	capbioenergy_LF = zeros(size(1:inputs["BIO_LF_RES_ALL"]))
	#capbiogasoline = zeros(size(1:inputs["BIO_LF_RES_ALL"]))
	#capbiojetfuel = zeros(size(1:inputs["BIO_LF_RES_ALL"]))
	#capbiodiesel = zeros(size(1:inputs["BIO_LF_RES_ALL"]))
	#capbiopowercredit = zeros(size(1:inputs["BIO_LF_RES_ALL"]))

	AnnualBioGasoline = zeros(size(1:inputs["BIO_LF_RES_ALL"]))
	AnnualBioJetfuel = zeros(size(1:inputs["BIO_LF_RES_ALL"]))
	AnnualBioDiesel = zeros(size(1:inputs["BIO_LF_RES_ALL"]))
	AnnualBioPowerCredit = zeros(size(1:inputs["BIO_LF_RES_ALL"]))

	MaxBiomassConsumption = zeros(size(1:inputs["BIO_LF_RES_ALL"]))
	AnnualBiomassConsumption = zeros(size(1:inputs["BIO_LF_RES_ALL"]))
	CapFactor = zeros(size(1:inputs["BIO_LF_RES_ALL"]))
	AnnualCO2Biomass = zeros(size(1:inputs["BIO_LF_RES_ALL"]))
	AnnualCO2Captured = zeros(size(1:inputs["BIO_LF_RES_ALL"]))
	AnnualCO2Emission = zeros(size(1:inputs["BIO_LF_RES_ALL"]))

	for i in 1:inputs["BIO_LF_RES_ALL"]
		
		if value(EP[:vCapacity_BIO_LF_per_type][i]) > 0.01

			capbioenergy_LF[i] = value(EP[:vCapacity_BIO_LF_per_type][i])
			#capbiogasoline[i] = value(EP[:vCapacity_BIO_LF_per_type][i]) * dfBioLF[!,:Biomass_energy_MMBtu_per_tonne][i] * dfBioLF[!,:Biorefinery_efficiency][i] * dfBioLF[!,:BioGasoline_fraction][i]
			#capbiojetfuel[i] = value(EP[:vCapacity_BIO_LF_per_type][i]) * dfBioLF[!,:Biomass_energy_MMBtu_per_tonne][i] * dfBioLF[!,:Biorefinery_efficiency][i] * dfBioLF[!,:BioJetfuel_fraction][i]
			#capbiodiesel[i] = value(EP[:vCapacity_BIO_LF_per_type][i]) * dfBioLF[!,:Biomass_energy_MMBtu_per_tonne][i] * dfBioLF[!,:Biorefinery_efficiency][i] * dfBioLF[!,:BioDiesel_fraction][i]
			#capbiopowercredit[i] = value(EP[:vCapacity_BIO_LF_per_type][i]) * dfBioLF[!,:Biomass_energy_MMBtu_per_tonne][i] * dfBioLF[!,:Biorefinery_efficiency][i] * dfBioLF[!,:BioElectricity_fraction][i] * MMBtu_to_MWh

			AnnualBioGasoline[i] = sum(inputs["omega"].* (value.(EP[:eBiogasoline_produced_MMBtu_per_plant_per_time])[i,:]))
			AnnualBioJetfuel[i] = sum(inputs["omega"].* (value.(EP[:eBiojetfuel_produced_MMBtu_per_plant_per_time])[i,:]))
			AnnualBioDiesel[i] = sum(inputs["omega"].* (value.(EP[:eBiodiesel_produced_MMBtu_per_plant_per_time])[i,:]))
			AnnualBioPowerCredit[i] = sum(inputs["omega"].* (value.(EP[:eBioLF_Power_credit_produced_MWh_per_plant_per_time])[i,:]))

			MaxBiomassConsumption[i] = value.(EP[:vCapacity_BIO_LF_per_type])[i] * 8760
			AnnualBiomassConsumption[i] = sum(inputs["omega"].* (value.(EP[:vBiomass_consumed_per_plant_per_time_LF])[i,:]))
			AnnualCO2Biomass[i] = sum(inputs["omega"].* (value.(EP[:eBiomass_CO2_per_plant_per_time_LF])[i,:]))
			AnnualCO2Captured[i] = sum(inputs["omega"].* (value.(EP[:eBio_LF_CO2_captured_per_plant_per_time])[i,:]))
			AnnualCO2Emission[i] = sum(inputs["omega"].* (value.(EP[:eBio_LF_CO2_emissions_per_plant_per_time])[i,:]))
			CapFactor[i] = AnnualBiomassConsumption[i]/MaxBiomassConsumption[i]

		else

			capbioenergy_LF[i] = 0
			#capbiogasoline[i] = 0
			#capbiojetfuel[i] = 0
			#capbiodiesel[i] = 0
			#capbiopowercredit[i] = 0
			AnnualBioGasoline[i] = 0
			AnnualBioJetfuel[i] = 0
			AnnualBioDiesel[i] = 0
			AnnualBioPowerCredit[i] = 0

			MaxBiomassConsumption[i] = 0
			AnnualBiomassConsumption[i] = 0
			AnnualCO2Biomass[i] = 0
			AnnualCO2Captured[i] = 0
			AnnualCO2Emission[i] = 0
			CapFactor[i] = 0

		end

		
	end

	dfCap = DataFrame(
		Resource = inputs["BIO_LF_RESOURCES_NAME"], Zone = dfBioLF[!,:Zone],
		Capacity_tonne_biomass_per_h = capbioenergy_LF[:],
		#Capacity_Biogasoline_MMBtu_per_h = capbiogasoline[:],
		#Capacity_Biojetfuel_MMBtu_per_h = capbiojetfuel[:],
		#Capacity_Biodiesel_MMBtu_per_h = capbiodiesel[:],
		#Capacity_Bio_Power_Credit_MWh_per_h = capbiopowercredit[:],
		Annual_Biogasoline_Production = AnnualBioGasoline[:],
		Annual_Biojetfuel_Production = AnnualBioJetfuel[:],
		Annual_Biodiesel_Production = AnnualBioDiesel[:],
		Annual_Bio_Power_Credit = AnnualBioPowerCredit[:],
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
			#Capacity_Biogasoline_MMBtu_per_h = sum(dfCap[!,:Capacity_Biogasoline_MMBtu_per_h]),
			#Capacity_Biojetfuel_MMBtu_per_h = sum(dfCap[!,:Capacity_Biojetfuel_MMBtu_per_h]),
			#Capacity_Biodiesel_MMBtu_per_h = sum(dfCap[!,:Capacity_Biodiesel_MMBtu_per_h]),
			#Capacity_Bio_Power_Credit_MWh_per_h = sum(dfCap[!,:Capacity_Bio_Power_Credit_MWh_per_h]),
			Annual_Biogasoline_Production = sum(dfCap[!,:Annual_Biogasoline_Production]),
			Annual_Biojetfuel_Production = sum(dfCap[!,:Annual_Biojetfuel_Production]),
			Annual_Biodiesel_Production = sum(dfCap[!,:Annual_Biodiesel_Production]),
			Annual_Bio_Power_Credit = sum(dfCap[!,:Annual_Bio_Power_Credit]),
			Max_Annual_Biomass_Consumption = sum(dfCap[!,:Max_Annual_Biomass_Consumption]), 
			Annual_Biomass_Consumption = sum(dfCap[!,:Annual_Biomass_Consumption]),
			CapacityFactor = "-",
			Annual_CO2_Biomass = sum(dfCap[!,:Annual_CO2_Emission]),
			Annual_CO2_Captured = sum(dfCap[!,:Annual_CO2_Captured]),
			Annual_CO2_Emission = sum(dfCap[!,:Annual_CO2_Emission]),
		)

	dfCap = vcat(dfCap, total)
	CSV.write(string(path,sep,"BESC_Bio_LF_capacity.csv"), dfCap)

	return dfCap
end