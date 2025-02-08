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
	syn_fuel_outputs(EP::Model, inputs::Dict, setup::Dict)
	
Sets up variables common to all synthetic fuels resources.

This module defines the synthetic fuels resource decision variable $x_{f,t}^{\textrm{C,Syn}} \forall f \in \mathcal{F}, z \in \mathcal{Z}, t \in \mathcal{T}$, representing CO2 input into the synthetic fuels resource $f$ at time period $t$.

$x_{f,b,t}^{\textrm{By,Syn}} \forall f \in \mathcal{F}, \forall b \in \mathcal{B}, z \in \mathcal{Z}, t \in \mathcal{T}$, representing synthetic fuels by products $b$ (if any) by the synthetic fuels resource $f$ at time period $t$.

The variables defined in this file named after ```vSFCO2in``` covers all variables $x_{f,t}^{\textrm{C,Syn}}$ and ```vSFByProd``` covers all variables $x_{f,b,t}^{\textrm{Syn,By}}$.

**Cost expressions**

This module additionally defines contributions to the objective function from variable costs of generation (variable OM plus fuel cost) from all synthetic fuels resources over all time periods.

```math
\begin{equation*}
	\textrm{C}^{\textrm{LF,Syn,o}} = \sum_{f \in \mathcal{F}} \sum_{t \in \mathcal{T}} \omega_t \times \left(\textrm{c}_{f}^{\textrm{Syn,VOM}} + \textrm{c}_{f}^{\textrm{Syn,FUEL}}\right) \times x_{f,t}^{\textrm{C,Syn}}
\end{equation*}
```

This module also defines contributions to the objective function from revenues of by-products (if any) of synthetic fuels generation from all resources over all time periods.

```math
\begin{equation*}
	\textrm{C}^{\textrm{LF,Syn,r}} = \sum_{f \in \mathcal{F}} \sum_{b \in \mathcal{B}} \sum_{t \in \mathcal{T}} \omega_t \times x_{f,b,t}^{\textrm{By,Syn}} \times \textrm{c}_{b}^{\textrm{By,Syn}}
\end{equation*}
```
"""
function syn_fuel_outputs(EP::Model, inputs::Dict, setup::Dict)

	println(" -- Syn Fuel Variable Cost Module")

    dfSynFuels = inputs["dfSynFuels"]
	dfSynFuelsByProdPrice = inputs["dfSynFuelsByProdPrice"]
	dfSynFuelsByProdExcess = inputs["dfSynFuelsByProdExcess"]

	#Define sets
	SYN_FUELS_RES_ALL = inputs["SYN_FUELS_RES_ALL"] #Number of Syn fuel units
	T = inputs["T"]     # Number of time steps (hours)
    NSFByProd = inputs["NSFByProd"] #Number of by products

    ## Variables ##
    #CO2 Required by SynFuel Resource in MTonnes
	@variable(EP, vSFCO2in[k = 1:SYN_FUELS_RES_ALL, t = 1:T] >= 0 )
    #Amount of By-productProduced in MMBTU
	@variable(EP, vSFByProd[k = 1:SYN_FUELS_RES_ALL, b = 1:NSFByProd, t = 1:T] >= 0 )
    
	### Expressions ###

	## Objective Function Expressions ##

    # Variable costs of "generation" for resource "y" during hour "t" = variable O&M plus fuel cost

	#Variable Cost of Syn Fuel Production
	@expression(EP, eCSFProdVar_out[k = 1:SYN_FUELS_RES_ALL,t = 1:T], 
	(inputs["omega"][t] * dfSynFuels[!,:Var_OM_cost_p_tonne_co2][k] * vSFCO2in[k,t]))
	
	#Revenue from by-product
	@expression(EP, eCSFByProdRevenue_out[k = 1:SYN_FUELS_RES_ALL, t = 1:T, b = 1:NSFByProd], 
	(inputs["omega"][t] * (dfSynFuelsByProdPrice[:,b][k] * dfSynFuelsByProdExcess[:,b][k]) * vSFCO2in[k,t]))


    #Sum variable cost of syn fuel production
	@expression(EP, eTotalCSFProdVarOutT[t=1:T], sum(eCSFProdVar_out[k,t] for k in 1:SYN_FUELS_RES_ALL))
	@expression(EP, eTotalCSFProdVarOut, sum(eTotalCSFProdVarOutT[t] for t in 1:T))

    #Sum revenue of syn fuel by-product
    @expression(EP, eTotalCSFByProdRevenueOutTK[t=1:T, k = 1:SYN_FUELS_RES_ALL], sum(eCSFByProdRevenue_out[k,t,b] for b = 1:NSFByProd))
    @expression(EP, eTotalCSFByProdRevenueOutT[t=1:T], sum(eTotalCSFByProdRevenueOutTK[t,k] for k = 1:SYN_FUELS_RES_ALL))
    @expression(EP, eTotalCSFByProdRevenueOut, sum(eTotalCSFByProdRevenueOutT[t] for t = 1:T))
	
	#Add total variable discharging cost contribution to the objective function
	EP[:eObj] += eTotalCSFProdVarOut
    EP[:eObj] -= eTotalCSFByProdRevenueOut

	return EP

end
