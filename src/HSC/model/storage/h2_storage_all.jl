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
    h2_storage_all(EP::Model, inputs::Dict, setup::Dict)

Sets up variables and constraints common to all hydrogen storage resources.

**Hydrogen storage discharge and inventory level decision variables**

This module defines the hydrogen storage energy inventory level variable $U_{s,z,t}^{\textrm{H,STO}} \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}$, representing hydrogen stored in the storage device $s$ in zone $z$ at time period $t$.

This module defines the power charge decision variable $x_{s,z,t}^{\textrm{H,CHA}}$ $\forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}$, representing charged hydrogen into the storage device $s$ in zone $z$ at time period $t$.

The variable defined in this file named after ```vH2S``` covers $U_{s,z,t}^{\textrm{H,STO}}$.

The variable defined in this file named after ```vH2_CHARGE_STOR``` covers $x_{s,z,t}^{\textrm{H,CHA}}$.

**Cost expressions**

This module additionally defines contributions to the objective function from variable costs (variable O&M plus fuel cost) of charging action of storage devices $s \in \mathcal{S}$ over all time periods $t \in \mathcal{T}$:

```math
\begin{equation*}
    \textrm{C}^{\textrm{H,STO,o}} = \sum_{s \in \mathcal{S}} \sum_{z \in \mathcal{Z}} \sum_{t \in \mathcal{T}} \omega_t \times \textrm{c}_{s,z,t}^{\textrm{H,STO,o}} \times x_{s,z,t}^{\textrm{H,CHA}}
\end{equation*}
```

**Power balance expressions**

Contributions to the power balance expression from compression due to storage charging action from storage devices $s \in \mathcal{S}$ are also defined as:

```math
\begin{equation*}
    PowerBal_{STO} = \sum_{s \in \mathcal{S}} \Phi_s^{\textrm{E,H}} x_{s,z,t}^{\textrm{\textrm{H,CHA}}} \quad \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

**Hydrogen balance expressions**

Contributions to the hydrogen balance expression from storage charging and discharging action from storage devices $s \in \mathcal{S}$ are also defined as:

```math
\begin{equation*}
    HydrogenBalGas_{STO} = \sum_{s \in \mathcal{S}} \left(x_{s,z,t}^{\textrm{H,DIS,Gas}} - x_{s,z,t}^{\textrm{H,CHA,Gas}}\right) \quad \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```
Liquid hydrogen balance contributions are defined in a similar manner, for liquid storage resources. 

```math
\begin{equation*}
    HydrogenBalLiq_{STO} = \sum_{s \in \mathcal{S}} \left(x_{s,z,t}^{\textrm{H,DIS,Liq}} - x_{s,z,t}^{\textrm{H,CHA,Liq}}\right) \quad \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

**Storage inventory level track constraints**

The following constraints apply to all storage resources, $s \in \mathcal{S}$, regardless of whether the charge/discharge capacities are symmetric or asymmetric.

The following two constraints track the state of charge of the storage resources at the end of each time period, relating the volume of energy stored at the end of the time period, $U_{s,z,t}^{\textrm{H,STO}}$, to the state of charge at the end of the prior time period, $U_{s,z,t-1}^{\textrm{H,STO}}$, the charge and discharge decisions in the current time period, $x_{s,z,t}^{\textrm{H,CHA}}, x_{s,z,t}^{\textrm{H,DIS}}$, and the self discharge rate for the storage resource (if any), $\eta_{s,z}^{H,loss}$. 
The first of these two constraints enforces storage inventory balance for interior time steps $(t \in \mathcal{T}^{interior})$, while the second enforces storage balance constraint for the initial time step $(t \in \mathcal{T}^{start})$.

```math
\begin{aligned}
    U_{s,z,t}^{\textrm{H,STO}} &= U_{s,z,t-1}^{\textrm{H,STO}} - \frac{1}{\eta_{s,z}^{\textrm{H,STO}}}x_{s,z,t}^{\textrm{H,DIS}} + \eta_{s,z}^{\textrm{H,STO}}x_{s,z,t}^{\textrm{H,STO}} - \eta_{s,z}^{\textrm{H,loss}}U_{s,z,t-1} \quad \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}^{interior} \\
    U_{s,z,t}^{\textrm{H,STO}} &= U_{s,z,t+\tau^{period}-1}^{\textrm{H,STO}} - \frac{1}{\eta_{s,z}^{\textrm{H,STO}}}x_{s,z,t}^{\textrm{H,DIS}} + \eta_{s,z}^{\textrm{H,STO}}x_{s,z,t}^{\textrm{H,CHA}} - \eta_{s,z}^{\textrm{H,loss}}U_{s,z,t+\tau^{period}-1} \quad \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}^{start}
\end{aligned}
```

**Bounds on storage power and energy capacity**

The storage power capacity sets lower and upper bounds on the storage energy capacity due to charging or discharging duration.

```math
\begin{aligned}
    y_{s,z}^{\textrm{H,STO,POW}} \times \tau_{s,z}^{MinDuration} &\leq y_{s,z}^{\textrm{H,STO,ENE}} \\
    y_{s,z}^{\textrm{H,STO,POW}} \times \tau_{s,z}^{MaxDuration} &\geq y_{s,z}^{\textrm{H,STO,ENE}}
\end{aligned}
```

It limits the volume of energy $U_{s,z,t}^{\textrm{H,STO}}$ at any time $t$ to be less than the installed energy storage capacity $y_{s,z}^{\textrm{H,STO,ENE}}$.

```math
\begin{equation*}
    0 \leq U_{s,z,t}^{\textrm{H,STO}} \leq y_{s,z}^{\textrm{H,STO,ENE}} \quad \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

It also limits the discharge power $x_{s,z,t}^{\textrm{H,DIS}}$ at any time to be less than the installed power capacity $y_{s,z}^{\textrm{H,STO,POW}}$.
Finally, the maximum discharge rate for storage resources, $x_{s,z,t}^{\textrm{H,STO}}$, is constrained to be less than the discharge power capacity, $y_{s,z}^{\textrm{H,STO,POW}}$ or the state of charge at the end of the last period, $U{s,z,t-1}^{\textrm{H,STO}}$, whichever is less.

```math
\begin{aligned}
    0 &\leq x_{s,z,t}^{\textrm{H,DIS}} \leq y_{s,z}^{\textrm{H,STO,POW}} \quad \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T} \\
    0 &\leq x_{s,z,t}^{\textrm{H,DIS}} \leq U_{s,z,t-1}^{\textrm{H,STO}}*\eta_{s,z}^{\textrm{H,DIS}} \quad \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}^{interior} \\
    0 &\leq x_{s,z,t}^{\textrm{H,DIS}} \leq U_{s,z,t+\tau^{period}-1}^{\textrm{H,STO}}*\eta_{s,z}^{\textrm{H,DIS}} \quad \forall s \in \mathcal{S}, z \in \mathcal{Z}, t \in \mathcal{T}^{start}
\end{aligned}
```
"""
function h2_storage_all(EP::Model, inputs::Dict, setup::Dict)
    # Setup variables, constraints, and expressions common to all hydrogen storage resources
    print_and_log(" -- H2 Storage Core Resources Module")

    dfH2Gen = inputs["dfH2Gen"]
    H2_STOR_ALL = inputs["H2_STOR_ALL"] # Set of all h2 storage resources
    H2_STOR_LIQ = inputs["H2_STOR_LIQ"] # Set of all liquid storage resources
    H2_STOR_GAS = inputs["H2_STOR_GAS"] # Set of all gaseous storage resources

    Z = inputs["Z"]     # Number of zones
    T = inputs["T"] # Number of time steps (hours) 
      
    START_SUBPERIODS = inputs["START_SUBPERIODS"] # Starting subperiod index for each representative period
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"] # Index of interior subperiod for each representative period
    H2_STOR_SHORT_DURATION = inputs["H2_STOR_SHORT_DURATION"] # Set of H2 storage modeled as short-duration (no energy carryover from one rep. week to the next)
    H2_STOR_LONG_DURATION = inputs["H2_STOR_LONG_DURATION"] # Set of H2 storage modeled as long-duration (energy carry over allowed)

    hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod

    ### Variables ###
    # Storage level of resource "y" at hour "t" [MWh] on zone "z" 
    @variable(EP, vH2S[y in H2_STOR_ALL, t=1:T] >= 0)

    # Rate of energy withdrawn from HSC by resource "y" at hour "t" [MWh/hour] on zone "z"
    @variable(EP, vH2_CHARGE_STOR[y in H2_STOR_ALL, t=1:T] >= 0)

    # Energy losses related to storage technologies (increase in effective demand)
    #@expression(EP, eEH2LOSS[y in H2_STOR_ALL], sum(inputs["omega"][t]*EP[:vH2_CHARGE_STOR][y,t] for t in 1:T) - sum(inputs["omega"][t]*EP[:vH2Gen][y,t] for t in 1:T))

    #Variable costs of "charging" for technologies "y" during hour "t" in zone "z"
    @expression(EP, eCVarH2Stor_in[y in H2_STOR_ALL,t=1:T], 
    if (dfH2Gen[!,:H2Stor_Charge_MMBtu_p_MWh][y]>0) # Charging consumes fuel 
        inputs["omega"][t]*dfH2Gen[!,:Var_OM_Cost_Charge_p_MWh][y]*vH2_CHARGE_STOR[y,t] +inputs["fuel_costs"][dfH2Gen[!,:Fuel][k]][t] * dfH2Gen[!,:H2Stor_Charge_MMBtu_p_MWh][k]
    else
        inputs["omega"][t]*dfH2Gen[!,:Var_OM_Cost_Charge_p_MWh][y]*vH2_CHARGE_STOR[y,t]
    end      
    )

    # Sum individual resource contributions to variable charging costs to get total variable charging costs
    @expression(EP, eTotalCVarH2StorInT[t=1:T], sum(eCVarH2Stor_in[y,t] for y in H2_STOR_ALL))
    @expression(EP, eTotalCVarH2StorIn, sum(eTotalCVarH2StorInT[t] for t in 1:T))
    EP[:eObj] += eTotalCVarH2StorIn


    # Term to represent electricity consumption associated with H2 storage charging and discharging
    @expression(EP, ePowerBalanceH2Stor[t=1:T, z=1:Z],
    sum(EP[:vH2_CHARGE_STOR][y,t]*dfH2Gen[!,:H2Stor_Charge_MWh_p_MWh][y] for y in intersect(dfH2Gen[dfH2Gen.Zone.==z,:R_ID],H2_STOR_ALL); init=0.0)
    )

    EP[:ePowerBalance] += -ePowerBalanceH2Stor

    # Adding power consumption by storage
    EP[:eH2NetpowerConsumptionByAll] += ePowerBalanceH2Stor
 
       # H2 Balance expressions
    @expression(EP, eH2BalanceStor[t=1:T, z=1:Z],
    sum(EP[:vH2Gen][y,t] - EP[:vH2_CHARGE_STOR][y,t] for y in intersect(H2_STOR_GAS, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID])))

    EP[:eH2Balance] += eH2BalanceStor   

    # LIQUID H2 Balance expressions
    if setup["ModelH2Liquid"]==1
        @expression(EP, eH2LiqBalanceStor[t=1:T, z=1:Z],
        sum(EP[:vH2Gen][y,t] - EP[:vH2_CHARGE_STOR][y,t] for y in intersect(H2_STOR_LIQ, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID])))

        EP[:eH2LiqBalance] += eH2LiqBalanceStor
    end

    ### End Expressions ###

    ### Constraints ###
    ## Storage energy capacity and state of charge related constraints:

    # Links state of charge in first time step with decisions in last time step of each subperiod
    # We use a modified formulation of this constraint (cSoCBalLongDurationStorageStart) when operations wrapping and long duration storage are being modeled
    
    if setup["TimeDomainReduction"] == 1 && !isempty(H2_STOR_LONG_DURATION)  && !isempty(H2_STOR_SHORT_DURATION) # Apply constraints to those storage technologies with short duration only (if non-empty)
        @constraint(EP, cH2SoCBalStart[t in START_SUBPERIODS, y in H2_STOR_SHORT_DURATION], EP[:vH2S][y,t] ==
            EP[:vH2S][y,t+hours_per_subperiod-1]-(1/dfH2Gen[!,:H2Stor_eff_discharge][y]*EP[:vH2Gen][y,t])
            +(dfH2Gen[!,:H2Stor_eff_charge][y]*EP[:vH2_CHARGE_STOR][y,t])-(dfH2Gen[!,:H2Stor_self_discharge_rate_p_hour][y]*EP[:vH2S][y,t+hours_per_subperiod-1]))
    else # Apply constraints to all storage technologies
        @constraint(EP, cH2SoCBalStart[t in START_SUBPERIODS, y in H2_STOR_ALL], EP[:vH2S][y,t] ==
            EP[:vH2S][y,t+hours_per_subperiod-1]-(1/dfH2Gen[!,:H2Stor_eff_discharge][y]*EP[:vH2Gen][y,t])
            +(dfH2Gen[!,:H2Stor_eff_charge][y]*EP[:vH2_CHARGE_STOR][y,t])-(dfH2Gen[!,:H2Stor_self_discharge_rate_p_hour][y]*EP[:vH2S][y,t+hours_per_subperiod-1]))
    end
    
    @constraints(EP, begin

        [y in H2_STOR_ALL, t in 1:T], EP[:eH2TotalCapEnergy][y]*dfH2Gen[!,:H2Stor_max_level][y] >= EP[:vH2S][y,t]
        [y in H2_STOR_ALL, t in 1:T], EP[:eH2TotalCapEnergy][y]*dfH2Gen[!,:H2Stor_min_level][y] <= EP[:vH2S][y,t]

        # Constraint on maximum discharging rate imposed if storage discharging capital cost >0
        # [y in intersect(H2_STOR_ALL,dfH2Gen[!,:Inv_Cost_p_MW_yr].>0), t in 1:T], EP[:vH2Gen][y,t] <= EP[:eH2TotalCapEnergy][y]
        # [y in H2_STOR_ALL, t in 1:T], EP[:vH2Gen][y,t] <= EP[:eH2GenTotalCap][y] * inputs["pH2_Max"][y,t]
        
        # energy stored for the next hour
        cH2SoCBalInterior[t in INTERIOR_SUBPERIODS, y in H2_STOR_ALL], EP[:vH2S][y,t] ==
            EP[:vH2S][y,t-1]-(1/dfH2Gen[!,:H2Stor_eff_discharge][y]*EP[:vH2Gen][y,t])+(dfH2Gen[!,:H2Stor_eff_charge][y]*EP[:vH2_CHARGE_STOR][y,t])-(dfH2Gen[!,:H2Stor_self_discharge_rate_p_hour][y]*EP[:vH2S][y,t-1])
    end)


    # Hydrogen storage discharge and charge power (and reserve contribution) related constraints for symmetric storage resources:
    # Maximum charging rate must be less than charge power rating
    @constraint(EP,
        [y in H2_STOR_ALL, t in 1:T],
        EP[:vH2_CHARGE_STOR][y, t] <= EP[:eTotalH2CapCharge][y]
    )

    ### End Constraints ###
    return EP
end
