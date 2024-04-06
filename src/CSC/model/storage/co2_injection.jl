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
	co2_injection(EP::Model, inputs::Dict,setup::Dict)

This module defines the CO2 injection decision variable $x_{s,z,t}^{\textrm{C,INJ}} \forall k \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}$, representing CO2 injected into storage resource $s$ in zone $z$ at time period $t$.

The variable defined in this file named after ```vDAC\textunderscore{CO2}\textunderscore{Injected}``` covers all variables $x_{s,z,t}^{\textrm{C,INJ}}$.

This module defines the power consumption decision variable $x_{z,t}^{\textrm{E,INJ}} \forall z\in \mathcal{Z}, t \in \mathcal{T}$, representing power consumed by CO2 injection in zone $z$ at time period $t$.

The variable defined in this file named after ```vPower\textunderscore{CO2}\textunderscore{Injection}``` cover variable $x_{z,t}^{E,INJ}$.

**Cost expressions**

This module additionally defines contributions to the objective function from variable costs of CO2 injection (variable OM) from all resources over all time periods.

```math
\begin{equation*}
	\textrm{C}^{\textrm{C,INJ,o}} = \sum_{s \in \mathcal{S}} \sum_{t \in \mathcal{T}} \omega_t \times \textrm{c}_{s}^{\textrm{INJ,VOM}} \times x_{s,z,t}^{\textrm{C,INJ}}
\end{equation*}
```

**Minimum and maximum injection output hourly**

For resources where upper bound $\overline{x_{s}^{\textrm{C,INJ}}}$ of injection rate is defined, then we impose constraints on minimum and maximum injection rate


```math
\begin{equation*}
	x_{s,z,t}^{\textrm{C,INJ}} \geq \underline{R_{s,z}^{\textrm{C,INJ}}} \times \overline{x_{s,z,t}^{\textrm{INJ}}} \quad \forall k \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

```math
\begin{equation*}
	x_{s,z,t}^{\textrm{C,INJ}} \leq \overline{R_{s,z}^{\textrm{C,INJ}}} \times \overline{x_{s,z,t}^{\textrm{INJ}}} \quad \forall k \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

**Maximum injection per year according to CO2 storage capacity per year**

```math
\begin{equation*}
	\sum_{t \in \mathcal{T}} x_{s,z,t}^{\textrm{C,INJ}} \leq y_{s,z}^{\textrm{C,STO}}
\end{equation*}
```
"""
function co2_injection(EP::Model, inputs::Dict,setup::Dict)

	#Rename CO2Storage dataframe
	dfCO2Storage = inputs["dfCO2Storage"]
	CO2_STOR_ALL = inputs["CO2_STOR_ALL"]

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	#####################################################################################################################################
	##Variables
	#CO2 injected into geological sequestration from carbon storage resource k (tonnes of CO2/hr) in time t
	@variable(EP, vCO2_Injected[k=1:CO2_STOR_ALL, t = 1:T] >= 0 )

	#Power required by carbon storage resource k (MW)
	@variable(EP, vPower_CO2_Injection[k=1:CO2_STOR_ALL, t = 1:T] >= 0 )
	
	###############################################################################################################################

	#Power Balance
	# If ParameterScale = 1, power system operation/capacity modeled in GW, no need to scale as MW/ton = GW/kton 
	# If ParameterScale = 0, power system operation/capacity modeled in MW

	@expression(EP, ePower_Balance_CO2_Storage[t=1:T, z=1:Z],
	sum(EP[:vPower_CO2_Injection][k,t] for k in dfCO2Storage[dfCO2Storage[!,:Zone].==z,:][!,:R_ID]))

	#Add to power balance to take power away from generated
	EP[:ePowerBalance_CSC] += -ePower_Balance_CO2_Storage

	##For CO2 Policy constraint right hand side development - power consumption by zone and each time step
	EP[:eCSCNetpowerConsumptionByAll] += ePower_Balance_CO2_Storage

	#CO2 Balance expressions
	@expression(EP, eStored_Captured_CO2[t=1:T, z=1:Z],
	sum(EP[:vCO2_Injected][k,t] for k in dfCO2Storage[(dfCO2Storage[!,:Zone].==z),:R_ID]))

	#ADD TO CO2 BALANCE
	EP[:eCaptured_CO2_Balance] -= eStored_Captured_CO2

	##Storage
	#Amount of carbon injected into geological sequestration in zone z at time t   
	@expression(EP, eCO2_Injected_per_zone[z=1:Z, t=1:T], sum(EP[:vCO2_Injected][k,t] for k in dfCO2Storage[(dfCO2Storage[!,:Zone].==z),:R_ID]))

	#Amount of carbon injected into geological sequestration in zone z at time t
	@expression(EP, eCO2_Injected_per_year[k=1:CO2_STOR_ALL], sum(inputs["omega"][t]*EP[:vCO2_Injected][k,t] for t in 1:T))

	###############################################################################################################################
	##Constraints
	#Power constraint
	@constraint(EP,cPower_Consumption_CO2_Storage[k=1:CO2_STOR_ALL, t = 1:T], EP[:vPower_CO2_Injection][k,t] == EP[:vCO2_Injected][k,t] * dfCO2Storage[!,:etaPCO2_MWh_per_tonne][k])

	#Max carbon injected into geological sequestration per resoruce type k
	@constraint(EP,cMax_CO2_Injected_per_type_per_year[k=1:CO2_STOR_ALL], EP[:eCO2_Injected_per_year][k] <= EP[:vCapacity_CO2_Storage_per_type][k])

	#Injection rate limit
	@constraint(EP,cMin_CO2_Injected_per_type_per_time[k=1:CO2_STOR_ALL, t=1:T], EP[:vCO2_Injected][k,t] >=  dfCO2Storage[!,:Max_injection_rate_tonne_per_hr][k] * dfCO2Storage[!,:CO2_Injection_Min_Output][k])
	@constraint(EP,cMax_CO2_Injected_per_type_per_time[k=1:CO2_STOR_ALL, t=1:T], EP[:vCO2_Injected][k,t] <=  dfCO2Storage[!,:Max_injection_rate_tonne_per_hr][k] * dfCO2Storage[!,:CO2_Injection_Max_Output][k])

	###############################################################################################################################

	#Variable Cost of CO2 Storage (Injection)
	if setup["ParameterScale"] ==1
		@expression(EP, eVar_OM_CO2_Injection_per_type_per_time[k = 1:CO2_STOR_ALL,t = 1:T], 
		(inputs["omega"][t] * (dfCO2Storage[!,:Var_OM_Cost_per_tonne][k]/ModelScalingFactor) * vCO2_Injected[k,t]))
    else
		@expression(EP, eVar_OM_CO2_Injection_per_type_per_time[k = 1:CO2_STOR_ALL,t = 1:T], 
		(inputs["omega"][t] * dfCO2Storage[!,:Var_OM_Cost_per_tonne][k] * vCO2_Injected[k,t]))
	end

	@expression(EP, eVar_OM_CO2_Injection_per_time[t=1:T], sum(eVar_OM_CO2_Injection_per_type_per_time[k,t] for k in 1:CO2_STOR_ALL))
	@expression(EP, eVar_OM_CO2_Injection_per_type[k = 1:CO2_STOR_ALL], sum(eVar_OM_CO2_Injection_per_type_per_time[k,t] for t in 1:T))
	@expression(EP, eVar_OM_CO2_Injection_total, sum(eVar_OM_CO2_Injection_per_time[t] for t in 1:T))
	
	# Add total variable cost to the objective function
	EP[:eObj] += eVar_OM_CO2_Injection_total

	return EP

end




