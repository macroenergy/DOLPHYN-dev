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
    h2_outputs(EP::Model, inputs::Dict, setup::Dict)

Sets up variables common to all hydrogen generation resources.

This module defines the hydrogen generation decision variable $x_{k,z,t}^{\textrm{H,GEN}} \forall k \in \mathcal{K}, z \in \mathcal{Z}, t \in \mathcal{T}$, representing hydrogen injected into the grid by hydrogen generation resource $k$ in zone $z$ at time period $t$.

This module defines the gydrogen discharge decision variable $x_{s,z,t}^{\textrm{\textrm{H,DIS}}} \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}$, representing hydrogen injected into the grid by hydrogen storage resource $s$ in zone $z$ at time period $t$.

The variable defined in this file named after ```vH2Gen``` covers all variables $x_{k,z,t}^{\textrm{H,GEN}}, x_{s,z,t}^{\textrm{\textrm{H,DIS}}}$.

```math
\begin{equation*}
    x_{g,z,t}^{\textrm{H,GEN}} = 
    \begin{cases}
        x_{k,z,t}^{\textrm{H,THE}} if g \in \mathcal{K} \\
        x_{s,z,t}^{\textrm{\textrm{H,DIS}}} if g \in \mathcal{S}
    \end{cases}
    \quad \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

**Cost expressions**

This module additionally defines contributions to the objective function from variable costs of generation (variable OM plus fuel cost) from all resources over all time periods.

```math
\begin{equation*}
    \textrm{C}^{\textrm{H,GEN,o}} = \sum_{g \in \mathcal{G}} \sum_{t \in \mathcal{T}} \omega_t \times \left(\textrm{c}_{g}^{\textrm{H,VOM}} + \textrm{c}_{g}^{\textrm{H,FUEL}}\right) \times x_{g,z,t}^{\textrm{H,GEN}}
\end{equation*}
```
"""
function h2_outputs(EP::Model, inputs::Dict, setup::Dict)

    print_and_log(" -- H2 Generation and Storage Discharge Module")

    dfH2Gen = inputs["dfH2Gen"]

    #Define sets
    H = inputs["H2_RES_ALL"] #Number of Hydrogen gen units
    T = inputs["T"]     # Number of time steps (hours)


    ### Variables ###

    #H2 injected to hydrogen grid from hydrogen generation resource k (MWh/hr of H2) in time t
    @variable(EP, vH2Gen[k=1:H, t = 1:T] >= 0)

    ### Expressions ###

    ## Objective Function Expressions ##

    # Variable costs of "generation" for resource "y" during hour "t" = variable O&M plus fuel cost
    @expression(EP, eCH2GenVar_out[k = 1:H,t = 1:T], 
    (inputs["omega"][t] * ((dfH2Gen[!,:Var_OM_Cost_p_MWh][k] + inputs["fuel_costs"][dfH2Gen[!,:Fuel][k]][t] * dfH2Gen[!,:etaFuel_MMBtu_p_MWh][k])) * vH2Gen[k,t]))


    @expression(EP, eTotalCH2GenVarOutT[t=1:T], sum(eCH2GenVar_out[k,t] for k in 1:H))
    @expression(EP, eTotalCH2GenVarOut, sum(eTotalCH2GenVarOutT[t] for t in 1:T))
    
    # Add total variable discharging cost contribution to the objective function
    EP[:eObj] += eTotalCH2GenVarOut

    return EP

end
