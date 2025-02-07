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
	DAC_var_cost(EP::Model, inputs::Dict, setup::Dict)

Sets up variables common to all direct air capture (DAC) resources.

This module defines the DAC decision variable $x_{d,z,t}^{\textrm{C,DAC}} \forall k \in \mathcal{K}, z \in \mathcal{Z}, t \in \mathcal{T}$, representing CO2 injected into the grid by DAC resource $d$ in zone $z$ at time period $t$.

The variable defined in this file named after ```vDAC\textunderscore{CO2}\textunderscore{Captured}``` covers all variables $x_{d,z,t}^{\textrm{C,DAC}}$.


**Cost expressions**

This module additionally defines contributions to the objective function from variable costs of generation (variable OM plus fuel cost) from all resources over all time periods.

```math
\begin{equation*}
	\textrm{C}^{\textrm{C,DAC,o}} = \sum_{d \in \mathcal{K}} \sum_{t \in \mathcal{T}} \omega_t \times \left(\textrm{c}_{d}^{\textrm{DAC,VOM}} + \textrm{c}_{d}^{\textrm{DAC,FUEL}}\right) \times x_{d,z,t}^{\textrm{C,DAC}}
\end{equation*}
```
"""
function DAC_var_cost(EP::Model, inputs::Dict, setup::Dict)

	println(" -- DAC Variable Cost Module")

    dfDAC = inputs["dfDAC"]
	DAC_RES_ALL = inputs["DAC_RES_ALL"]

	#Define sets
	T = inputs["T"]     # Number of time steps (hours)

	#####################################################################################################################################
	##Variables
	#CO2 captured from carbon capture resource k (tonnes of CO2/hr) in time t
	@variable(EP, vDAC_CO2_Captured[k=1:DAC_RES_ALL, t = 1:T] >= 0 )

	#Power required by carbon capture resource k (MW)
	@variable(EP, vPower_DAC[k=1:DAC_RES_ALL, t = 1:T] >= 0 )

	#Power produced by carbon capture resource k (MW)
	@variable(EP, vPower_Produced_DAC[k=1:DAC_RES_ALL, t = 1:T] >= 0 )

	#NG required by carbon capture resource k (MW)
	@variable(EP, vNG_DAC[k=1:DAC_RES_ALL, t = 1:T] >= 0 )

	#####################################################################################################################################
	##Expressions
	@expression(EP,eVar_OM_DAC_per_type_per_time[k=1:DAC_RES_ALL, t = 1:T], inputs["omega"][t] * (dfDAC[!,:Var_OM_Cost_per_tonne][k] + dfDAC[!,:etaFuel_MMBtu_per_tonne][k] * inputs["fuel_costs"][dfDAC[!,:Fuel][k]][t]) * EP[:vDAC_CO2_Captured][k,t] )


	#Total variable cost per resource type
	@expression(EP, eVar_OM_DAC_per_time[t=1:T], sum(EP[:eVar_OM_DAC_per_type_per_time][k,t] for k in 1:DAC_RES_ALL))
	
	@expression(EP, eVar_OM_DAC_per_type[k=1:DAC_RES_ALL], sum(EP[:eVar_OM_DAC_per_type_per_time][k,t] for t in 1:T))

	@expression(EP, eVar_OM_DAC, sum(EP[:eVar_OM_DAC_per_time][t] for t in 1:T))

	# Add total variable cost contribution to the objective function
	EP[:eObj] += EP[:eVar_OM_DAC]

	return EP

end
