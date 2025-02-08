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
	bio_electricity_var_cost(EP::Model, inputs::Dict, setup::Dict)

Sets up variables common to all biorefinery resources.

This module defines the biorefinery resource decision variable $x_{r,t}^{\textrm{B,Bio}} \forall r \in \mathcal{R}, z \in \mathcal{Z}, t \in \mathcal{T}$, representing biomass input into the biorefinery resource $r$ at time period $t$, $x_{r,t}^{\textrm{E,Bio}} \forall r \in \mathcal{R}, z \in \mathcal{Z}, t \in \mathcal{T}$, representing power input into the biorefinery resource $r$ at time period $t$ (if any), and $x_{r,t}^{\textrm{H,Bio}} \forall r \in \mathcal{R}, z \in \mathcal{Z}, t \in \mathcal{T}$, representing electricity input into the biorefinery resource $r$ at time period $t$ (if any). 

The variables defined in this file named after ```vBiomass_consumed_per_plant_per_time_ELEC``` covers all variables $x_{r,t}^{\textrm{B,Bio}}$.

The variables defined in this file named after ```vPower_BIO_ELEC``` covers all variables $x_{r,t}^{\textrm{E,Bio}}$ (if any).

**Cost expressions**

This module additionally defines contributions to the objective function from variable costs of generation (variable OM) from all biorefinery resources over all time periods.

```math
\begin{equation*}
	\textrm{C}^{\textrm{Bio,o}} = \sum_{r \in \mathcal{R}} \sum_{t \in \mathcal{T}} \omega_t \times \textrm{c}_{r}^{\textrm{Bio,VOM}} \times x_{r,t}^{\textrm{B,Bio}}
\end{equation*}
```
"""
function bio_electricity_var_cost(EP::Model, inputs::Dict, setup::Dict)

	println(" -- Bio Electricity Variable Cost Module")

    dfBioELEC = inputs["dfBioELEC"]
	BIO_ELEC_RES_ALL = inputs["BIO_ELEC_RES_ALL"]

	#Define sets
	T = inputs["T"]     # Number of time steps (hours)

	#####################################################################################################################################
	#Variables
	@variable(EP,vBiomass_consumed_per_plant_per_time_ELEC[i = 1:BIO_ELEC_RES_ALL, t = 1:T] >= 0)

	#####################################################################################################################################
	#Variable cost per plant per time
	@expression(EP, eVar_Cost_BIO_ELEC_per_plant_per_time[i = 1:BIO_ELEC_RES_ALL, t = 1:T], inputs["omega"][t] * EP[:vBiomass_consumed_per_plant_per_time_ELEC][i,t] * dfBioELEC[!,:Var_OM_per_tonne][i])

	#Variable cost per plant
	@expression(EP, eVar_Cost_BIO_ELEC_per_plant[i = 1:BIO_ELEC_RES_ALL], sum(EP[:eVar_Cost_BIO_ELEC_per_plant_per_time][i,t] for t in 1:T))

	#Total variable cost
	@expression(EP, eVar_Cost_BIO_ELEC, sum(EP[:eVar_Cost_BIO_ELEC_per_plant][i] for i in 1:BIO_ELEC_RES_ALL))

	EP[:eObj] += EP[:eVar_Cost_BIO_ELEC]
	
	return EP

end
