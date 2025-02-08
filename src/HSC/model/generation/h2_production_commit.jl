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
    h2_production_commit(EP::Model, inputs::Dict, setup::Dict)

This function defines the operating constraints for thermal hydrogen generation plants subject to unit commitment constraints on hydrogen plant start-ups and shut-down decision ($g \in \mathcal{UC}$).

**Hydrogen balance expression**

Contributions to the hydrogen balance expression from each thermal resources with unit commitment $g \in \mathcal{UC}$ are also defined as below. If liquid hydrogen is modeled, a liquid hydrogen balance expression is needed and contributions to the gas balance are accounted for. 

```math
\begin{equation*}
    HydrogenBalGas_{GEN} = \sum_{g \in \mathcal{UC}} x_{g,z,t}^{\textrm{H,GEN}} - \sum_{g \in \mathcal{UC}} x_{g,z,t}^{\textrm{H,LIQ}} + \sum_{g \in \mathcal{UC}} x_{g,z,t}^{\textrm{H,EVAP}} \quad \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

```math
\begin{equation*}
    HydrogenBalLiq_{GEN} = \sum_{g \in \mathcal{UC}} x_{g,z,t}^{\textrm{H,LIQ}} - \sum_{g \in \mathcal{UC}} x_{g,z,t}^{\textrm{H,EVAP}} \quad \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

**Startup and shutdown events (thermal plant cycling)**

*Capacity limits on unit commitment decision variables*

Thermal resources subject to unit commitment ($k \in \mathcal{UC}$) adhere to the following constraints on commitment states, startup events, and shutdown events, which limit each decision to be no greater than the maximum number of discrete units installed (as per the following three constraints):

```math
\begin{equation*}
    n_{g,z,t}^{\textrm{H,GEN}} \leq \frac{y_{g,z}^{\textrm{H,GEN}}}{\Omega_{g,z}^{\textrm{H,GEN,size}}} \quad \forall g \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

```math
\begin{equation*}
    n_{g,z,t}^{\textrm{H,UP}} \leq \frac{y_{g,z}^{\textrm{H,GEN}}}{\Omega_{g,z}^{\textrm{H,GEN,size}}} \quad \forall g \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

```math
\begin{equation*}
    n_{g,z,t}^{\textrm{H,DN}} \leq \frac{y_{g,z}^{\textrm{H,GEN}}}{\Omega_{g,z}^{\textrm{H,GEN,size}}} \quad \forall g \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```
where decision $n_{g,z,t}^{\textrm{H,GEN}}$ designates the commitment state of generator cluster $g$ in zone $z$ at time $t$, 
decision $n_{g,z,t}^{\textrm{H,UP}}$ represents number of startup decisions, 
decision $n_{g,z,t}^{\textrm{H,DN}}$ represents number of shutdown decisions, 
$y_{g,z}^{\textrm{H,GEN}}$ is the total installed capacity, and parameter $\Omega_{g,z}^{\textrm{H,GEN},size}$ is the unit size.
(See Constraints 1-3 in the code)

*Commitment state constraint linking start-up and shut-down decisions*

Additionally, the following constarint maintains the commitment state variable across time, 
$n_{g,z,t}^{\textrm{H,GEN}}$, as the sum of the commitment state in the prior, $n_{g,z,t-1}^{\textrm{H,GEN}}$, 
period plus the number of units started in the current period, $n_{g,z,t}^{H,UP}$, 
minus the number of units shut down in the current period, $n_{g,z,t}^{H,DN}$:

```math
\begin{aligned}
    n_{g,z,t}^{\textrm{H,GEN}} &= n_{g,z,t-1}^{\textrm{H,GEN}} + n_{g,z,t}^{\textrm{H,UP}} - n_{g,z,t}^{\textrm{H,DN}} \quad \forall g \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}^{interior} \\
    n_{g,z,t}^{\textrm{H,GEN}} &= n_{g,z,t +\tau^{period}-1}^{\textrm{H,GEN}} + n_{g,z,t}^{\textrm{H,UP}} - n_{g,z,t}^{\textrm{H,DN}} \quad \forall g \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}^{start}
\end{aligned}
```
(See Constraint 4 in the code)

Like other time-coupling constraints, this constraint wraps around to link the commitment state in the first time step of the year (or each representative period), $t \in \mathcal{T}^{start}$, to the last time step of the year (or each representative period), $t+\tau^{period}-1$.

**Ramping constraints**

Thermal resources subject to unit commitment ($k \in \mathcal{UC}$) adhere to the following ramping constraints on hourly changes in power output:

```math
\begin{aligned}
    x_{g,z,t-1}^{\textrm{H,GEN}} - x_{g,z,t}^{\textrm{H,GEN}} &\leq \kappa_{g,z}^{\textrm{H,DN}} \times \Omega_{g,z}^{\textrm{H,GEN,size}} \times \left(n_{g,z,t}^{\textrm{H,UP}} - n_{g,z,t}^{\textrm{H,DN}}\right) \\
    \qquad &- \underline{\rho_{g,z,t}^{\textrm{H,GEN}}} \times \Omega_{g,z}^{\textrm{H,GEN,size}} \times n_{g,z,t}^{\textrm{H,DN}} \\
    \qquad &+ \text{min}(\overline{\rho_{g,z,t}^{\textrm{H,GEN}}}}, \text{max}(\underline{\rho_{g,z,t}^{\textrm{H,GEN}}}, \kappa_{g,z}^{\textrm{H,GEN}})) \times \Omega_{g,z}^{\textrm{H,GEN,size}} \times n_{g,z,t}^{\textrm{H,DN}} \\
    \quad \forall g \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T} 
\end{aligned}
```

```math
\begin{aligned}
    x_{g,z,t}^{\textrm{H,GEN}} - x_{g,z,t-1}^{\textrm{H,GEN}} &\leq \kappa_{g,z}^{\textrm{H,UP}} \times \Omega_{g,z}^{\textrm{H,GEN,size}} \times \left(n_{g,z,t}^{\textrm{H,UP}} - n_{g,z,t}^{\textrm{H,DN}}\right) \\
    \qquad &+ \text{min}(\overline{\rho_{g,z,t}^{\textrm{H,GEN}}}, \text{max}(\underline{\rho_{g,z,t}^{\textrm{H,GEN}}}, \kappa_{k,z}^{\textrm{H,UP}})) \times \Omega_{k,z}^{\textrm{H,GEN,size}} \times n_{g,z,t}^{\textrm{H,DN}} \\
    \qquad &- \underline{\rho_{g,z,t}^{\textrm{H,GEN}}} \times \Omega_{g,z}^{\textrm{H,GEN,size}} \times n_{g,z,t}^{\textrm{H,DN}} \quad \forall g \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```
(See Constraints 5-6 in the code)

where decision $x_{g,z,t}^{\textrm{H,GEN}}$ is the energy injected into the grid by technology $y$ in zone $z$ at time $t$, parameter $\kappa_{g,z,t}^{\textrm{H,UP}}$, $\kappa_{G,z,t}^{\textrm{H,DN}}$ is the maximum ramp-up or ramp-down rate as a percentage of installed capacity, parameter $\underline{\rho_{g,z}^{\textrm{H,GEN}}}$ is the minimum stable power output per unit of installed capacity, 
and parameter $\overline{\rho_{g,z,t}^{\textrm{H,GEN}}}$ is the maximum available generation per unit of installed capacity. These constraints account for the ramping limits for committed (online) units as well as faster changes in power enabled by units starting or shutting down in the current time step.

```math
\begin{equation*}
    x_{g,z,t}^{\textrm{H,GEN}} \geq \underline{\rho_{g,z,t}^{\textrm{H,GEN}}} \times \Omega_{g,z}^{\textrm{H,GEN,size}} \times n_{g,z,t}^{\textrm{H,UP}} \quad \forall g \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

```math
\begin{equation*}
    x_{g,z,t}^{\textrm{H,GEN}} \geq \overline{\rho_{g,z}^{\textrm{H,GEN}}} \times \Omega_{g,z}^{\textrm{H,GEN,size}} \times n_{g,z,t}^{\textrm{H,UP}} \quad \forall g \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

(See Constraints 7-8 the code)

**Minimum and maximum up and down time**

Thermal resources subject to unit commitment adhere to the following constraints on the minimum time steps after start-up before a unit can shutdown again (minimum up time) and the minimum time steps after shut-down before a unit can start-up again (minimum down time):

```math
\begin{equation*}
    n_{g,z,t}^{\textrm{H,GEN}} \geq \displaystyle \sum_{\tau = t-\tau_{g,z}^{\textrm{H,UP}}}^t n_{g,z,\tau}^{\textrm{H,UP}} \quad \forall g \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

```math
\begin{equation*}
    \frac{y_{g,z}^{\textrm{H,GEN}}}{\Omega_{g,z}^{\textrm{H,GEN,size}}} - n_{g,z,t}^{\textrm{H,UP}} \geq \displaystyle \sum_{\tau = t-\tau_{g,z}^{\textrm{H,DN}}}^t n_{g,z,\tau}^{\textrm{H,DN}} \quad \forall g \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```
(See Constraints 9-10 in the code)

where $\tau_{g,z}^{\textrm{H,UP}}$ and $\tau_{g,z}^{\textrm{H,DN}}$ is the minimum up or down time for units in generating cluster $g$ in zone $z$.

Like with the ramping constraints, the minimum up and down constraint time also wrap around from the start of each time period to the end of each period.
It is recommended that users of DOLPHYN must use longer subperiods than the longest min up/down time if modeling unit commitment. Otherwise, the model will report error.
"""
function h2_production_commit(EP::Model, inputs::Dict, setup::Dict)

    print_and_log(" -- H2 Production (Unit Commitment) Module")
    
    # Rename H2Gen dataframe
    dfH2Gen = inputs["dfH2Gen"]
    H2GenCommit = setup["H2GenCommit"]

    T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Number of zones
    H = inputs["H"]        #NUmber of hydrogen generation units 

    H2_GAS_COMMIT = inputs["H2_GEN_COMMIT"] #This is needed only for H2 balance

    if setup["ModelH2Liquid"]==1
        H2_LIQ_COMMIT = inputs["H2_LIQ_COMMIT"]
        H2_EVAP_COMMIT = inputs["H2_EVAP_COMMIT"]
        H2_GEN_COMMIT = union(H2_LIQ_COMMIT, H2_GAS_COMMIT, H2_EVAP_COMMIT) #liquefiers are treated at generators, all the same expressions & contraints apply, except for H2 balance
    else
        H2_GEN_COMMIT = H2_GAS_COMMIT
    end
    H2_GEN_NEW_CAP = inputs["H2_GEN_NEW_CAP"] 
    H2_GEN_RET_CAP = inputs["H2_GEN_RET_CAP"] 
    
    #Define start subperiods and interior subperiods
    START_SUBPERIODS = inputs["START_SUBPERIODS"]
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
    hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod

    ###Variables###

    # commitment state variable
    @variable(EP, vH2GenCOMMIT[k in H2_GEN_COMMIT, t=1:T] >= 0)
    # Start up variable
    @variable(EP, vH2GenStart[k in H2_GEN_COMMIT, t=1:T] >= 0)
    # Shutdown Variable
    @variable(EP, vH2GenShut[k in H2_GEN_COMMIT, t=1:T] >= 0)

    ###Expressions###

    #Objective function expressions
    # Startup costs of "generation" for resource "y" during hour "t"
    @expression(EP, eH2GenCStart[k in H2_GEN_COMMIT, t=1:T],(inputs["omega"][t]*inputs["C_H2_Start"][k]*vH2GenStart[k,t]))

    # Julia is fastest when summing over one row one column at a time
    @expression(EP, eTotalH2GenCStartT[t=1:T], sum(eH2GenCStart[k,t] for k in H2_GEN_COMMIT))
    @expression(EP, eTotalH2GenCStart, sum(eTotalH2GenCStartT[t] for t=1:T))

    EP[:eObj] += eTotalH2GenCStart

    #H2 Balance expressions
    @expression(EP, eH2GenCommit[t=1:T, z=1:Z],
    sum(EP[:vH2Gen][k,t] for k in intersect(H2_GAS_COMMIT, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID])))

    EP[:eH2Balance] += eH2GenCommit

    if setup["ModelH2Liquid"]==1
        #H2 LIQUID Balance expressions
        @expression(EP, eH2LiqCommit[t=1:T, z=1:Z],
        sum(EP[:vH2Gen][k,t] for k in intersect(H2_LIQ_COMMIT, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID])))
        
        # Add Liquid H2 to liquid balance, AND REMOVE it from the gas balance
        EP[:eH2Balance] -= eH2LiqCommit
        EP[:eH2LiqBalance] += eH2LiqCommit

        #H2 EVAPORATION Balance expressions
        if !isempty(H2_EVAP_COMMIT)
            @expression(EP, eH2EvapCommit[t=1:T, z=1:Z],
            sum(EP[:vH2Gen][k,t] for k in intersect(H2_EVAP_COMMIT, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID])))
        
            # Add evaporated H2 to gas balance, AND REMOVE it from the liquid balance
            EP[:eH2Balance] += eH2EvapCommit
            EP[:eH2LiqBalance] -= eH2EvapCommit
        end
    end

    #Power Consumption for H2 Generation
    @expression(EP, ePowerBalanceH2GenCommit[t=1:T, z=1:Z],
    sum(EP[:vP2G][k,t] for k in intersect(H2_GEN_COMMIT, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID]))) 

    EP[:ePowerBalance] += -ePowerBalanceH2GenCommit


    ##For CO2 Polcy constraint right hand side development - power consumption by zone and each time step
    EP[:eH2NetpowerConsumptionByAll] += ePowerBalanceH2GenCommit

    ### Constraints ###
    ## Declaration of integer/binary variables
    if H2GenCommit == 1 # Integer UC constraints
        for k in H2_GEN_COMMIT
            set_integer.(vH2GenCOMMIT[k,:])
            set_integer.(vH2GenStart[k,:])
            set_integer.(vH2GenShut[k,:])
            if k in H2_GEN_RET_CAP
                set_integer(EP[:vH2GenRetCap][k])
            end
            if k in H2_GEN_NEW_CAP 
                set_integer(EP[:vH2GenNewCap][k])
            end
        end
    end #END unit commitment configuration

    ###Constraints###
    @constraints(EP, begin
        #Power Balance
        [k in H2_GEN_COMMIT, t = 1:T], EP[:vP2G][k,t] == EP[:vH2Gen][k,t] * dfH2Gen[!,:etaP2G][k]
    end)

    ### Capacitated limits on unit commitment decision variables (Constraints #1-3)
    @constraints(EP, begin
        [k in H2_GEN_COMMIT, t=1:T], EP[:vH2GenCOMMIT][k,t] <= EP[:eH2GenTotalCap][k]/dfH2Gen[!,:Cap_Size_MW][k]
        [k in H2_GEN_COMMIT, t=1:T], EP[:vH2GenStart][k,t] <= EP[:eH2GenTotalCap][k]/dfH2Gen[!,:Cap_Size_MW][k]
        [k in H2_GEN_COMMIT, t=1:T], EP[:vH2GenShut][k,t] <= EP[:eH2GenTotalCap][k]/dfH2Gen[!,:Cap_Size_MW][k]
    end)

    # Commitment state constraint linking startup and shutdown decisions (Constraint #4)
    @constraints(EP, begin
    # For Start Hours, links first time step with last time step in subperiod
    [k in H2_GEN_COMMIT, t in START_SUBPERIODS], EP[:vH2GenCOMMIT][k,t] == EP[:vH2GenCOMMIT][k,(t+hours_per_subperiod-1)] + EP[:vH2GenStart][k,t] - EP[:vH2GenShut][k,t]
    # For all other hours, links commitment state in hour t with commitment state in prior hour + sum of start up and shut down in current hour
    [k in H2_GEN_COMMIT, t in INTERIOR_SUBPERIODS], EP[:vH2GenCOMMIT][k,t] == EP[:vH2GenCOMMIT][k,t-1] + EP[:vH2GenStart][k,t] - EP[:vH2GenShut][k,t]
    end)


    ### Maximum ramp up and down between consecutive hours (Constraints #5-6)

    ## For Start Hours
    # Links last time step with first time step, ensuring position in hour 1 is within eligible ramp of final hour position
    # rampup constraints
    @constraint(EP,[k in H2_GEN_COMMIT, t in START_SUBPERIODS],
    EP[:vH2Gen][k,t]-EP[:vH2Gen][k,(t+hours_per_subperiod-1)] <= dfH2Gen[!,:Ramp_Up_Percentage][k] * dfH2Gen[!,:Cap_Size_MW][k]*(EP[:vH2GenCOMMIT][k,t]-EP[:vH2GenStart][k,t])
    + min(inputs["pH2_Max"][k,t],max(dfH2Gen[!,:H2Gen_min_output][k],dfH2Gen[!,:Ramp_Up_Percentage][k]))*dfH2Gen[!,:Cap_Size_MW][k]*EP[:vH2GenStart][k,t]
    - dfH2Gen[!,:H2Gen_min_output][k] * dfH2Gen[!,:Cap_Size_MW][k] * EP[:vH2GenShut][k,t])

    # rampdown constraints
    @constraint(EP,[k in H2_GEN_COMMIT, t in START_SUBPERIODS],
    EP[:vH2Gen][k,(t+hours_per_subperiod-1)]-EP[:vH2Gen][k,t] <= dfH2Gen[!,:Ramp_Down_Percentage][k]*dfH2Gen[!,:Cap_Size_MW][k]*(EP[:vH2GenCOMMIT][k,t]-EP[:vH2GenStart][k,t])
    - dfH2Gen[!,:H2Gen_min_output][k]*dfH2Gen[!,:Cap_Size_MW][k]*EP[:vH2GenStart][k,t]
    + min(inputs["pH2_Max"][k,t],max(dfH2Gen[!,:H2Gen_min_output][k],dfH2Gen[!,:Ramp_Down_Percentage][k]))*dfH2Gen[!,:Cap_Size_MW][k]*EP[:vH2GenShut][k,t])

    ## For Interior Hours
    # rampup constraints
    @constraint(EP,[k in H2_GEN_COMMIT, t in INTERIOR_SUBPERIODS],
        EP[:vH2Gen][k,t]-EP[:vH2Gen][k,t-1] <= dfH2Gen[!,:Ramp_Up_Percentage][k]*dfH2Gen[!,:Cap_Size_MW][k]*(EP[:vH2GenCOMMIT][k,t]-EP[:vH2GenStart][k,t])
            + min(inputs["pH2_Max"][k,t],max(dfH2Gen[!,:H2Gen_min_output][k],dfH2Gen[!,:Ramp_Up_Percentage][k]))*dfH2Gen[!,:Cap_Size_MW][k]*EP[:vH2GenStart][k,t]
            -dfH2Gen[!,:H2Gen_min_output][k]*dfH2Gen[!,:Cap_Size_MW][k]*EP[:vH2GenShut][k,t])

    # rampdown constraints
    @constraint(EP,[k in H2_GEN_COMMIT, t in INTERIOR_SUBPERIODS],
    EP[:vH2Gen][k,t-1]-EP[:vH2Gen][k,t] <= dfH2Gen[!,:Ramp_Down_Percentage][k]*dfH2Gen[!,:Cap_Size_MW][k]*(EP[:vH2GenCOMMIT][k,t]-EP[:vH2GenStart][k,t])
    -dfH2Gen[!,:H2Gen_min_output][k]*dfH2Gen[!,:Cap_Size_MW][k]*EP[:vH2GenStart][k,t]
    +min(inputs["pH2_Max"][k,t],max(dfH2Gen[!,:H2Gen_min_output][k],dfH2Gen[!,:Ramp_Down_Percentage][k]))*dfH2Gen[!,:Cap_Size_MW][k]*EP[:vH2GenShut][k,t])

    @constraints(EP, begin
    # Minimum stable generated per technology "k" at hour "t" > = Min stable output level
    [k in H2_GEN_COMMIT, t=1:T], EP[:vH2Gen][k,t] >= dfH2Gen[!,:Cap_Size_MW][k] *dfH2Gen[!,:H2Gen_min_output][k]* EP[:vH2GenCOMMIT][k,t]
    # Maximum power generated per technology "k" at hour "t" < Max power
    [k in H2_GEN_COMMIT, t=1:T], EP[:vH2Gen][k,t] <= dfH2Gen[!,:Cap_Size_MW][k] * EP[:vH2GenCOMMIT][k,t] * inputs["pH2_Max"][k,t]
    end)


    ### Minimum up and down times (Constraints #9-10)
    for y in H2_GEN_COMMIT

        ## up time
        Up_Time = Int(floor(dfH2Gen[!,:Up_Time][y]))
        Up_Time_HOURS = [] # Set of hours in the summation term of the maximum up time constraint for the first subperiod of each representative period
        for s in START_SUBPERIODS
            Up_Time_HOURS = union(Up_Time_HOURS, (s+1):(s+Up_Time-1))
        end

        @constraints(EP, begin
            # cUpTimeInterior: Constraint looks back over last n hours, where n = dfH2Gen[!,:Up_Time][y]
            [t in setdiff(INTERIOR_SUBPERIODS,Up_Time_HOURS)], EP[:vH2GenCOMMIT][y,t] >= sum(EP[:vH2GenStart][y,e] for e=(t-dfH2Gen[!,:Up_Time][y]):t)

            # cUpTimeWrap: If n is greater than the number of subperiods left in the period, constraint wraps around to first hour of time series
            # cUpTimeWrap constraint equivalant to: sum(EP[:vH2GenStart][y,e] for e=(t-((t%hours_per_subperiod)-1):t))+sum(EP[:vH2GenStart][y,e] for e=(hours_per_subperiod_max-(dfH2Gen[!,:Up_Time][y]-(t%hours_per_subperiod))):hours_per_subperiod_max)
            [t in Up_Time_HOURS], EP[:vH2GenCOMMIT][y,t] >= sum(EP[:vH2GenStart][y,e] for e=(t-((t%hours_per_subperiod)-1):t))+sum(EP[:vH2GenStart][y,e] for e=((t+hours_per_subperiod-(t%hours_per_subperiod))-(dfH2Gen[!,:Up_Time][y]-(t%hours_per_subperiod))):(t+hours_per_subperiod-(t%hours_per_subperiod)))

            # cUpTimeStart:
            # NOTE: Expression t+hours_per_subperiod-(t%hours_per_subperiod) is equivalant to "hours_per_subperiod_max"
            [t in START_SUBPERIODS], EP[:vH2GenCOMMIT][y,t] >= EP[:vH2GenStart][y,t]+sum(EP[:vH2GenStart][y,e] for e=((t+hours_per_subperiod-1)-(dfH2Gen[!,:Up_Time][y]-1)):(t+hours_per_subperiod-1))
        end)

        ## down time
        Down_Time = Int(floor(dfH2Gen[!,:Down_Time][y]))
        Down_Time_HOURS = [] # Set of hours in the summation term of the maximum down time constraint for the first subperiod of each representative period
        for s in START_SUBPERIODS
            Down_Time_HOURS = union(Down_Time_HOURS, (s+1):(s+Down_Time-1))
        end

        # Constraint looks back over last n hours, where n = dfH2Gen[!,:Down_Time][y]
        # TODO: Replace LHS of constraints in this block with eNumPlantsOffline[y,t]
        @constraints(EP, begin
            # cDownTimeInterior: Constraint looks back over last n hours, where n = inputs["pDMS_Time"][y]
            [t in setdiff(INTERIOR_SUBPERIODS,Down_Time_HOURS)], EP[:eH2GenTotalCap][y]/dfH2Gen[!,:Cap_Size_MW][y]-EP[:vH2GenCOMMIT][y,t] >= sum(EP[:vH2GenShut][y,e] for e=(t-dfH2Gen[!,:Down_Time][y]):t)

            # cDownTimeWrap: If n is greater than the number of subperiods left in the period, constraint wraps around to first hour of time series
            # cDownTimeWrap constraint equivalant to: EP[:eH2GenTotalCap][y]/dfH2Gen[!,:Cap_Size_MW][y]-EP[:vH2GenCOMMIT][y,t] >= sum(EP[:vH2GenShut][y,e] for e=(t-((t%hours_per_subperiod)-1):t))+sum(EP[:vH2GenShut][y,e] for e=(hours_per_subperiod_max-(dfH2Gen[!,:Down_Time][y]-(t%hours_per_subperiod))):hours_per_subperiod_max)
            [t in Down_Time_HOURS], EP[:eH2GenTotalCap][y]/dfH2Gen[!,:Cap_Size_MW][y]-EP[:vH2GenCOMMIT][y,t] >= sum(EP[:vH2GenShut][y,e] for e=(t-((t%hours_per_subperiod)-1):t))+sum(EP[:vH2GenShut][y,e] for e=((t+hours_per_subperiod-(t%hours_per_subperiod))-(dfH2Gen[!,:Down_Time][y]-(t%hours_per_subperiod))):(t+hours_per_subperiod-(t%hours_per_subperiod)))

            # cDownTimeStart:
            # NOTE: Expression t+hours_per_subperiod-(t%hours_per_subperiod) is equivalant to "hours_per_subperiod_max"
            [t in START_SUBPERIODS], EP[:eH2GenTotalCap][y]/dfH2Gen[!,:Cap_Size_MW][y]-EP[:vH2GenCOMMIT][y,t]  >= EP[:vH2GenShut][y,t]+sum(EP[:vH2GenShut][y,e] for e=((t+hours_per_subperiod-1)-(dfH2Gen[!,:Down_Time][y]-1)):(t+hours_per_subperiod-1))
        end)
    end

    return EP

end