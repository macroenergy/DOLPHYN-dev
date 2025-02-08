"""
DOLPNYN: Decision Optimization for Low-carbon Power and Nydrogen Networks
Copyright (C) 2022,  Massachusetts Institute of Technology
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITNOUT ANY WARRANTY; without even the implied warranty of
MERCNANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt.  Users uncompressing this from an archive may not have
received this license file.  If not, see <http://www.gnu.org/licenses/>.
"""

@doc raw"""
    ng_pipeline(EP::Model, inputs::Dict, setup::Dict)

This function includes the variables, expressions and objective funtion of natural gas pipeline.

This function expresses natural gas exchange through pipeline i between two zones and can be split into NG delivering and flowing out.

This module defines the natural gas pipeline construction decision variable $y_{i,z \rightarrow z^{\prime}}^{\textrm{N,PIP}} \forall i \in \mathcal{I}, z \rightarrow z^{\prime} \in \mathcal{B}$, representing newly constructed natural gas pipeline of type $i$ through path $z \rightarrow z^{\prime}$.

This module defines the natural gas pipeline flow decision variable $x_{i,z \rightarrow z^{\prime},t}^{\textrm{N,PIP}} \forall i \in \mathcal{I}, z \rightarrow z^{\prime} \in \mathcal{B}, t \in \mathcal{T}$, representing natural gas flow via pipeline of type $i$ through path $z \rightarrow z^{\prime}$ at time period $t$.

This module defines the natural gas pipeline storage level decision variable $U_{i,z \rightarrow z^{\prime},t}^{\textrm{N,PIP}} \forall i \in \mathcal{I}, z \rightarrow z^{\prime} \in \mathcal{B}, t \in \mathcal{T}$, representing natural gas stored in pipeline of type $i$ through path $z \rightarrow z^{\prime}$ at time period $t$.

The variable defined in this file named after ```vNGNPipe``` covers variable $y_{i,z \rightarrow z^{\prime}}^{\textrm{N,PIP}}$.

The variable defined in this file named after ```vNGPipeFlow_pos``` covers variable $x_{i,z \rightarrow z^{\prime},t}^{\textrm{N,PIP+}}$.

The variable defined in this file named after ```vNGPipeFlow_neg``` covers variable $x_{i,z \rightarrow z^{\prime},t}^{\textrm{N,PIP-}}$.

The variable defined in this file named after ```vNGPipeLevel``` covers variable $U_{i,z \rightarrow z^{\prime},t}^{\textrm{N,PIP}}$.

**Cost expressions**

This module additionally defines contributions to the objective function from investment costs of generation (fixed OM plus construction) from all pipeline resources $i \in \mathcal{I}$:

```math
\begin{equation*}
    \textrm{C}^{\textrm{N,PIP,c}}=\delta_{i}^{\textrm{N,PIP}} \sum_{i \in \mathbb{I}} \sum_{z \rightarrow z^{\prime} \in \mathbb{B}} \textrm{c}_{i}^{\textrm{N,PIP}} \textrm{L}_{z \rightarrow z^{\prime}} l_{i,z \rightarrow z^{\prime}}
    h_{i,z \rightarrow z^{\prime}, t}^{\textrm{N,PIP}}=h_{i, z \rightarrow z^{\prime}, t}^{\textrm{N,PIP+}}-h_{i, z \rightarrow z^{\prime}, t}^{\textrm{PIP-}} \quad \forall i \in \mathbb{I}, z \rightarrow z^{\prime} \in \mathbb{B}, t \in \mathbb{T}
\end{equation*}
 ```

The flow rate of NG through pipeline type $i$ is capped by the operational limits of the pipeline, multiplied by the number of constructed pipeline $i$
```math
\begin{equation*}
    \overline{\textrm{F}}_{i} l_{i,z \rightarrow z^{\prime}} \geq x_{i,z \rightarrow z^{\prime}, t}^{\textrm{\textrm{N,PIP+}}}, x_{i,z \rightarrow z^{\prime}, t}^{\textrm{\textrm{N,PIP-}}} \geq 0 \quad \forall i \in \mathbb{I}, z \rightarrow z^{\prime} \in \mathbb{B}, t \in \mathbb{T}
\end{equation*}    
```

The pipeline has storage capacity via line packing:
```math
\begin{equation*}
    \overline{\textrm{U}}_{i}^{\textrm{\textrm{N,PIP}}} l_{i,z \rightarrow z^{\prime}} \geq -\sum_{\tau=t_{0}}^{t}\left(x_{i,z^{\prime} \rightarrow z, \tau}^{\textrm{\textrm{N,PIP}}}+x_{i,z \rightarrow z^{\prime}, \tau}^{\textrm{\textrm{N,PIP}}}\right) \Delta t \geq \underline{\textrm{R}}_{i}^{\textrm{\textrm{N,PIP}}} \overline{\textrm{E}}_{i}^{\textrm{\textrm{N,PIP}}} l_{i,z \rightarrow z^{\prime}} \\
    & \forall z^{\prime} \in \mathbb{Z}, z \in \mathbb{Z}, i \in \mathbb{I}, t \in \mathbb{T}
\end{equation*}   
```

The change of natural gas pipeline storage inventory is modeled as follows:
```math
\begin{equation*}
    U_{i,z \rightarrow z^{\prime},t}^{\textrm{N,PIP}} - U_{i,z \rightarrow z^{\prime},t-1} = x_{i,z \rightarrow z^{\prime},t}^{\textrm{N,PIP-}} + x_{i,z^{\prime} \rightarrow z,t}^{\textrm{N,PIP-}}
\end{equation*}
```
"""
function ng_pipeline(EP::Model, inputs::Dict, setup::Dict)

    print_and_log(" -- NG Pipeline Module")

    T = inputs["T"] # Model operating time steps
    Z = inputs["Z"]  # Model demand zones - assumed to be same for NG and electricity

    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
    START_SUBPERIODS = inputs["START_SUBPERIODS"]
    hours_per_subperiod = inputs["hours_per_subperiod"]

    NG_P = inputs["NG_P"] # Number of Nydrogen Pipelines
    NG_Pipe_Map = inputs["NG_Pipe_Map"]

    ### Variables ###
    @variable(EP, vNGNPipe[p = 1:NG_P] >= 0) # Number of Pipes
    @variable(EP, vNGPipeLevel[p = 1:NG_P, t = 1:T] >= 0) # Storage in the pipe
    @variable(EP, vNGPipeFlow_pos[p = 1:NG_P, t = 1:T, d = [1, -1]] >= 0) # positive pipeflow
    @variable(EP, vNGPipeFlow_neg[p = 1:NG_P, t = 1:T, d = [1, -1]] >= 0) # negative pipeflow

    # Unidirectional pipeline flow constraints. hsc_pipeline inputs file must have 2 pipelines in between each zone for this to work properly (flipping the -1 and +1 directions)
    # Constraints force the source zone to only export NG through pipeline p while the destination zone can only import
    if setup["NGPipeDirection"] == 1
        @constraint(EP, vNGPipeFlow_pos[:, :, 1] .== 0)
        @constraint(EP, vNGPipeFlow_neg[:, :, -1] .== 0)
    end

    ### Expressions ###
    # Calculate the number of new pipes
    @expression(EP, eNGNPipeNew[p = 1:NG_P], vNGNPipe[p] - inputs["pNG_Pipe_No_Curr"][p])

    # Calculate net flow at each pipe-zone interfrace
    @expression(EP,eNGPipeFlow_net[p = 1:NG_P, t = 1:T, d = [-1, 1]],vNGPipeFlow_pos[p, t, d] - vNGPipeFlow_neg[p, t, d])

    ## Objective Function Expressions ##
    # Capital cost of pipelines 
    @expression(EP,eCNGPipe,sum(eNGNPipeNew[p] * inputs["pCAPEX_NG_Pipe"][p] for p = 1:NG_P))

    EP[:eObj] += eCNGPipe

    # Capital cost of booster compressors located along each pipeline - more booster compressors needed for longer pipelines than shorter pipelines
    @expression(EP,eCNGCompPipe,sum(eNGNPipeNew[p] * inputs["pCAPEX_Comp_NG_Pipe"][p] for p = 1:NG_P))

    EP[:eObj] += eCNGCompPipe

    ## End Objective Function Expressions ##

    ## Balance Expressions ##
    # NG Power Consumption balance

    @expression(
        EP,
        ePowerBalanceNGPipeCompression[t = 1:T, z = 1:Z],
        sum(
            vNGPipeFlow_neg[
                p, t, NG_Pipe_Map[(NG_Pipe_Map[!, :Zone].==z).&(NG_Pipe_Map[!, :pipe_no].==p), :,][!,:d][1]
            ] * inputs["pComp_MWh_per_MMBtu_Pipe"][p] for p in NG_Pipe_Map[NG_Pipe_Map[!, :Zone].==z, :][!, :pipe_no]
        )
    )

    EP[:ePowerBalance] += -ePowerBalanceNGPipeCompression
    EP[:eNGNetpowerConsumptionByAll] += ePowerBalanceNGPipeCompression


    # NG balance - net flows of NG from between z and zz via pipeline p over time period t
    @expression(
        EP,
        eNGPipeZoneDemand[t = 1:T, z = 1:Z],
        sum(
            eNGPipeFlow_net[p, t, NG_Pipe_Map[(NG_Pipe_Map[!, :Zone].==z).&(NG_Pipe_Map[!, :pipe_no].==p), :][!,:d][1]] 
            for p in NG_Pipe_Map[NG_Pipe_Map[!, :Zone].==z, :][!, :pipe_no]
        )
    )

    EP[:eNGBalance] += eNGPipeZoneDemand

    #EP[:eNTransmissionByZone] += eNGPipeZoneDemand

    ## End Balance Expressions ##
    ### End Expressions ###

    ### Constraints ###

    # Constraints
    if setup["NGPipeInteger"] == 1
        for p = 1:NG_P
            set_integer.(vNGNPipe[p])
        end
    end

    # Modeling expansion of the pipleline network
    if setup["NGNetworkExpansion"] == 1
        # If network expansion allowed Total no. of Pipes >= Existing no. of Pipe 
        @constraints(EP, begin
            [p in 1:NG_P], EP[:eNGNPipeNew][p] >= 0
        end)
    else
        # If network expansion is not alllowed Total no. of Pipes == Existing no. of Pipe 
        @constraints(EP, begin
            [p in 1:NG_P], EP[:eNGNPipeNew][p] == 0
        end)
    end

    # Constraint maximum pipe flow
    @constraints(
        EP,
        begin
            [p in 1:NG_P, t = 1:T, d in [-1, 1]],
            EP[:eNGPipeFlow_net][p, t, d] <=
            EP[:vNGNPipe][p] * inputs["pNG_Pipe_Max_Flow"][p]
            [p in 1:NG_P, t = 1:T, d in [-1, 1]],
            -EP[:eNGPipeFlow_net][p, t, d] <=
            EP[:vNGNPipe][p] * inputs["pNG_Pipe_Max_Flow"][p]
        end
    )

    # Constrain positive and negative pipe flows
    @constraints(
        EP,
        begin
            [p in 1:NG_P, t = 1:T, d in [-1, 1]],
            vNGNPipe[p] * inputs["pNG_Pipe_Max_Flow"][p] >= vNGPipeFlow_pos[p, t, d]
            [p in 1:NG_P, t = 1:T, d in [-1, 1]],
            vNGNPipe[p] * inputs["pNG_Pipe_Max_Flow"][p] >= vNGPipeFlow_neg[p, t, d]
        end
    )

    # Minimum and maximum pipe level constraint
    @constraints(
        EP,
        begin
            [p in 1:NG_P, t = 1:T],
            vNGPipeLevel[p, t] >= inputs["pNG_Pipe_Min_Cap"][p] * vNGNPipe[p]
            [p in 1:NG_P, t = 1:T],
            inputs["pNG_Pipe_Max_Cap"][p] * vNGNPipe[p] >= vNGPipeLevel[p, t]
        end
    )

    # Pipeline storage level change
    @constraints(
        EP,
        begin
            [p in 1:NG_P, t in START_SUBPERIODS],
            vNGPipeLevel[p, t] ==
            vNGPipeLevel[p, t+hours_per_subperiod-1] - eNGPipeFlow_net[p, t, -1] -
            eNGPipeFlow_net[p, t, 1]
        end
    )

    @constraints(
        EP,
        begin
            [p in 1:NG_P, t in INTERIOR_SUBPERIODS],
            vNGPipeLevel[p, t] ==
            vNGPipeLevel[p, t-1] - eNGPipeFlow_net[p, t, -1] - eNGPipeFlow_net[p, t, 1]
        end
    )

    @constraints(EP, begin
        [p in 1:NG_P], vNGNPipe[p] <= inputs["pNG_Pipe_No_Max"][p]
    end)

    return EP
end # end NGPipeline module