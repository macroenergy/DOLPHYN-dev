@doc raw"""
	write_capacity(path::AbstractString, inputs::Dict, setup::Dict, EP::Model))

Function for writing the diferent capacities for the different generation technologies (starting capacities or, existing capacities, retired capacities, and new-built capacities).
"""
function write_capacity(path::AbstractString, inputs::Dict, setup::Dict, EP::Model)
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
	if setup["ParameterScale"] ==1
		dfCap.StartCap = dfCap.StartCap * ModelScalingFactor
		dfCap.RetCap = dfCap.RetCap * ModelScalingFactor
		dfCap.NewCap = dfCap.NewCap * ModelScalingFactor
		dfCap.EndCap = dfCap.EndCap * ModelScalingFactor
		dfCap.StartEnergyCap = dfCap.StartEnergyCap * ModelScalingFactor
		dfCap.RetEnergyCap = dfCap.RetEnergyCap * ModelScalingFactor
		dfCap.NewEnergyCap = dfCap.NewEnergyCap * ModelScalingFactor
		dfCap.EndEnergyCap = dfCap.EndEnergyCap * ModelScalingFactor
		dfCap.StartChargeCap = dfCap.StartChargeCap * ModelScalingFactor
		dfCap.RetChargeCap = dfCap.RetChargeCap * ModelScalingFactor
		dfCap.NewChargeCap = dfCap.NewChargeCap * ModelScalingFactor
		dfCap.EndChargeCap = dfCap.EndChargeCap * ModelScalingFactor
		dfCap.MaxAnnualGeneration = dfCap.MaxAnnualGeneration * ModelScalingFactor
		dfCap.AnnualGeneration = dfCap.AnnualGeneration * ModelScalingFactor
		dfCap.AnnualEmissions = dfCap.AnnualEmissions * ModelScalingFactor
	end

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

	dfCap = vcat(dfCap, total)
	CSV.write(joinpath(path, "capacity.csv"), dfCap)
	return dfCap
end
