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
	write_h2_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the capacities for the different hydrogen resources (starting capacities or, existing capacities, retired capacities, and new-built capacities).
"""
function write_h2_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	# Capacity decisions
	dfH2Gen = inputs["dfH2Gen"]
	H = inputs["H2_RES_ALL"]

	H2_GEN_COMMIT = inputs["H2_GEN_COMMIT"]::Vector{Int}

	capdischarge = zeros(size(inputs["H2_RESOURCES_NAME"]))
    new_cap_and_commit = intersect(inputs["H2_GEN_NEW_CAP"], H2_GEN_COMMIT)
    new_cap_not_commit = setdiff(inputs["H2_GEN_NEW_CAP"], H2_GEN_COMMIT)
    if !isempty(new_cap_and_commit)
        capdischarge[new_cap_and_commit] .= value.(EP[:vH2GenNewCap][new_cap_and_commit]).data .* dfH2Gen[new_cap_and_commit,:Cap_Size_MW]
    end
    
	if !isempty(new_cap_not_commit)
        capdischarge[new_cap_not_commit] .= value.(EP[:vH2GenNewCap][new_cap_not_commit]).data
    end

    retcapdischarge = zeros(size(inputs["H2_RESOURCES_NAME"]))
    ret_cap_and_commit = intersect(inputs["H2_GEN_RET_CAP"], H2_GEN_COMMIT)
    ret_cap_not_commit = setdiff(inputs["H2_GEN_RET_CAP"], H2_GEN_COMMIT)
    if !isempty(ret_cap_and_commit)
        retcapdischarge[ret_cap_and_commit] .= value.(EP[:vH2GenRetCap][ret_cap_and_commit]).data .* dfH2Gen[ret_cap_and_commit,:Cap_Size_MW]
    end
    if !isempty(ret_cap_not_commit)
        retcapdischarge[ret_cap_not_commit] .= value.(EP[:vH2GenRetCap][ret_cap_not_commit]).data
    end

    capcharge = zeros(size(inputs["H2_RESOURCES_NAME"]))
    retcapcharge = zeros(size(inputs["H2_RESOURCES_NAME"]))
    stor_new_cap_charge = intersect(inputs["H2_STOR_ALL"], inputs["NEW_CAP_H2_STOR_CHARGE"])
    stor_ret_cap = intersect(inputs["H2_STOR_ALL"], inputs["RET_CAP_H2_STOR_CHARGE"])
    if !isempty(stor_new_cap_charge)
        capcharge[stor_new_cap_charge] .= value.(EP[:vH2CAPCHARGE][stor_new_cap_charge]).data
    end
    if !isempty(stor_ret_cap)
        retcapcharge[stor_ret_cap] .= value.(EP[:vH2RETCAPCHARGE][stor_ret_cap]).data
    end

    capenergy = zeros(size(inputs["H2_RESOURCES_NAME"]))
    retcapenergy = zeros(size(inputs["H2_RESOURCES_NAME"]))
    stor_new_cap_energy = intersect(inputs["H2_STOR_ALL"], inputs["NEW_CAP_H2_ENERGY"])
    stor_ret_cap_energy = intersect(inputs["H2_STOR_ALL"], inputs["RET_CAP_H2_ENERGY"])
    if !isempty(stor_new_cap_energy)
        capenergy[stor_new_cap_energy] = value.(EP[:vH2CAPENERGY][stor_new_cap_energy]).data
    end
    if !isempty(stor_ret_cap_energy)
        retcapenergy[stor_ret_cap_energy] = value.(EP[:vH2RETCAPENERGY][stor_ret_cap_energy]).data
    end


	MaxGen = AnnualGen = CapFactor = zeros(size(inputs["H2_RESOURCES_NAME"]))

	h2genTC = value.(EP[:eH2GenTotalCap])
	MaxGen = h2genTC * 8760

	h2gen = value.(EP[:vH2Gen])
	AnnualGen = h2gen *inputs["omega"]

	for i in 1:H
		if MaxGen[i] == 0
			CapFactor[i] = 0
		else
			CapFactor[i] = AnnualGen[i]/MaxGen[i]
		end
	end
	
	AnnualCO2Emissions = zeros(size(inputs["H2_RESOURCES_NAME"]))

	h2emissionsbyplant = value.(EP[:eH2EmissionsByPlant])
	AnnualCO2Emissions = h2emissionsbyplant * inputs["omega"]

    dfCap = DataFrame(
        Resource = inputs["H2_RESOURCES_NAME"], Zone = dfH2Gen[!,:Zone],
        StartCap = dfH2Gen[!,:Existing_Cap_MW],
        RetCap = retcapdischarge[:],
        NewCap = capdischarge[:],
        EndCap = value.(EP[:eH2GenTotalCap]),
        StartEnergyCap = dfH2Gen[!,:Existing_Energy_Cap_MWh],
        RetEnergyCap = retcapenergy[:],
        NewEnergyCap = capenergy[:],
        EndEnergyCap = dfH2Gen[!,:Existing_Energy_Cap_MWh]+capenergy[:]-retcapenergy[:],
        StartChargeCap = dfH2Gen[!,:Existing_Charge_Cap_MW],
        RetChargeCap = retcapcharge[:],
        NewChargeCap = capcharge[:],
        EndChargeCap = dfH2Gen[!,:Existing_Charge_Cap_MW]+capcharge[:]-retcapcharge[:],
		MaxAnnualGeneration = MaxGen[:],
		AnnualGeneration = AnnualGen[:],
		CapacityFactor = CapFactor[:],
		AnnualEmissions = AnnualCO2Emissions[:],
    )

	total = DataFrame(
		Resource = "Total", Zone = "n/a",
		StartCap = sum(dfCap[!,:StartCap]), RetCap = sum(dfCap[!,:RetCap]),
		NewCap = sum(dfCap[!,:NewCap]), EndCap = sum(dfCap[!,:EndCap]),
		StartEnergyCap = sum(dfCap[!,:StartEnergyCap]), RetEnergyCap = sum(dfCap[!,:RetEnergyCap]),
		NewEnergyCap = sum(dfCap[!,:NewEnergyCap]), EndEnergyCap = sum(dfCap[!,:EndEnergyCap]),
		StartChargeCap = sum(dfCap[!,:StartChargeCap]), RetChargeCap = sum(dfCap[!,:RetChargeCap]),
		NewChargeCap = sum(dfCap[!,:NewChargeCap]), EndChargeCap = sum(dfCap[!,:EndChargeCap]),
		MaxAnnualGeneration = sum(dfCap[!,:MaxAnnualGeneration]), AnnualGeneration = sum(dfCap[!,:AnnualGeneration]),
		AnnualEmissions = sum(dfCap[!,:AnnualEmissions]),
		CapacityFactor = "-"
	)

	if setup["ModelBESC"] == 1 && setup["BIO_H2_On"] == 1
		dfbiorefinery = inputs["dfbiorefinery"]
		B = inputs["BIO_RES_ALL"]

		newcap_BioH2 = zeros(size(inputs["BIO_RESOURCES_NAME"]))
		for i in inputs["BIO_H2"]
			newcap_BioH2[i] = value(EP[:vCapacity_BIO_per_type][i]) * dfbiorefinery[!,:BioH2_yield_tonne_per_tonne][i]
		end

		startcap_BioH2 = zeros(size(inputs["BIO_RESOURCES_NAME"]))

		retcap_BioH2 = zeros(size(inputs["BIO_RESOURCES_NAME"]))

		startenergycap_BioH2 = zeros(size(inputs["BIO_RESOURCES_NAME"]))

		retenergycap_BioH2 = zeros(size(inputs["BIO_RESOURCES_NAME"]))

		newenergycap_BioH2 = zeros(size(inputs["BIO_RESOURCES_NAME"]))

		endenergycap_BioH2 = zeros(size(inputs["BIO_RESOURCES_NAME"]))

		startchargecap_BioH2 = zeros(size(inputs["BIO_RESOURCES_NAME"]))

		retchargecap_BioH2 = zeros(size(inputs["BIO_RESOURCES_NAME"]))

		newchargecap_BioH2 = zeros(size(inputs["BIO_RESOURCES_NAME"]))

		endchargecap_BioH2 = zeros(size(inputs["BIO_RESOURCES_NAME"]))

		AnnualGen_BioH2 = zeros(size(1:inputs["BIO_RES_ALL"]))
		for i in 1:B
			AnnualGen_BioH2[i] = sum(inputs["omega"].* (value.(EP[:eBiohydrogen_produced_per_plant_per_time])[i,:]))
		end
	
		MaxGen_BioH2 = zeros(size(1:inputs["BIO_RES_ALL"]))
		for i in 1:B
			MaxGen_BioH2[i] = value.(EP[:vCapacity_BIO_per_type])[i] * dfbiorefinery[!,:BioH2_yield_tonne_per_tonne][i] * 8760
		end

		CapFactor_BioH2 = zeros(size(1:inputs["BIO_RES_ALL"]))
		for i in 1:B
			if MaxGen_BioH2[i] == 0
				CapFactor_BioH2[i] = 0
			else
				CapFactor_BioH2[i] = AnnualGen_BioH2[i]/MaxGen_BioH2[i]
			end
		end

		AnnualCO2Emissions_BioH2 = zeros(size(1:inputs["BIO_RES_ALL"]))
		for i in 1:B
			AnnualCO2Emissions_BioH2[i] = 0 #Already counted in power capacity page
		end
	
		dfBioH2_Cap = DataFrame(
			Resource = inputs["BIO_RESOURCES_NAME"], Zone = dfbiorefinery[!,:Zone],
			StartCap = startcap_BioH2[:],
			RetCap = retcap_BioH2[:],
			NewCap = newcap_BioH2[:],
			EndCap = newcap_BioH2[:],
			StartEnergyCap = startenergycap_BioH2[:],
			RetEnergyCap = retenergycap_BioH2[:],
			NewEnergyCap = newenergycap_BioH2[:],
			EndEnergyCap = endenergycap_BioH2[:],
			StartChargeCap = startchargecap_BioH2[:],
			RetChargeCap = retchargecap_BioH2[:],
			NewChargeCap = newchargecap_BioH2[:],
			EndChargeCap = endchargecap_BioH2[:],
			MaxAnnualGeneration = MaxGen_BioH2[:],
			AnnualGeneration = AnnualGen_BioH2[:],
			CapacityFactor = CapFactor_BioH2[:],
			AnnualEmissions = AnnualCO2Emissions_BioH2[:]
		)
	
		total_w_BioH2 = DataFrame(
				Resource = "Total", Zone = "n/a",
				StartCap = sum(dfCap[!,:StartCap]) + sum(dfBioH2_Cap[!,:StartCap]), RetCap = sum(dfCap[!,:RetCap]) + sum(dfBioH2_Cap[!,:RetCap]),
				NewCap = sum(dfCap[!,:NewCap]) + sum(dfBioH2_Cap[!,:NewCap]), EndCap = sum(dfCap[!,:EndCap]) + sum(dfBioH2_Cap[!,:EndCap]),
				StartEnergyCap = sum(dfCap[!,:StartEnergyCap]) + sum(dfBioH2_Cap[!,:StartEnergyCap]), RetEnergyCap = sum(dfCap[!,:RetEnergyCap]) + sum(dfBioH2_Cap[!,:RetEnergyCap]),
				NewEnergyCap = sum(dfCap[!,:NewEnergyCap]) + sum(dfBioH2_Cap[!,:NewEnergyCap]),EndEnergyCap = sum(dfCap[!,:EndEnergyCap]) + sum(dfBioH2_Cap[!,:EndEnergyCap]),
				StartChargeCap = sum(dfCap[!,:StartChargeCap]) + sum(dfBioH2_Cap[!,:StartChargeCap]), RetChargeCap = sum(dfCap[!,:RetChargeCap]) + sum(dfBioH2_Cap[!,:RetChargeCap]),
				NewChargeCap = sum(dfCap[!,:NewChargeCap]) + sum(dfBioH2_Cap[!,:NewChargeCap]),EndChargeCap = sum(dfCap[!,:EndChargeCap]) + sum(dfBioH2_Cap[!,:EndChargeCap]),
				MaxAnnualGeneration = sum(dfCap[!,:MaxAnnualGeneration]) + sum(dfBioH2_Cap[!,:MaxAnnualGeneration]), AnnualGeneration = sum(dfCap[!,:AnnualGeneration]) + sum(dfBioH2_Cap[!,:AnnualGeneration]),
				AnnualEmissions = sum(dfCap[!,:AnnualEmissions]) + sum(dfBioH2_Cap[!,:AnnualEmissions]),
				CapacityFactor = "-"
			)
	
		dfCap_Total_w_BioH2 = vcat(dfCap, dfBioH2_Cap, total_w_BioH2)
		CSV.write(string(path,sep,"HSC_generation_storage_capacity_w_BioH2.csv"), dfCap_Total_w_BioH2)
	end

	dfCap = vcat(dfCap, total)
	CSV.write(string(path,sep,"HSC_generation_storage_capacity.csv"), dfCap)
	return dfCap
end
