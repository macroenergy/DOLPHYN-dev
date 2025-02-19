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
    bio_agri_process_waste_supply(EP::Model, inputs::Dict, setup::Dict)

Sets up agricultural process waste biomass variables

This module defines the agricultural process waste biomass resource decision variable $x_{z,t}^{\textrm{B,Agri_Process_Waste}} \forall z \in \mathcal{Z}, t \in \mathcal{T}$, representing agricultural process waste biomass utilized in zone $z$ at time period $t$. 

The variables defined in this file named after ```vAgri_Process_Waste_biomass_purchased_per_zone_per_time``` covers all variables $x_{z,t}^{\textrm{B,Agri_Process_Waste}}$.

**Cost expressions**

This module additionally defines contributions to the objective function from variable costs of generation (variable OM) from agricultural process waste biomass supply over all time periods.

```math
\begin{equation*}
	\textrm{C}^{\textrm{Agri_Process_Waste,o}} = \sum_{z \in \mathcal{Z}} \sum_{t \in \mathcal{T}} \omega_t \times \textrm{c}_{r}^{\textrm{Agri_Process_Waste,VOM}} \times x_{z,t}^{\textrm{B,Agri_Process_Waste}}
\end{equation*}
```	

**Maximum agricultural process waste biomass supply**

```math
\begin{equation*}
	x_{z,t}^{\textrm{B,Agri_Process_Waste}} \leq  y_{z}^{\textrm{B,Agri_Process_Waste}} \quad \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

This function creates expression to add the CO2 emissions for agricultural process waste biomass in each zone, which is subsequently added to the total emissions.
"""
function bio_agri_process_waste_supply(EP::Model, inputs::Dict, setup::Dict)

	println(" -- Bioenergy Agricultural Process Waste Biomass Supply Cost Module")

	#Define sets
	T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Zones

	dfAgri_Process_Waste = inputs["dfAgri_Process_Waste"]
	AGRI_PROCESS_WASTE_SUPPLY_RES_ALL = inputs["AGRI_PROCESS_WASTE_SUPPLY_RES_ALL"]
	BESC_AGRI_PROCESS_WASTE_SUPPLY = inputs["BESC_AGRI_PROCESS_WASTE_SUPPLY"]

	##Variables
	#Agri_Process_Waste Biomass purchased from supply = k (tonnes/hr) in time t
	@variable(EP, vAgri_Process_Waste_biomass_purchased[k=1:AGRI_PROCESS_WASTE_SUPPLY_RES_ALL, t = 1:T] >= 0 )

	Agri_Process_Waste_biomass_supply_max = dfAgri_Process_Waste[!,:Max_tonne_per_hr]
	Agri_Process_Waste_biomass_cost_per_tonne = dfAgri_Process_Waste[!,:Cost_per_tonne]
	Agri_Process_Waste_biomass_emission_per_tonne = dfAgri_Process_Waste[!,:Emissions_tonne_per_tonne]

	#Agri_Process_Waste Biomass Balance Expressions
	@expression(EP, eAgri_Process_Waste_biomass_purchased_per_time_per_zone[t=1:T, z=1:Z],
	sum(EP[:vAgri_Process_Waste_biomass_purchased][k,t] for k in intersect(BESC_AGRI_PROCESS_WASTE_SUPPLY, dfAgri_Process_Waste[dfAgri_Process_Waste[!,:Zone].==z,:][!,:R_ID])))

	EP[:eAgri_Process_Waste_Biomass_Supply] += EP[:eAgri_Process_Waste_biomass_purchased_per_time_per_zone]

	#Agri_Process_Waste Biomass VOM
	@expression(EP,eAgri_Process_Waste_Biomass_Supply_cost_per_type_per_time[k=1:AGRI_PROCESS_WASTE_SUPPLY_RES_ALL, t = 1:T], inputs["omega"][t] * EP[:vAgri_Process_Waste_biomass_purchased][k,t] * Agri_Process_Waste_biomass_cost_per_tonne[k])

	@expression(EP, eAgri_Process_Waste_Biomass_Supply_cost_per_zone_per_time[z=1:Z,t=1:T],
	sum(EP[:eAgri_Process_Waste_Biomass_Supply_cost_per_type_per_time][k,t] for k in intersect(BESC_AGRI_PROCESS_WASTE_SUPPLY, dfAgri_Process_Waste[dfAgri_Process_Waste[!,:Zone].==z,:][!,:R_ID])))

	@expression(EP, eAgri_Process_Waste_Biomass_Supply_cost_per_zone[z=1:Z], sum(EP[:eAgri_Process_Waste_Biomass_Supply_cost_per_zone_per_time][z,t] for t in 1:T))

	@expression(EP, eAgri_Process_Waste_Biomass_Supply_cost, sum(EP[:eAgri_Process_Waste_Biomass_Supply_cost_per_zone][z] for z in 1:Z))

	EP[:eObj] += EP[:eAgri_Process_Waste_Biomass_Supply_cost]


	#Emission
	@expression(EP,eAgri_Process_Waste_biomass_emission_per_type_per_time[k=1:AGRI_PROCESS_WASTE_SUPPLY_RES_ALL, t = 1:T], EP[:vAgri_Process_Waste_biomass_purchased][k,t] * Agri_Process_Waste_biomass_emission_per_tonne[k])

	@expression(EP, eAgri_Process_Waste_biomass_emission_per_zone_per_time[z=1:Z,t=1:T], sum(EP[:eAgri_Process_Waste_biomass_emission_per_type_per_time][k,t] for k in intersect(BESC_AGRI_PROCESS_WASTE_SUPPLY, dfAgri_Process_Waste[dfAgri_Process_Waste[!,:Zone].==z,:][!,:R_ID])))


	#Max biomass supply constraint
	@constraint(EP,cAgri_Process_Waste_biomass_Max[k in 1:AGRI_PROCESS_WASTE_SUPPLY_RES_ALL, t in 1:T], EP[:vAgri_Process_Waste_biomass_purchased][k,t] <= Agri_Process_Waste_biomass_supply_max[k])

	return EP

end
