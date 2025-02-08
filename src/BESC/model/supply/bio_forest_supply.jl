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
    bio_forest_supply(EP::Model, inputs::Dict, setup::Dict)

Sets up forest biomass variables

This module defines the forest biomass resource decision variable $x_{z,t}^{\textrm{B,Forest}} \forall z \in \mathcal{Z}, t \in \mathcal{T}$, representing forest biomass utilized in zone $z$ at time period $t$. 

The variables defined in this file named after ```vForest_biomass_purchased_per_zone_per_time``` covers all variables $x_{z,t}^{\textrm{B,Forest}}$.

**Cost expressions**

This module additionally defines contributions to the objective function from variable costs of generation (variable OM) from forest biomass supply over all time periods.

```math
\begin{equation*}
	\textrm{C}^{\textrm{Forest,o}} = \sum_{z \in \mathcal{Z}} \sum_{t \in \mathcal{T}} \omega_t \times \textrm{c}_{r}^{\textrm{Forest,VOM}} \times x_{z,t}^{\textrm{B,Forest}}
\end{equation*}
```	

**Maximum forest biomass supply**

```math
\begin{equation*}
	x_{z,t}^{\textrm{B,Forest}} \leq  y_{z}^{\textrm{B,Forest}} \quad \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

This function creates expression to add the CO2 emissions for forest biomass in each zone, which is subsequently added to the total emissions.
"""
function bio_forest_supply(EP::Model, inputs::Dict, setup::Dict)

	println(" -- Bioenergy Forestry Biomass Supply Cost Module")

	#Define sets
	T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Zones

	dfForest = inputs["dfForest"]
	FOREST_SUPPLY_RES_ALL = inputs["FOREST_SUPPLY_RES_ALL"]
	BESC_FOREST_SUPPLY = inputs["BESC_FOREST_SUPPLY"]

	##Variables
	#Forest Biomass purchased from supply = k (tonnes/hr) in time t
	@variable(EP, vForest_biomass_purchased[k=1:FOREST_SUPPLY_RES_ALL, t = 1:T] >= 0 )

	Forest_biomass_supply_max = dfForest[!,:Max_tonne_per_hr]
	Forest_biomass_cost_per_tonne = dfForest[!,:Cost_per_tonne]
	Forest_biomass_emission_per_tonne = dfForest[!,:Emissions_tonne_per_tonne]

	#Forest Biomass Balance Expressions
	@expression(EP, eForest_biomass_purchased_per_time_per_zone[t=1:T, z=1:Z],
	sum(EP[:vForest_biomass_purchased][k,t] for k in intersect(BESC_FOREST_SUPPLY, dfForest[dfForest[!,:Zone].==z,:][!,:R_ID])))

	EP[:eForest_Biomass_Supply] += EP[:eForest_biomass_purchased_per_time_per_zone]

	#Forest Biomass VOM
	@expression(EP,eForest_Biomass_Supply_cost_per_type_per_time[k=1:FOREST_SUPPLY_RES_ALL, t = 1:T], inputs["omega"][t] * EP[:vForest_biomass_purchased][k,t] * Forest_biomass_cost_per_tonne[k])

	@expression(EP, eForest_Biomass_Supply_cost_per_zone_per_time[z=1:Z,t=1:T],
	sum(EP[:eForest_Biomass_Supply_cost_per_type_per_time][k,t] for k in intersect(BESC_FOREST_SUPPLY, dfForest[dfForest[!,:Zone].==z,:][!,:R_ID])))

	@expression(EP, eForest_Biomass_Supply_cost_per_zone[z=1:Z], sum(EP[:eForest_Biomass_Supply_cost_per_zone_per_time][z,t] for t in 1:T))

	@expression(EP, eForest_Biomass_Supply_cost, sum(EP[:eForest_Biomass_Supply_cost_per_zone][z] for z in 1:Z))

	EP[:eObj] += EP[:eForest_Biomass_Supply_cost]


	#Emission
	@expression(EP,eForest_biomass_emission_per_type_per_time[k=1:FOREST_SUPPLY_RES_ALL, t = 1:T], EP[:vForest_biomass_purchased][k,t] * Forest_biomass_emission_per_tonne[k])

	@expression(EP, eForest_biomass_emission_per_zone_per_time[z=1:Z,t=1:T], sum(EP[:eForest_biomass_emission_per_type_per_time][k,t] for k in intersect(BESC_FOREST_SUPPLY, dfForest[dfForest[!,:Zone].==z,:][!,:R_ID])))


	#Max biomass supply constraint
	@constraint(EP,cForest_biomass_Max[k in 1:FOREST_SUPPLY_RES_ALL, t in 1:T], EP[:vForest_biomass_purchased][k,t] <= Forest_biomass_supply_max[k])

	return EP

end
