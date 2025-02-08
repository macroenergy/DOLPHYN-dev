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
	write_h2_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the costs of hydrogen supply chain pertaining to the objective function (fixed, variable O&M etc.).
"""
function write_h2_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	## Cost results
	dfH2Gen = inputs["dfH2Gen"]

	H = inputs["H2_RES_ALL"]
	H2_STOR_ALL = inputs["H2_STOR_ALL"] # Set of all h2 storage resources

	SEG = inputs["SEG"]  # Number of lines
	Z = inputs["Z"]     # Number of zones
	T = inputs["T"]     # Number of time steps (hours)
	H2_GEN_COMMIT = inputs["H2_GEN_COMMIT"] # H2 production technologies with unit commitment

	if setup["ModelH2G2P"] == 1
		dfH2G2P = inputs["dfH2G2P"]
		cG2PFix = value.(EP[:eTotalH2G2PCFix])
		cG2PVar = value.(EP[:eTotalCH2G2PVarOut])

		if !isempty(inputs["H2_G2P_COMMIT"])
			#cH2Start = value.(EP[:eTotalH2G2PCStart])
			cH2Start_G2P = value.(EP[:eTotalH2G2PCStart])
		else
			#cH2Start = 0
			cH2Start_G2P = 0
		end

	else
		cG2PFix = 0
		#cH2Start = 0
		cH2Start_G2P = 0
		cG2PVar = 0
	end

    if setup["ModelH2Trucks"] == 1
		cH2Fix_Truck = value.(EP[:eTotalCFixH2TruckChargePower]) + value.(EP[:eTotalCFixH2TruckNumber])
		cTruckVar = value.(EP[:OPEX_Truck]) + value.(EP[:OPEX_Truck_Compression])
	else
		cH2Fix_Truck = 0
		cTruckVar = 0
	end

	dfH2Cost = DataFrame(Costs = ["cH2Total", "cH2Fix_Gen", "cH2Fix_G2P", "cH2Fix_Stor", "cH2Fix_Truck", "cH2Var", "cH2NSE", "cH2Start", "cH2Start_G2P", "cNetworkExp"])

	cH2Var = (value(EP[:eTotalCH2GenVarOut])+ (!isempty(inputs["H2_FLEX"]) ? value(EP[:eTotalCH2VarFlexIn]) : 0)+ (!isempty(inputs["H2_STOR_ALL"]) ? value(EP[:eTotalCVarH2StorIn]) : 0))
	cH2Fix_Gen = value(EP[:eTotalH2GenCFix])
	cH2Fix_G2P = cG2PFix
	cH2Var_G2P = cG2PVar
	cH2Fix_Stor = ((!isempty(inputs["H2_STOR_ALL"]) ? value(EP[:eTotalCFixH2Energy]) + value(EP[:eTotalCFixH2Charge]) : 0))

	# Adding emissions penalty to variable cost depending on type of emissions policy constraint
	# Emissions penalty is already scaled by adjusting the value of carbon price used in emissions_HSC.jl
	if((setup["CO2Cap"]==4 && setup["SystemCO2Constraint"]==2)||(setup["H2CO2Cap"]==4 && setup["SystemCO2Constraint"]==1))
		cH2Var  = cH2Var + value(EP[:eCH2GenTotalEmissionsPenalty])
	end

	cH2Start = 0

	if !isempty(inputs["H2_GEN_COMMIT"])
		cH2Start += value(EP[:eTotalH2GenCStart])
	end

	if Z > 1
		if setup["ModelH2Pipelines"] == 1
			cH2NetworkExpCost = value(EP[:eCH2Pipe])
		else
			cH2NetworkExpCost=0
		end
	else
		cH2NetworkExpCost=0
	end

    cH2Total = cH2Var + cH2Fix_Gen + cH2Fix_G2P + cH2Fix_Stor + cH2Fix_Truck + cH2Start + cH2Start_G2P + value(EP[:eTotalH2CNSE]) + cH2NetworkExpCost

    dfH2Cost[!,Symbol("Total")] = [cH2Total, cH2Fix_Gen, cH2Fix_G2P, cH2Fix_Stor, cH2Fix_Truck, cH2Var, value(EP[:eTotalH2CNSE]), cH2Start, cH2Start_G2P, cH2NetworkExpCost]

	for z in 1:Z
		tempCTotal = 0
		tempC_H2_Fix_Gen = 0
		tempC_H2_Fix_G2P = 0
		tempC_H2_Var_G2P = 0
		tempC_H2_Fix_Stor = 0
		tempC_H2_Var = 0
		tempC_H2_Start = 0
		tempC_H2_Start_G2P = 0

		for y in intersect(inputs["H2_STOR_ALL"], dfH2Gen[dfH2Gen[!,:Zone].==z,:R_ID])
			tempC_H2_Fix_Stor = tempC_H2_Fix_Stor +
			(y in inputs["H2_STOR_ALL"] ? value.(EP[:eCFixH2Energy])[y] : 0) +
			(y in inputs["H2_STOR_ALL"] ? value.(EP[:eCFixH2Charge])[y] : 0)
		end

		for y in dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID]
			tempC_H2_Fix_Gen = tempC_H2_Fix_Gen +
				value.(EP[:eH2GenCFix])[y]
			tempC_H2_Var = tempC_H2_Var +
				(y in inputs["H2_STOR_ALL"] ? sum(value.(EP[:eCVarH2Stor_in])[y,:]) : 0) +
				(y in inputs["H2_FLEX"] ? sum(value.(EP[:eCH2VarFlex_in])[y,:]) : 0) +
				sum(value.(EP[:eCH2GenVar_out])[y,:])
			if !isempty(H2_GEN_COMMIT)
				tempCTotal = tempCTotal +
					value.(EP[:eH2GenCFix])[y] +
					(y in inputs["H2_STOR_ALL"] ? value.(EP[:eCFixH2Energy])[y] : 0) +
					(y in inputs["H2_STOR_ALL"] ? value.(EP[:eCFixH2Charge])[y] : 0) +
					(y in inputs["H2_STOR_ALL"] ? sum(value.(EP[:eCVarH2Stor_in])[y,:]) : 0) +
					(y in inputs["H2_FLEX"] ? sum(value.(EP[:eCH2VarFlex_in])[y,:]) : 0) +
					sum(value.(EP[:eCH2GenVar_out])[y,:]) +
					(y in inputs["H2_GEN_COMMIT"] ? sum(value.(EP[:eH2GenCStart])[y,:]) : 0)
				tempC_H2_Start = tempC_H2_Start +
					(y in inputs["H2_GEN_COMMIT"] ? sum(value.(EP[:eH2GenCStart])[y,:]) : 0)
			else
				tempCTotal = tempCTotal +
					value.(EP[:eH2GenCFix])[y] +
					(y in inputs["H2_STOR_ALL"] ? value.(EP[:eCFixH2Energy])[y] : 0) +
					(y in inputs["H2_STOR_ALL"] ? value.(EP[:eCFixH2Charge])[y] : 0) +
					(y in inputs["H2_STOR_ALL"] ? sum(value.(EP[:eCVarH2Stor_in])[y,:]) : 0) +
					(y in inputs["H2_FLEX"] ? sum(value.(EP[:eCH2VarFlex_in])[y,:]) : 0) +
					sum(value.(EP[:eCH2GenVar_out])[y,:])
			end
		end

		if setup["ModelH2G2P"] == 1
			for  y in dfH2G2P[dfH2G2P[!,:Zone].==z,:][!,:R_ID]

				tempC_H2_Fix_G2P += value.(EP[:eH2G2PCFix])[y]
				tempC_H2_Var_G2P += sum(value.(EP[:eCH2G2PVar_out])[y,:])
				tempCTotal += value.(EP[:eH2G2PCFix])[y] + sum(value.(EP[:eCH2G2PVar_out])[y,:])

				if !isempty(inputs["H2_G2P_COMMIT"])
					if y in inputs["H2_G2P_COMMIT"]
						tempC_H2_Start_G2P += value.(EP[:eTotalH2G2PCStartK])[y]
						tempCTotal += value.(EP[:eTotalH2G2PCStartK])[y]
					end
				else
					tempC_H2_Start_G2P = 0
				end
			end
		end

		# Add emisions penalty related costs if the constraints are active
		if((setup["CO2Cap"]==4 && setup["SystemCO2Constraint"]==2)||(setup["H2CO2Cap"]==4 && setup["SystemCO2Constraint"]==1))
			tempC_H2_Var  = tempC_H2_Var + value.(EP[:eCH2EmissionsPenaltybyZone])[z]
			tempCTotal = tempCTotal +value.(EP[:eCH2EmissionsPenaltybyZone])[z]
		end

		tempC_H2_NSE = sum(value.(EP[:eH2CNSE])[:,:,z])
		tempCTotal = tempCTotal + tempC_H2_NSE

		dfH2Cost[!,Symbol("Zone$z")] = [tempCTotal, tempC_H2_Fix_Gen, tempC_H2_Fix_G2P, tempC_H2_Fix_Stor, "-", tempC_H2_Var, tempC_H2_NSE, tempC_H2_Start, tempC_H2_Start_G2P, "-"]

end
	CSV.write(string(path, sep, "HSC_costs.csv"), dfH2Cost)
end
