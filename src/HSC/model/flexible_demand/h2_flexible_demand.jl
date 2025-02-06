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
    h2_flexible_demand(EP::Model, inputs::Dict, setup::Dict)

This function defines the operating constraints for flexible demand resources. As implemented, flexible demand resources ($y \in \mathcal{DF}$) are characterized by: a) maximum deferrable demand as a fraction of available capacity in a particular time step $t$, $\rho^{max}_{y,z,t}$, b) the maximum time this demand can be advanced and delayed, defined by parameters, $\tau^{advance}_{y,z}$ and $\tau^{delay}_{y,z}$, respectively and c) the energy losses associated with shifting demand, $\eta_{y,z}^{dflex}$.

**Tracking total deferred demand**

The operational constraints governing flexible demand resources are as follows.

The first two constraints model keep track of inventory of deferred demand in each time step.  Specifically, the amount of deferred demand remaining to be served ($\Gamma_{y,z,t}$) depends on the amount in the previous time step minus the served demand during time step $t$ ($\Theta_{y,z,t}$) while accounting for energy losses associated with demand flexibility, plus the demand that has been deferred during the current time step ($\Pi_{y,z,t}$). Note that variable $\Gamma_{y,z,t} \in \mathbb{R}$, $\forall y \in \mathcal{DF}, t  \in \mathcal{T}$. Similar to hydro inventory or storage state of charge constraints, for the first time step of the year (or each representative period), we define the deferred demand level based on level of deferred demand in the last time step of the year (or each representative period).

```math
\begin{aligned}
\Gamma_{y,z,t} = \Gamma_{y,z,t-1} -\eta_{y,z}^{dflex}\Theta_{y,z,t} +\Pi_{y,z,t} \hspace{4 cm}  \forall y \in \mathcal{DF}, z \in \mathcal{Z}, t \in \mathcal{T}^{interior} \\
\Gamma_{y,z,t} = \Gamma_{y,z,t +\tau^{period}-1} -\eta_{y,z}^{dflex}\Theta_{y,z,t} +\Pi_{y,z,t} \hspace{4 cm}  \forall y \in \mathcal{DF}, z \in \mathcal{Z}, t \in \mathcal{T}^{start}
\end{aligned}
```

**Bounds on available demand flexibility**

At any given time step, the amount of demand that can be shifted or deferred cannot exceed the maximum deferrable demand, defined by product of the availability factor ($\rho^{max}_{y,t}$) times the available capacity($\Delta^{total}_{y,z}$).

```math
\begin{aligned}
\Pi_{y,t} \leq \rho^{max}_{y,z,t}\Delta_{y,z} \hspace{4 cm}  \forall y \in \mathcal{DF}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```

**Maximum time delay and advancements**

Delayed demand must then be served within a fixed number of time steps. This is done by enforcing the sum of demand satisfied ($\Theta_{y,z,t}$) in the following $\tau^{delay}_{y,z}$ time steps (e.g., t + 1 to t + $\tau^{delay}_{y,z}$) to be greater than or equal to the level of energy deferred during time step $t$.

```math
\begin{aligned}
\sum_{e=t+1}^{t+\tau^{delay}_{y,z}}{\Theta_{y,z,e}} \geq \Gamma_{y,z,t}
    \hspace{4 cm}  \forall y \in \mathcal{DF},z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```

A similar constraints maximum time steps of demand advancement. This is done by enforcing the sum of demand deferred ($\Pi_{y,t}$) in the following $\tau^{advance}_{y}$ time steps (e.g., t + 1 to t + $\tau^{advance}_{y}$) to be greater than or equal to the total level of energy deferred during time $t$ (-$\Gamma_{y,t}$). The negative sign is included to account for the established sign convention that treat demand deferred in advance of the actual demand is defined to be negative.

```math
\begin{aligned}
\sum_{e=t+1}^{t+\tau^{advance}_{y,z}}{\Pi_{y,z,e}} \geq -\Gamma_{y,z,t}
    \hspace{4 cm}  \forall y \in \mathcal{DF}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```

If $t$ is first time step of the year (or the first time step of the representative period), then the above two constraints are implemented to look back over the last n time steps, starting with the last time step of the year (or the last time step of the representative period). This time-wrapping implementation is similar to the time-wrapping implementations used for defining the storage balance constraints for hydropower reservoir resources and energy storage resources.

"""
function h2_flexible_demand(EP::Model, inputs::Dict, setup::Dict)
## Flexible demand resources available during all hours and can be either delayed or advanced (virtual storage-shiftable demand) - DR ==1

print_and_log(" -- H2 Flexible Demand Resources Module")

dfH2Gen = inputs["dfH2Gen"]

T = inputs["T"]     # Number of time steps (hours)
Z = inputs["Z"]     # Number of zones
H2_FLEX = inputs["H2_FLEX"] # Set of flexible demand resources

START_SUBPERIODS = inputs["START_SUBPERIODS"]
INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]

hours_per_subperiod = inputs["hours_per_subperiod"] # Total number of hours per subperiod

END_HOURS = START_SUBPERIODS .+ hours_per_subperiod .- 1 # Last subperiod of each representative period

### Variables ###

# Variable tracking total advanced (negative) or deferred (positive) demand for demand flex resource k in period t
@variable(EP, vS_H2_FLEX[k in H2_FLEX, t=1:T]);

# Variable tracking demand deferred by demand H2_Flex resource k in period t
@variable(EP, vH2_CHARGE_FLEX[k in H2_FLEX, t=1:T] >= 0);

### Expressions ###

## Power Balance Expressions ##
# vH2Gen refers to deferred demand that is met and hence has a negative sign
# vH2_CHARGE_FLEX refers to deferred demand in period in t
@expression(EP, eH2BalanceDemandFlex[t=1:T, z=1:Z],
    sum(-EP[:vH2Gen][k,t]+EP[:vH2_CHARGE_FLEX][k,t] for k in intersect(H2_FLEX, dfH2Gen[(dfH2Gen[!,:Zone].==z),:][!,:R_ID])))

EP[:eH2Balance] += eH2BalanceDemandFlex

## Objective Function Expressions ##


# Variable costs of "charging" for technologies "k" during hour "t" in zone "z"
@expression(EP, eCH2VarFlex_in[k in H2_FLEX,t=1:T], inputs["omega"][t]*dfH2Gen[!,:Var_OM_Cost_Charge_p_MWh][k]*vH2_CHARGE_FLEX[k,t])


# Sum individual resource contributions to variable charging costs to get total variable charging costs
@expression(EP, eTotalCH2VarFlexInT[t=1:T], sum(eCH2VarFlex_in[k,t] for k in H2_FLEX))
@expression(EP, eTotalCH2VarFlexIn, sum(eTotalCH2VarFlexInT[t] for t in 1:T))
EP[:eObj] += eTotalCH2VarFlexIn

### Constraints ###

###Constraints###
@constraints(EP, begin
# State of "charge" constraint (equals previous state + charge - discharge)
# NOTE: no maximum energy "stored" or deferred for later hours
# NOTE: Flexible_Demand_Energy_Eff corresponds to energy loss due to time shifting
[k in H2_FLEX, t in INTERIOR_SUBPERIODS], EP[:vS_H2_FLEX][k,t] == EP[:vS_H2_FLEX][k,t-1]-dfH2Gen[!,:Flexible_Demand_Energy_Eff][k]*(EP[:vH2Gen][k,t])+(EP[:vH2_CHARGE_FLEX][k,t])
# Links last time step with first time step, ensuring position in hour 1 is within eligible change from final hour position
[k in H2_FLEX, t in START_SUBPERIODS], EP[:vS_H2_FLEX][k,t] == EP[:vS_H2_FLEX][k,t+hours_per_subperiod-1]-dfH2Gen[!,:Flexible_Demand_Energy_Eff][k]*(EP[:vH2Gen][k,t])+(EP[:vH2_CHARGE_FLEX][k,t])

# Maximum charging rate
# NOTE: the maximum amount that can be shifted is given by hourly availability of the resource times the maximum capacity of the resource
#Removed generator variability
[k in H2_FLEX, t=1:T], EP[:vH2_CHARGE_FLEX][k,t] <= inputs["pH2_Max"][k,t] * EP[:eH2GenTotalCap][k] 
# NOTE: no maximum discharge rate unless constrained by other factors like transmission, etc.
end)

# NOTE: no maximum discharge rate unless constrained by other factors like transmission, etc.

## Flexible demand is available only during specified hours with time delay or time advance (virtual storage-shiftable demand)
for k in H2_FLEX

    # Require deferred demands to be satisfied within the specified time delay
    max_flexible_demand_delay = Int(floor(dfH2Gen[!,:Max_Flexible_Demand_Delay][k]))
    H2_FLEXIBLE_DEMAND_DELAY_HOURS = [] # Set of hours in the summation term of the maximum demand delay constraint for the first subperiod of each representative period
    for s in START_SUBPERIODS
        flexible_demand_delay_start = s+hours_per_subperiod-max_flexible_demand_delay
        H2_FLEXIBLE_DEMAND_DELAY_HOURS = union(H2_FLEXIBLE_DEMAND_DELAY_HOURS, flexible_demand_delay_start:(s+hours_per_subperiod-2))
    end

    @constraints(EP, begin
        # cFlexibleDemandDelay: Constraints looks back over last n hours, where n = dfH2Gen[!,:Max_Flexible_Demand_Delay][k]
        [t in setdiff(1:T,H2_FLEXIBLE_DEMAND_DELAY_HOURS,END_HOURS)], sum(EP[:vH2Gen][k,e] for e=(t+1):(t+dfH2Gen[!,:Max_Flexible_Demand_Delay][k])) >= EP[:vS_H2_FLEX][k,t]

        # cFlexibleDemandDelayWrap: If n is greater than the number of subperiods left in the period, constraint wraps around to first hour of time series
        # cFlexibleDemandDelayWrap constraint is equivalant to: sum(EP[:vH2Gen][k,e] for e=(t+1):(hours_per_subperiod_max)+sum(EP[:vH2Gen][k,e] for e=hours_per_subperiod_min:(hours_per_subperiod_min-1+dfH2Gen[!,:Max_Flexible_Demand_Delay][k]-(hours_per_subperiod-(t%hours_per_subperiod)))) >= EP[:vS_H2_FLEX][k,t]
        [t in H2_FLEXIBLE_DEMAND_DELAY_HOURS], sum(EP[:vH2Gen][k,e] for e=(t+1):(t+hours_per_subperiod-(t%hours_per_subperiod)))+sum(EP[:vH2Gen][k,e] for e=(hours_per_subperiod*Int(floor((t-1)/hours_per_subperiod))+1):((hours_per_subperiod*Int(floor((t-1)/hours_per_subperiod))+1)-1+dfH2Gen[!,:Max_Flexible_Demand_Delay][k]-(hours_per_subperiod-(t%hours_per_subperiod)))) >= EP[:vS_H2_FLEX][k,t]

        # cFlexibleDemandDelayEnd: cFlexibleDemandDelayEnd constraint is equivalant to: sum(EP[:vH2Gen][k,e] for e=hours_per_subperiod_min:(hours_per_subperiod_min-1+dfH2Gen[!,:Max_Flexible_Demand_Delay][k])) >= EP[:vS_H2_FLEX][k,t]
        [t in END_HOURS], sum(EP[:vH2Gen][k,e] for e=(hours_per_subperiod*Int(floor((t-1)/hours_per_subperiod))+1):((hours_per_subperiod*Int(floor((t-1)/hours_per_subperiod))+1)-1+dfH2Gen[!,:Max_Flexible_Demand_Delay][k])) >= EP[:vS_H2_FLEX][k,t]
        # NOTE: Expression (hours_per_subperiod*Int(floor((t-1)/hours_per_subperiod))+1) is equivalant to "hours_per_subperiod_min"
        # NOTE: Expression t+hours_per_subperiod-(t%hours_per_subperiod) is equivalant to "hours_per_subperiod_max"
    end)

    # Require advanced demands to be satisfied within the specified time period
    max_flexible_demand_advance = Int(floor(dfH2Gen[!,:Max_Flexible_Demand_Advance][k]))
    H2_FLEXIBLE_DEMAND_ADVANCE_HOURS = [] # Set of hours in the summation term of the maximum advance demand constraint for the first subperiod of each representative period
    for s in START_SUBPERIODS
        flexible_demand_advance_start = s+hours_per_subperiod-max_flexible_demand_advance
        H2_FLEXIBLE_DEMAND_ADVANCE_HOURS = union(H2_FLEXIBLE_DEMAND_ADVANCE_HOURS, flexible_demand_advance_start:(s+hours_per_subperiod-2))
    end

    @constraints(EP, begin
        # cFlexibleDemandAdvance: Constraint looks back over last n hours, where n = dfH2Gen[!,:Max_Flexible_Demand_Advance][k]
        [t in setdiff(1:T,H2_FLEXIBLE_DEMAND_ADVANCE_HOURS,END_HOURS)], sum(EP[:vH2_CHARGE_FLEX][k,e] for e=(t+1):(t+dfH2Gen[!,:Max_Flexible_Demand_Advance][k])) >= -EP[:vS_H2_FLEX][k,t]

        # cFlexibleDemandAdvanceWrap: If n is greater than the number of subperiods left in the period, constraint wraps around to first hour of time series
        # cFlexibleDemandAdvanceWrap constraint is equivalant to: sum(EP[:vH2_CHARGE_FLEX][k,e] for e=(t+1):hours_per_subperiod_max)+sum(EP[:vH2_CHARGE_FLEX][k,e] for e=hours_per_subperiod_min:(hours_per_subperiod_min-1+dfH2Gen[!,:Max_Flexible_Demand_Advance][k]-(hours_per_subperiod-(t%hours_per_subperiod)))) >= -EP[:vS_H2_FLEX][k,t]
        [t in H2_FLEXIBLE_DEMAND_ADVANCE_HOURS], sum(EP[:vH2_CHARGE_FLEX][k,e] for e=(t+1):(t+hours_per_subperiod-(t%hours_per_subperiod)))+sum(EP[:vH2_CHARGE_FLEX][k,e] for e=(hours_per_subperiod*Int(floor((t-1)/hours_per_subperiod))+1):((hours_per_subperiod*Int(floor((t-1)/hours_per_subperiod))+1)-1+dfH2Gen[!,:Max_Flexible_Demand_Advance][k]-(hours_per_subperiod-(t%hours_per_subperiod)))) >= -EP[:vS_H2_FLEX][k,t]

        # cFlexibleDemandAdvanceEnd: cFlexibleDemandAdvanceEnd constraint is equivalant to: sum(EP[:vH2_CHARGE_FLEX][k,e] for e=hours_per_subperiod_min:(hours_per_subperiod_min-1+dfH2Gen[!,:Max_Flexible_Demand_Advance][k])) >= -EP[:vS_H2_FLEX][k,t]
        [t in END_HOURS], sum(EP[:vH2_CHARGE_FLEX][k,e] for e=(hours_per_subperiod*Int(floor((t-1)/hours_per_subperiod))+1):((hours_per_subperiod*Int(floor((t-1)/hours_per_subperiod))+1)-1+dfH2Gen[!,:Max_Flexible_Demand_Advance][k])) >= -EP[:vS_H2_FLEX][k,t]
        # NOTE: Expression (hours_per_subperiod*Int(floor((t-1)/hours_per_subperiod))+1) is equivalant to "hours_per_subperiod_min"
        # NOTE: Expression t+hours_per_subperiod-(t%hours_per_subperiod) is equivalant to "hours_per_subperiod_max"
    end)
end

return EP
end
