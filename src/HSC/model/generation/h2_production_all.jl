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
    h2_production_all(EP::Model, inputs::Dict, setup::Dict)

The h2 generation module creates decision variables, expressions, and constraints related to hydrogen generation infrastructure. 
Hydrogen generation expressions are also applied to liquefiers and evaporators. 

This module defines the power consumption decision variable $x_{z,t}^{\textrm{E,H-GEN}} \forall z\in \mathcal{Z}, t \in \mathcal{T}$, representing power consumed by electrolyzers in zone $z$ at time period $t$.

The variable defined in this file named after ```vP2G``` cover variable $x_{z,t}^{E,H-GEN}$.

**Constraints on hydrogen generation capacity**

One cannot retire more capacity than existing capacity.
```math
\begin{equation*}
    0 \leq y_{g}^{\textrm{H,GEN,retired}} \leq y_{g}^{\textrm{H,GEN,existing}} \quad \forall g \in \mathcal{G}
\end{equation*}
```

For resources where upper bound $\overline{y_{g}^{\textrm{H,GEN}}}$ and lower bound $\underline{y_{g}^{\textrm{H,GEN}}}$ of capacity is defined, then we impose constraints on minimum and maximum generation capacity.

```math
\begin{equation*}
    \underline{y_{g}^{\textrm{H,GEN}}} \leq y_{g}^{\textrm{H,GEN}} \leq \overline{y_{g}^{\textrm{H,GEN}}} \quad \forall g \in \mathcal{G}
\end{equation*}
```
"""
function h2_production_all(EP::Model, inputs::Dict, setup::Dict)

    print_and_log(" -- H2 Production Core Module")
    
    dfH2Gen = inputs["dfH2Gen"]

    #Define sets
    if setup["ModelH2Liquid"] ==1
        H2_GEN_NO_COMMIT= union(inputs["H2_GEN_NO_COMMIT"], inputs["H2_LIQ_NO_COMMIT"], inputs["H2_EVAP_NO_COMMIT"])
        H2_GEN_COMMIT = union(inputs["H2_GEN_COMMIT"], inputs["H2_LIQ_COMMIT"], inputs["H2_EVAP_COMMIT"])
        H2_GEN = union(inputs["H2_GEN"], inputs["H2_LIQ"], inputs["H2_EVAP"])
    else
        H2_GEN_COMMIT = inputs["H2_GEN_COMMIT"]
        H2_GEN_NO_COMMIT = inputs["H2_GEN_NO_COMMIT"]
        H2_GEN = inputs["H2_GEN"]    
    end

    H2_GEN_RET_CAP = inputs["H2_GEN_RET_CAP"]
    H =inputs["H2_RES_ALL"]
    
    T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Number of zones

    ####Variables####
    #Define variables needed across both commit and no commit sets

    #Power required by hydrogen generation resource k to make hydrogen (MW)
    @variable(EP, vP2G[k in H2_GEN, t = 1:T] >= 0 )

    #NG Consumption for H2 Generation
    if setup["ModelNGSC"] == 1
        @variable(EP, vNG2G[k in H2_GEN, t = 1:T] >= 0 )

        @constraints(EP, begin
            #NG Balance
            [k in H2_GEN, t = 1:T], EP[:vNG2G][k,t] == EP[:vH2Gen][k,t] * dfH2Gen[!,:etaNG_MMBtu_p_MWh][k]
        end)

        @expression(EP, eNGBalanceH2Gen[t=1:T, z=1:Z],
        sum(EP[:vNG2G][k,t] for k in intersect(H2_GEN, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID]))) 

        EP[:eNGBalance] -= eNGBalanceH2Gen

        EP[:eH2NetNGConsumptionByAll] += eNGBalanceH2Gen

    end
    
    ### Constratints ###

    ## Constraints on retirements and capacity additions
    # Cannot retire more capacity than existing capacity
    @constraint(EP, cH2GenMaxRetNoCommit[k in intersect(H2_GEN_RET_CAP, H2_GEN_NO_COMMIT)], EP[:vH2GenRetCap][k] <= dfH2Gen[!,:Existing_Cap_MW][k])
    @constraint(EP, cH2GenMaxRetCommit[k in intersect(H2_GEN_RET_CAP, H2_GEN_COMMIT)], dfH2Gen[!,:Cap_Size_MW][k] * EP[:vH2GenRetCap][k] <= dfH2Gen[!,:Existing_Cap_MW][k])

    ## Constraints on new built capacity
    # Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
    # DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MW is >= Max_Cap_MW and lead to infeasabilty
    @constraint(EP, cH2GenMaxCap[k in intersect(dfH2Gen[dfH2Gen.Max_Cap_MW.>0,:R_ID], 1:H)],EP[:eH2GenTotalCap][k] <= dfH2Gen[!,:Max_Cap_MW][k])

    # Constraint on minimum capacity (if applicable) [set input to -1 if no constraint on minimum capacity]
    # DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MW is <= Min_Cap_MW and lead to infeasabilty
    @constraint(EP, cH2GenMinCap[k in intersect(dfH2Gen[dfH2Gen.Min_Cap_MW.>0,:R_ID], 1:H)], EP[:eH2GenTotalCap][k] >= dfH2Gen[!,:Min_Cap_MW][k])

    return EP

end
