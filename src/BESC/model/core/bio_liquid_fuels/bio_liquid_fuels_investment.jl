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
	bio_liquid_fuels_investment(EP::Model, inputs::Dict, setup::Dict)

Sets up constraints common to all biorefinery resources.

This function defines the expressions and constraints keeping track of total available biorefinery capacity $y_{r}^{\textrm{B,Bio}}$ based on its input biomass in tonne per hour as well as constraints on capacity.

The expression defined in this file named after ```vCapacity_BIO_LF_per_type``` covers all variables $y_{r}^{\textrm{B,Bio}}$.

The total capacity of each biorefinery resource is defined as the sum of newly invested capacity based on the assumption there are no existing biorefinery resources. 

**Cost expressions**

This module additionally defines contributions to the objective function from investment costs of biorefinery (fixed O\&M plus investment costs) from all resources $r \in \mathcal{R}$:

```math
\begin{equation*}
	\textrm{C}^{\textrm{Bio,c}} = \sum_{r \in \mathcal{R}} \sum_{z \in \mathcal{Z}} y_{r, z}^{\textrm{B,Bio}}\times \textrm{c}_{r}^{\textrm{Bio,INV}} + \sum_{r \in \mathcal{R}} \sum_{z \in \mathcal{Z}} y_{r, z}^{\textrm{B,Bio}} \times \textrm{c}_{r}^{\textrm{Bio,FOM}}
\end{equation*}
```

**Constraints on biorefinery resource capacity**

For resources where upper bound $\overline{y_{r}^{\textrm{B,Bio}}}$ and lower bound $\underline{y_{r}^{\textrm{B,Bio}}}$ of capacity is defined, then we impose constraints on minimum and maximum biorefinery resource input biomass capacity.

```math
\begin{equation*}
	\underline{y_{r}^{\textrm{B,Bio}}} \leq y_{r}^{\textrm{B,Bio}} \leq \overline{y_{r}^{\textrm{B,Bio}}} \quad \forall r \in \mathcal{R}
\end{equation*}
```
"""
function bio_liquid_fuels_investment(EP::Model, inputs::Dict, setup::Dict)
	
	println(" -- Bio Liquid Fuels Fixed Cost Module")

	dfBioLF = inputs["dfBioLF"]
	BIO_LF_RES_ALL = inputs["BIO_LF_RES_ALL"]
	
	#General variables for non-piecewise and piecewise cost functions
	@variable(EP,vCapacity_BIO_LF_per_type[i = 1:BIO_LF_RES_ALL])

	BIO_LF_Capacity_Min_Limit = dfBioLF[!,:Min_capacity_tonne_per_hr]
	BIO_LF_Capacity_Max_Limit = dfBioLF[!,:Max_capacity_tonne_per_hr]
	
	BIO_LF_Inv_Cost_per_tonne_per_hr_yr = dfBioLF[!,:Inv_Cost_per_tonne_per_hr_yr]
	BIO_LF_Fixed_OM_Cost_per_tonne_per_hr_yr = dfBioLF[!,:Fixed_OM_Cost_per_tonne_per_hr_yr]

	#Min and max capacity constraints
	@constraint(EP,cMinCapacity_per_unit_BIO_LF[i = 1:BIO_LF_RES_ALL], EP[:vCapacity_BIO_LF_per_type][i] >= BIO_LF_Capacity_Min_Limit[i])
	@constraint(EP,cMaxCapacity_per_unit_BIO_LF[i = 1:BIO_LF_RES_ALL], EP[:vCapacity_BIO_LF_per_type][i] <= BIO_LF_Capacity_Max_Limit[i])

	#Investment cost = CAPEX
	@expression(EP, eCAPEX_BIO_LF_per_type[i = 1:BIO_LF_RES_ALL], EP[:vCapacity_BIO_LF_per_type][i] * BIO_LF_Inv_Cost_per_tonne_per_hr_yr[i])

	#Fixed OM cost
	@expression(EP, eFixed_OM_BIO_LF_per_type[i = 1:BIO_LF_RES_ALL], EP[:vCapacity_BIO_LF_per_type][i] * BIO_LF_Fixed_OM_Cost_per_tonne_per_hr_yr[i])

	#Total fixed cost = CAPEX + Fixed OM
	@expression(EP, eFixed_Cost_BIO_LF_per_type[i = 1:BIO_LF_RES_ALL], EP[:eFixed_OM_BIO_LF_per_type][i] + EP[:eCAPEX_BIO_LF_per_type][i])

	#Total cost
	#Expression for total CAPEX for all resoruce types (For output)
	@expression(EP,eCAPEX_BIO_LF_total, sum(EP[:eCAPEX_BIO_LF_per_type][i] for i in 1:BIO_LF_RES_ALL))

	#Expression for total Fixed OM for all resoruce types (For output)
	@expression(EP,eFixed_OM_BIO_LF_total, sum(EP[:eFixed_OM_BIO_LF_per_type][i] for i in 1:BIO_LF_RES_ALL))

	#Expression for total Fixed Cost for all resoruce types (For output and to add to objective function)
	@expression(EP,eFixed_Cost_BIO_LF_total, sum(EP[:eFixed_Cost_BIO_LF_per_type][i] for i in 1:BIO_LF_RES_ALL))

	EP[:eObj] += EP[:eFixed_Cost_BIO_LF_total]

    return EP

end
