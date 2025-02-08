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
	syn_ng_outputs(EP::Model, inputs::Dict, setup::Dict)
	
Sets up variables common to all synthetic gas resources.

This module defines the synthetic gas resource decision variable $x_{f,t}^{\textrm{C,Syn}} \forall f \in \mathcal{F}, z \in \mathcal{Z}, t \in \mathcal{T}$, representing CO2 input into the synthetic gas resource $f$ at time period $t$.

$x_{f,b,t}^{\textrm{By,Syn}} \forall f \in \mathcal{F}, \forall b \in \mathcal{B}, z \in \mathcal{Z}, t \in \mathcal{T}$, representing synthetic fuels by products $b$ (if any) by the synthetic fuels resource $f$ at time period $t$.

The variables defined in this file named after ```vSyn_NG_CO2in``` covers all variables $x_{f,t}^{\textrm{C,Syn}}$.

**Cost expressions**

This module additionally defines contributions to the objective function from variable costs of generation (variable OM plus fuel cost) from all synthetic fuels resources over all time periods.

```math
\begin{equation*}
	\textrm{C}^{\textrm{NG,Syn,o}} = \sum_{f \in \mathcal{F}} \sum_{t \in \mathcal{T}} \omega_t \times \left(\textrm{c}_{f}^{\textrm{Syn,VOM}} + \textrm{c}_{f}^{\textrm{Syn,NG}}\right) \times x_{f,t}^{\textrm{C,Syn}}
\end{equation*}
```

"""
function syn_ng_outputs(EP::Model, inputs::Dict, setup::Dict)

	println(" -- Syn NG Variable Cost Module")

    dfSyn_NG = inputs["dfSyn_NG"]

	#Define sets
	SYN_NG_RES_ALL = inputs["SYN_NG_RES_ALL"] #Number of Syn fuel units
	T = inputs["T"]     # Number of time steps (hours)

    ## Variables ##
    #CO2 Required by SynFuel Resource in MTonnes
	@variable(EP, vSyn_NG_CO2in[k in 1:SYN_NG_RES_ALL, t = 1:T] >= 0 )

	### Expressions ###
	## Objective Function Expressions ##

	#Variable Cost of Syn NG Production
	@expression(EP, eCSyn_NGProdVar_out[k = 1:SYN_NG_RES_ALL,t = 1:T], 
	(inputs["omega"][t] * dfSyn_NG[!,:Var_OM_cost_p_tonne_co2][k] * vSyn_NG_CO2in[k,t]))
	
    #Sum variable cost of syn fuel production
	@expression(EP, eTotalCSyn_NGProdVarOutT[t=1:T], sum(eCSyn_NGProdVar_out[k,t] for k in 1:SYN_NG_RES_ALL))
	@expression(EP, eTotalCSyn_NGProdVarOut, sum(eTotalCSyn_NGProdVarOutT[t] for t in 1:T))

	#Add total variable discharging cost contribution to the objective function
	EP[:eObj] += eTotalCSyn_NGProdVarOut

	return EP

end
