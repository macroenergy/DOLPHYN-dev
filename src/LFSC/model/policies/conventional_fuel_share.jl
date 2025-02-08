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
	conventional_fuel_share(EP::Model, inputs::Dict, setup::Dict)

This function establishes constraints that can be flexibily applied to define alternative forms of policies that require generation of a quantity of conventional fuel in the entire system across the entire year, and also the min and max ratio between conventional fuels

	"""
function conventional_fuel_share(EP::Model, inputs::Dict, setup::Dict)
	println(" -- Conventional Fuel Share and Ratio Requirement Policies Module")
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	#Calculate total conventional fuels according to resolution settings (Regional/Global or Hourly/Annual)
	if setup["Liquid_Fuels_Regional_Demand"] == 1 && setup["Liquid_Fuels_Hourly_Demand"] == 1
		@expression(EP, AnnualeGlobalConvGasoline, sum(sum(inputs["omega"][t] * EP[:eCFGasolineBalance][t,z] for z = 1:Z) for t = 1:T))
		@expression(EP, AnnualeGlobalConvJetfuel, sum(sum(inputs["omega"][t] * EP[:eCFJetfuelBalance][t,z] for z = 1:Z) for t = 1:T))
		@expression(EP, AnnualeGlobalConvDiesel, sum(sum(inputs["omega"][t] * EP[:eCFDieselBalance][t,z] for z = 1:Z) for t = 1:T))
	
	elseif setup["Liquid_Fuels_Regional_Demand"] == 1 && setup["Liquid_Fuels_Hourly_Demand"] == 0
		@expression(EP, AnnualeGlobalConvGasoline, sum(EP[:eCFGasolineBalance][z] for z = 1:Z))
		@expression(EP, AnnualeGlobalConvJetfuel, sum(EP[:eCFJetfuelBalance][z] for z = 1:Z))
		@expression(EP, AnnualeGlobalConvDiesel, sum(EP[:eCFDieselBalance][z] for z = 1:Z))

	elseif setup["Liquid_Fuels_Regional_Demand"] == 0 && setup["Liquid_Fuels_Hourly_Demand"] == 1
		@expression(EP, AnnualeGlobalConvGasoline, sum(inputs["omega"][t] * EP[:eCFGasolineBalance][t] for t = 1:T))
		@expression(EP, AnnualeGlobalConvJetfuel, sum(inputs["omega"][t] * EP[:eCFJetfuelBalance][t] for t = 1:T))
		@expression(EP, AnnualeGlobalConvDiesel, sum(inputs["omega"][t] * EP[:eCFDieselBalance][t] for t = 1:T))

	elseif setup["Liquid_Fuels_Regional_Demand"] == 0 && setup["Liquid_Fuels_Hourly_Demand"] == 0
		@expression(EP, AnnualeGlobalConvGasoline, EP[:eCFGasolineBalance])
		@expression(EP, AnnualeGlobalConvJetfuel, EP[:eCFJetfuelBalance])
		@expression(EP, AnnualeGlobalConvDiesel, EP[:eCFDieselBalance])

	end


	######## Conventional Fuels Ratio Requirement

	#Min and max ratio of conventional Jet fuel to conventional Gasoline
	Conv_Jetfuel_to_Gasoline_Ratio_Min = setup["Conv_Jetfuel_to_Gasoline_Ratio_Min"]
	Conv_Jetfuel_to_Gasoline_Ratio_Max = setup["Conv_Jetfuel_to_Gasoline_Ratio_Max"]

	#Min and max ratio of conventional Diesel to conventional Gasoline
	Conv_Diesel_to_Gasoline_Ratio_Min = setup["Conv_Diesel_to_Gasoline_Ratio_Min"]
	Conv_Diesel_to_Gasoline_Ratio_Max = setup["Conv_Diesel_to_Gasoline_Ratio_Max"]


	if setup["Conv_Jetfuel_to_Gasoline_ratio"] == 1

		@constraint(EP, cMin_Conv_Jetfuel_to_Gasoline, AnnualeGlobalConvJetfuel >=  Conv_Jetfuel_to_Gasoline_Ratio_Min * AnnualeGlobalConvGasoline)
		@constraint(EP, cMax_Conv_Jetfuel_to_Gasoline, AnnualeGlobalConvJetfuel <=  Conv_Jetfuel_to_Gasoline_Ratio_Max * AnnualeGlobalConvGasoline)

	end

	if setup["Conv_Diesel_to_Gasoline_ratio"] == 1
		
		@constraint(EP, cMin_Conv_Diesel_to_Gasoline, AnnualeGlobalConvDiesel >=  Conv_Diesel_to_Gasoline_Ratio_Min * AnnualeGlobalConvGasoline)
		@constraint(EP, cMax_Conv_Diesel_to_Gasoline, AnnualeGlobalConvDiesel <=  Conv_Diesel_to_Gasoline_Ratio_Max * AnnualeGlobalConvGasoline)

	end

	######## Conventional Fuels Share Requirement

	#Share of conventional fuels in total fuels (synthetic + bio + conv)
	Conv_Diesel_Share = setup["Conv_Diesel_Share"]
	Conv_Jetfuel_Share = setup["Conv_Jetfuel_Share"]
	Conv_Gasoline_Share = setup["Conv_Gasoline_Share"]

	### Gasoline
	if setup["Conventional_Gasoline_Share_Requirement"] == 1

		## Conventional Gasoline Share Requirements
		@expression(EP, eAnnualGlobalSBGasoline, sum(sum(inputs["omega"][t] * EP[:eSBFGasolineBalance][t,z] for z = 1:Z) for t = 1:T))
		@constraint(EP, cConvGasolineShare, (1-Conv_Gasoline_Share) * EP[:AnnualeGlobalConvGasoline] == Conv_Gasoline_Share * EP[:eAnnualGlobalSBGasoline])
	
	end

	### Jetfuel
	if setup["Conventional_Jetfuel_Share_Requirement"] == 1

		## Conventional Jetfuel Share Requirements
		@expression(EP, eAnnualGlobalSBJetfuel, sum(sum(inputs["omega"][t] * EP[:eSBFJetfuelBalance][t,z] for z = 1:Z) for t = 1:T))
		@constraint(EP, cConvJetfuelShare, (1-Conv_Jetfuel_Share) * EP[:AnnualeGlobalConvJetfuel] == Conv_Jetfuel_Share * EP[:eAnnualGlobalSBJetfuel])
	
	end

	### Diesel
	if setup["Conventional_Diesel_Share_Requirement"] == 1

		## Conventional Diesel Share Requirements
		@expression(EP, eAnnualGlobalSBDiesel, sum(sum(inputs["omega"][t] * EP[:eSBFDieselBalance][t,z] for z = 1:Z) for t = 1:T))
		@constraint(EP, cConvDieselShare, (1-Conv_Diesel_Share) * EP[:AnnualeGlobalConvDiesel] == Conv_Diesel_Share * EP[:eAnnualGlobalSBDiesel])

	end
	
	return EP
end
