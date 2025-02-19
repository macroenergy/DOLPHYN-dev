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
    h2_g2p_all(EP::Model, inputs::Dict, setup::Dict)

The hydrogen to power module creates decision variables, expressions, and constraints related to hydrogen generation infrastructure

The variable defined in this file named after ```vH2G2P``` covers .

**Constraints on generation discharge capacity**

One cannot retire more capacity than existing capacity.
```math
\begin{equation*}
    0 \leq y_{g, z}^{\textrm{\textrm{H,G2P,retired}} \leq y_{g, z}^{\textrm{\textrm{H,G2P,existing}} \quad \forall g \in \mathcal{G}, z \in \mathcal{Z}
\end{equation*}
```

For resources where upper bound $\overline{y_{g}^{\textrm{\textrm{H,G2P}}}}$ and lower bound $\underline{y_{g}^{\textrm{\textrm{H,G2P}}}}$ of capacity is defined, then we impose constraints on minimum and maximum power capacity.

```math
\begin{equation*}
    \underline{y}_{g, z}^{\textrm{\textrm{H,G2P}}} \leq y_{g, z}^{\textrm{\textrm{H,G2P}} \leq \overline{y}_{g, z}^{\textrm{\textrm{H,G2P}} \quad \forall g \in \mathcal{G}, z \in \mathcal{Z}
\end{equation*}
"""
function h2_g2p_all(EP::Model, inputs::Dict, setup::Dict)
    print_and_log("H2-g2p operation constraints")

    dfH2G2P = inputs["dfH2G2P"]

    #Define sets

    H2_G2P = inputs["H2_G2P"]
    H =inputs["H2_G2P_ALL"]

    T = inputs["T"]     # Number of time steps (hours)

    ####Variables####
    #Define variables needed across both commit and no commit sets

    #H2 required by G2P resource k to make hydrogen (MWh/hr)
    @variable(EP, vH2G2P[k in H2_G2P, t = 1:T] >= 0 )

    ### Constratints ###


    # Constraint on minimum capacity (if applicable) [set input to -1 if no constraint on minimum capacity]
    # DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MW is <= Min_Cap_MW and lead to infeasabilty
    @constraint(EP, cH2G2PMinCap[k in intersect(dfH2G2P[dfH2G2P.Min_Cap_MW.>0,:R_ID], 1:H)], EP[:eH2G2PTotalCap][k] >= dfH2G2P[!,:Min_Cap_MW][k])

    return EP

end
