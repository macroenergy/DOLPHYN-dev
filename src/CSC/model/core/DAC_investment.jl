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
	DAC_investment(EP::Model, inputs::Dict, setup::Dict)

Sets up constraints common to all DAC resources.

This function defines the expressions and constraints keeping track of total available DAC CO2 capture capacity $y_{d}^{\textrm{C,DAC}}$ as well as constraints on capacity.

The expression defined in this file named after ```vCapacity\textunderscore{DAC}\textunderscore{per}\textunderscore{type}``` covers all variables $y_{d}^{\textrm{C,DAC}}$.

The total capacity of each DAC resource is defined as the sum of newly invested capacity based on the assumption there are no existing DAC resources. 

**Cost expressions**

This module additionally defines contributions to the objective function from investment costs of DAC (fixed O\&M plus investment costs) from all generation resources $d \in \mathcal{D}$:

```math
\begin{equation*}
	\textrm{C}^{\textrm{C,DAC,c}} = \sum_{d \in \mathcal{D}} \sum_{z \in \mathcal{Z}} y_{d, z}^{\textrm{C,DAC}}\times \textrm{c}_{d}^{\textrm{DAC,INV}} + \sum_{d \in \mathcal{D}} \sum_{z \in \mathcal{Z}} y_{g, z}^{\textrm{C,DAC,total}} \times \textrm{c}_{d}^{\textrm{DAC,FOM}}
\end{equation*}
```

**Constraints on DAC capacity**

For resources where upper bound $\overline{y_{d}^{\textrm{C,DAC}}}$ and lower bound $\underline{y_{d}^{\textrm{C,DAC}}}$ of capacity is defined, then we impose constraints on minimum and maximum capture capacity.

```math
\begin{equation*}
	\underline{y_{d}^{\textrm{C,DAC}}} \leq y_{d}^{\textrm{C,DAC}} \leq \overline{y_{d}^{\textrm{C,DAC}}} \quad \forall d \in \mathcal{D}
\end{equation*}
```
"""
function DAC_investment(EP::Model, inputs::Dict, setup::Dict)
	
	println(" -- DAC Fixed Cost Module")

	dfDAC = inputs["dfDAC"]
	DAC_RES_ALL = inputs["DAC_RES_ALL"]

	#General variables for non-piecewise and piecewise cost functions
	@variable(EP,vCapacity_DAC_per_type[i = 1:DAC_RES_ALL])

	DAC_Capacity_Min_Limit = dfDAC[!,:Min_capacity_tonne_per_hr] # t/h
	DAC_Capacity_Max_Limit = dfDAC[!,:Max_capacity_tonne_per_hr] # t/h
	DAC_Inv_Cost_per_tonne_per_hr_yr = dfDAC[!,:Inv_Cost_per_tonne_per_hr_yr]
	DAC_Fixed_OM_Cost_per_tonne_per_hr_yr = dfDAC[!,:Fixed_OM_Cost_per_tonne_per_hr_yr]

	#Investment cost = CAPEX
	@expression(EP, eCAPEX_DAC_per_type[i = 1:DAC_RES_ALL], EP[:vCapacity_DAC_per_type][i] * DAC_Inv_Cost_per_tonne_per_hr_yr[i])

	#Fixed OM cost
	@expression(EP, eFixed_OM_DAC_per_type[i = 1:DAC_RES_ALL], EP[:vCapacity_DAC_per_type][i] * DAC_Fixed_OM_Cost_per_tonne_per_hr_yr[i])

	#####################################################################################################################################
	#Min and max capacity constraints
	@constraint(EP,cMinCapacity_per_unit[i = 1:DAC_RES_ALL], EP[:vCapacity_DAC_per_type][i] >= DAC_Capacity_Min_Limit[i])

	# Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
	@constraint(EP, cMaxCapacity_per_unit[i = intersect(dfDAC[dfDAC.Max_capacity_tonne_per_hr.>0, :R_ID], 1:DAC_RES_ALL)], EP[:vCapacity_DAC_per_type][i] <= DAC_Capacity_Max_Limit[i])

	
	#####################################################################################################################################
	##Expressions
	#Cost per type of technology
	
	#Total fixed cost = CAPEX + Fixed OM
	@expression(EP, eFixed_Cost_DAC_per_type[i = 1:DAC_RES_ALL], EP[:eFixed_OM_DAC_per_type][i] + EP[:eCAPEX_DAC_per_type][i])
	
	#Total cost
	#Expression for total CAPEX for all resoruce types (For output and to add to objective function)
	@expression(EP,eCAPEX_DAC_total, sum(EP[:eCAPEX_DAC_per_type][i] for i in 1:DAC_RES_ALL))
	
	#Expression for total Fixed OM for all resoruce types (For output and to add to objective function)
	@expression(EP,eFixed_OM_DAC_total, sum(EP[:eFixed_OM_DAC_per_type][i] for i in 1:DAC_RES_ALL))
	
	#Expression for total Fixed Cost for all resoruce types (For output and to add to objective function)
	@expression(EP,eFixed_Cost_DAC_total, sum(EP[:eFixed_Cost_DAC_per_type][i] for i in 1:DAC_RES_ALL))
	
	EP[:eObj] += EP[:eFixed_Cost_DAC_total]

    return EP

end
