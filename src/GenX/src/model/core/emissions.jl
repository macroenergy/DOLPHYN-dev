@doc raw"""
	emissions(EP::Model, inputs::Dict)

This function creates expression to add the CO2 emissions by plants in each zone, which is subsequently added to the total emissions
"""
function emissions!(EP::Model, inputs::Dict)

	println(" -- Emissions Module (for CO2 Policy modularization")

	dfGen = inputs["dfGen"]

	G = inputs["G"]     # Number of resources (generators, storage, DR, and DERs)
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	@expression(EP, eEmissionsByPlant[y=1:G,t=1:T],
		if y in inputs["COMMIT"]
			(dfGen[y,:CO2_per_MWh]*EP[:vP][y,t]+dfGen[y,:CO2_per_Start]*EP[:vSTART][y,t])*(1-dfGen[!, :CCS_Rate][y])
		else
			dfGen[y,:CO2_per_MWh]*EP[:vP][y,t]*(1-dfGen[!, :CCS_Rate][y])
		end
	)

	@expression(EP, eCO2CaptureByPlant[y = 1:G, t = 1:T],
        if y in inputs["COMMIT"]
			(dfGen[y,:CO2_per_MWh]*EP[:vP][y,t]+dfGen[y,:CO2_per_Start]*EP[:vSTART][y,t])*(dfGen[!, :CCS_Rate][y])
		else
			dfGen[y,:CO2_per_MWh]*EP[:vP][y,t]*(dfGen[!, :CCS_Rate][y])
		end
    )

	@expression(EP, ePower_CO2_captured_per_plant_per_time[y=1:G,t=1:T], EP[:eCO2CaptureByPlant][y,t])
	@expression(EP, ePower_CO2_captured_per_zone_per_time[z=1:Z, t=1:T], sum(ePower_CO2_captured_per_plant_per_time[y,t] for y in dfGen[(dfGen[!,:Zone].==z),:R_ID]))
	@expression(EP, ePower_CO2_captured_per_time_per_zone[t=1:T, z=1:Z], sum(ePower_CO2_captured_per_plant_per_time[y,t] for y in dfGen[(dfGen[!,:Zone].==z),:R_ID]))
	
	if setup["ModelNGSC"] == 1
		#If NGSC is modeled, not using fuel from the fuels input, so have to account for CO2 captured from CCS of NG utilization in plant separately
		@expression(EP, eNGCO2CaptureByPlant[y = 1:G, t = 1:T],
			if y in inputs["COMMIT"]
				(dfGen[y,:NG_MMBtu_per_MWh] * EP[:vP][y,t] + dfGen[y,:Start_NG_MMBTU_per_MW] * EP[:vSTART][y,t]) * inputs["ng_co2_per_mmbtu"] * (dfGen[!, :CCS_Rate][y])
			else
				dfGen[y,:NG_MMBtu_per_MWh] * EP[:vP][y,t] * inputs["ng_co2_per_mmbtu"] * (dfGen[!, :CCS_Rate][y])
			end
		)

		@expression(EP, ePower_NG_CO2_captured_per_plant_per_time[y=1:G,t=1:T], EP[:eNGCO2CaptureByPlant][y,t])
		@expression(EP, ePower_NG_CO2_captured_per_zone_per_time[z=1:Z, t=1:T], sum(ePower_NG_CO2_captured_per_plant_per_time[y,t] for y in dfGen[(dfGen[!,:Zone].==z),:R_ID]))
		@expression(EP, ePower_NG_CO2_captured_per_time_per_zone[t=1:T, z=1:Z], sum(ePower_NG_CO2_captured_per_plant_per_time[y,t] for y in dfGen[(dfGen[!,:Zone].==z),:R_ID]))

		### For output purpose only
		#Although CO2 emissions are accounted for in total NG utilization, we still want to show how much raw CO2 power sector (Before CCS) produces in the output files
		@expression(EP, eNGCO2EmissionByPlant[y = 1:G, t = 1:T],
			if y in inputs["COMMIT"]
				(dfGen[y,:NG_MMBtu_per_MWh] * EP[:vP][y,t] + dfGen[y,:Start_NG_MMBTU_per_MW] * EP[:vSTART][y,t]) * inputs["ng_co2_per_mmbtu"]
			else
				dfGen[y,:NG_MMBtu_per_MWh] * EP[:vP][y,t] * inputs["ng_co2_per_mmbtu"]
			end
		)

		@expression(EP, ePower_NG_CO2_emission_per_plant_per_time[y=1:G,t=1:T], EP[:eNGCO2EmissionByPlant][y,t])
		@expression(EP, ePower_NG_CO2_emission_per_zone_per_time[z=1:Z, t=1:T], sum(ePower_NG_CO2_emission_per_plant_per_time[y,t] for y in dfGen[(dfGen[!,:Zone].==z),:R_ID]))
	end

	@expression(EP, eEmissionsByZone[z=1:Z, t=1:T], sum(eEmissionsByPlant[y,t] for y in dfGen[(dfGen[!,:Zone].==z),:R_ID]))
	

end
