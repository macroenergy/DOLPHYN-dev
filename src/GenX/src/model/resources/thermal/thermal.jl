@doc raw"""
	thermal!(EP::Model, inputs::Dict, setup::Dict)
The thermal module creates decision variables, expressions, and constraints related to thermal power plants e.g. coal, oil or natural gas steam plants, natural gas combined cycle and combustion turbine plants, nuclear, hydrogen combustion etc.
This module uses the following 'helper' functions in separate files: ```thermal_commit()``` for thermal resources subject to unit commitment decisions and constraints (if any) and ```thermal_no_commit()``` for thermal resources not subject to unit commitment (if any).
"""
function thermal!(EP::Model, inputs::Dict, setup::Dict)
	dfGen = inputs["dfGen"]

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	THERM_COMMIT = inputs["THERM_COMMIT"]
	THERM_NO_COMMIT = inputs["THERM_NO_COMMIT"]
	THERM_ALL = inputs["THERM_ALL"]

	dfGen = inputs["dfGen"]

	if !isempty(THERM_COMMIT)
		thermal_commit!(EP, inputs, setup)
	end

	if !isempty(THERM_NO_COMMIT)
		thermal_no_commit!(EP, inputs, setup)
	end
	
	#NG required by thermal power generation resource y to make electricity (MMBtu)
    if setup["ModelNGSC"] == 1
        @variable(EP, vNG2P[y=THERM_ALL,t=1:T] >= 0 )

		@constraints(EP, begin
            #NG Balance
            [y in THERM_ALL, t in 1:T], EP[:vNG2P][y,t] == EP[:vP][y,t] * dfGen[!,:NG_MMBtu_per_MWh][y]
        end)

		@expression(EP, eNGBalanceElectricity[t=1:T, z=1:Z],
        sum(EP[:vNG2P][y,t] for y in intersect(THERM_ALL, dfGen[dfGen[!,:Zone].==z,:][!,:R_ID]))) 

        EP[:eNGBalance] -= eNGBalanceElectricity

        EP[:eElectricityNetNGConsumptionByAll] += eNGBalanceElectricity

		#NG required for plant startup
		@variable(EP, vNG_Start[y=THERM_COMMIT,t=1:T] >= 0 )

		@constraints(EP, begin
			#NG Start Balance
			[y in THERM_COMMIT, t in 1:T], EP[:vNG_Start][y,t] == EP[:vSTART][y,t] * dfGen[!,:Cap_Size][y] * dfGen[!,:Start_NG_MMBTU_per_MW][y]
		end)

		@expression(EP, eNGStartBalanceElectricity[t=1:T, z=1:Z],
        sum(EP[:vNG_Start][y,t] for y in intersect(THERM_COMMIT, dfGen[dfGen[!,:Zone].==z,:][!,:R_ID]))) 

        EP[:eNGBalance] -= eNGStartBalanceElectricity

        EP[:eElectricityNetNGConsumptionByAll] += eNGStartBalanceElectricity

    end

	##CO2 Polcy Module Thermal Generation by zone
	@expression(EP, eGenerationByThermAll[z=1:Z, t=1:T], # the unit is GW
		sum(EP[:vP][y,t] for y in intersect(inputs["THERM_ALL"], dfGen[dfGen[!,:Zone].==z,:R_ID]))
	)
	EP[:eGenerationByZone] += eGenerationByThermAll

	# Capacity Reserves Margin policy
	if setup["CapacityReserveMargin"] > 0
		@expression(EP, eCapResMarBalanceThermal[res=1:inputs["NCapacityReserveMargin"], t=1:T], sum(dfGen[y,Symbol("CapRes_$res")] * EP[:eTotalCap][y] for y in THERM_ALL))
		EP[:eCapResMarBalance] += eCapResMarBalanceThermal
	end

end
