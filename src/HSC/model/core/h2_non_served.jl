@doc raw"""
    h2_non_served(EP::Model, inputs::Dict, setup::Dict)

This function defines the non-served hydrogen demand decision variable $x_{s,z,t}^{\textrm{H,NSD}} \forall z \in \mathcal{Z}, \forall t \in \mathcal{T}$, representing the total amount of hydrogen demand curtailed in demand segment $s$ at time period $t$ in zone $z$. 
The first segment of non-served hydrogen, $s=1$, is used to denote the cost of involuntary hydrogen demand curtailment, specified as the value of $c_{1}^{\textrm{H,NSD}}$.
Additional segments, $s \geq 2$ can be used to specify a segment-wise approximation of a price elastic hydrogen demand curve, or segments of price-responsive curtailable hydrogen loads.
Each segment denotes a price/cost at which the segment of hydrogen demand is willing to curtail consumption, $\textrm{n}_{s}^{\textrm{H,NSD}}$, representing the marginal willingness to pay for hydrogen demand of this segment of demand (or opportunity cost incurred when demand is not served) 
and a maximum quantity of demand in this segment, $\textrm{n}_{s}^{\textrm{H,NSD}}$, specified as a share of hydrogen demand in each zone in each time step, $\textrm{D}_{z, t}^{\textrm{H}}$. Note that the current implementation assumes demand segments are an equal share of hourly load in all zones.

The variable defined in this file named after ```vH2NSE``` covers the variable $x_{s,z,t}^{\textrm{H,NSD}}$.

**Cost expressions**

This function defines contributions to the objective function from the cost of non-served hydrogen/curtailed hydrogen from all demand curtailment segments $s \in \mathcal{SEG}$ over all time periods $t \in \mathcal{T}$ and all zones $z \in \mathcal{Z}$:

```math
\begin{equation*}
    \textrm{C}^{\textrm{H,NSD},o} = \sum_{s \in \mathcal{SEG}} \sum_{z \in \mathcal{Z}} \sum_{t \in \mathcal{T}} \omega_t \times \textrm{n}_{s}^{\textrm{H,NSD}} \times x_{s,z,t}^{\textrm{H,NSD}}
\end{equation*}
```

Contributions to the hydrogen balance expression from non-served hydrogen/curtailed hydrogen from each demand segment $s \in \mathcal{SEG}$ are also defined as:

```math
\begin{equation*}
    HydrogenBal_{NSE} = \sum_{s \in \mathcal{SEG}} x_{s,z,t}^{\textrm{H,NSD}} \quad \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

**Bounds on curtailable hydrogen demand**

Hydrogen demand curtailed in each segment of curtailable demands $s \in \mathcal{SEG}$ cannot exceed maximum allowable share of hydrogen demand:

```math
\begin{equation*}
    x_{s,z,t}^{\textrm{H,NSD}} \leq \textrm{n}_{s}^{\textrm{H,NSD}} \times \textrm{D}_{z,t}^{\textrm{H}} \quad \forall s \in \mathcal{SEG}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

Additionally, total demand curtailed in each time step cannot exceed total hydrogen demand:

```math
\begin{equation*}
    \sum_{s \in \mathcal{SEG}} x_{s,z,t}^{\textrm{H,NSD}} \leq \textrm{D}_{z,t}^{\textrm{H}} \quad \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```
"""
function h2_non_served(EP::Model, inputs::Dict, setup::Dict)

    print_and_log("Hydrogen Non-served Energy Module")

    T = inputs["T"]::Int     # Number of time steps
    Z = inputs["Z"]::Int     # Number of zones
    H2_SEG = inputs["H2_SEG"] # Number of load curtailment segments
    
    SCALING = setup["scaling"]::Float64 

    ### Variables ###

    # Non-served hydrogen/curtailed hydrogen demand in the segment "s" at hour "t" in zone "z"
    @variable(EP, vH2NSE[s = 1:H2_SEG, t = 1:T, z = 1:Z] >= 0)

    ### Expressions ###

    ## Objective Function Expressions ##

    # Cost of non-served hydrogen/curtailed hydrogen demand at hour "t" in zone "z"
    @expression(
        EP,
        eH2CNSE[s = 1:H2_SEG, t = 1:T, z = 1:Z],
        (inputs["omega"][t] * inputs["pC_H2_D_Curtail"][s] * vH2NSE[s, t, z])
    )

    # Sum individual demand segment contributions to non-served energy costs to get total non-served energy costs
    # Julia is fastest when summing over one row one column at a time
    eTotalH2CNSE = sum_expression(eH2CNSE, SCALING^2)
    EP[:eTotalH2CNSE] = eTotalH2CNSE

    # Add total cost contribution of non-served energy/curtailed demand to the objective function
    add_similar_to_expression!(EP[:eObj], eTotalH2CNSE)

    ## Power Balance Expressions ##
    @expression(EP, eH2BalanceNse[t = 1:T, z = 1:Z], sum(vH2NSE[s, t, z] for s = 1:H2_SEG))

    # Add non-served energy/curtailed demand contribution to power balance expression
    add_similar_to_expression!(EP[:eH2Balance], eH2BalanceNse)

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
        eH2BalanceNse[t,z] <= inputs["H2_D"][t, z]
    )

    return EP
end