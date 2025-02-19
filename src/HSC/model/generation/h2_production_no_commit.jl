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
    h2_production_no_commit(EP::Model, inputs::Dict,setup::Dict)

This function defines the operating constraints for hydrogen generation plants (thermal and electrolysis) NOT subject to unit commitment constraints on power plant start-ups and shut-down decisions $g \in \mathcal{THE} \setminus \mathcal{UC}$.

**Hydrogen balance expressions**

Contributions to the hydrogen balance expression from each thermal resources without unit commitment $g \in \mathcal{THE} \setminus \mathcal{UC}$ are also defined below. If liquid hydrogen is modeled, a liquid hydrogen balance expression is needed and contributions to the gas balance are accounted for. 
    
```math
\begin{equation*}
    HydrogenBalGas_{GEN} = \sum_{g \in \mathcal{G}} x_{g,z,t}^{\textrm{H,GEN}} - \sum_{g \in \mathcal{G}} x_{g,z,t}^{\textrm{H,LIQ}} + \sum_{g \in \mathcal{G}} x_{g,z,t}^{\textrm{H,EVAP}} \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```    

```math
\begin{equation*}
    HydrogenBalLiq_{GEN} = \sum_{g \in \mathcal{G}} x_{g,z,t}^{\textrm{H,LIQ}} - \sum_{g \in \mathcal{G}} x_{g,z,t}^{\textrm{H,EVAP}} \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```    

**Ramping limits**

Thermal resources not subject to unit commitment $k \in \mathcal{THE} \setminus \mathcal{UC}$ adhere instead to the following ramping limits on hourly changes in hydrogen output:

```math
\begin{equation*}
    x_{g,z,t-1}^{\textrm{H,GEN}} - x_{g,z,t}^{\textrm{H,GEN}} \leq \kappa_{g,z}^{\textrm{H,DN}} y_{g,z}^{\textrm{H,GEN}} \quad \forall g \in \mathcal{THE} \setminus \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

```math
\begin{equation*}
    x_{g,z,t}^{\textrm{H,GEN}} - x_{g,z,t-1}^{\textrm{H,GEN}} \leq \kappa_{g,z}^{\textrm{H,UP}} y_{g,z}^{\textrm{H,GEN}} \quad \forall g \in \mathcal{THE} \setminus \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```
(See Constraints 1-2 in the code)

This set of time-coupling constraints wrap around to ensure the hydrogen output in the first time step of each year (or each representative period), $t \in \mathcal{T}^{start}$, is within the eligible ramp of the power output in the final time step of the year (or each representative period), $t+\tau^{period}-1$.

**Minimum and maximum hydrogen output**

```math
\begin{equation*}
    x_{g,z,t}^{\textrm{H,GEN}} \geq \underline{R_{g,z}^{\textrm{H,GEN}}} \times y_{g,z}^{\textrm{H,GEN}} \quad \forall g \in \mathcal{THE} \setminus \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

```math
\begin{equation*}
    x_{g,z,t}^{\textrm{H,GEN}} \leq \overline{R_{g,z}^{\textrm{H,GEN}}} \times y_{g,z}^{\textrm{H,GEN}} \quad \forall g \in \mathcal{THE} \setminus \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```
(See Constraints 3-4 in the code)
"""
function h2_production_no_commit(EP::Model, inputs::Dict,setup::Dict)

    print_and_log(" -- H2 Production (No Unit Commitment) Module")
    
    #Rename H2Gen dataframe
    dfH2Gen = inputs["dfH2Gen"]

    T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Number of zones
    H = inputs["H2_GEN"]        #NUmber of hydrogen generation units 
    
    H2_GAS_NO_COMMIT = inputs["H2_GEN_NO_COMMIT"]

    if setup["ModelH2Liquid"] ==1
        H2_LIQ_NO_COMMIT = inputs["H2_LIQ_NO_COMMIT"]
        H2_EVAP_NO_COMMIT = inputs["H2_EVAP_NO_COMMIT"]
        H2_GEN_NO_COMMIT = union(H2_GAS_NO_COMMIT, H2_LIQ_NO_COMMIT, H2_EVAP_NO_COMMIT)
    else
        H2_GEN_NO_COMMIT = H2_GAS_NO_COMMIT
    end

    #Define start subperiods and interior subperiods
    START_SUBPERIODS = inputs["START_SUBPERIODS"]
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
    hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod

    ###Expressions###

    #H2 Balance expressions
    @expression(EP, eH2GenNoCommit[t=1:T, z=1:Z],
    sum(EP[:vH2Gen][k,t] for k in intersect(H2_GAS_NO_COMMIT, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID])))

    EP[:eH2Balance] += eH2GenNoCommit

    if setup["ModelH2Liquid"]==1
        #H2 LIQUID Balance expressions
        @expression(EP, eH2LiqNoCommit[t=1:T, z=1:Z],
        sum(EP[:vH2Gen][k,t] for k in intersect(H2_LIQ_NO_COMMIT, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID])))

        # Add Liquid H2 to liquid balance, AND REMOVE it from the gas balance
        EP[:eH2Balance] -= eH2LiqNoCommit
        EP[:eH2LiqBalance] += eH2LiqNoCommit

        #H2 Evaporation Balance expressions
        if !isempty(H2_EVAP_NO_COMMIT)
            @expression(EP, eH2EvapNoCommit[t=1:T, z=1:Z],
            sum(EP[:vH2Gen][k,t] for k in intersect(H2_EVAP_NO_COMMIT, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID])))

            # Add evaporated H2 to gas balance, AND REMOVE it from the liquid balance
            EP[:eH2Balance] += eH2EvapNoCommit
            EP[:eH2LiqBalance] -= eH2EvapNoCommit
        end
    end

    #Power Consumption for H2 Generation
    @expression(EP, ePowerBalanceH2GenNoCommit[t=1:T, z=1:Z],
    sum(EP[:vP2G][k,t] for k in intersect(H2_GEN_NO_COMMIT, dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID]))) 

    EP[:ePowerBalance] += -ePowerBalanceH2GenNoCommit


    ##For CO2 Polcy constraint right hand side development - power consumption by zone and each time step
    EP[:eH2NetpowerConsumptionByAll] += ePowerBalanceH2GenNoCommit


    ###Constraints###
    # Power and natural gas consumption associated with H2 generation in each time step
    @constraints(EP, begin
        #Power Balance
        [k in H2_GEN_NO_COMMIT, t = 1:T], EP[:vP2G][k,t] == EP[:vH2Gen][k,t] * dfH2Gen[!,:etaP2G][k]
    end)
    
    @constraints(EP, begin
    # Minimum stable generated per technology "k" at hour "t" > = Min stable output level
    [k in H2_GEN_NO_COMMIT, t=1:T], EP[:vH2Gen][k,t] >= EP[:eH2GenTotalCap][k] * dfH2Gen[!,:H2Gen_min_output][k]
    end)

    @constraints(EP, begin
    # Maximum power generated per technology "k" at hour "t"
    [k in H2_GEN_NO_COMMIT, t=1:T], EP[:vH2Gen][k,t] <= EP[:eH2GenTotalCap][k]* inputs["pH2_Max"][k,t]
    end)

    #Ramping cosntraints 
    @constraints(EP, begin

        ## Maximum ramp up between consecutive hours
        # Start Hours: Links last time step with first time step, ensuring position in hour 1 is within eligible ramp of final hour position
        # NOTE: We should make wrap-around a configurable option
        [k in H2_GEN_NO_COMMIT, t in START_SUBPERIODS], EP[:vH2Gen][k,t]-EP[:vH2Gen][k,(t + hours_per_subperiod-1)] <= dfH2Gen[!,:Ramp_Up_Percentage][k] * EP[:eH2GenTotalCap][k]

        # Interior Hours
        [k in H2_GEN_NO_COMMIT, t in INTERIOR_SUBPERIODS], EP[:vH2Gen][k,t]-EP[:vH2Gen][k,t-1] <= dfH2Gen[!,:Ramp_Up_Percentage][k]*EP[:eH2GenTotalCap][k]

        ## Maximum ramp down between consecutive hours
        # Start Hours: Links last time step with first time step, ensuring position in hour 1 is within eligible ramp of final hour position
        [k in H2_GEN_NO_COMMIT, t in START_SUBPERIODS], EP[:vH2Gen][k,(t+hours_per_subperiod-1)] - EP[:vH2Gen][k,t] <= dfH2Gen[!,:Ramp_Down_Percentage][k] * EP[:eH2GenTotalCap][k]

        # Interior Hours
        [k in H2_GEN_NO_COMMIT, t in INTERIOR_SUBPERIODS], EP[:vH2Gen][k,t-1] - EP[:vH2Gen][k,t] <= dfH2Gen[!,:Ramp_Down_Percentage][k] * EP[:eH2GenTotalCap][k]
    
    end)

    return EP

end




