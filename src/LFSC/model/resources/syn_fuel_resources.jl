"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
Copyright (C) 2021,  Massachusetts Institute of Technology
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
    syn_fuel_resources(EP::Model, inputs::Dict, setup::Dict)

This module creates decision variables, expressions, and constraints related to synthetic fuels resources.

This module defines the power consumption decision variable $x_{f,t}^{\textrm{E,Syn}} \forall f\in \mathcal{F}, t \in \mathcal{T}$, representing power consumed by synthetic fuels resource $f$ at time period $t$.

The variable defined in this file named after ```vSFPin``` cover variable $x_{f,t}^{E,Syn}$.

This module defines the hydrogen consumption decision variable $x_{f,t}^{\textrm{H,Syn}} \forall f\in \mathcal{F}, t \in \mathcal{T}$, representing hydrogen consumed by synthetic fuels resource $f$ at time period $t$.

The variable defined in this file named after ```vSFH2in``` cover variable $x_{f,t}^{H,Syn}$.

This module defines the synthetic gasoline, jetfuel, and diesel production decision variables $x_{f,t}^{\textrm{Gasoline,Syn}} \forall f\in \mathcal{F}, t \in \mathcal{T}$, $x_{f,t}^{\textrm{Jetfuel,Syn}} \forall f\in \mathcal{F}, t \in \mathcal{T}$, $x_{f,t}^{\textrm{Diesel,Syn}} \forall f\in \mathcal{F}, t \in \mathcal{T}$ representing  synthetic gasoline, jetfuel, and diesel produced by resource $f$ at time period $t$.

The variables defined in this file named after ```vSFProd_Gasoline``` cover variable $x_{f,t}^{Gasoline,Syn}$, ```vSFProd_Jetfuel``` cover variable $x_{f,t}^{Jetfuel,Syn}$, and ```vSFProd_Diesel``` cover variable $x_{f,t}^{Diesel,Syn}$.

**Maximum CO2 input to synthetic fuels resource**

```math
\begin{equation*}
	x_{f,t}^{\textrm{C,Syn}} \leq  y_{f}^{\textrm{C,Syn}} \quad \forall f \in \mathcal{F}, t \in \mathcal{T}
\end{equation*}
```
"""
function syn_fuel_resources(EP::Model, inputs::Dict, setup::Dict)

	#Rename H2Gen dataframe
	dfSynFuels = inputs["dfSynFuels"]
    dfSynFuelsByProdExcess = inputs["dfSynFuelsByProdExcess"]

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

    NSFByProd = inputs["NSFByProd"]
	SYN_FUELS_RES_ALL = inputs["SYN_FUELS_RES_ALL"]

	####Variables####
	#Define variables needed across both commit and no commit sets
    
    #Amount of Syn Fuel Produced, in MMBTU
	@variable(EP, vSFProd_Diesel[k = 1:SYN_FUELS_RES_ALL, t = 1:T] >= 0 )
	@variable(EP, vSFProd_Jetfuel[k = 1:SYN_FUELS_RES_ALL, t = 1:T] >= 0 )
	@variable(EP, vSFProd_Gasoline[k = 1:SYN_FUELS_RES_ALL, t = 1:T] >= 0 )

    #Hydrogen Required by SynFuel Resource, in MWh
    @variable(EP, vSFH2in[k = 1:SYN_FUELS_RES_ALL, t = 1:T] >= 0 )
    #Power Required by SynFuel Resource, in MWh
    @variable(EP, vSFPin[k = 1:SYN_FUELS_RES_ALL, t = 1:T] >= 0 )

	###Expressions###
	
    #Liquid Fuel Balance Expression
    @expression(EP, eSynFuelProd_Diesel[t=1:T, z=1:Z],
		sum(EP[:vSFProd_Diesel][k,t] for k in intersect(1:SYN_FUELS_RES_ALL, dfSynFuels[dfSynFuels[!,:Zone].==z,:][!,:R_ID])))

	@expression(EP, eSynFuelProd_Jetfuel[t=1:T, z=1:Z],
		sum(EP[:vSFProd_Jetfuel][k,t] for k in intersect(1:SYN_FUELS_RES_ALL, dfSynFuels[dfSynFuels[!,:Zone].==z,:][!,:R_ID])))

	@expression(EP, eSynFuelProd_Gasoline[t=1:T, z=1:Z],
    	sum(EP[:vSFProd_Gasoline][k,t] for k in intersect(1:SYN_FUELS_RES_ALL, dfSynFuels[dfSynFuels[!,:Zone].==z,:][!,:R_ID])))

    EP[:eLFDieselBalance] += eSynFuelProd_Diesel
	EP[:eLFJetfuelBalance] += eSynFuelProd_Jetfuel
	EP[:eLFGasolineBalance] += eSynFuelProd_Gasoline

	#H2 Balance expressions
	@expression(EP, eSynFuelH2Cons[t=1:T, z=1:Z],
		sum(EP[:vSFH2in][k,t] for k in intersect(1:SYN_FUELS_RES_ALL, dfSynFuels[dfSynFuels[!,:Zone].==z,:][!,:R_ID])))

	EP[:eH2Balance_LFSC] -= eSynFuelH2Cons

    #CO2 Balance Expression
    @expression(EP, eSynFuelCO2Cons_Per_Time_Per_Zone[t=1:T, z=1:Z],
		sum(EP[:vSFCO2in][k,t] for k in intersect(1:SYN_FUELS_RES_ALL, dfSynFuels[dfSynFuels[!,:Zone].==z,:][!,:R_ID])))

	@expression(EP, eSynFuelCO2Cons_Per_Zone_Per_Time[z=1:Z, t=1:T],
		sum(EP[:vSFCO2in][k,t] for k in intersect(1:SYN_FUELS_RES_ALL, dfSynFuels[dfSynFuels[!,:Zone].==z,:][!,:R_ID])))

	EP[:eCaptured_CO2_Balance] -= eSynFuelCO2Cons_Per_Time_Per_Zone

	#Power Balance Expression
	@expression(EP, ePowerBalanceSynFuelRes[t=1:T, z=1:Z],
		sum(EP[:vSFPin][k,t] for k in intersect(1:SYN_FUELS_RES_ALL, dfSynFuels[dfSynFuels[!,:Zone].==z,:][!,:R_ID]))) 

	EP[:ePowerBalance_LFSC] += -ePowerBalanceSynFuelRes

	###Constraints###
	if setup["ParameterScale"] ==1
		#SynFuel Diesel Production Equal to CO2 in * Synf Fuel Diesel Production to CO2 in Ratio (change mmbtu/tonne CO2 to mmbtu/ktonne CO2)
		@constraints(EP, begin 
			[k in 1:SYN_FUELS_RES_ALL, t = 1:T], EP[:vSFProd_Diesel][k,t] == EP[:vSFCO2in][k,t] * dfSynFuels[!,:mmbtu_sf_diesel_p_tonne_co2][k] * ModelScalingFactor
		end)

		#SynFuel Jetfuel Production Equal to CO2 in * Synf Fuel Jetfuel Production to CO2 in Ratio (change mmbtu/tonne CO2 to mmbtu/ktonne CO2)
		@constraints(EP, begin 
			[k in 1:SYN_FUELS_RES_ALL, t = 1:T], EP[:vSFProd_Jetfuel][k,t] == EP[:vSFCO2in][k,t] * dfSynFuels[!,:mmbtu_sf_jetfuel_p_tonne_co2][k] * ModelScalingFactor
		end)

		#SynFuel Gasoline Production Equal to CO2 in * Synf Fuel Gasoline Production to CO2 in Ratio (change mmbtu/tonne CO2 to mmbtu/ktonne CO2)
			@constraints(EP, begin 
			[k in 1:SYN_FUELS_RES_ALL, t = 1:T], EP[:vSFProd_Gasoline][k,t] == EP[:vSFCO2in][k,t] * dfSynFuels[!,:mmbtu_sf_gasoline_p_tonne_co2][k] * ModelScalingFactor
		end)

		#Hydrogen Consumption (change MWh H2 / tonne CO2 to MWh H2/ktonne CO2 since H2 is not scaled in HSC)
		@constraints(EP, begin
		[k in 1:SYN_FUELS_RES_ALL, t = 1:T], EP[:vSFH2in][k,t] == EP[:vSFCO2in][k,t] * dfSynFuels[!,:mwh_h2_p_tonne_co2][k] * ModelScalingFactor
		end)

		# By-product produced constraint (change mmbtu/tonne CO2 to mmbtu/ktonne CO2)
		@constraints(EP, begin
		[k in 1:SYN_FUELS_RES_ALL, b in 1:NSFByProd, t=1:T], EP[:vSFByProd][k, b, t] == EP[:vSFCO2in][k,t] * dfSynFuelsByProdExcess[:,b][k] * ModelScalingFactor
		end)

	else
		#SynFuel Diesel Production Equal to CO2 in * Synf Fuel Diesel Production to CO2 in Ratio
		@constraints(EP, begin 
		[k in 1:SYN_FUELS_RES_ALL, t = 1:T], EP[:vSFProd_Diesel][k,t] == EP[:vSFCO2in][k,t] * dfSynFuels[!,:mmbtu_sf_diesel_p_tonne_co2][k]
		end)

		#SynFuel Jetfuel Production Equal to CO2 in * Synf Fuel Jetfuel Production to CO2 in Ratio (change mmbtu/tonne CO2 to mmbtu/ktonne CO2)
		@constraints(EP, begin 
			[k in 1:SYN_FUELS_RES_ALL, t = 1:T], EP[:vSFProd_Jetfuel][k,t] == EP[:vSFCO2in][k,t] * dfSynFuels[!,:mmbtu_sf_jetfuel_p_tonne_co2][k]
		end)

		#SynFuel Gasoline Production Equal to CO2 in * Synf Fuel Gasoline Production to CO2 in Ratio (change mmbtu/tonne CO2 to mmbtu/ktonne CO2)
			@constraints(EP, begin 
			[k in 1:SYN_FUELS_RES_ALL, t = 1:T], EP[:vSFProd_Gasoline][k,t] == EP[:vSFCO2in][k,t] * dfSynFuels[!,:mmbtu_sf_gasoline_p_tonne_co2][k]
		end)

		#Hydrogen Consumption, in MWh
		@constraints(EP, begin
		[k in 1:SYN_FUELS_RES_ALL, t = 1:T], EP[:vSFH2in][k,t] == EP[:vSFCO2in][k,t] * dfSynFuels[!,:mwh_h2_p_tonne_co2][k]
		end)

		# By-product produced constraint
		@constraints(EP, begin
		[k in 1:SYN_FUELS_RES_ALL, b in 1:NSFByProd, t=1:T], EP[:vSFByProd][k, b, t] == EP[:vSFCO2in][k,t] * dfSynFuelsByProdExcess[:,b][k]
		end)
	end

	#Power and natural gas consumption associated with Syn Fuel Production in each time step (no change to MW/tonne CO2 to GW/ktonne CO2 when parameter scaling = 1)	 
	@constraints(EP, begin
	[k in 1:SYN_FUELS_RES_ALL, t = 1:T], EP[:vSFPin][k,t] == EP[:vSFCO2in][k,t] * dfSynFuels[!,:mwh_p_tonne_co2][k]
	end)


    # Production must be smaller than available capacity
	@constraints(EP, begin [k in 1:SYN_FUELS_RES_ALL, t=1:T], EP[:vSFCO2in][k,t] <= EP[:vCapacity_Syn_Fuel_per_type][k] end)

	return EP
end
