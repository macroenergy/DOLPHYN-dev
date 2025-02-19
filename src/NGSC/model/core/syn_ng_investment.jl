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
	syn_ng_investment(EP::Model, inputs::Dict, setup::Dict)

Sets up constraints common to all synthetic gas resources.

This function defines the expressions and constraints keeping track of total available synthetic gas capacity $y_{f}^{\textrm{C,Syn}}$ based on its input CO2 in tonne per hour as well as constraints on capacity.

The expression defined in this file named after ```vCapacity_Syn_NG_per_type``` covers all variables $y_{f}^{\textrm{C,Syn}}$.

The total capacity of each synthetic gas resource is defined as the sum of newly invested capacity based on the assumption there are no existing synthetic gas resources. 

**Cost expressions**

This module additionally defines contributions to the objective function from investment costs of synthetic gas (fixed O\&M plus investment costs) from all generation resources $f \in \mathcal{F}$:

```math
\begin{equation*}
	\textrm{C}^{\textrm{LF,Syn,c}} = \sum_{f \in \mathcal{F}} \sum_{z \in \mathcal{Z}} y_{f, z}^{\textrm{C,Syn}}\times \textrm{c}_{f}^{\textrm{Syn,INV}} + \sum_{f \in \mathcal{F}} \sum_{z \in \mathcal{Z}} y_{f, z}^{\textrm{C,Syn}} \times \textrm{c}_{f}^{\textrm{Syn,FOM}}
\end{equation*}
```

**Constraints on synthetic gas resource capacity**

For resources where upper bound $\overline{y_{f}^{\textrm{C,Syn}}}$ and lower bound $\underline{y_{f}^{\textrm{C,Syn}}}$ of capacity is defined, then we impose constraints on minimum and maximum synthetic gas resource input CO2 capacity.

```math
\begin{equation*}
	\underline{y_{f}^{\textrm{C,Syn}}} \leq y_{f}^{\textrm{C,Syn}} \leq \overline{y_{f}^{\textrm{C,Syn}}} \quad \forall f \in \mathcal{F}
\end{equation*}
```
"""
function syn_ng_investment(EP::Model, inputs::Dict, setup::Dict)
	
	println(" -- Syn Gas Fixed Cost Module")

    dfSyn_NG = inputs["dfSyn_NG"]
	SYN_NG_RES_ALL = inputs["SYN_NG_RES_ALL"]

	##Load cost parameters

	#General variables
	@variable(EP,vCapacity_Syn_NG_per_type[i in 1:SYN_NG_RES_ALL]>=0) #Capacity of units in co2 input tonnes/hr 

	#Load capacity parameters
	MinCapacity_tonne_p_hr = dfSyn_NG[!,:MinCapacity_tonne_p_hr] # t/h
	MaxCapacity_tonne_p_hr = dfSyn_NG[!,:MaxCapacity_tonne_p_hr] # t/h/h
	Inv_Cost_p_tonne_co2_p_hr_yr = dfSyn_NG[!,:Inv_Cost_p_tonne_co2_p_hr_yr] # $/tonne
	Fixed_OM_cost_p_tonne_co2_hr_yr = dfSyn_NG[!,:Fixed_OM_cost_p_tonne_co2_hr_yr] # $/tonne

	#Linear CAPEX using refcapex similar to fixed O&M cost calculation method
	#Investment cost = CAPEX
	@expression(EP, eCAPEX_Syn_NG_per_type[i in 1:SYN_NG_RES_ALL], EP[:vCapacity_Syn_NG_per_type][i] * Inv_Cost_p_tonne_co2_p_hr_yr[i] )
	#Fixed OM cost #Check again to match capacity
	@expression(EP, eFixed_OM_Syn_NG_per_type[i in 1:SYN_NG_RES_ALL], EP[:vCapacity_Syn_NG_per_type][i] * Fixed_OM_cost_p_tonne_co2_hr_yr[i])

	#####################################################################################################################################
	#Min and max capacity constraints
	@constraint(EP,cMinSyn_NGCapacity_per_unit[i in 1:SYN_NG_RES_ALL], EP[:vCapacity_Syn_NG_per_type][i]  >= MinCapacity_tonne_p_hr[i])

	#Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
	@constraint(EP, cMaxSyn_NGCapacity_per_unit[i in intersect(dfSyn_NG[dfSyn_NG.MaxCapacity_tonne_p_hr.>0, :R_ID], 1:SYN_NG_RES_ALL)], EP[:vCapacity_Syn_NG_per_type][i] <= MaxCapacity_tonne_p_hr[i])

	#####################################################################################################################################
	##Expressions
	#Cost per type of technology
	
	#Total fixed cost = CAPEX + Fixed OM
	@expression(EP, eFixed_Cost_Syn_NG_per_type[i in 1:SYN_NG_RES_ALL], EP[:eFixed_OM_Syn_NG_per_type][i] + EP[:eCAPEX_Syn_NG_per_type][i])

	#Total cost
	#Expression for total CAPEX for all resoruce types (For output and to add to objective function)
	@expression(EP,eCAPEX_Syn_NG_total, sum(EP[:eCAPEX_Syn_NG_per_type][i] for i in 1:SYN_NG_RES_ALL))

	#Expression for total Fixed OM for all resoruce types (For output and to add to objective function)
	@expression(EP,eFixed_OM_Syn_NG_total, sum(EP[:eFixed_OM_Syn_NG_per_type][i] for i in 1:SYN_NG_RES_ALL))

	#Expression for total Fixed Cost for all resoruce types (For output and to add to objective function)
	@expression(EP,eFixed_Cost_Syn_NG_total, sum(EP[:eFixed_Cost_Syn_NG_per_type][i] for i in 1:SYN_NG_RES_ALL))

	# Add term to objective function expression
	EP[:eObj] += EP[:eFixed_Cost_Syn_NG_total]

    return EP

end