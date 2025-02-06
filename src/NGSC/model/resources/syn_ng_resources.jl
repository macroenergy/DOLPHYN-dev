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
    syn_ng_resources(EP::Model, inputs::Dict, setup::Dict)

This module creates decision variables, expressions, and constraints related to synthetic gas resources.

This module defines the power consumption decision variable $x_{f,t}^{\textrm{E,Syn}} \forall f\in \mathcal{F}, t \in \mathcal{T}$, representing power consumed by synthetic gas resource $f$ at time period $t$.

The variable defined in this file named after ```vSyn_NG_Power_in``` cover variable $x_{f,t}^{E,Syn}$.

This module defines the hydrogen consumption decision variable $x_{f,t}^{\textrm{H,Syn}} \forall f\in \mathcal{F}, t \in \mathcal{T}$, representing hydrogen consumed by synthetic gas resource $f$ at time period $t$.

The variable defined in this file named after ```vSyn_NG_H2in``` cover variable $x_{f,t}^{H,Syn}$.

This module defines the synthetic gasoline, jetgas, and diesel production decision variables $x_{f,t}^{\textrm{Gasoline,Syn}} \forall f\in \mathcal{F}, t \in \mathcal{T}$, $x_{f,t}^{\textrm{Jetgas,Syn}} \forall f\in \mathcal{F}, t \in \mathcal{T}$, $x_{f,t}^{\textrm{Diesel,Syn}} \forall f\in \mathcal{F}, t \in \mathcal{T}$ representing  synthetic gasoline, jetgas, and diesel produced by resource $f$ at time period $t$.

The variables defined in this file named after ```vSyn_NG_Prod_Gasoline``` cover variable $x_{f,t}^{Gasoline,Syn}$, ```vSyn_NG_Prod_Jetgas``` cover variable $x_{f,t}^{Jetgas,Syn}$, and ```vSyn_NG_Prod``` cover variable $x_{f,t}^{Diesel,Syn}$.

**Maximum CO2 input to synthetic gas resource**

```math
\begin{equation*}
	x_{f,t}^{\textrm{C,Syn}} \leq  y_{f}^{\textrm{C,Syn}} \quad \forall f \in \mathcal{F}, t \in \mathcal{T}
\end{equation*}
```
"""
function syn_ng_resources(EP::Model, inputs::Dict, setup::Dict)

	println(" -- Synthetic NG Resources")

	dfSyn_NG = inputs["dfSyn_NG"]
    
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	SYN_NG_RES_ALL = inputs["SYN_NG_RES_ALL"]

	####Variables####
	#Define variables needed across both commit and no commit sets
    
    #Amount of Syn Gas Produced in MMBTU
	@variable(EP, vSyn_NG_Prod[k = 1:SYN_NG_RES_ALL, t = 1:T] >= 0 )

    #Hydrogen Required by Syn_NG Resource
    @variable(EP, vSyn_NG_H2in[k = 1:SYN_NG_RES_ALL, t = 1:T] >= 0 )

    #Power Required by Syn_NG Resource
    @variable(EP, vSyn_NG_Power_in[k = 1:SYN_NG_RES_ALL, t = 1:T] >= 0 )

	#################################################################################################################

	###Expressions###
	@expression(EP, eSyn_NG_Prod_Plant[k = 1:SYN_NG_RES_ALL, t=1:T], vSyn_NG_Prod[k,t])

    #Natural Gas Balance Expression
    @expression(EP, eSyn_NG_Prod[t=1:T, z=1:Z],
		sum(EP[:eSyn_NG_Prod_Plant][k,t] for k in intersect(1:SYN_NG_RES_ALL, dfSyn_NG[dfSyn_NG[!,:Zone].==z,:][!,:R_ID])))

    EP[:eSB_NG_Balance] += eSyn_NG_Prod #Add to syn + bio gas balance: For conv NG share policy
	EP[:eNGBalance] += eSyn_NG_Prod

	##################################################################################################################

	#H2 Balance expressions
	@expression(EP, eSyn_NG_H2_Cons[t=1:T, z=1:Z],
		sum(EP[:vSyn_NG_H2in][k,t] for k in intersect(1:SYN_NG_RES_ALL, dfSyn_NG[dfSyn_NG[!,:Zone].==z,:][!,:R_ID])))

	EP[:eH2Balance] -= eSyn_NG_H2_Cons

    #CO2 Balance Expression
    @expression(EP, eSyn_NG_CO2_Cons_Per_Time_Per_Zone[t=1:T, z=1:Z],
		sum(EP[:vSyn_NG_CO2in][k,t] for k in intersect(1:SYN_NG_RES_ALL, dfSyn_NG[dfSyn_NG[!,:Zone].==z,:][!,:R_ID])))

	@expression(EP, eSyn_NG_CO2_Cons_Per_Zone_Per_Time[z=1:Z, t=1:T],
		sum(EP[:vSyn_NG_CO2in][k,t] for k in intersect(1:SYN_NG_RES_ALL, dfSyn_NG[dfSyn_NG[!,:Zone].==z,:][!,:R_ID])))

	EP[:eCaptured_CO2_Balance] -= eSyn_NG_CO2_Cons_Per_Time_Per_Zone

	#Power Balance Expression
	@expression(EP, eSyn_NG_Power_Cons[t=1:T, z=1:Z],
		sum(EP[:vSyn_NG_Power_in][k,t] for k in intersect(1:SYN_NG_RES_ALL, dfSyn_NG[dfSyn_NG[!,:Zone].==z,:][!,:R_ID]))) 

	EP[:ePowerBalance] += -eSyn_NG_Power_Cons

	##################################################################################################################

	###Constraints###
	
	#Syn_NG Production Equal to CO2 in * Synf Gas Diesel Production to CO2 in Ratio
	@constraints(EP, begin 
	[k in 1:SYN_NG_RES_ALL, t = 1:T], EP[:vSyn_NG_Prod][k,t] == EP[:vSyn_NG_CO2in][k,t] * dfSyn_NG[!,:mmbtu_syn_ng_p_tonne_co2][k]
	end)

	#Hydrogen Consumption
	@constraints(EP, begin
	[k in 1:SYN_NG_RES_ALL, t = 1:T], EP[:vSyn_NG_H2in][k,t] == EP[:vSyn_NG_CO2in][k,t] * dfSyn_NG[!,:tonnes_h2_p_tonne_co2][k]
	end)

	#Power consumption associated with Syn Gas Production in each time step 
	@constraints(EP, begin
	[k in 1:SYN_NG_RES_ALL, t = 1:T], EP[:vSyn_NG_Power_in][k,t] == EP[:vSyn_NG_CO2in][k,t] * dfSyn_NG[!,:mwh_p_tonne_co2][k]
	end)

    # Production must be smaller than available capacity
	@constraints(EP, begin 
	[k in 1:SYN_NG_RES_ALL, t=1:T], EP[:vSyn_NG_CO2in][k,t] <= EP[:vCapacity_Syn_NG_per_type][k] 
	end)

	return EP
end
