

@doc raw"""
	write_g2p_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the diferent capacities for the different hydrogen to power technologies (starting capacities or, existing capacities, retired capacities, and new-built capacities).
"""
function write_g2p_capacity(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	# Capacity decisions
	dfH2G2P = inputs["dfH2G2P"]::DataFrame
	H = inputs["H2_G2P_ALL"]::Int

	capdischarge = zeros(size(inputs["H2_G2P_NAME"]))
	for i in inputs["H2_G2P_NEW_CAP"]
		if i in inputs["H2_G2P_COMMIT"]
			capdischarge[i] = value(EP[:vH2G2PNewCap][i]) * dfH2G2P[!,:Cap_Size_MW][i]
		else
			capdischarge[i] = value(EP[:vH2G2PNewCap][i])
		end
	end

	retcapdischarge = zeros(size(inputs["H2_G2P_NAME"]))
	for i in inputs["H2_G2P_RET_CAP"]
		if i in inputs["H2_G2P_COMMIT"]
			retcapdischarge[i] = first(value.(EP[:vH2G2PRetCap][i])) * dfH2G2P[!,:Cap_Size_MW][i]
		else
			retcapdischarge[i] = first(value.(EP[:vH2G2PRetCap][i]))
		end
	end

	startenergycap = zeros(size(1:inputs["H2_G2P_ALL"]))
	for i in 1:H
		startenergycap[i] = 0
	end

	retenergycap = zeros(size(1:inputs["H2_G2P_ALL"]))
	for i in 1:H
		retenergycap[i] = 0
	end

	newenergycap = zeros(size(1:inputs["H2_G2P_ALL"]))
	for i in 1:H
		newenergycap[i] = 0
	end

	endenergycap = zeros(size(1:inputs["H2_G2P_ALL"]))
	for i in 1:H
		endenergycap[i] = 0
	end

	startchargecap = zeros(size(1:inputs["H2_G2P_ALL"]))
	for i in 1:H
		startchargecap[i] = 0
	end

	retchargecap = zeros(size(1:inputs["H2_G2P_ALL"]))
	for i in 1:H
		retchargecap[i] = 0
	end

	newchargecap = zeros(size(1:inputs["H2_G2P_ALL"]))
	for i in 1:H
		newchargecap[i] = 0
	end

	endchargecap = zeros(size(1:inputs["H2_G2P_ALL"]))
	for i in 1:H
		endchargecap[i] = 0
	end

	MaxGen = zeros(size(1:inputs["H2_G2P_ALL"]))
	for i in 1:H
		MaxGen[i] = value.(EP[:eH2G2PTotalCap])[i] * 8760
	end

	AnnualGen = zeros(size(1:inputs["H2_G2P_ALL"]))
	for i in 1:H
		AnnualGen[i] = sum(inputs["omega"].* (value.(EP[:vPG2P])[i,:]))
	end

	CapFactor = zeros(size(1:inputs["H2_G2P_ALL"]))
	for i in 1:H
		if MaxGen[i] == 0
			CapFactor[i] = 0
		else
			CapFactor[i] = AnnualGen[i]/MaxGen[i]
		end
	end

	

	dfCap = DataFrame(
		Resource = inputs["H2_G2P_NAME"], Zone = dfH2G2P[!,:Zone],
		StartCap = dfH2G2P[!,:Existing_Cap_MW],
		RetCap = retcapdischarge[:],
		NewCap = capdischarge[:],
		EndCap = value.(EP[:eH2G2PTotalCap]),
		StartEnergyCap = startenergycap[:],
		RetEnergyCap = retenergycap[:],
		NewEnergyCap = newenergycap[:],
		EndEnergyCap = endenergycap[:],
		StartChargeCap = startchargecap[:],
		RetChargeCap = retchargecap[:],
		NewChargeCap = newchargecap[:],
		EndChargeCap = endchargecap[:],
		MaxAnnualGeneration = MaxGen[:],
		AnnualGeneration = AnnualGen[:],
		CapacityFactor = CapFactor[:]
	)


	total = DataFrame(
			Resource = "Total", Zone = "n/a",
			StartCap = sum(dfCap[!,:StartCap]), RetCap = sum(dfCap[!,:RetCap]),
			NewCap = sum(dfCap[!,:NewCap]), EndCap = sum(dfCap[!,:EndCap]),
			StartEnergyCap = sum(dfCap[!,:StartEnergyCap]), RetEnergyCap = sum(dfCap[!,:RetEnergyCap]),
			NewEnergyCap = sum(dfCap[!,:NewEnergyCap]),EndEnergyCap = sum(dfCap[!,:EndEnergyCap]),
			StartChargeCap = sum(dfCap[!,:StartChargeCap]), RetChargeCap = sum(dfCap[!,:RetChargeCap]),
			NewChargeCap = sum(dfCap[!,:NewChargeCap]),EndChargeCap = sum(dfCap[!,:EndChargeCap]),
			MaxAnnualGeneration = sum(dfCap[!,:MaxAnnualGeneration]), AnnualGeneration = sum(dfCap[!,:AnnualGeneration]),
			CapacityFactor = "-"
		)

	dfCap = vcat(dfCap, total)
	CSV.write(string(path,sep,"HSC_g2p_capacity.csv"), dfCap)
	return dfCap
end