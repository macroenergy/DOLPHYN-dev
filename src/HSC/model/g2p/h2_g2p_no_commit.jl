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
    h2_g2p_no_commit(EP::Model, inputs::Dict,setup::Dict)

This module creates decision variables, expressions, and constraints related to various hydrogen to power technologies without unit commitment constraints

**Hydrogen balance expressions**

Contributions to the power balance expression from each thermal resources without unit commitment $k \in \mathcal{THE} \setminus \mathcal{UC}$ are also defined as:
    
```math
\begin{equation*}
    HydrogenBal_{G2P} = \sum_{k \in \mathcal{K}} x_{k,z,t}^{\textrm{H,G2P}} \quad \forall k \in \mathcal{G2P} \setminus \mathcal{UC}
\end{equation*}
```    

Thermal resources not subject to unit commitment $k \in \mathcal{THE} \setminus \mathcal{UC}$ adhere instead to the following ramping limits on hourly changes in power output:

```math
\begin{equation*}
    x_{k,z,t-1}^{\textrm{H,G2P}} - x_{k,z,t}^{\textrm{H,G2P}} \leq \kappa_{k,z}^{\textrm{G2P,DN}} y_{k,z}^{\textrm{H,G2P}} \quad \forall k \in \mathcal{THE} \setminus \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

```math
\begin{equation*}
    x_{k,z,t}^{\textrm{H,G2P}} - x_{k,z,t-1}^{\textrm{H,G2P}} \leq \kappa_{k,z}^{\textrm{G2P,UP}} y_{k,z}^{\textrm{H,G2P}} \quad \forall k \in \mathcal{THE} \setminus \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```
(See Constraints 1-2 in the code)

**Minimum and maximum power output**

When not modeling regulation and reserves, hydrogen units not subject to unit commitment decisions are bound by the following limits on maximum and minimum power output:

```math
\begin{equation*}
    x_{k,z,t}^{\textrm{H,G2P}} \geq \underline{\textrm{R}}_{k,z}^{\textrm{H,G2P}}} \times y_{k,z}^{\textrm{H,G2P}} \quad \forall k \in \mathcal{THE} \setminus \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

```math
\begin{equation*}
    x_{k,z,t}^{\textrm{H,G2P}} \leq \overline{\textrm{R}}_{k,z}^{\textrm{H,G2P}}} \times y_{k,z}^{\textrm{H,G2P}} \quad \forall y \in \mathcal{THE} \setminus \mathcal{UC}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```
(See Constraints 3-4 in the code)
"""
function h2_g2p_no_commit(EP::Model, inputs::Dict,setup::Dict)

    #Rename H2Gen dataframe
    dfH2G2P = inputs["dfH2G2P"]

    T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Number of zones
    H = inputs["H2_G2P"]        #NUmber of hydrogen generation units 
    
    H2_G2P_NO_COMMIT = inputs["H2_G2P_NO_COMMIT"]
    
    #Define start subperiods and interior subperiods
    START_SUBPERIODS = inputs["START_SUBPERIODS"]
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
    hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod

    ###Expressions###

    #H2 Balance expressions
    @expression(EP, eH2G2PNoCommit[t=1:T, z=1:Z],
    sum(EP[:vH2G2P][k,t] for k in intersect(H2_G2P_NO_COMMIT, dfH2G2P[dfH2G2P[!,:Zone].==z,:][!,:R_ID])))

    EP[:eH2Balance] -= eH2G2PNoCommit

    #Power Consumption for H2 Generation
    if setup["ParameterScale"] ==1 # IF ParameterScale = 1, power system operation/capacity modeled in GW rather than MW 
        @expression(EP, ePowerBalanceH2G2PNoCommit[t=1:T, z=1:Z],
        sum(EP[:vPG2P][k,t]/ModelScalingFactor for k in intersect(H2_G2P_NO_COMMIT, dfH2G2P[dfH2G2P[!,:Zone].==z,:][!,:R_ID]))) 

    else # IF ParameterScale = 0, power system operation/capacity modeled in MW so no scaling of H2 related power consumption
        @expression(EP, ePowerBalanceH2G2PNoCommit[t=1:T, z=1:Z],
        sum(EP[:vPG2P][k,t] for k in intersect(H2_G2P_NO_COMMIT, dfH2G2P[dfH2G2P[!,:Zone].==z,:][!,:R_ID]))) 
    end

    EP[:ePowerBalance_HSC] += ePowerBalanceH2G2PNoCommit

    ###Constraints###
    # Power and natural gas consumption associated with H2 generation in each time step
    @constraints(EP, begin
        #Power Balance
        [k in H2_G2P_NO_COMMIT, t = 1:T], EP[:vPG2P][k,t] == EP[:vH2G2P][k,t] * dfH2G2P[!,:etaG2P][k]
    end)

    @constraints(EP, begin
    # Maximum power generated per technology "k" at hour "t"
    [k in H2_G2P_NO_COMMIT, t=1:T], EP[:vPG2P][k,t] <= EP[:eH2G2PTotalCap][k]* inputs["pH2_g2p_Max"][k,t]
    end)

    #Ramping cosntraints 
    @constraints(EP, begin

        ## Maximum ramp up between consecutive hours
        # Start Hours: Links last time step with first time step, ensuring position in hour 1 is within eligible ramp of final hour position
        # NOTE: We should make wrap-around a configurable option
        [k in H2_G2P_NO_COMMIT, t in START_SUBPERIODS], EP[:vPG2P][k,t]-EP[:vPG2P][k,(t + hours_per_subperiod-1)] <= dfH2G2P[!,:Ramp_Up_Percentage][k] * EP[:eH2G2PTotalCap][k]

        # Interior Hours
        [k in H2_G2P_NO_COMMIT, t in INTERIOR_SUBPERIODS], EP[:vPG2P][k,t]-EP[:vPG2P][k,t-1] <= dfH2G2P[!,:Ramp_Up_Percentage][k]*EP[:eH2G2PTotalCap][k]

        ## Maximum ramp down between consecutive hours
        # Start Hours: Links last time step with first time step, ensuring position in hour 1 is within eligible ramp of final hour position
        [k in H2_G2P_NO_COMMIT, t in START_SUBPERIODS], EP[:vPG2P][k,(t+hours_per_subperiod-1)] - EP[:vPG2P][k,t] <= dfH2G2P[!,:Ramp_Down_Percentage][k] * EP[:eH2G2PTotalCap][k]

        # Interior Hours
        [k in H2_G2P_NO_COMMIT, t in INTERIOR_SUBPERIODS], EP[:vPG2P][k,t-1] - EP[:vPG2P][k,t] <= dfH2G2P[!,:Ramp_Down_Percentage][k] * EP[:eH2G2PTotalCap][k]
    
    end)

    return EP

end




