@doc raw"""
	write_capacity(path::AbstractString, inputs::Dict, setup::Dict, EP::Model))

Function for writing the diferent capacities for the different generation technologies (starting capacities or, existing capacities, retired capacities, and new-built capacities).
"""
function write_capacity(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)

	StartCapTotal = 0
	RetCapTotal = 0
	NewCapTotal = 0
	EndCapTotal = 0
	StartEnergyCapTotal = 0
	RetEnergyCapTotal = 0
	NewEnergyCapTotal = 0
	EndEnergyCapTotal = 0
	StartChargeCapTotal = 0
	RetChargeCapTotal = 0
	NewChargeCapTotal = 0
	EndChargeCapTotal = 0
	MaxAnnualGenerationTotal = 0
	AnnualGenerationTotal = 0
	AnnualEmissionsTotal = 0

	# Capacity decisions
	dfGen = inputs["dfGen"]
	MultiStage = setup["MultiStage"]
	G = inputs["G"]
	
	capdischarge = zeros(size(inputs["RESOURCES"]))
	for i in inputs["NEW_CAP"]
		if i in inputs["COMMIT"]
			capdischarge[i] = value(EP[:vCAP][i])*dfGen[!,:Cap_Size][i]
		else
			capdischarge[i] = value(EP[:vCAP][i])
		end
	end

	retcapdischarge = zeros(size(inputs["RESOURCES"]))
	for i in inputs["RET_CAP"]
		if i in inputs["COMMIT"]
			retcapdischarge[i] = first(value.(EP[:vRETCAP][i]))*dfGen[!,:Cap_Size][i]
		else
			retcapdischarge[i] = first(value.(EP[:vRETCAP][i]))
		end
	end

	capcharge = zeros(size(inputs["RESOURCES"]))
	retcapcharge = zeros(size(inputs["RESOURCES"]))
	existingcapcharge = zeros(size(inputs["RESOURCES"]))
	for i in inputs["STOR_ASYMMETRIC"]
		if i in inputs["NEW_CAP_CHARGE"]
			capcharge[i] = value(EP[:vCAPCHARGE][i])
		end
		if i in inputs["RET_CAP_CHARGE"]
			retcapcharge[i] = value(EP[:vRETCAPCHARGE][i])
		end
		existingcapcharge[i] = MultiStage == 1 ? value(EP[:vEXISTINGCAPCHARGE][i]) : dfGen[!,:Existing_Charge_Cap_MW][i]
	end

	capenergy = zeros(size(inputs["RESOURCES"]))
	retcapenergy = zeros(size(inputs["RESOURCES"]))
	existingcapenergy = zeros(size(inputs["RESOURCES"]))
	for i in inputs["STOR_ALL"]
		if i in inputs["NEW_CAP_ENERGY"]
			capenergy[i] = value(EP[:vCAPENERGY][i])
		end
		if i in inputs["RET_CAP_ENERGY"]
			retcapenergy[i] = value(EP[:vRETCAPENERGY][i])
		end
		existingcapenergy[i] = MultiStage == 1 ? value(EP[:vEXISTINGCAPENERGY][i]) :  dfGen[!,:Existing_Cap_MWh][i]
	end

	MaxGen = zeros(size(inputs["RESOURCES"]))
	for i in 1:G
		MaxGen[i] = value.(EP[:eTotalCap])[i] * 8760
	end

	AnnualGen = zeros(size(inputs["RESOURCES"]))
	for i in 1:G
		AnnualGen[i] = sum(inputs["omega"].* (value.(EP[:vP])[i,:]))
	end

	CapFactor = zeros(size(inputs["RESOURCES"]))
	for i in 1:G
		if MaxGen[i] == 0
			CapFactor[i] = 0
		else
			CapFactor[i] = AnnualGen[i]/MaxGen[i]
		end
	end

	AnnualCO2Emissions = zeros(size(inputs["RESOURCES"]))
	for i in 1:G
		AnnualCO2Emissions[i] = sum(inputs["omega"].* (value.(EP[:eEmissionsByPlant])[i,:]))
	end
	
	dfCap = DataFrame(
		Resource = inputs["RESOURCES"], Zone = dfGen[!,:Zone],
		StartCap = MultiStage == 1 ? value.(EP[:vEXISTINGCAP]) : dfGen[!,:Existing_Cap_MW],
		RetCap = retcapdischarge[:],
		NewCap = capdischarge[:],
		EndCap = value.(EP[:eTotalCap]),
		StartEnergyCap = existingcapenergy[:],
		RetEnergyCap = retcapenergy[:],
		NewEnergyCap = capenergy[:],
		EndEnergyCap = existingcapenergy[:] - retcapenergy[:] + capenergy[:],
		StartChargeCap = existingcapcharge[:],
		RetChargeCap = retcapcharge[:],
		NewChargeCap = capcharge[:],
		EndChargeCap = existingcapcharge[:] - retcapcharge[:] + capcharge[:],
		MaxAnnualGeneration = MaxGen[:],
		AnnualGeneration = AnnualGen[:],
		CapacityFactor = CapFactor[:],
		AnnualEmissions = AnnualCO2Emissions[:]
	)

	StartCapTotal += sum(dfCap[!,:StartCap])
	RetCapTotal += sum(dfCap[!,:RetCap])
	NewCapTotal += sum(dfCap[!,:NewCap]) 
	EndCapTotal += sum(dfCap[!,:EndCap])
	StartEnergyCapTotal += sum(dfCap[!,:StartEnergyCap])
	RetEnergyCapTotal += sum(dfCap[!,:RetEnergyCap])
	NewEnergyCapTotal += sum(dfCap[!,:NewEnergyCap]) 
	EndEnergyCapTotal += sum(dfCap[!,:EndEnergyCap])
	StartChargeCapTotal += sum(dfCap[!,:StartChargeCap]) 
	RetChargeCapTotal += sum(dfCap[!,:RetChargeCap])
	NewChargeCapTotal += sum(dfCap[!,:NewChargeCap]) 
	EndChargeCapTotal += sum(dfCap[!,:EndChargeCap])
	MaxAnnualGenerationTotal += sum(dfCap[!,:MaxAnnualGeneration])
	AnnualGenerationTotal += sum(dfCap[!,:AnnualGeneration])
	AnnualEmissionsTotal += sum(dfCap[!,:AnnualEmissions])

	total = DataFrame(
			Resource = "Total", Zone = "n/a",
			StartCap = StartCapTotal, 
			RetCap = RetCapTotal,
			NewCap = NewCapTotal, 
			EndCap = EndCapTotal,
			StartEnergyCap = StartEnergyCapTotal, 
			RetEnergyCap = RetEnergyCapTotal,
			NewEnergyCap = NewEnergyCapTotal, 
			EndEnergyCap = EndEnergyCapTotal,
			StartChargeCap = StartChargeCapTotal, 
			RetChargeCap = RetChargeCapTotal,
			NewChargeCap = NewChargeCapTotal, 
			EndChargeCap = EndChargeCapTotal,
			MaxAnnualGeneration = MaxAnnualGenerationTotal, 
			AnnualGeneration = AnnualGenerationTotal,
			AnnualEmissions = AnnualEmissionsTotal,
			CapacityFactor = "-"
		)

	dfCap_Power = vcat(dfCap, total)
	CSV.write(joinpath(path, "capacity.csv"), dfCap_Power)

	############################### Multi-Sector ##################################

	dfCap_Combined = vcat(dfCap)

	#If H2G2P modeled, write new output capacity file with H2G2P capacity combined
	if setup["ModelH2"] == 1 && setup["ModelH2G2P"] == 1
		# Capacity decisions
		dfH2G2P = inputs["dfH2G2P"]
		H = inputs["H2_G2P_ALL"]
	
		capdischarge_H2G2P = zeros(size(inputs["H2_G2P_NAME"]))
		for i in inputs["H2_G2P_NEW_CAP"]
			if i in inputs["H2_G2P_COMMIT"]
				capdischarge_H2G2P[i] = value(EP[:vH2G2PNewCap][i]) * dfH2G2P[!,:Cap_Size_MW][i]
			else
				capdischarge_H2G2P[i] = value(EP[:vH2G2PNewCap][i])
			end
		end
	
		retcapdischarge_H2G2P = zeros(size(inputs["H2_G2P_NAME"]))
		for i in inputs["H2_G2P_RET_CAP"]
			if i in inputs["H2_G2P_COMMIT"]
				retcapdischarge_H2G2P[i] = first(value.(EP[:vH2G2PRetCap][i])) * dfH2G2P[!,:Cap_Size_MW][i]
			else
				retcapdischarge_H2G2P[i] = first(value.(EP[:vH2G2PRetCap][i]))
			end
		end
	
		startenergycap_H2G2P = zeros(size(1:inputs["H2_G2P_ALL"]))
	
		retenergycap_H2G2P = zeros(size(1:inputs["H2_G2P_ALL"]))

		newenergycap_H2G2P = zeros(size(1:inputs["H2_G2P_ALL"]))
	
		endenergycap_H2G2P = zeros(size(1:inputs["H2_G2P_ALL"]))
	
		startchargecap_H2G2P = zeros(size(1:inputs["H2_G2P_ALL"]))
	
		retchargecap_H2G2P = zeros(size(1:inputs["H2_G2P_ALL"]))

		newchargecap_H2G2P = zeros(size(1:inputs["H2_G2P_ALL"]))

		endchargecap_H2G2P = zeros(size(1:inputs["H2_G2P_ALL"]))
	
		MaxGen_H2G2P = zeros(size(1:inputs["H2_G2P_ALL"]))
		for i in 1:H
			MaxGen_H2G2P[i] = value.(EP[:eH2G2PTotalCap])[i] * 8760
		end
	
		AnnualGen_H2G2P = zeros(size(1:inputs["H2_G2P_ALL"]))
		for i in 1:H
			AnnualGen_H2G2P[i] = sum(inputs["omega"].* (value.(EP[:vPG2P])[i,:]))
		end
	
		CapFactor_H2G2P = zeros(size(1:inputs["H2_G2P_ALL"]))
		for i in 1:H
			if MaxGen_H2G2P[i] == 0
				CapFactor_H2G2P[i] = 0
			else
				CapFactor_H2G2P[i] = AnnualGen_H2G2P[i]/MaxGen_H2G2P[i]
			end
		end

		AnnualCO2Emissions_H2G2P = zeros(size(1:inputs["H2_G2P_ALL"]))
		for i in 1:H
			AnnualCO2Emissions_H2G2P[i] = 0
		end
	
		dfCap_H2G2P = DataFrame(
			Resource = inputs["H2_G2P_NAME"], Zone = dfH2G2P[!,:Zone],
			StartCap = dfH2G2P[!,:Existing_Cap_MW],
			RetCap = retcapdischarge_H2G2P[:],
			NewCap = capdischarge_H2G2P[:],
			EndCap = value.(EP[:eH2G2PTotalCap]),
			StartEnergyCap = startenergycap_H2G2P[:],
			RetEnergyCap = retenergycap_H2G2P[:],
			NewEnergyCap = newenergycap_H2G2P[:],
			EndEnergyCap = endenergycap_H2G2P[:],
			StartChargeCap = startchargecap_H2G2P[:],
			RetChargeCap = retchargecap_H2G2P[:],
			NewChargeCap = newchargecap_H2G2P[:],
			EndChargeCap = endchargecap_H2G2P[:],
			MaxAnnualGeneration = MaxGen_H2G2P[:],
			AnnualGeneration = AnnualGen_H2G2P[:],
			CapacityFactor = CapFactor_H2G2P[:],
			AnnualEmissions = AnnualCO2Emissions_H2G2P[:]
		)

		StartCapTotal += sum(dfCap_H2G2P[!,:StartCap])
		RetCapTotal += sum(dfCap_H2G2P[!,:RetCap])
		NewCapTotal += sum(dfCap_H2G2P[!,:NewCap]) 
		EndCapTotal += sum(dfCap_H2G2P[!,:EndCap])
		StartEnergyCapTotal += sum(dfCap_H2G2P[!,:StartEnergyCap])
		RetEnergyCapTotal += sum(dfCap_H2G2P[!,:RetEnergyCap])
		NewEnergyCapTotal += sum(dfCap_H2G2P[!,:NewEnergyCap]) 
		EndEnergyCapTotal += sum(dfCap_H2G2P[!,:EndEnergyCap])
		StartChargeCapTotal += sum(dfCap_H2G2P[!,:StartChargeCap]) 
		RetChargeCapTotal += sum(dfCap_H2G2P[!,:RetChargeCap])
		NewChargeCapTotal += sum(dfCap_H2G2P[!,:NewChargeCap]) 
		EndChargeCapTotal += sum(dfCap_H2G2P[!,:EndChargeCap])
		MaxAnnualGenerationTotal += sum(dfCap_H2G2P[!,:MaxAnnualGeneration])
		AnnualGenerationTotal += sum(dfCap_H2G2P[!,:AnnualGeneration])
		AnnualEmissionsTotal += sum(dfCap_H2G2P[!,:AnnualEmissions])

		dfCap_Combined = vcat(dfCap_Combined, dfCap_H2G2P)

	end

	if setup["ModelBESC"] == 1

		if setup["Bio_ELEC_On"] == 1
			dfBioELEC = inputs["dfBioELEC"]
			B = inputs["BIO_ELEC_RES_ALL"]

			newcap_BioE = zeros(size(inputs["BIO_ELEC_RESOURCES_NAME"]))
			startcap_BioE = zeros(size(inputs["BIO_ELEC_RESOURCES_NAME"]))
			retcap_BioE = zeros(size(inputs["BIO_ELEC_RESOURCES_NAME"]))
			startenergycap_BioE = zeros(size(inputs["BIO_ELEC_RESOURCES_NAME"]))
			retenergycap_BioE = zeros(size(inputs["BIO_ELEC_RESOURCES_NAME"]))
			newenergycap_BioE = zeros(size(inputs["BIO_ELEC_RESOURCES_NAME"]))
			endenergycap_BioE = zeros(size(inputs["BIO_ELEC_RESOURCES_NAME"]))
			startchargecap_BioE = zeros(size(inputs["BIO_ELEC_RESOURCES_NAME"]))
			retchargecap_BioE = zeros(size(inputs["BIO_ELEC_RESOURCES_NAME"]))
			newchargecap_BioE = zeros(size(inputs["BIO_ELEC_RESOURCES_NAME"]))
			endchargecap_BioE = zeros(size(inputs["BIO_ELEC_RESOURCES_NAME"]))
			AnnualCO2Emissions_BioE = zeros(size(inputs["BIO_ELEC_RESOURCES_NAME"]))

			for i in 1:B
				newcap_BioE[i] = value(EP[:vCapacity_BIO_ELEC_per_type][i]) * dfBioELEC[!,:Biomass_energy_MMBtu_per_tonne][i] * dfBioELEC[!,:Biorefinery_efficiency][i] * dfBioELEC[!,:BioElectricity_fraction][i] * MMBtu_to_MWh
			end

			AnnualGen_BioE = zeros(size(1:B))
			for i in 1:B
				AnnualGen_BioE[i] = sum(inputs["omega"].* (value.(EP[:eBioELEC_produced_MWh_per_plant_per_time])[i,:]))
			end
		
			MaxGen_BioE = zeros(size(1:B))
			for i in 1:B
				MaxGen_BioE[i] = value.(EP[:vCapacity_BIO_ELEC_per_type])[i] * dfBioELEC[!,:Biomass_energy_MMBtu_per_tonne][i] * dfBioELEC[!,:Biorefinery_efficiency][i] * dfBioELEC[!,:BioElectricity_fraction][i] * MMBtu_to_MWh * 8760
			end

			CapFactor_BioE = zeros(size(1:B))
			for i in 1:B
				if MaxGen_BioE[i] == 0
					CapFactor_BioE[i] = 0
				else
					CapFactor_BioE[i] = AnnualGen_BioE[i]/MaxGen_BioE[i]
				end
			end

			for i in 1:B
				AnnualCO2Emissions_BioE[i] = 0
			end
		
			dfBioE_Cap = DataFrame(
				Resource = inputs["BIO_ELEC_RESOURCES_NAME"], Zone = dfBioELEC[!,:Zone],
				StartCap = startcap_BioE[:],
				RetCap = retcap_BioE[:],
				NewCap = newcap_BioE[:],
				EndCap = newcap_BioE[:],
				StartEnergyCap = startenergycap_BioE[:],
				RetEnergyCap = retenergycap_BioE[:],
				NewEnergyCap = newenergycap_BioE[:],
				EndEnergyCap = endenergycap_BioE[:],
				StartChargeCap = startchargecap_BioE[:],
				RetChargeCap = retchargecap_BioE[:],
				NewChargeCap = newchargecap_BioE[:],
				EndChargeCap = endchargecap_BioE[:],
				MaxAnnualGeneration = MaxGen_BioE[:],
				AnnualGeneration = AnnualGen_BioE[:],
				CapacityFactor = CapFactor_BioE[:],
				AnnualEmissions = AnnualCO2Emissions_BioE[:]
			)

			StartCapTotal += sum(dfBioE_Cap[!,:StartCap])
			RetCapTotal += sum(dfBioE_Cap[!,:RetCap])
			NewCapTotal += sum(dfBioE_Cap[!,:NewCap]) 
			EndCapTotal += sum(dfBioE_Cap[!,:EndCap])
			StartEnergyCapTotal += sum(dfBioE_Cap[!,:StartEnergyCap])
			RetEnergyCapTotal += sum(dfBioE_Cap[!,:RetEnergyCap])
			NewEnergyCapTotal += sum(dfBioE_Cap[!,:NewEnergyCap]) 
			EndEnergyCapTotal += sum(dfBioE_Cap[!,:EndEnergyCap])
			StartChargeCapTotal += sum(dfBioE_Cap[!,:StartChargeCap]) 
			RetChargeCapTotal += sum(dfBioE_Cap[!,:RetChargeCap])
			NewChargeCapTotal += sum(dfBioE_Cap[!,:NewChargeCap]) 
			EndChargeCapTotal += sum(dfBioE_Cap[!,:EndChargeCap])
			MaxAnnualGenerationTotal += sum(dfBioE_Cap[!,:MaxAnnualGeneration])
			AnnualGenerationTotal += sum(dfBioE_Cap[!,:AnnualGeneration])
			AnnualEmissionsTotal += sum(dfBioE_Cap[!,:AnnualEmissions])
	
			dfCap_Combined = vcat(dfCap_Combined, dfBioE_Cap)
		end

		
		if setup["Bio_H2_On"] == 1
			dfBioH2 = inputs["dfBioH2"]
			B = inputs["BIO_H2_RES_ALL"]
		
			newcap_BioH2 = zeros(size(inputs["BIO_H2_RESOURCES_NAME"]))
			startcap_BioH2 = zeros(size(inputs["BIO_H2_RESOURCES_NAME"]))
			retcap_BioH2 = zeros(size(inputs["BIO_H2_RESOURCES_NAME"]))
			startenergycap_BioH2 = zeros(size(inputs["BIO_H2_RESOURCES_NAME"]))
			retenergycap_BioH2 = zeros(size(inputs["BIO_H2_RESOURCES_NAME"]))
			newenergycap_BioH2 = zeros(size(inputs["BIO_H2_RESOURCES_NAME"]))
			endenergycap_BioH2 = zeros(size(inputs["BIO_H2_RESOURCES_NAME"]))
			startchargecap_BioH2 = zeros(size(inputs["BIO_H2_RESOURCES_NAME"]))
			retchargecap_BioH2 = zeros(size(inputs["BIO_H2_RESOURCES_NAME"]))
			newchargecap_BioH2 = zeros(size(inputs["BIO_H2_RESOURCES_NAME"]))
			endchargecap_BioH2 = zeros(size(inputs["BIO_H2_RESOURCES_NAME"]))
			AnnualCO2Emissions_BioH2 = zeros(size(inputs["BIO_H2_RESOURCES_NAME"]))
		
			for i in 1:B
				newcap_BioH2[i] = value(EP[:vCapacity_BIO_H2_per_type][i]) * dfBioH2[!,:Biomass_energy_MMBtu_per_tonne][i] * dfBioH2[!,:Biorefinery_efficiency][i] * dfBioH2[!,:BioElectricity_fraction][i] * MMBtu_to_MWh
			end
		
			AnnualGen_BioH2 = zeros(size(1:B))
			for i in 1:B
				AnnualGen_BioH2[i] = sum(inputs["omega"].* (value.(EP[:eBioH2_Power_credit_produced_MWh_per_plant_per_time])[i,:]))
			end
		
			MaxGen_BioH2 = zeros(size(1:B))
			for i in 1:B
				MaxGen_BioH2[i] = value.(EP[:vCapacity_BIO_H2_per_type])[i] * dfBioH2[!,:Biomass_energy_MMBtu_per_tonne][i] * dfBioH2[!,:Biorefinery_efficiency][i] * dfBioH2[!,:BioElectricity_fraction][i] * MMBtu_to_MWh * 8760
			end
		
			CapFactor_BioH2 = zeros(size(1:B))
			for i in 1:B
				if MaxGen_BioH2[i] == 0
					CapFactor_BioH2[i] = 0
				else
					CapFactor_BioH2[i] = AnnualGen_BioH2[i]/MaxGen_BioH2[i]
				end
			end
		
			for i in 1:B
				AnnualCO2Emissions_BioH2[i] = 0
			end
		
			dfBioH2_Cap = DataFrame(
				Resource = inputs["BIO_H2_RESOURCES_NAME"], Zone = dfBioH2[!,:Zone],
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
		
			StartCapTotal += sum(dfBioH2_Cap[!,:StartCap])
			RetCapTotal += sum(dfBioH2_Cap[!,:RetCap])
			NewCapTotal += sum(dfBioH2_Cap[!,:NewCap]) 
			EndCapTotal += sum(dfBioH2_Cap[!,:EndCap])
			StartEnergyCapTotal += sum(dfBioH2_Cap[!,:StartEnergyCap])
			RetEnergyCapTotal += sum(dfBioH2_Cap[!,:RetEnergyCap])
			NewEnergyCapTotal += sum(dfBioH2_Cap[!,:NewEnergyCap]) 
			EndEnergyCapTotal += sum(dfBioH2_Cap[!,:EndEnergyCap])
			StartChargeCapTotal += sum(dfBioH2_Cap[!,:StartChargeCap]) 
			RetChargeCapTotal += sum(dfBioH2_Cap[!,:RetChargeCap])
			NewChargeCapTotal += sum(dfBioH2_Cap[!,:NewChargeCap]) 
			EndChargeCapTotal += sum(dfBioH2_Cap[!,:EndChargeCap])
			MaxAnnualGenerationTotal += sum(dfBioH2_Cap[!,:MaxAnnualGeneration])
			AnnualGenerationTotal += sum(dfBioH2_Cap[!,:AnnualGeneration])
			AnnualEmissionsTotal += sum(dfBioH2_Cap[!,:AnnualEmissions])
		
			dfCap_Combined = vcat(dfCap_Combined, dfBioH2_Cap)
		end


		if setup["Bio_LF_On"] == 1
			dfBioLF = inputs["dfBioLF"]
			B = inputs["BIO_LF_RES_ALL"]
		
			newcap_BioLF = zeros(size(inputs["BIO_LF_RESOURCES_NAME"]))
			startcap_BioLF = zeros(size(inputs["BIO_LF_RESOURCES_NAME"]))
			retcap_BioLF = zeros(size(inputs["BIO_LF_RESOURCES_NAME"]))
			startenergycap_BioLF = zeros(size(inputs["BIO_LF_RESOURCES_NAME"]))
			retenergycap_BioLF = zeros(size(inputs["BIO_LF_RESOURCES_NAME"]))
			newenergycap_BioLF = zeros(size(inputs["BIO_LF_RESOURCES_NAME"]))
			endenergycap_BioLF = zeros(size(inputs["BIO_LF_RESOURCES_NAME"]))
			startchargecap_BioLF = zeros(size(inputs["BIO_LF_RESOURCES_NAME"]))
			retchargecap_BioLF = zeros(size(inputs["BIO_LF_RESOURCES_NAME"]))
			newchargecap_BioLF = zeros(size(inputs["BIO_LF_RESOURCES_NAME"]))
			endchargecap_BioLF = zeros(size(inputs["BIO_LF_RESOURCES_NAME"]))
			AnnualCO2Emissions_BioLF = zeros(size(inputs["BIO_LF_RESOURCES_NAME"]))
		
			for i in 1:B
				newcap_BioLF[i] = value(EP[:vCapacity_BIO_LF_per_type][i]) * dfBioLF[!,:Biomass_energy_MMBtu_per_tonne][i] * dfBioLF[!,:Biorefinery_efficiency][i] * dfBioLF[!,:BioElectricity_fraction][i] * MMBtu_to_MWh
			end
		
			AnnualGen_BioLF = zeros(size(1:B))
			for i in 1:B
				AnnualGen_BioLF[i] = sum(inputs["omega"].* (value.(EP[:eBioLF_Power_credit_produced_MWh_per_plant_per_time])[i,:]))
			end
		
			MaxGen_BioLF = zeros(size(1:B))
			for i in 1:B
				MaxGen_BioLF[i] = value.(EP[:vCapacity_BIO_LF_per_type])[i] * dfBioLF[!,:Biomass_energy_MMBtu_per_tonne][i] * dfBioLF[!,:Biorefinery_efficiency][i] * dfBioLF[!,:BioElectricity_fraction][i] * MMBtu_to_MWh * 8760
			end
		
			CapFactor_BioLF = zeros(size(1:B))
			for i in 1:B
				if MaxGen_BioLF[i] == 0
					CapFactor_BioLF[i] = 0
				else
					CapFactor_BioLF[i] = AnnualGen_BioLF[i]/MaxGen_BioLF[i]
				end
			end
		
			for i in 1:B
				AnnualCO2Emissions_BioLF[i] = 0
			end
		
			dfBioLF_Cap = DataFrame(
				Resource = inputs["BIO_LF_RESOURCES_NAME"], Zone = dfBioLF[!,:Zone],
				StartCap = startcap_BioLF[:],
				RetCap = retcap_BioLF[:],
				NewCap = newcap_BioLF[:],
				EndCap = newcap_BioLF[:],
				StartEnergyCap = startenergycap_BioLF[:],
				RetEnergyCap = retenergycap_BioLF[:],
				NewEnergyCap = newenergycap_BioLF[:],
				EndEnergyCap = endenergycap_BioLF[:],
				StartChargeCap = startchargecap_BioLF[:],
				RetChargeCap = retchargecap_BioLF[:],
				NewChargeCap = newchargecap_BioLF[:],
				EndChargeCap = endchargecap_BioLF[:],
				MaxAnnualGeneration = MaxGen_BioLF[:],
				AnnualGeneration = AnnualGen_BioLF[:],
				CapacityFactor = CapFactor_BioLF[:],
				AnnualEmissions = AnnualCO2Emissions_BioLF[:]
			)

			StartCapTotal += sum(dfBioLF_Cap[!,:StartCap])
			RetCapTotal += sum(dfBioLF_Cap[!,:RetCap])
			NewCapTotal += sum(dfBioLF_Cap[!,:NewCap]) 
			EndCapTotal += sum(dfBioLF_Cap[!,:EndCap])
			StartEnergyCapTotal += sum(dfBioLF_Cap[!,:StartEnergyCap])
			RetEnergyCapTotal += sum(dfBioLF_Cap[!,:RetEnergyCap])
			NewEnergyCapTotal += sum(dfBioLF_Cap[!,:NewEnergyCap]) 
			EndEnergyCapTotal += sum(dfBioLF_Cap[!,:EndEnergyCap])
			StartChargeCapTotal += sum(dfBioLF_Cap[!,:StartChargeCap]) 
			RetChargeCapTotal += sum(dfBioLF_Cap[!,:RetChargeCap])
			NewChargeCapTotal += sum(dfBioLF_Cap[!,:NewChargeCap]) 
			EndChargeCapTotal += sum(dfBioLF_Cap[!,:EndChargeCap])
			MaxAnnualGenerationTotal += sum(dfBioLF_Cap[!,:MaxAnnualGeneration])
			AnnualGenerationTotal += sum(dfBioLF_Cap[!,:AnnualGeneration])
			AnnualEmissionsTotal += sum(dfBioLF_Cap[!,:AnnualEmissions])
		
			dfCap_Combined = vcat(dfCap_Combined, dfBioLF_Cap)
		end


		if setup["Bio_NG_On"] == 1
			dfBioNG = inputs["dfBioNG"]
			B = inputs["BIO_NG_RES_ALL"]
		
			newcap_BioNG = zeros(size(inputs["BIO_NG_RESOURCES_NAME"]))
			startcap_BioNG = zeros(size(inputs["BIO_NG_RESOURCES_NAME"]))
			retcap_BioNG = zeros(size(inputs["BIO_NG_RESOURCES_NAME"]))
			startenergycap_BioNG = zeros(size(inputs["BIO_NG_RESOURCES_NAME"]))
			retenergycap_BioNG = zeros(size(inputs["BIO_NG_RESOURCES_NAME"]))
			newenergycap_BioNG = zeros(size(inputs["BIO_NG_RESOURCES_NAME"]))
			endenergycap_BioNG = zeros(size(inputs["BIO_NG_RESOURCES_NAME"]))
			startchargecap_BioNG = zeros(size(inputs["BIO_NG_RESOURCES_NAME"]))
			retchargecap_BioNG = zeros(size(inputs["BIO_NG_RESOURCES_NAME"]))
			newchargecap_BioNG = zeros(size(inputs["BIO_NG_RESOURCES_NAME"]))
			endchargecap_BioNG = zeros(size(inputs["BIO_NG_RESOURCES_NAME"]))
			AnnualCO2Emissions_BioNG = zeros(size(inputs["BIO_NG_RESOURCES_NAME"]))
		
			for i in 1:B
				newcap_BioNG[i] = value(EP[:vCapacity_BIO_NG_per_type][i]) * dfBioNG[!,:Biomass_energy_MMBtu_per_tonne][i] * dfBioNG[!,:Biorefinery_efficiency][i] * dfBioNG[!,:BioElectricity_fraction][i] * MMBtu_to_MWh
			end
		
			AnnualGen_BioNG = zeros(size(1:B))
			for i in 1:B
				AnnualGen_BioNG[i] = sum(inputs["omega"].* (value.(EP[:eBioNG_Power_credit_produced_MWh_per_plant_per_time])[i,:]))
			end
		
			MaxGen_BioNG = zeros(size(1:B))
			for i in 1:B
				MaxGen_BioNG[i] = value.(EP[:vCapacity_BIO_NG_per_type])[i] * dfBioNG[!,:Biomass_energy_MMBtu_per_tonne][i] * dfBioNG[!,:Biorefinery_efficiency][i] * dfBioNG[!,:BioElectricity_fraction][i] * MMBtu_to_MWh * 8760
			end
		
			CapFactor_BioNG = zeros(size(1:B))
			for i in 1:B
				if MaxGen_BioNG[i] == 0
					CapFactor_BioNG[i] = 0
				else
					CapFactor_BioNG[i] = AnnualGen_BioNG[i]/MaxGen_BioNG[i]
				end
			end
		
			for i in 1:B
				AnnualCO2Emissions_BioNG[i] = 0
			end
		
			dfBioNG_Cap = DataFrame(
				Resource = inputs["BIO_NG_RESOURCES_NAME"], Zone = dfBioNG[!,:Zone],
				StartCap = startcap_BioNG[:],
				RetCap = retcap_BioNG[:],
				NewCap = newcap_BioNG[:],
				EndCap = newcap_BioNG[:],
				StartEnergyCap = startenergycap_BioNG[:],
				RetEnergyCap = retenergycap_BioNG[:],
				NewEnergyCap = newenergycap_BioNG[:],
				EndEnergyCap = endenergycap_BioNG[:],
				StartChargeCap = startchargecap_BioNG[:],
				RetChargeCap = retchargecap_BioNG[:],
				NewChargeCap = newchargecap_BioNG[:],
				EndChargeCap = endchargecap_BioNG[:],
				MaxAnnualGeneration = MaxGen_BioNG[:],
				AnnualGeneration = AnnualGen_BioNG[:],
				CapacityFactor = CapFactor_BioNG[:],
				AnnualEmissions = AnnualCO2Emissions_BioNG[:]
			)
		
			StartCapTotal += sum(dfBioNG_Cap[!,:StartCap])
			RetCapTotal += sum(dfBioNG_Cap[!,:RetCap])
			NewCapTotal += sum(dfBioNG_Cap[!,:NewCap]) 
			EndCapTotal += sum(dfBioNG_Cap[!,:EndCap])
			StartEnergyCapTotal += sum(dfBioNG_Cap[!,:StartEnergyCap])
			RetEnergyCapTotal += sum(dfBioNG_Cap[!,:RetEnergyCap])
			NewEnergyCapTotal += sum(dfBioNG_Cap[!,:NewEnergyCap]) 
			EndEnergyCapTotal += sum(dfBioNG_Cap[!,:EndEnergyCap])
			StartChargeCapTotal += sum(dfBioNG_Cap[!,:StartChargeCap]) 
			RetChargeCapTotal += sum(dfBioNG_Cap[!,:RetChargeCap])
			NewChargeCapTotal += sum(dfBioNG_Cap[!,:NewChargeCap]) 
			EndChargeCapTotal += sum(dfBioNG_Cap[!,:EndChargeCap])
			MaxAnnualGenerationTotal += sum(dfBioNG_Cap[!,:MaxAnnualGeneration])
			AnnualGenerationTotal += sum(dfBioNG_Cap[!,:AnnualGeneration])
			AnnualEmissionsTotal += sum(dfBioNG_Cap[!,:AnnualEmissions])
		
			dfCap_Combined = vcat(dfCap_Combined, dfBioNG_Cap)
		end

	end

	total_combined = DataFrame(
			Resource = "Total", Zone = "n/a",
			StartCap = StartCapTotal, 
			RetCap = RetCapTotal,
			NewCap = NewCapTotal, 
			EndCap = EndCapTotal,
			StartEnergyCap = StartEnergyCapTotal, 
			RetEnergyCap = RetEnergyCapTotal,
			NewEnergyCap = NewEnergyCapTotal, 
			EndEnergyCap = EndEnergyCapTotal,
			StartChargeCap = StartChargeCapTotal, 
			RetChargeCap = RetChargeCapTotal,
			NewChargeCap = NewChargeCapTotal, 
			EndChargeCap = EndChargeCapTotal,
			MaxAnnualGeneration = MaxAnnualGenerationTotal, 
			AnnualGeneration = AnnualGenerationTotal,
			AnnualEmissions = AnnualEmissionsTotal,
			CapacityFactor = "-"
		)
	
	dfCap_Combined = vcat(dfCap_Combined, total_combined)

	CSV.write(joinpath(path, "capacity_multi_sector.csv"), dfCap_Combined)

	return dfCap_Power
end
