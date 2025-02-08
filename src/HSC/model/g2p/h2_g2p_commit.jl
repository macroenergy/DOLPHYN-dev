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
    h2_g2p_commit(EP::Model, inputs::Dict, setup::Dict)

This module creates decision variables, expressions, and constraints related to various hydrogen to power technologies with unit commitment constraints (e.g. natural gas reforming etc.)

**G2P Unit commitment decision variables:**

This module defines the commitment state variable $n_{k,z,t}^{\textrm{H,G2P}}$ of generator cluster $k$ in zone $z$ at time $t$ $\forall k \in \mathcal{K}, z \in \mathcal{Z}, t \in \mathcal{T}$.

This module defines the number of startup decision variable $n_{k,z,t}^{\textrm{H,G2P,UP}}$ of generator cluster $k$ in zone $z$ at time $t$ $\forall k \in \mathcal{K}, z \in \mathcal{Z}, t \in \mathcal{T}$.

This module defines the number of shutdown decision variable $n_{k,z,t}^{\textrm{H,G2P,DN}}$ of generator cluster $k$ in zone $z$ at time $t$ $\forall k \in \mathcal{K}, z \in \mathcal{Z}, t \in \mathcal{T}$.

The variable defined in this file named after ```vH2G2PCOMMIT``` covers $\n_{k,z,t}^{\textrm{H,G2P}}$.

The variable defined in this file named after ```vH2G2PSTART``` covers $\n_{k,z,t}^{\textrm{H,G2P,UP}}$.

The variable defined in this file named after ```vH2G2PSHUT``` covers $\n_{k,z,t}^{\textrm{H,G2P,DN}}$.

**Cost expressions:**

The total cost of start-ups across g2p generators subject to unit commitment ($h \in UC$) and all time periods, t is expressed as:

```math
\begin{equation*}
    \textrm{C}^{\textrm{H,G2P,start}} = \sum_{k \in \mathcal{UC}} \sum_{t \in \mathcal{T}} \omega_t \times \textrm{c}_{k}^{\textrm{H,G2P,start}} \times n_{k,z,t}^{\textrm{H,G2P,UP}}
\end{equation*}
```

**Startup and shutdown events (thermal plant cycling)**

*Capacitated limits on g2p unit commitment decision variables*

Hydrogen to power resources subject to unit commitment ($k \in \mathcal{UC}$) adhere to the following constraints on commitment states, startup events, and shutdown events, which limit each decision to be no greater than the maximum number of discrete units installed (as per the following three constraints):

```math
\begin{equation*}
    n_{k,z,t}^{\textrm{H,G2P}} \leq \frac{y_{k,z}^{\textrm{H,G2P}}}{\Omega_{k,z}^{\textrm{H,G2P,size}}} \quad \forall k \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

```math
\begin{aligned}
    n_{k,z,t}^{\textrm{H,G2P,UP}} \leq \frac{y_{k,z}^{\textrm{H,G2P}}}{\Omega_{k,z}^{\textrm{H,G2P,size}}} \quad \forall k \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```

```math
\begin{aligned}
    n_{k,z,t}^{\textrm{H,G2P,DN}} \leq \frac{y_{k,z}^{\textrm{H,G2P}}}{\Omega_{k,z}^{\textrm{H,G2P,size}}} \quad \forall k \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```
where decision $n_{k,z,t}^{\textrm{H,G2P}}$ designates the commitment state of generator cluster $k$ in zone $z$ at time $t$, 
decision $n_{k,z,t}^{\textrm{H,G2P,UP}}$ represents number of startup decisions, 
decision $n_{k,z,t}^{\textrm{H,G2P,DN}}$ represents number of shutdown decisions, 
$y_{k,z}^{\textrm{H,G2P}}$ is the total installed capacity, and parameter $\Omega_{k,z}^{\textrm{H,G2P,size}}$ is the unit size.
(See Constraints 1-3 in the code)

*Hydrogen to power commitment state constraint linking start-up and shut-down decisions*

Additionally, the following constarint maintains the commitment state variable across time, 
$n_{k,z,t}^{\textrm{H,G2P}}$, as the sum of the commitment state in the prior, $n_{k,z,t-1}^{\textrm{H,G2P}}$, 
period plus the number of units started in the current period, $n_{k,z,t}^{\textrm{H,G2P,UP}}$, 
minus the number of units shut down in the current period, $n_{k,z,t}^{\textrm{H,G2P,DN}}$:

```math
\begin{aligned}
    n_{k,z,t}^{\textrm{H,G2P}} &= n_{k,z,t-1}^{\textrm{H,G2P}} + n_{k,z,t}^{\textrm{H,G2P,UP}} - n_{k,z,t}^{\textrm{H,G2P,DN}} \quad \forall k \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}^{interior} \\
    n_{k,z,t}^{\textrm{H,G2P}} &= n_{k,z,t +\tau^{period}-1}^{\textrm{H,G2P}} + n_{k,z,t}^{\textrm{H,G2P,UP}} - n_{k,z,t}^{\textrm{H,G2P,DN}} \quad \forall k \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}^{start}
\end{aligned}
```
(See Constraint 4 in the code)

Like other time-coupling constraints, this constraint wraps around to link the commitment state in the first time step of the year (or each representative period), $t \in \mathcal{T}^{start}$, to the last time step of the year (or each representative period), $t+\tau^{period}-1$.

**Ramping constraints**

Thermal resources subject to unit commitment ($k \in \mathcal{UC}$) adhere to the following ramping constraints on hourly changes in power output:

```math
\begin{aligned}
    x_{k,z,t-1}^{\textrm{H,G2P}} - x_{k,z,t}^{\textrm{H,G2P}} &\leq \kappa_{k,z}^{\textrm{H,G2P,DN}} \times \Omega_{k,z}^{\textrm{H,G2P,size}} \times \left(n_{k,z,t}^{\textrm{H,G2P,UP}} - n_{k,z,t}^{\textrm{H,G2P,DN}}\right) \\
    \qquad &- \underline{\rho_{k,z,t}^{\textrm{H,G2P}}} \times \Omega_{k,z}^{\textrm{H,G2P,size}} \times n_{k,z,t}^{\textrm{H,G2P,DN}} \\
    \qquad &+ \text{min}(\overline{\rho_{k,z,t}^{\textrm{H,G2P}}}}, \text{max}(\underline{\rho_{k,z,t}^{\textrm{H,G2P}}}, \kappa_{k,z}^{\textrm{H,G2P}})) \times \Omega_{k,z}^{\textrm{H,G2P,size}} \times n_{k,z,t}^{\textrm{H,G2P,DN}} \quad \forall k \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T} 
\end{aligned}
```

```math
\begin{aligned}
    x_{k,z,t}^{\textrm{H,G2P}} - x_{k,z,t-1}^{\textrm{H,G2P}} &\leq \kappa_{k,z}^{\textrm{H,G2P,UP}} \times \Omega_{k,z}^{\textrm{H,G2P,size}} \times \left(n_{k,z,t}^{\textrm{H,G2P,UP}} - n_{k,z,t}^{\textrm{H,G2P,DN}}\right) \\
    \qquad &+ \text{min}(\overline{\rho}_{k,z,t}^{\textrm{H,G2P}}, \text{max}(\underline{\rho}_{k,z,t}^{\textrm{H,G2P}}, \kappa_{k,z}^{\textrm{H,G2P,UP}})) \times \Omega_{k,z}^{\textrm{H,G2P,size}} \times n_{k,z,t}^{\textrm{H,G2P,DN}} \\
    \qquad &- \underline{\rho}_{k,z,t}^{\textrm{H,G2P}} \times \Omega_{k,z}^{\textrm{H,G2P,size}} \times n_{k,z,t}^{\textrm{H,G2P,DN}} \quad \forall k \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{aligned}
```
(See Constraints 5-6 in the code)

**Minimum and maximum power output**

If not modeling regulation and spinning reserves, hydrogen to power resources subject to unit commitment adhere to the following constraints that ensure power output does not exceed minimum and maximum feasible levels:

```math
\begin{equation*}
    x_{k,z,t}^{\textrm{H,G2P}} \geq \underline{\rho}_{k,z,t}^{\textrm{H,G2P}} \times \Omega_{k,z}^{\textrm{H,G2P,size}} \times n_{k,z,t}^{\textrm{H,G2P,UP}} \quad \forall y \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

```math
\begin{equation*}
    x_{k,z,t}^{\textrm{H,G2P}} \geq \overline{\rho}_{k,z}^{\textrm{H,G2P}} \times \Omega_{k,z}^{\textrm{H,G2P,size}} \times n_{k,z,t}^{\textrm{H,G2P,UP}} \quad \forall y \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

(See Constraints 7-8 the code)

**Minimum and maximum up and down time**

Hydrogen to power resources subject to unit commitment adhere to the following constraints on the minimum time steps after start-up before a unit can shutdown again (minimum up time) and the minimum time steps after shut-down before a unit can start-up again (minimum down time):

```math
\begin{equation*}
    n_{k,z,t}^{\textrm{H,G2P}} \geq \displaystyle \sum_{\tau = t-\tau_{k,z}^{\textrm{H,G2P,UP}}}^t n_{k,z,\tau}^{\textrm{H,G2P,UP}} \quad \forall y \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

```math
\begin{equation*}
    \frac{y_{k,z}^{\textrm{H,G2P}}}{\Omega_{k,z}^{\textrm{H,G2P,size}}} - n_{k,z,t}^{\textrm{H,G2P,UP}} \geq \displaystyle \sum_{\tau = t-\tau_{k,z}^{\textrm{H,G2P,DN}}}^t n_{k,z,\tau}^{\textrm{H,G2P,DN}} \quad \forall y \in \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```
(See Constraints 9-10 in the code)

where $\tau_{k,z}^{\textrm{H,G2P,UP}}$ and $\tau_{k,z}^{DN}$ is the minimum up or down time for units in generating cluster $k$ in zone $z$.

Like with the ramping constraints, the minimum up and down constraint time also wrap around from the start of each time period to the end of each period.
It is recommended that users of DOLPHYN must use longer subperiods than the longest min up/down time if modeling UC. Otherwise, the model will report error.
"""
function h2_g2p_commit(EP::Model, inputs::Dict, setup::Dict)

    #Rename H2Gen dataframe
    dfH2G2P = inputs["dfH2G2P"]
    H2G2PCommit = setup["H2G2PCommit"]

    T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Number of zones
    H = inputs["H"]        #NUmber of hydrogen generation units 
    
    H2_G2P_COMMIT = inputs["H2_G2P_COMMIT"]
    H2_G2P_NEW_CAP = inputs["H2_G2P_NEW_CAP"] 
    H2_G2P_RET_CAP = inputs["H2_G2P_RET_CAP"] 
    
    #Define start subperiods and interior subperiods
    START_SUBPERIODS = inputs["START_SUBPERIODS"]
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
    hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod

    ###Variables###

    # commitment state variable
    @variable(EP, vH2G2PCOMMIT[k in H2_G2P_COMMIT, t=1:T] >= 0)
    # Start up variable
    @variable(EP, vH2G2PStart[k in H2_G2P_COMMIT, t=1:T] >= 0)
    # Shutdown Variable
    @variable(EP, vH2G2PShut[k in H2_G2P_COMMIT, t=1:T] >= 0)

    ###Expressions###

    #Objective function expressions
    # Startup costs of "generation" for resource "y" during hour "t"
    @expression(EP, eH2G2PCStart[k in H2_G2P_COMMIT, t=1:T],(inputs["omega"][t]*inputs["C_G2P_Start"][k]*vH2G2PStart[k,t]))


    # Julia is fastest when summing over one row one column at a time
    @expression(EP, eTotalH2G2PCStartT[t=1:T], sum(eH2G2PCStart[k,t] for k in H2_G2P_COMMIT))
    @expression(EP, eTotalH2G2PCStartK[k = H2_G2P_COMMIT], sum(eH2G2PCStart[k,t] for t in 1:T))
    @expression(EP, eTotalH2G2PCStart, sum(eTotalH2G2PCStartT[t] for t=1:T))

    EP[:eObj] += eTotalH2G2PCStart

    # H2 Balance expressions
    @expression(EP, eH2G2PCommit[t=1:T, z=1:Z],
    sum(EP[:vH2G2P][k,t] for k in intersect(H2_G2P_COMMIT, dfH2G2P[dfH2G2P[!,:Zone].==z,:][!,:R_ID])))

    EP[:eH2Balance] -= eH2G2PCommit

    # Power generation from g2p units
    @expression(EP, ePowerBalanceH2G2PCommit[t=1:T, z=1:Z],
    sum(EP[:vPG2P][k,t] for k in intersect(H2_G2P_COMMIT, dfH2G2P[dfH2G2P[!,:Zone].==z,:][!,:R_ID]))) 

    EP[:ePowerBalance] += ePowerBalanceH2G2PCommit

    ### Constraints ###
    ## Declaration of integer/binary variables
    if H2G2PCommit == 1 # Integer UC constraints
        for k in H2_G2P_COMMIT
            set_integer.(vH2G2PCOMMIT[k,:])
            set_integer.(vH2G2PStart[k,:])
            set_integer.(vH2G2PShut[k,:])
            if k in H2_G2P_RET_CAP
                set_integer(EP[:vH2G2PRetCap][k])
            end
            if k in H2_G2P_NEW_CAP 
                set_integer(EP[:vH2G2PNewCap][k])
            end
        end
    end #END unit commitment configuration

        ###Constraints###
        @constraints(EP, begin
        #Power Balance
        [k in H2_G2P_COMMIT, t = 1:T], EP[:vPG2P][k,t] == EP[:vH2G2P][k,t] * dfH2G2P[!,:etaG2P][k]
    end)

    ### Capacitated limits on unit commitment decision variables (Constraints #1-3)
    @constraints(EP, begin
        [k in H2_G2P_COMMIT, t=1:T], EP[:vH2G2PCOMMIT][k,t] <= EP[:eH2G2PTotalCap][k]/dfH2G2P[!,:Cap_Size_MW][k]
        [k in H2_G2P_COMMIT, t=1:T], EP[:vH2G2PStart][k,t] <= EP[:eH2G2PTotalCap][k]/dfH2G2P[!,:Cap_Size_MW][k]
        [k in H2_G2P_COMMIT, t=1:T], EP[:vH2G2PShut][k,t] <= EP[:eH2G2PTotalCap][k]/dfH2G2P[!,:Cap_Size_MW][k]
    end)

    # Commitment state constraint linking startup and shutdown decisions (Constraint #4)
    @constraints(EP, begin
    # For Start Hours, links first time step with last time step in subperiod
    [k in H2_G2P_COMMIT, t in START_SUBPERIODS], EP[:vH2G2PCOMMIT][k,t] == EP[:vH2G2PCOMMIT][k,(t+hours_per_subperiod-1)] + EP[:vH2G2PStart][k,t] - EP[:vH2G2PShut][k,t]
    # For all other hours, links commitment state in hour t with commitment state in prior hour + sum of start up and shut down in current hour
    [k in H2_G2P_COMMIT, t in INTERIOR_SUBPERIODS], EP[:vH2G2PCOMMIT][k,t] == EP[:vH2G2PCOMMIT][k,t-1] + EP[:vH2G2PStart][k,t] - EP[:vH2G2PShut][k,t]
    end)


    ### Maximum ramp up and down between consecutive hours (Constraints #5-6)

    ## For Start Hours
    # Links last time step with first time step, ensuring position in hour 1 is within eligible ramp of final hour position
    # rampup constraints
    @constraint(EP,[k in H2_G2P_COMMIT, t in START_SUBPERIODS],
    EP[:vPG2P][k,t]-EP[:vPG2P][k,(t+hours_per_subperiod-1)] <= dfH2G2P[!,:Ramp_Up_Percentage][k] * dfH2G2P[!,:Cap_Size_MW][k]*(EP[:vH2G2PCOMMIT][k,t]-EP[:vH2G2PStart][k,t])
    + min(inputs["pH2_g2p_Max"][k,t],max(dfH2G2P[!,:G2P_min_output][k],dfH2G2P[!,:Ramp_Up_Percentage][k]))*dfH2G2P[!,:Cap_Size_MW][k]*EP[:vH2G2PStart][k,t]
    - dfH2G2P[!,:G2P_min_output][k] * dfH2G2P[!,:Cap_Size_MW][k] * EP[:vH2G2PShut][k,t])

    # rampdown constraints
    @constraint(EP,[k in H2_G2P_COMMIT, t in START_SUBPERIODS],
    EP[:vPG2P][k,(t+hours_per_subperiod-1)]-EP[:vPG2P][k,t] <= dfH2G2P[!,:Ramp_Down_Percentage][k]*dfH2G2P[!,:Cap_Size_MW][k]*(EP[:vH2G2PCOMMIT][k,t]-EP[:vH2G2PStart][k,t])
    - dfH2G2P[!,:G2P_min_output][k]*dfH2G2P[!,:Cap_Size_MW][k]*EP[:vH2G2PStart][k,t]
    + min(inputs["pH2_g2p_Max"][k,t],max(dfH2G2P[!,:G2P_min_output][k],dfH2G2P[!,:Ramp_Down_Percentage][k]))*dfH2G2P[!,:Cap_Size_MW][k]*EP[:vH2G2PShut][k,t])

    ## For Interior Hours
    # rampup constraints
    @constraint(EP,[k in H2_G2P_COMMIT, t in INTERIOR_SUBPERIODS],
        EP[:vPG2P][k,t]-EP[:vPG2P][k,t-1] <= dfH2G2P[!,:Ramp_Up_Percentage][k]*dfH2G2P[!,:Cap_Size_MW][k]*(EP[:vH2G2PCOMMIT][k,t]-EP[:vH2G2PStart][k,t])
            + min(inputs["pH2_g2p_Max"][k,t],max(dfH2G2P[!,:G2P_min_output][k],dfH2G2P[!,:Ramp_Up_Percentage][k]))*dfH2G2P[!,:Cap_Size_MW][k]*EP[:vH2G2PStart][k,t]
            -dfH2G2P[!,:G2P_min_output][k]*dfH2G2P[!,:Cap_Size_MW][k]*EP[:vH2G2PShut][k,t])

    # rampdown constraints
    @constraint(EP,[k in H2_G2P_COMMIT, t in INTERIOR_SUBPERIODS],
    EP[:vPG2P][k,t-1]-EP[:vPG2P][k,t] <= dfH2G2P[!,:Ramp_Down_Percentage][k]*dfH2G2P[!,:Cap_Size_MW][k]*(EP[:vH2G2PCOMMIT][k,t]-EP[:vH2G2PStart][k,t])
    -dfH2G2P[!,:G2P_min_output][k]*dfH2G2P[!,:Cap_Size_MW][k]*EP[:vH2G2PStart][k,t]
    +min(inputs["pH2_g2p_Max"][k,t],max(dfH2G2P[!,:G2P_min_output][k],dfH2G2P[!,:Ramp_Down_Percentage][k]))*dfH2G2P[!,:Cap_Size_MW][k]*EP[:vH2G2PShut][k,t])

    @constraints(EP, begin
    # Minimum stable generated per technology "k" at hour "t" > = Min stable output level
    [k in H2_G2P_COMMIT, t=1:T], EP[:vPG2P][k,t] >= dfH2G2P[!,:Cap_Size_MW][k] *dfH2G2P[!,:G2P_min_output][k]* EP[:vH2G2PCOMMIT][k,t]
    # Maximum power generated per technology "k" at hour "t" < Max power
    [k in H2_G2P_COMMIT, t=1:T], EP[:vPG2P][k,t] <= dfH2G2P[!,:Cap_Size_MW][k] * EP[:vH2G2PCOMMIT][k,t] * inputs["pH2_g2p_Max"][k,t]
    end)


    ### Minimum up and down times (Constraints #9-10)
    for y in H2_G2P_COMMIT

        ## up time
        Up_Time = Int(floor(dfH2G2P[!,:Up_Time][y]))
        Up_Time_HOURS = [] # Set of hours in the summation term of the maximum up time constraint for the first subperiod of each representative period
        for s in START_SUBPERIODS
            Up_Time_HOURS = union(Up_Time_HOURS, (s+1):(s+Up_Time-1))
        end

        @constraints(EP, begin
            # cUpTimeInterior: Constraint looks back over last n hours, where n = dfH2G2P[!,:Up_Time][y]
            [t in setdiff(INTERIOR_SUBPERIODS,Up_Time_HOURS)], EP[:vH2G2PCOMMIT][y,t] >= sum(EP[:vH2G2PStart][y,e] for e=(t-dfH2G2P[!,:Up_Time][y]):t)

            # cUpTimeWrap: If n is greater than the number of subperiods left in the period, constraint wraps around to first hour of time series
            # cUpTimeWrap constraint equivalant to: sum(EP[:vH2G2PStart][y,e] for e=(t-((t%hours_per_subperiod)-1):t))+sum(EP[:vH2G2PStart][y,e] for e=(hours_per_subperiod_max-(dfH2G2P[!,:Up_Time][y]-(t%hours_per_subperiod))):hours_per_subperiod_max)
            [t in Up_Time_HOURS], EP[:vH2G2PCOMMIT][y,t] >= sum(EP[:vH2G2PStart][y,e] for e=(t-((t%hours_per_subperiod)-1):t))+sum(EP[:vH2G2PStart][y,e] for e=((t+hours_per_subperiod-(t%hours_per_subperiod))-(dfH2G2P[!,:Up_Time][y]-(t%hours_per_subperiod))):(t+hours_per_subperiod-(t%hours_per_subperiod)))

            # cUpTimeStart:
            # NOTE: Expression t+hours_per_subperiod-(t%hours_per_subperiod) is equivalant to "hours_per_subperiod_max"
            [t in START_SUBPERIODS], EP[:vH2G2PCOMMIT][y,t] >= EP[:vH2G2PStart][y,t]+sum(EP[:vH2G2PStart][y,e] for e=((t+hours_per_subperiod-1)-(dfH2G2P[!,:Up_Time][y]-1)):(t+hours_per_subperiod-1))
        end)

        ## down time
        Down_Time = Int(floor(dfH2G2P[!,:Down_Time][y]))
        Down_Time_HOURS = [] # Set of hours in the summation term of the maximum down time constraint for the first subperiod of each representative period
        for s in START_SUBPERIODS
            Down_Time_HOURS = union(Down_Time_HOURS, (s+1):(s+Down_Time-1))
        end

        # Constraint looks back over last n hours, where n = dfH2G2P[!,:Down_Time][y]
        # TODO: Replace LHS of constraints in this block with eNumPlantsOffline[y,t]
        @constraints(EP, begin
            # cDownTimeInterior: Constraint looks back over last n hours, where n = inputs["pDMS_Time"][y]
            [t in setdiff(INTERIOR_SUBPERIODS,Down_Time_HOURS)], EP[:eH2G2PTotalCap][y]/dfH2G2P[!,:Cap_Size_MW][y]-EP[:vH2G2PCOMMIT][y,t] >= sum(EP[:vH2G2PShut][y,e] for e=(t-dfH2G2P[!,:Down_Time][y]):t)

            # cDownTimeWrap: If n is greater than the number of subperiods left in the period, constraint wraps around to first hour of time series
            # cDownTimeWrap constraint equivalant to: EP[:eH2G2PTotalCap][y]/dfH2G2P[!,:Cap_Size_MW][y]-EP[:vH2G2PCOMMIT][y,t] >= sum(EP[:vH2G2PShut][y,e] for e=(t-((t%hours_per_subperiod)-1):t))+sum(EP[:vH2G2PShut][y,e] for e=(hours_per_subperiod_max-(dfH2G2P[!,:Down_Time][y]-(t%hours_per_subperiod))):hours_per_subperiod_max)
            [t in Down_Time_HOURS], EP[:eH2G2PTotalCap][y]/dfH2G2P[!,:Cap_Size_MW][y]-EP[:vH2G2PCOMMIT][y,t] >= sum(EP[:vH2G2PShut][y,e] for e=(t-((t%hours_per_subperiod)-1):t))+sum(EP[:vH2G2PShut][y,e] for e=((t+hours_per_subperiod-(t%hours_per_subperiod))-(dfH2G2P[!,:Down_Time][y]-(t%hours_per_subperiod))):(t+hours_per_subperiod-(t%hours_per_subperiod)))

            # cDownTimeStart:
            # NOTE: Expression t+hours_per_subperiod-(t%hours_per_subperiod) is equivalant to "hours_per_subperiod_max"
            [t in START_SUBPERIODS], EP[:eH2G2PTotalCap][y]/dfH2G2P[!,:Cap_Size_MW][y]-EP[:vH2G2PCOMMIT][y,t]  >= EP[:vH2G2PShut][y,t]+sum(EP[:vH2G2PShut][y,e] for e=((t+hours_per_subperiod-1)-(dfH2G2P[!,:Down_Time][y]-1)):(t+hours_per_subperiod-1))
        end)
    end

    return EP

end