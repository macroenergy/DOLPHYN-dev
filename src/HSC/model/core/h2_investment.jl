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
    h2_investment(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

Sets up constraints common to all hydrogen generation resources.

This function defines the expressions and constraints keeping track of total available generation capacity $y_{k}^{\textrm{H,GEN}}$ as well as constraints on capacity retirements.

This function defines the expressions and constraints keeping track of total available storage discharge capacity $y_{s}^{\textrm{\textrm{H,STO},DIS}}$ as well as constraints on capacity retirements.

The expression defined in this file named after ```eH2GenTotalCap``` covers all variables $y_{k}^{\textrm{H,THE}}, y_{s}^{\textrm{\textrm{H,STO},DIS}}$.

```math
\begin{equation*}
    y_{g, z}^{\textrm{H,GEN}} = 
    \begin{cases}
        y_{k, z}^{\textrm{H,THE}} \quad if \quad g \in \mathcal{K} \\
        y_{s, z}^{\textrm{\textrm{H,STO},DIS}} \quad if \quad g \in \mathcal{S}
    \end{cases}
    \quad \forall g \in \mathcal{G}, z \in \mathcal{Z}
\end{equation*}
```

This module additionally defines contributions to the objective function from variable costs of generation (variable OM plus fuel cost) from all resources over all time periods.

The total capacity of each resource (SMR, storage, electrolysis) is defined as the sum of the existing capacity plus the newly invested capacity minus any retired capacity. 
Note for energy storage resources in hydrogen sector, additional energy and charge capacity decisions and constraints are defined in the storage module.

```math
\begin{equation*}
    \begin{split}
    y_{g, z}^{\textrm{H,GEN}} &= y_{g}^{\textrm{H,GEN,total}} \\ 
    & = y_{g, z}^{\textrm{H,GEN,existing}} + y_{g, z}^{\textrm{H,GEN,new}} - y_{g, z}^{\textrm{H,GEN,retired}}
    \end{split}
    \quad \forall g \in \mathcal{G}, z \in \mathcal{Z}
\end{equation*}
```

**Cost expressions**

This module additionally defines contributions to the objective function from investment costs of generation (fixed O\&M plus investment costs) from all generation resources $g \in \mathcal{G}$:

```math
\begin{equation*}
    \textrm{C}^{\textrm{H,GEN,c}} = \sum_{g \in \mathcal{G}} \sum_{z \in \mathcal{Z}} y_{g, z}^{\textrm{H,GEN,new}}\times \textrm{c}_{g}^{\textrm{H,INV}} + \sum_{g \in \mathcal{G}} \sum_{z \in \mathcal{Z}} y_{g, z}^{\textrm{H,GEN,total}} \times \textrm{c}_{g}^{\textrm{H,FOM}}
\end{equation*}
```

**Constraints on generation discharge capacity**

One cannot retire more capacity than existing capacity.
```math
\begin{equation*}
    0 \leq y_{g, z}^{\textrm{H,GEN,retired}} \leq y_{g, z}^{\textrm{H,GEN,existing}} \quad \forall g \in \mathcal{G}, z \in \mathcal{Z}
\end{equation*}
```
"""
function h2_investment(EP::Model, inputs::Dict, setup::Dict)

    print_and_log(" -- H2 Investment Discharge Module")

    dfH2Gen = inputs["dfH2Gen"]

    # Define sets
    H2_GEN_NEW_CAP = inputs["H2_GEN_NEW_CAP"]
    H2_GEN_RET_CAP = inputs["H2_GEN_RET_CAP"]
    H2_GEN_COMMIT = inputs["H2_GEN_COMMIT"]
    if setup["ModelH2Liquid"] ==1
        H2_LIQ_COMMIT = inputs["H2_LIQ_COMMIT"]
        H2_EVAP_COMMIT = inputs["H2_EVAP_COMMIT"]
        H2_COMMIT = union(H2_GEN_COMMIT, H2_LIQ_COMMIT, H2_EVAP_COMMIT)
        H2_LIQ = inputs["H2_LIQ"]
        H2_EVAP = inputs["H2_EVAP"]
    else
        H2_COMMIT = H2_GEN_COMMIT
    end
    H2_GEN = inputs["H2_GEN"]
    H2_STOR_ALL = inputs["H2_STOR_ALL"]
    H = inputs["H2_RES_ALL"]

    # Capacity of New H2 Gen units (MWh/hr)
    # For generation with unit commitment, this variable refers to the number of units, not capacity. 
    @variable(EP, vH2GenNewCap[k in H2_GEN_NEW_CAP] >= 0)
    # Capacity of Retired H2 Gen units (MWh/hr)
    # For generation with unit commitment, this variable refers to the number of units, not capacity. 
    @variable(EP, vH2GenRetCap[k in H2_GEN_RET_CAP] >= 0)

    ### Expressions ###
    # Cap_Size is set to 1 for all variables when unit UCommit == 0
    # When UCommit > 0, Cap_Size is set to 1 for all variables except those where THERM == 1
    @expression(
        EP,
        eH2GenTotalCap[k in 1:H],
        if k in intersect(H2_GEN_NEW_CAP, H2_GEN_RET_CAP) # Resources eligible for new capacity and retirements
            if k in H2_COMMIT
                dfH2Gen[!, :Existing_Cap_MW][k] +
                dfH2Gen[!, :Cap_Size_MW][k] *
                (EP[:vH2GenNewCap][k] - EP[:vH2GenRetCap][k])
            else
                dfH2Gen[!, :Existing_Cap_MW][k] + EP[:vH2GenNewCap][k] -
                EP[:vH2GenRetCap][k]
            end
        elseif k in setdiff(H2_GEN_NEW_CAP, H2_GEN_RET_CAP) # Resources eligible for only new capacity
            if k in H2_COMMIT
                dfH2Gen[!, :Existing_Cap_MW][k] +
                dfH2Gen[!, :Cap_Size_MW][k] * EP[:vH2GenNewCap][k]
            else
                dfH2Gen[!, :Existing_Cap_MW][k] + EP[:vH2GenNewCap][k]
            end
        elseif k in setdiff(H2_GEN_RET_CAP, H2_GEN_NEW_CAP) # Resources eligible for only capacity retirements
            if k in H2_COMMIT
                dfH2Gen[!, :Existing_Cap_MW][k] -
                dfH2Gen[!, :Cap_Size_MW][k] * EP[:vH2GenRetCap][k]
            else
                dfH2Gen[!, :Existing_Cap_MW][k] - EP[:vH2GenRetCap][k]
            end
        else
            # Resources not eligible for new capacity or retirements
            dfH2Gen[!, :Existing_Cap_MW][k]
        end
    )

    ## Objective Function Expressions ##

    # Sum individual resource contributions to fixed costs to get total fixed costs
    # Fixed costs for resource "y" = annuitized investment cost plus fixed O&M costs
    # If resource is not eligible for new capacity, fixed costs are only O&M costs
    @expression(
        EP,
        eH2GenCFix[k in 1:H],
        if k in H2_GEN_NEW_CAP # Resources eligible for new capacity
            if k in H2_COMMIT
                dfH2Gen[!, :Inv_Cost_p_MW_yr][k] *
                dfH2Gen[!, :Cap_Size_MW][k] *
                EP[:vH2GenNewCap][k] +
                dfH2Gen[!, :Fixed_OM_Cost_p_MW_yr][k] * eH2GenTotalCap[k]
            else
                dfH2Gen[!, :Inv_Cost_p_MW_yr][k] * EP[:vH2GenNewCap][k] +
                dfH2Gen[!, :Fixed_OM_Cost_p_MW_yr][k] * eH2GenTotalCap[k]
            end
        else
            dfH2Gen[!, :Fixed_OM_Cost_p_MW_yr][k] * eH2GenTotalCap[k]
        end
    )

    # Calculate total costs for each zone, for each gen type
    @expression(EP, eTotalH2GenCFix, sum(EP[:eH2GenCFix][k] for k in H2_GEN))

    # Adding conditional for when liquefaction is considered
    # FIXME - These costs aren't being printed anywhere. I've temporarily added them to eTotalH2GenCFix
    if setup["ModelH2Liquid"] ==1
        @expression(EP, eTotalH2LiqCFix, sum(EP[:eH2GenCFix][k] for k in union(H2_LIQ, H2_EVAP)))
        eTotalH2GenCFix += eTotalH2LiqCFix
        # EP[:eObj] += eTotalH2LiqCFix
    end

    # Add term to objective function expression
    EP[:eObj] += eTotalH2GenCFix
    

    return EP

end
