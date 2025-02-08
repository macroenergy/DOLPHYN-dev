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
    h2_storage_investment_charge(EP::Model, inputs::Dict, setup::Dict)

This function defines the expressions and constraints keeping track of total available hydrogen storage charge capacity ($s \in \mathcal{S}^{asym}, \mathcal{S}^{asym} \subseteq \mathcal{S}$) as well as constraints on capacity retirements. 
The function also adds investment and fixed OM costs related to charge capacity to the objective function.

The total capacity of each hydrogen storage resource is defined as the sum of the existing capacity plus the newly invested capacity minus any retired capacity.

```math
\begin{equation*}
    y_{s,z}^{\textrm{H,CHA,total}} = y_{s,z}^{\textrm{H,CHA,existing}} + y_{s,z}^{\textrm{H,CHA,new}} - y_{s,z}^{\textrm{H,CHA,retired}} \quad \forall s \in \mathcal{S}^{asym}, z \in \mathcal{Z}
\end{equation*}
```

**Cost expressions**

In addition, this module adds investment and fixed OM costs related to charge capacity to the objective function:
```math
\begin{equation*}
    \sum_{s \in \mathcal{S}^{asym}} \sum_{z \in \mathcal{Z}} (\textrm{c}_{s,z}^{\textrm{H,CHA,INV}} \times y_{s,z}^{\textrm{H,CHA,new}} + \textrm{c}_{s,z}^{\textrm{H,CHA,FOM}} \times y_{s,z}^{\textrm{H,CHA,total}})
\end{equation*}
```

**Constraints on storage charge capacity**

One cannot retire more capacity than existing capacity.
```math
\begin{equation*}
    0 \leq y_{s,z}^{\textrm{H,CHA,retired}} \leq y_{s,z}^{\textrm{H,CHA,existing}} \quad \forall s \in \mathcal{S}^{asym}, z \in \mathcal{Z}
\end{equation*}
```

For storage resources where upper bound $\overline{R_{s,z}^{\textrm{H,CHA}}}$ and lower bound $\underline{R_{s,z}^{\textrm{H,CHA}}}$ is defined, then we impose constraints on minimum and maximum storage charge capacity.
```math
\begin{equation*}
    \underline{R_{s,z}^{\textrm{H,CHA}}} \leq y_{s,z}^{\textrm{H,CHA}} \leq \overline{R_{s,z}^{\textrm{H,CHA}}} \quad \forall s \in \mathcal{S}^{asym}, z \in \mathcal{Z}
\end{equation*}
```
"""
function h2_storage_investment_charge(EP::Model, inputs::Dict, setup::Dict)

    print_and_log(" -- H2 Storage Charging Investment Module")

    dfH2Gen = inputs["dfH2Gen"]

    H2_STOR_ALL = inputs["H2_STOR_ALL"] # Set of H2 storage resources - all have asymmetric (separate) charge/discharge capacity components

    NEW_CAP_H2_STOR_CHARGE = inputs["NEW_CAP_H2_STOR_CHARGE"] # Set of asymmetric charge/discharge storage resources eligible for new charge capacity
    RET_CAP_H2_STOR_CHARGE = inputs["RET_CAP_H2_STOR_CHARGE"] # Set of asymmetric charge/discharge storage resources eligible for charge capacity retirements

    ### Variables ###

    ## Storage capacity built and retired for storage resources with independent charge and discharge charge capacities (STOR=2)

    # New installed charge capacity of resource "y"
    @variable(EP, vH2CAPCHARGE[y in NEW_CAP_H2_STOR_CHARGE] >= 0)

    # Retired charge capacity of resource "y" from existing capacity
    @variable(EP, vH2RETCAPCHARGE[y in RET_CAP_H2_STOR_CHARGE] >= 0)

    ### Expressions ###
    # Total available charging capacity in MWh/hour
    @expression(
        EP,
        eTotalH2CapCharge[y in H2_STOR_ALL],
        if (y in intersect(NEW_CAP_H2_STOR_CHARGE, RET_CAP_H2_STOR_CHARGE))
            dfH2Gen[!, :Existing_Charge_Cap_MW][y] + EP[:vH2CAPCHARGE][y] -
            EP[:vH2RETCAPCHARGE][y]
        elseif (y in setdiff(NEW_CAP_H2_STOR_CHARGE, RET_CAP_H2_STOR_CHARGE))
            dfH2Gen[!, :Existing_Charge_Cap_MW][y] + EP[:vH2CAPCHARGE][y]
        elseif (y in setdiff(RET_CAP_H2_STOR_CHARGE, NEW_CAP_H2_STOR_CHARGE))
            dfH2Gen[!, :Existing_Charge_Cap_MW][y] - EP[:vH2RETCAPCHARGE][y]
        else
            dfH2Gen[!, :Existing_Charge_Cap_MW][y]
        end
    )

    ## Objective Function Expressions ##

    # Fixed costs for resource "y" = annuitized investment cost plus fixed O&M costs
    # If resource is not eligible for new charge capacity, fixed costs are only O&M costs
    # Sum individual resource contributions to fixed costs to get total fixed costs
    @expression(
        EP,
        eCFixH2Charge[y in H2_STOR_ALL],
        if y in NEW_CAP_H2_STOR_CHARGE # Resources eligible for new charge capacity
            dfH2Gen[!, :Inv_Cost_Charge_p_MW_yr][y] * vH2CAPCHARGE[y] +
            dfH2Gen[!, :Fixed_OM_Cost_Charge_p_MW_yr][y] * eTotalH2CapCharge[y]
        else
            dfH2Gen[!, :Fixed_OM_Cost_Charge_p_MW_yr][y] * eTotalH2CapCharge[y]
        end
    )

    # Sum individual resource contributions to fixed costs to get total fixed costs
    @expression(EP, eTotalCFixH2Charge, sum(EP[:eCFixH2Charge][y] for y in H2_STOR_ALL))

    # Add term to objective function expression
    EP[:eObj] += eTotalCFixH2Charge

    ### Constratints ###

    ## Constraints on retirements and capacity additions
    #Cannot retire more charge capacity than existing charge capacity
    @constraint(
        EP,
        cMaxRetH2Charge[y in RET_CAP_H2_STOR_CHARGE],
        vH2RETCAPCHARGE[y] <= dfH2Gen[!, :Existing_Charge_Cap_MW][y]
    )

    # Constraints on new built capacity

    # Constraint on maximum charge capacity (if applicable) [set input to -1 if no constraint on maximum charge capacity]
    # DEV NOTE: This constraint may be violated in some cases where Existing_Charge_Cap_MW is >= Max_Charge_Cap_MW and lead to infeasabilty
    @constraint(
        EP,
        cMaxCapH2Charge[y in intersect(
            dfH2Gen[!, :Max_Charge_Cap_MW] .> 0,
            H2_STOR_ALL,
        )],
        eTotalH2CapCharge[y] <= dfH2Gen[!, :Max_Charge_Cap_MW][y]
    )

    # Constraint on minimum charge capacity (if applicable) [set input to -1 if no constraint on minimum charge capacity]
    # DEV NOTE: This constraint may be violated in some cases where Existing_Charge_Cap_MW is <= Min_Charge_Cap_MW and lead to infeasabilty
    @constraint(
        EP,
        cMinCapH2Charge[y in intersect(
            dfH2Gen[!, :Min_Charge_Cap_MW] .> 0,
            H2_STOR_ALL,
        )],
        eTotalH2CapCharge[y] >= dfH2Gen[!, :Min_Charge_Cap_MW][y]
    )

    return EP
end
