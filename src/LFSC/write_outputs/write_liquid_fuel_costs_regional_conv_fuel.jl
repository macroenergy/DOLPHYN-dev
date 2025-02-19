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
	write_liquid_fuel_costs_regional_conv_fuel(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for writing the cost for the different sectors of the liquid fuels supply chain (Synthetic fuel resources CAPEX and OPEX, different types of conventional gasoline, jetfuel, and diesel).
"""
function write_liquid_fuel_costs_regional_conv_fuel(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	## Cost results
	if setup["ModelSyntheticFuels"] == 1
		dfSynFuels= inputs["dfSynFuels"]
	end

	Z = inputs["Z"]     # Number of zones
	T = inputs["T"]     # Number of time steps (hours)

	dfSynFuelsCost = DataFrame(Costs = ["cSFTotal", "cSFFix", "cSFVar", "cSFByProdRev", "CSFConvDieselFuelCost","CSFConvJetfuelFuelCost","CSFConvGasolineFuelCost"])
	if setup["ModelSyntheticFuels"] == 1
		cSFVar = value(EP[:eTotalCSFProdVarOut])
		cSFFix = value(EP[:eFixed_Cost_Syn_Fuel_total])
		cSFByProdRev = - value(EP[:eTotalCSFByProdRevenueOut])
	else
		cSFVar = 0
		cSFFix = 0
		cSFByProdRev = 0
	end

	cSFConvDieselFuelCost = value(EP[:eTotalCLFDieselVarOut])
	cSFConvJetfuelFuelCost = value(EP[:eTotalCLFJetfuelVarOut])
	cSFConvGasolineFuelCost = value(EP[:eTotalCLFGasolineVarOut])

	if setup["CO2Cap"]==4 
        ErrorException("Carbon Price for SynFuels Not implemented")
    end

	# Adding emissions penalty to variable cost depending on type of emissions policy constraint
	# Emissions penalty is already scaled by adjusting the value of carbon price used in emissions_HSC.jl
	#if((setup["CO2Cap"]==4 && setup["SystemCO2Constraint"]==2)||(setup["H2CO2Cap"]==4 && setup["SystemCO2Constraint"]==1))
	#	cSFVar  = cSFVar + value(EP[:eCH2GenTotalEmissionsPenalty])
	#end
	 
    cSFTotal = cSFVar + cSFFix + cSFByProdRev + cSFConvDieselFuelCost + cSFConvJetfuelFuelCost + cSFConvGasolineFuelCost

    dfSynFuelsCost[!,Symbol("Total")] = [cSFTotal, cSFFix, cSFVar, cSFByProdRev, cSFConvDieselFuelCost, cSFConvJetfuelFuelCost, cSFConvGasolineFuelCost]

	for z in 1:Z
		tempCTotal = 0
		tempC_SF_Fix = 0
		tempC_SF_Var = 0
		tempC_SF_ByProd = 0

		if setup["Liquid_Fuels_Regional_Demand"] == 1
			tempCDieselConvFuel = sum(value.(EP[:eTotalCLFDieselVarOut_Z])[z,:])
			tempCJetfuelConvFuel = sum(value.(EP[:eTotalCLFJetfuelVarOut_Z])[z,:])
			tempCGasolineConvFuel = sum(value.(EP[:eTotalCLFGasolineVarOut_Z])[z,:])
		else
			tempCDieselConvFuel = "-"
			tempCJetfuelConvFuel = "-"
			tempCGasolineConvFuel = "-"
		end

		if setup["ModelSyntheticFuels"] == 1
			for y in dfSynFuels[dfSynFuels[!,:Zone].==z,:][!,:R_ID]
				tempC_SF_Fix = tempC_SF_Fix +
					value.(EP[:eFixed_Cost_Syn_Fuels_per_type])[y]

				tempC_SF_Var = tempC_SF_Var +
					sum(value.(EP[:eCSFProdVar_out])[y,:])

				tempC_SF_ByProd = tempC_SF_ByProd + -sum(value.(EP[:eTotalCSFByProdRevenueOutTK])[:,y])


				tempCTotal = tempCTotal +
						value.(EP[:eFixed_Cost_Syn_Fuels_per_type])[y] +
						sum(value.(EP[:eCSFProdVar_out])[y,:]) +
						-sum(value.(EP[:eTotalCSFByProdRevenueOutTK])[:,y]) 
			end
		end

		if setup["Liquid_Fuels_Regional_Demand"] == 1
			tempCTotal = tempCTotal +  tempCDieselConvFuel + tempCJetfuelConvFuel + tempCGasolineConvFuel
		end

		if setup["CO2Cap"]==4 
			ErrorException("Carbon Price for SynFuels Not implemented")
		end

		# Add emisions penalty related costs if the constraints are active
		#if((setup["CO2Cap"]==4 && setup["SystemCO2Constraint"]==2)||(setup["H2CO2Cap"]==4 && setup["SystemCO2Constraint"]==1))
		#	tempC_SF_Var  = tempC_SF_Var + value.(EP[:eCH2EmissionsPenaltybyZone])[z]
		#	tempCTotal = tempCTotal +value.(EP[:eCH2EmissionsPenaltybyZone])[z]
		#end

		dfSynFuelsCost[!,Symbol("Zone$z")] = [tempCTotal, tempC_SF_Fix, tempC_SF_Var, tempC_SF_ByProd, tempCDieselConvFuel, tempCJetfuelConvFuel, tempCGasolineConvFuel]
	end
	CSV.write(string(path,sep,"LF_costs.csv"), dfSynFuelsCost)
end
