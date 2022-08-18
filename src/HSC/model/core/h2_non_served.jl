"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2021,  Massachusetts Institute of Technology
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
	h2_non_served_energy(EP::Model, inputs::Dict, setup::Dict)

This function defines the non-served hydrogen demand decision variable $x_{s,z,t}^{H,NSD} \forall z \in \mathcal{Z}, \forall t \in \mathcal{T}$, representing the total amount of hydrogen demand curtailed in demand segment $s$ at time period $t$ in zone $z$. 
The first segment of non-served hydrogen, $s=1$, is used to denote the cost of involuntary hydrogen demand curtailment, specified as the value of $c_{1}^{H,NSD}$.
Additional segments, $s \geq 2$ can be used to specify a segment-wise approximation of a price elastic hydrogen demand curve, or segments of price-responsive curtailable hydrogen loads.
Each segment denotes a price/cost at which the segment of hydrogen demand is willing to curtail consumption, $n_{s}^{H,NSD}$, representing the marginal willingness to pay for hydrogen demand of this segment of demand (or opportunity cost incurred when demand is not served) 
and a maximum quantity of demand in this segment, $n_{s}^{H,NSD}$, specified as a share of hydrogen demand in each zone in each time step, $D_{z, t}^{H}$. Note that the current implementation assumes demand segments are an equal share of hourly load in all zones.

The variable defined in this file named after ```vH2NSE``` covers the variable $x_{s,z,t}^{H2,NSD}$.

**Cost expressions**

This function defines contributions to the objective function from the cost of non-served hydrogen/curtailed hydrogen from all demand curtailment segments $s \in \mathcal{SEG}$ over all time periods $t \in \mathcal{T}$ and all zones $z \in \mathcal{Z}$:

```math
\begin{eqution}
	C^{H,NSD,o} = \sum_{s \in \mathcal{SEG}} \sum_{z \in \mathcal{Z}} \sum_{t \in \mathcal{T}} \omega_t \times n_{s}^{H,NSD} \times x_{s,z,t}^{H,NSD}
\end{eqution}
```

Contributions to the hydrogen balance expression from non-served hydrogen/curtailed hydrogen from each demand segment $s \in \mathcal{SEG}$ are also defined as:

```math
\begin{equation}
	HydrogenBal_{NSE} = \sum_{s \in \mathcal{SEG}} x_{s,z,t}^{H,NSD} \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation}
```

**Bounds on curtailable hydrogen demand**

Hydrogen demand curtailed in each segment of curtailable demands $s \in \mathcal{SEG}$ cannot exceed maximum allowable share of hydrogen demand:

```math
\begin{equation}
	x_{s,z,t}^{H,NSD} \leq n_{s}^{H,NSD} \times D_{z,t}^{H} \forall s \in \mathcal{SEG}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation}
```

Additionally, total demand curtailed in each time step cannot exceed total hydrogen demand:

```math
\begin{equation}
	\sum_{s \in \mathcal{SEG}} x_{s,z,t}^{H,NSD} \leq D_{z,t} \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation}
```
"""
function h2_non_served_energy(EP::Model, inputs::Dict, setup::Dict)

    println("Hydrogen Non-served Energy Module")

    T = inputs["T"]     # Number of time steps
    Z = inputs["Z"]     # Number of zones
    H2_SEG = inputs["H2_SEG"] # Number of load curtailment segments

    ### Variables ###

    # Non-served energy/curtailed demand in the segment "s" at hour "t" in zone "z"
    @variable(EP, vH2NSE[s = 1:H2_SEG, t = 1:T, z = 1:Z] >= 0)

    ### Expressions ###

    ## Objective Function Expressions ##

    # Cost of non-served energy/curtailed demand at hour "t" in zone "z"
    @expression(
        EP,
        eH2CNSE[s = 1:H2_SEG, t = 1:T, z = 1:Z],
        (inputs["omega"][t] * inputs["pC_H2_D_Curtail"][s] * vH2NSE[s, t, z])
    )

    # Sum individual demand segment contributions to non-served energy costs to get total non-served energy costs
    # Julia is fastest when summing over one row one column at a time
    @expression(
        EP,
        eTotalH2CNSETS[t = 1:T, z = 1:Z],
        sum(eH2CNSE[s, t, z] for s = 1:H2_SEG)
    )
    @expression(EP, eTotalH2CNSET[t = 1:T], sum(eTotalH2CNSETS[t, z] for z = 1:Z))

    #  ParameterScale = 1 --> objective function is in million $ . In power system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
    #  ParameterScale = 0 --> objective function is in $
    if setup["ParameterScale"] == 1
        @expression(
            EP,
            eTotalH2CNSE,
            sum(eTotalH2CNSET[t] / (ModelScalingFactor)^2 for t = 1:T)
        )
    else
        @expression(EP, eTotalH2CNSE, sum(eTotalH2CNSET[t] for t = 1:T))
    end


    # Add total cost contribution of non-served energy/curtailed demand to the objective function
    EP[:eObj] += eTotalH2CNSE

    ## Power Balance Expressions ##
    @expression(EP, eH2BalanceNse[t = 1:T, z = 1:Z], sum(vH2NSE[s, t, z] for s = 1:H2_SEG))

    # Add non-served energy/curtailed demand contribution to power balance expression
    EP[:eH2Balance] += eH2BalanceNse

    ### Constratints ###

    # Demand curtailed in each segment of curtailable demands cannot exceed maximum allowable share of demand
    @constraint(
        EP,
        cH2NSEPerSeg[s = 1:H2_SEG, t = 1:T, z = 1:Z],
        vH2NSE[s, t, z] <= inputs["pMax_H2_D_Curtail"][s] * inputs["H2_D"][t, z]
    )

    # Total demand curtailed in each time step (hourly) cannot exceed total demand
    @constraint(
        EP,
        cMaxH2NSE[t = 1:T, z = 1:Z],
        sum(vH2NSE[s, t, z] for s = 1:H2_SEG) <= inputs["H2_D"][t, z]
    )

    return EP
end
