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
    co2_pipeline(EP::Model, inputs::Dict, setup::Dict)

This function includes the variables, expressions and objective funtion of CO2 pipeline.

This function expresses CO2 exchange through pipeline i between two zones and can be split into CO2 delivering and flowing out.

This module defines the CO2 pipeline construction decision variable $y_{i,z \rightarrow z^{\prime}}^{\textrm{C,PIP}} \forall i \in \mathcal{I}, z \rightarrow z^{\prime} \in \mathcal{B}$, representing newly constructed CO2 pipeline of type $i$ through path $z \rightarrow z^{\prime}$.

This module defines the CO2 pipeline flow decision variable $x_{i,z \rightarrow z^{\prime},t}^{\textrm{C,PIP}} \forall i \in \mathcal{I}, z \rightarrow z^{\prime} \in \mathcal{B}, t \in \mathcal{T}$, representing CO2 flow via pipeline of type $i$ through path $z \rightarrow z^{\prime}$ at time period $t$.

This module defines the CO2 pipeline storage level decision variable $U_{i,z \rightarrow z^{\prime},t}^{\textrm{C,PIP}} \forall i \in \mathcal{I}, z \rightarrow z^{\prime} \in \mathcal{B}, t \in \mathcal{T}$, representing CO2 stored in pipeline of type $i$ through path $z \rightarrow z^{\prime}$ at time period $t$.

The variable defined in this file named after ```vCO2NPipe``` covers variable $y_{i,z \rightarrow z^{\prime}}^{\textrm{C,PIP}}$.

The variable defined in this file named after ```vCO2PipeFlow_pos``` covers variable $x_{i,z \rightarrow z^{\prime},t}^{\textrm{C,PIP+}}$.

The variable defined in this file named after ```vCO2PipeFlow_neg``` covers variable $x_{i,z \rightarrow z^{\prime},t}^{\textrm{C,PIP-}}$.

The variable defined in this file named after ```vCO2PipeLevel``` covers variable $U_{i,z \rightarrow z^{\prime},t}^{\textrm{C,PIP}}$.

**Cost expressions**

This module additionally defines contributions to the objective function from investment costs of generation (fixed OM plus construction) from all pipeline resources $i \in \mathcal{I}$:

```math
\begin{equation*}
    \textrm{C}^{\textrm{C,PIP,c}}=\delta_{i}^{\textrm{C,PIP}} \sum_{i \in \mathbb{I}} \sum_{z \rightarrow z^{\prime} \in \mathbb{B}} \textrm{c}_{i}^{\textrm{C,PIP}} \textrm{L}_{z \rightarrow z^{\prime}} l_{i,z \rightarrow z^{\prime}}
    h_{i,z \rightarrow z^{\prime}, t}^{\textrm{C,PIP}}=h_{i, z \rightarrow z^{\prime}, t}^{\textrm{C,PIP+}}-h_{i, z \rightarrow z^{\prime}, t}^{\textrm{PIP-}} \quad \forall i \in \mathbb{I}, z \rightarrow z^{\prime} \in \mathbb{B}, t \in \mathbb{T}
\end{equation*}
```

The flow rate of CO2 through pipeline type $i$ is capped by the operational limits of the pipeline, multiplied by the number of constructed pipeline $i$
```math
\begin{equation*}
    \overline{\textrm{F}}_{i} l_{i,z \rightarrow z^{\prime}} \geq x_{i,z \rightarrow z^{\prime}, t}^{\textrm{\textrm{C,PIP+}}}, x_{i,z \rightarrow z^{\prime}, t}^{\textrm{\textrm{C,PIP-}}} \geq 0 \quad \forall i \in \mathbb{I}, z \rightarrow z^{\prime} \in \mathbb{B}, t \in \mathbb{T}
\end{equation*}    
```

The pipeline has storage capacity via line packing:
```math
\begin{equation*}
    \overline{\textrm{U}}_{i}^{\textrm{\text{C,PIP}}} l_{i,z \rightarrow z^{\prime}} \geq -\sum_{\tau=t_{0}}^{t}\left(x_{i,z^{\prime}\rightarrow z, \tau}^{\textrm{\textrm{C,PIP}}}+x_{i,z \rightarrow z^{\prime} \tau}^{\textrm{\textrm{C,PIP}}}\right)\Delta t \geq\underline{\textrm{R}}_{i}^{\textrm{\textrm{C,PIP}}}\overline{\textrm{E}}_{i}^{\textrm{\textrm{C,PIP}}} l_{i,z \rightarrow z^{\prime}} \forall z^{\prime} \in Z, z \in Z, i \in I, t \in T
\end{equation*}  
```

The change of CO2 pipeline storage inventory is modeled as follows:
```math
\begin{equation*}
    U_{i,z \rightarrow z^{\prime},t}^{\textrm{C,PIP}} - U_{i,z \rightarrow z^{\prime},t-1} = x_{i,z \rightarrow z^{\prime},t}^{\textrm{C,PIP-}} + x_{i,z^{\prime} \rightarrow z,t}^{\textrm{C,PIP-}}
\end{equation*}
```
"""
function co2_pipeline(EP::Model, inputs::Dict, setup::Dict)

 #Number of Pipes

    EP = CO2_pipeline_investment(EP, inputs, setup)
    EP = CO2_pipeline_Operations(EP, inputs, setup)

    ### Note: To be confirmed. Impact of Location change 
    #  # Constraints
	# if setup["CO2PipeInteger"] == 1
    #     for p=1:CO2_P
	# 	    set_integer.(vCO2NPipe[p])
    #     end
	# end
    return EP

end


function CO2_pipeline_Operations(EP::Model, inputs::Dict, setup::Dict)
	
    println("CO2 Pipeline Operation Module")

    T = inputs["T"] # Model operating time steps
    Z = inputs["Z"]  # Model demand zones - assumed to be same for CO2 and electricity
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
    START_SUBPERIODS = inputs["START_SUBPERIODS"]
    hours_per_subperiod = inputs["hours_per_subperiod"]

    CO2_Pipe_Map = inputs["CO2_Pipe_Map"] 
    CO2_P = inputs["CO2_P"]


	### Variables ###
    @variable(EP, vCO2PipeLevel[p=1:CO2_P, t = 1:T] >= 0 ) #Storage in the pipe
    @variable(EP, vCO2PipeFlow_pos[p=1:CO2_P, t = 1:T, d = [1,-1]] >= 0) #positive pipeflow
    @variable(EP, vCO2PipeFlow_neg[p=1:CO2_P, t = 1:T, d = [1,-1]] >= 0) #negative pipeflow
    @variable(EP, vCO2Loss[t=1:T,z=1:Z] >= 0 ) #CO2 Loss in Pipe

	# ### Expressions ###
    # #Calculate the number of new pipes
    # @expression(EP, eCO2NPipeNew[p = 1:CO2_P], vCO2NPipe[p] - inputs["pCO2_Pipe_No_Curr"][p])

	## End Objective Function Expressions ##

	## Balance Expressions ##
	# Electrical energy requirement for pipeline operation
    # IF ParameterScale = 1, power system operation/capacity modeled in GW rather than MW, , no need to scale as MW/ton = GW/kton
    # IF ParameterScale = 0, power system operation/capacity modeled in MW so no scaling of CO2 related power consumption
    @expression(EP, ePowerDemandCO2Pipe[t=1:T, z=1:Z],
    sum(vCO2PipeFlow_neg[p,t,CO2_Pipe_Map[(CO2_Pipe_Map[!,:Zone] .== z) .& (CO2_Pipe_Map[!,:pipe_no] .== p), :][!,:d][1]] * inputs["pMWh_per_tonne_CO2_Pipe"][p] for  p in CO2_Pipe_Map[CO2_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))    
    
    @expression(EP, ePowerDemandCO2Pipe_zt[z=1:Z,t=1:T],
    sum(vCO2PipeFlow_neg[p,t,CO2_Pipe_Map[(CO2_Pipe_Map[!,:Zone] .== z) .& (CO2_Pipe_Map[!,:pipe_no] .== p), :][!,:d][1]] * inputs["pMWh_per_tonne_CO2_Pipe"][p] for  p in CO2_Pipe_Map[CO2_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))    

	# Electrical energy requirement for booster compression
    # IF ParameterScale = 1, power system operation/capacity modeled in GW rather than MW, , no need to scale as MW/ton = GW/kton
    # IF ParameterScale = 0, power system operation/capacity modeled in MW so no scaling of CO2 related power consumption
    @expression(EP, ePowerDemandCO2PipeCompression[t=1:T, z=1:Z],
    sum(vCO2PipeFlow_neg[p,t,CO2_Pipe_Map[(CO2_Pipe_Map[!,:Zone] .== z) .& (CO2_Pipe_Map[!,:pipe_no] .== p), :][!,:d][1]] * inputs["pComp_MWh_per_tonne_CO2_Pipe"][p] for  p in CO2_Pipe_Map[CO2_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))    

    @expression(EP, ePowerDemandCO2PipeCompression_zt[z=1:Z,t=1:T],
    sum(vCO2PipeFlow_neg[p,t,CO2_Pipe_Map[(CO2_Pipe_Map[!,:Zone] .== z) .& (CO2_Pipe_Map[!,:pipe_no] .== p), :][!,:d][1]] * inputs["pComp_MWh_per_tonne_CO2_Pipe"][p] for  p in CO2_Pipe_Map[CO2_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))    

    EP[:ePowerBalance_CSC] += -ePowerDemandCO2Pipe
    EP[:ePowerBalance_CSC] += -ePowerDemandCO2PipeCompression

    EP[:eCSCNetpowerConsumptionByAll] += ePowerDemandCO2Pipe
    EP[:eCSCNetpowerConsumptionByAll] += ePowerDemandCO2PipeCompression


	### Constraints ###


    # Modeling loss of CO2 in the piplelines
    if setup["CO2Pipeline_Loss"]==1
        # If modeling CO2 loss from pipe
        @expression(EP, eCO2Loss_Pipes_per_pipe[t=1:T,z=1:Z], sum(vCO2PipeFlow_neg[p,t,CO2_Pipe_Map[(CO2_Pipe_Map[!,:Zone] .== z) .& (CO2_Pipe_Map[!,:pipe_no] .== p), :][!,:d][1]] * inputs["pLoss_tonne_per_tonne_CO2_Pipe"][p] for  p in CO2_Pipe_Map[CO2_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))
        
        @expression(EP, eCO2Loss_Pipes[t=1:T,z=1:Z], sum(vCO2PipeFlow_neg[p,t,CO2_Pipe_Map[(CO2_Pipe_Map[!,:Zone] .== z) .& (CO2_Pipe_Map[!,:pipe_no] .== p), :][!,:d][1]] * inputs["pLoss_tonne_per_tonne_CO2_Pipe"][p] for  p in CO2_Pipe_Map[CO2_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))
        @expression(EP, eCO2Loss_Pipes_zt[z=1:Z,t=1:T], sum(vCO2PipeFlow_neg[p,t,CO2_Pipe_Map[(CO2_Pipe_Map[!,:Zone] .== z) .& (CO2_Pipe_Map[!,:pipe_no] .== p), :][!,:d][1]] * inputs["pLoss_tonne_per_tonne_CO2_Pipe"][p] for  p in CO2_Pipe_Map[CO2_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))
    else
        # If not modeling CO2 loss from pipe
        @expression(EP, eCO2Loss_Pipes[t=1:T,z=1:Z], 0)
        @expression(EP, eCO2Loss_Pipes_zt[z=1:Z,t=1:T], 0)
    end

    

    #Calculate net flow at each pipe-zone interfrace
    @expression(EP, eCO2PipeFlow_net[p = 1:CO2_P, t = 1:T, d = [-1,1]],  vCO2PipeFlow_pos[p,t,d] - vCO2PipeFlow_neg[p,t,d]*(1-inputs["pLoss_tonne_per_tonne_CO2_Pipe"][p]))

    # CO2 balance - net flows of CO2 from between z and zz via pipeline p over time period t
    @expression(EP, ePipeZoneCO2Demand_No_Loss[t=1:T,z=1:Z],
        sum(eCO2PipeFlow_net[p,t, CO2_Pipe_Map[(CO2_Pipe_Map[!,:Zone] .== z) .& (CO2_Pipe_Map[!,:pipe_no] .== p), :][!,:d][1]] for p in CO2_Pipe_Map[CO2_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))

    # CO2 balance - net flows of CO2 from between z and zz via pipeline p over time period t
    @expression(EP, ePipeZoneCO2Demand[t=1:T,z=1:Z],ePipeZoneCO2Demand_No_Loss[t,z] - eCO2Loss_Pipes[t,z])

    #EP[:eCaptured_CO2_Balance] -= eCO2Loss_Pipes #No need as we have already deducted the loss from the balance
    EP[:eCaptured_CO2_Balance] += ePipeZoneCO2Demand

    if setup["ParameterScale"] ==1 
        #Pipe flow constraint
        @constraint(EP, cMinCO2Pipeflow[d in [-1,1], p in 1:CO2_P, t=1:T], EP[:eCO2PipeFlow_net][p,t,d] >= -EP[:vCO2NPipe][p] * inputs["pCO2_Pipe_Max_Flow"][p]/ModelScalingFactor)
        @constraint(EP, cMaxCO2Pipeflow[d in [-1,1], p in 1:CO2_P, t=1:T], EP[:eCO2PipeFlow_net][p,t,d] <= EP[:vCO2NPipe][p] * inputs["pCO2_Pipe_Max_Flow"][p]/ModelScalingFactor)
    
        #Constrain positive and negative pipe flows
        @constraint(EP, cMaxPositiveCO2Flow[d in [-1,1], p in 1:CO2_P, t=1:T], EP[:vCO2NPipe][p] * inputs["pCO2_Pipe_Max_Flow"][p] >= vCO2PipeFlow_pos[p,t,d]/ModelScalingFactor)
        @constraint(EP, cMaxNegativeCO2Flow[d in [-1,1], p in 1:CO2_P, t=1:T], EP[:vCO2NPipe][p] * inputs["pCO2_Pipe_Max_Flow"][p] >= vCO2PipeFlow_neg[p,t,d]/ModelScalingFactor)
        
        #Pipe level constraint
        @constraint(EP, cMinCO2PipeLevel[p in 1:CO2_P, t=1:T], vCO2PipeLevel[p,t] >= inputs["pCO2_Pipe_Min_Cap"][p] * EP[:vCO2NPipe][p]/ModelScalingFactor)
        @constraint(EP, cMaxCO2PipeLevel[p in 1:CO2_P, t=1:T], vCO2PipeLevel[p,t] <= inputs["pCO2_Pipe_Max_Cap"][p] * EP[:vCO2NPipe][p]/ModelScalingFactor)
    else
        #Pipe flow constraint
        @constraint(EP, cMinCO2Pipeflow[d in [-1,1], p in 1:CO2_P, t=1:T], EP[:eCO2PipeFlow_net][p,t,d] >= -EP[:vCO2NPipe][p] * inputs["pCO2_Pipe_Max_Flow"][p])
        @constraint(EP, cMaxCO2Pipeflow[d in [-1,1], p in 1:CO2_P, t=1:T], EP[:eCO2PipeFlow_net][p,t,d] <= EP[:vCO2NPipe][p] * inputs["pCO2_Pipe_Max_Flow"][p])
        
        #Constrain positive and negative pipe flows
        @constraint(EP, cMaxPositiveCO2Flow[d in [-1,1], p in 1:CO2_P, t=1:T], EP[:vCO2NPipe][p] * inputs["pCO2_Pipe_Max_Flow"][p] >= vCO2PipeFlow_pos[p,t,d])
        @constraint(EP, cMaxNegativeCO2Flow[d in [-1,1], p in 1:CO2_P, t=1:T], EP[:vCO2NPipe][p] * inputs["pCO2_Pipe_Max_Flow"][p] >= vCO2PipeFlow_neg[p,t,d])

        #Pipe level constraint
        @constraint(EP, cMinCO2PipeLevel[p in 1:CO2_P, t=1:T], vCO2PipeLevel[p,t] >= inputs["pCO2_Pipe_Min_Cap"][p] * EP[:vCO2NPipe][p])
        @constraint(EP, cMaxCO2PipeLevel[p in 1:CO2_P, t=1:T], vCO2PipeLevel[p,t] <= inputs["pCO2_Pipe_Max_Cap"][p] * EP[:vCO2NPipe][p])
    end

    #CO2 Balance in pipe
    @constraint(EP, cCO2PipeBalanceStart[p in 1:CO2_P, t in START_SUBPERIODS], vCO2PipeLevel[p,t] == vCO2PipeLevel[p,t + hours_per_subperiod - 1] - eCO2PipeFlow_net[p,t, -1] - eCO2PipeFlow_net[p,t,1])

    @constraint(EP, cCO2PipeBalanceInterior[p in 1:CO2_P, t in INTERIOR_SUBPERIODS], vCO2PipeLevel[p,t] == vCO2PipeLevel[p,t - 1] - eCO2PipeFlow_net[p,t, -1] - eCO2PipeFlow_net[p,t,1])

    @constraint(EP, cCO2PipesMaxNumber[p in 1:CO2_P], EP[:vCO2NPipe][p] <= inputs["pCO2_Pipe_No_Max"][p])

	return EP
end



# ### This file splits the Investment decision variables for Benders Decomposition

# function CO2_pipeline_investment111(EP::Model, inputs::Dict, setup::Dict)
# 	println("CO2 Pipeline Investment Module")

#     # T = inputs["T"] # Model operating time steps
#     # Z = inputs["Z"]  # Model demand zones - assumed to be same for CO2 and electricity

# 	CO2_P = inputs["CO2_P"] # Number of CO2 Pipelines

    
#     ### Expressions ###
#     #Calculate the number of new pipes
#     @expression(EP, eCO2NPipeNew[p = 1:CO2_P], EP[:vCO2NPipe][p] - inputs["pCO2_Pipe_No_Curr"][p])


#     	## Objective Function Expressions ##
# 	# Capital cost of pipelines 
#     #  ParameterScale = 1 --> objective function is in million $
# 	#  ParameterScale = 0 --> objective function is in $

#     if setup["ParameterScale"] ==1 
#         @expression(EP, eCCO2Pipe,  sum(eCO2NPipeNew[p] * inputs["pCAPEX_CO2_Pipe"][p]/(ModelScalingFactor)^2 for p = 1:CO2_P) + sum(EP[:vCO2NPipe][p] * inputs["pFixed_OM_CO2_Pipe"][p]/(ModelScalingFactor)^2 for p = 1:CO2_P))
#     else
#         @expression(EP, eCCO2Pipe,  sum(eCO2NPipeNew[p] * inputs["pCAPEX_CO2_Pipe"][p] for p = 1:CO2_P) + sum(EP[:vCO2NPipe][p] * inputs["pFixed_OM_CO2_Pipe"][p] for p = 1:CO2_P))
#     end

#     EP[:eObj] += eCCO2Pipe

#         # Capital cost of booster compressors located along each pipeline - more booster compressors needed for longer pipelines than shorter pipelines
#      #  ParameterScale = 1 --> objective function is in million $
# 	#  ParameterScale = 0 --> objective function is in $
# 	if setup["ParameterScale"] ==1 
#         @expression(EP, eCCO2CompPipe, sum(eCO2NPipeNew[p] * inputs["pCAPEX_Comp_CO2_Pipe"][p]/(ModelScalingFactor)^2 for p = 1:CO2_P))

# 	else
#         @expression(EP, eCCO2CompPipe, sum(eCO2NPipeNew[p] * inputs["pCAPEX_Comp_CO2_Pipe"][p] for p = 1:CO2_P))
# 	end
	

#     EP[:eObj] += eCCO2CompPipe


#     # Constraints
# 	if setup["CO2PipeInteger"] == 1
#         for p=1:CO2_P
# 		    set_integer.(EP[:vCO2NPipe][p])
#         end
# 	end

#         # Modeling expansion of the pipleline network
#         if setup["CO2NetworkExpansion"]==1
#             # If network expansion allowed Total no. of Pipes >= Existing no. of Pipe 
#             @constraint(EP, cCO2NetworkExpansion[p in 1:CO2_P], EP[:eCO2NPipeNew][p] >= 0)
#         else
#             # If network expansion is not alllowed Total no. of Pipes == Existing no. of Pipe 
#             @constraint(EP, cCO2NetworkExpansion[p in 1:CO2_P], EP[:eCO2NPipeNew][p] == 0)
#         end
#     return EP
# end






# """
# DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
# Copyright (C) 2022,  Massachusetts Institute of Technology
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# A complete copy of the GNU General Public License v2 (GPLv2) is available
# in LICENSE.txt.  Users uncompressing this from an archive may not have
# received this license file.  If not, see <http://www.gnu.org/licenses/>.
# """

# @doc raw"""
#     co2_pipeline(EP::Model, inputs::Dict, setup::Dict)

# This function includes the variables, expressions and objective funtion of CO2 pipeline.

# This function expresses CO2 exchange through pipeline i between two zones and can be split into CO2 delivering and flowing out.

# This module defines the CO2 pipeline construction decision variable $y_{i,z \rightarrow z^{\prime}}^{\textrm{C,PIP}} \forall i \in \mathcal{I}, z \rightarrow z^{\prime} \in \mathcal{B}$, representing newly constructed CO2 pipeline of type $i$ through path $z \rightarrow z^{\prime}$.

# This module defines the CO2 pipeline flow decision variable $x_{i,z \rightarrow z^{\prime},t}^{\textrm{C,PIP}} \forall i \in \mathcal{I}, z \rightarrow z^{\prime} \in \mathcal{B}, t \in \mathcal{T}$, representing CO2 flow via pipeline of type $i$ through path $z \rightarrow z^{\prime}$ at time period $t$.

# This module defines the CO2 pipeline storage level decision variable $U_{i,z \rightarrow z^{\prime},t}^{\textrm{C,PIP}} \forall i \in \mathcal{I}, z \rightarrow z^{\prime} \in \mathcal{B}, t \in \mathcal{T}$, representing CO2 stored in pipeline of type $i$ through path $z \rightarrow z^{\prime}$ at time period $t$.

# The variable defined in this file named after ```vCO2NPipe``` covers variable $y_{i,z \rightarrow z^{\prime}}^{\textrm{C,PIP}}$.

# The variable defined in this file named after ```vCO2PipeFlow_pos``` covers variable $x_{i,z \rightarrow z^{\prime},t}^{\textrm{C,PIP+}}$.

# The variable defined in this file named after ```vCO2PipeFlow_neg``` covers variable $x_{i,z \rightarrow z^{\prime},t}^{\textrm{C,PIP-}}$.

# The variable defined in this file named after ```vCO2PipeLevel``` covers variable $U_{i,z \rightarrow z^{\prime},t}^{\textrm{C,PIP}}$.

# **Cost expressions**

# This module additionally defines contributions to the objective function from investment costs of generation (fixed OM plus construction) from all pipeline resources $i \in \mathcal{I}$:

# ```math
# \begin{equation*}
#     \textrm{C}^{\textrm{C,PIP,c}}=\delta_{i}^{\textrm{C,PIP}} \sum_{i \in \mathbb{I}} \sum_{z \rightarrow z^{\prime} \in \mathbb{B}} \textrm{c}_{i}^{\textrm{C,PIP}} \textrm{L}_{z \rightarrow z^{\prime}} l_{i,z \rightarrow z^{\prime}}
#     h_{i,z \rightarrow z^{\prime}, t}^{\textrm{C,PIP}}=h_{i, z \rightarrow z^{\prime}, t}^{\textrm{C,PIP+}}-h_{i, z \rightarrow z^{\prime}, t}^{\textrm{PIP-}} \quad \forall i \in \mathbb{I}, z \rightarrow z^{\prime} \in \mathbb{B}, t \in \mathbb{T}
# \end{equation*}
# ```

# The flow rate of CO2 through pipeline type $i$ is capped by the operational limits of the pipeline, multiplied by the number of constructed pipeline $i$
# ```math
# \begin{equation*}
#     \overline{\textrm{F}}_{i} l_{i,z \rightarrow z^{\prime}} \geq x_{i,z \rightarrow z^{\prime}, t}^{\textrm{\textrm{C,PIP+}}}, x_{i,z \rightarrow z^{\prime}, t}^{\textrm{\textrm{C,PIP-}}} \geq 0 \quad \forall i \in \mathbb{I}, z \rightarrow z^{\prime} \in \mathbb{B}, t \in \mathbb{T}
# \end{equation*}    
# ```

# The pipeline has storage capacity via line packing:
# ```math
# \begin{equation*}
#     \overline{\textrm{U}}_{i}^{\textrm{\text{C,PIP}}} l_{i,z \rightarrow z^{\prime}} \geq -\sum_{\tau=t_{0}}^{t}\left(x_{i,z^{\prime}\rightarrow z, \tau}^{\textrm{\textrm{C,PIP}}}+x_{i,z \rightarrow z^{\prime} \tau}^{\textrm{\textrm{C,PIP}}}\right)\Delta t \geq\underline{\textrm{R}}_{i}^{\textrm{\textrm{C,PIP}}}\overline{\textrm{E}}_{i}^{\textrm{\textrm{C,PIP}}} l_{i,z \rightarrow z^{\prime}} \forall z^{\prime} \in Z, z \in Z, i \in I, t \in T
# \end{equation*}  
# ```

# The change of CO2 pipeline storage inventory is modeled as follows:
# ```math
# \begin{equation*}
#     U_{i,z \rightarrow z^{\prime},t}^{\textrm{C,PIP}} - U_{i,z \rightarrow z^{\prime},t-1} = x_{i,z \rightarrow z^{\prime},t}^{\textrm{C,PIP-}} + x_{i,z^{\prime} \rightarrow z,t}^{\textrm{C,PIP-}}
# \end{equation*}
# ```
# """
# function co2_pipeline(EP::Model, inputs::Dict, setup::Dict)

# 	println("CO2 Pipeline Module")

#     T = inputs["T"] # Model operating time steps
#     Z = inputs["Z"]  # Model demand zones - assumed to be same for CO2 and electricity
#     INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
#     START_SUBPERIODS = inputs["START_SUBPERIODS"]
#     hours_per_subperiod = inputs["hours_per_subperiod"]

# 	CO2_P = inputs["CO2_P"] # Number of CO2 Pipelines
#     CO2_Pipe_Map = inputs["CO2_Pipe_Map"] 

# 	### Variables ###
#     @variable(EP, vCO2NPipe[p=1:CO2_P] >= 0 ) #Number of Pipes
#     @variable(EP, vCO2PipeLevel[p=1:CO2_P, t = 1:T] >= 0 ) #Storage in the pipe
#     @variable(EP, vCO2PipeFlow_pos[p=1:CO2_P, t = 1:T, d = [1,-1]] >= 0) #positive pipeflow
#     @variable(EP, vCO2PipeFlow_neg[p=1:CO2_P, t = 1:T, d = [1,-1]] >= 0) #negative pipeflow
#     @variable(EP, vCO2Loss[t=1:T,z=1:Z] >= 0 ) #CO2 Loss in Pipe

# 	### Expressions ###
#     #Calculate the number of new pipes
#     @expression(EP, eCO2NPipeNew[p = 1:CO2_P], vCO2NPipe[p] - inputs["pCO2_Pipe_No_Curr"][p])

# 	## Objective Function Expressions ##
# 	# Capital cost of pipelines 
#     #  ParameterScale = 1 --> objective function is in million $
# 	#  ParameterScale = 0 --> objective function is in $

#     if setup["ParameterScale"] ==1 
#         @expression(EP, eCCO2Pipe,  sum(eCO2NPipeNew[p] * inputs["pCAPEX_CO2_Pipe"][p]/(ModelScalingFactor)^2 for p = 1:CO2_P) + sum(vCO2NPipe[p] * inputs["pFixed_OM_CO2_Pipe"][p]/(ModelScalingFactor)^2 for p = 1:CO2_P))
#     else
#         @expression(EP, eCCO2Pipe,  sum(eCO2NPipeNew[p] * inputs["pCAPEX_CO2_Pipe"][p] for p = 1:CO2_P) + sum(vCO2NPipe[p] * inputs["pFixed_OM_CO2_Pipe"][p] for p = 1:CO2_P))
#     end

#     EP[:eObj] += eCCO2Pipe

#     # Capital cost of booster compressors located along each pipeline - more booster compressors needed for longer pipelines than shorter pipelines
#      #  ParameterScale = 1 --> objective function is in million $
# 	#  ParameterScale = 0 --> objective function is in $
# 	if setup["ParameterScale"] ==1 
#         @expression(EP, eCCO2CompPipe, sum(eCO2NPipeNew[p] * inputs["pCAPEX_Comp_CO2_Pipe"][p]/(ModelScalingFactor)^2 for p = 1:CO2_P))

# 	else
#         @expression(EP, eCCO2CompPipe, sum(eCO2NPipeNew[p] * inputs["pCAPEX_Comp_CO2_Pipe"][p] for p = 1:CO2_P))
# 	end
	

#     EP[:eObj] += eCCO2CompPipe

# 	## End Objective Function Expressions ##

# 	## Balance Expressions ##
# 	# Electrical energy requirement for pipeline operation
#     # IF ParameterScale = 1, power system operation/capacity modeled in GW rather than MW, , no need to scale as MW/ton = GW/kton
#     # IF ParameterScale = 0, power system operation/capacity modeled in MW so no scaling of CO2 related power consumption
#     @expression(EP, ePowerDemandCO2Pipe[t=1:T, z=1:Z],
#     sum(vCO2PipeFlow_neg[p,t,CO2_Pipe_Map[(CO2_Pipe_Map[!,:Zone] .== z) .& (CO2_Pipe_Map[!,:pipe_no] .== p), :][!,:d][1]] * inputs["pMWh_per_tonne_CO2_Pipe"][p] for  p in CO2_Pipe_Map[CO2_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))    
    
#     @expression(EP, ePowerDemandCO2Pipe_zt[z=1:Z,t=1:T],
#     sum(vCO2PipeFlow_neg[p,t,CO2_Pipe_Map[(CO2_Pipe_Map[!,:Zone] .== z) .& (CO2_Pipe_Map[!,:pipe_no] .== p), :][!,:d][1]] * inputs["pMWh_per_tonne_CO2_Pipe"][p] for  p in CO2_Pipe_Map[CO2_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))    

# 	# Electrical energy requirement for booster compression
#     # IF ParameterScale = 1, power system operation/capacity modeled in GW rather than MW, , no need to scale as MW/ton = GW/kton
#     # IF ParameterScale = 0, power system operation/capacity modeled in MW so no scaling of CO2 related power consumption
#     @expression(EP, ePowerDemandCO2PipeCompression[t=1:T, z=1:Z],
#     sum(vCO2PipeFlow_neg[p,t,CO2_Pipe_Map[(CO2_Pipe_Map[!,:Zone] .== z) .& (CO2_Pipe_Map[!,:pipe_no] .== p), :][!,:d][1]] * inputs["pComp_MWh_per_tonne_CO2_Pipe"][p] for  p in CO2_Pipe_Map[CO2_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))    

#     @expression(EP, ePowerDemandCO2PipeCompression_zt[z=1:Z,t=1:T],
#     sum(vCO2PipeFlow_neg[p,t,CO2_Pipe_Map[(CO2_Pipe_Map[!,:Zone] .== z) .& (CO2_Pipe_Map[!,:pipe_no] .== p), :][!,:d][1]] * inputs["pComp_MWh_per_tonne_CO2_Pipe"][p] for  p in CO2_Pipe_Map[CO2_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))    

#     EP[:ePowerBalance_CSC] += -ePowerDemandCO2Pipe
#     EP[:ePowerBalance_CSC] += -ePowerDemandCO2PipeCompression

#     EP[:eCSCNetpowerConsumptionByAll] += ePowerDemandCO2Pipe
#     EP[:eCSCNetpowerConsumptionByAll] += ePowerDemandCO2PipeCompression


# 	### Constraints ###

#     # Constraints
# 	if setup["CO2PipeInteger"] == 1
#         for p=1:CO2_P
# 		    set_integer.(vCO2NPipe[p])
#         end
# 	end

#     # Modeling expansion of the pipleline network
#     if setup["CO2NetworkExpansion"]==1
#         # If network expansion allowed Total no. of Pipes >= Existing no. of Pipe 
#         @constraint(EP, cCO2NetworkExpansion[p in 1:CO2_P], EP[:eCO2NPipeNew][p] >= 0)
#     else
#         # If network expansion is not alllowed Total no. of Pipes == Existing no. of Pipe 
#         @constraint(EP, cCO2NetworkExpansion[p in 1:CO2_P], EP[:eCO2NPipeNew][p] == 0)
#     end

#     # Modeling loss of CO2 in the piplelines
#     if setup["CO2Pipeline_Loss"]==1
#         # If modeling CO2 loss from pipe
#         @expression(EP, eCO2Loss_Pipes_per_pipe[t=1:T,z=1:Z], sum(vCO2PipeFlow_neg[p,t,CO2_Pipe_Map[(CO2_Pipe_Map[!,:Zone] .== z) .& (CO2_Pipe_Map[!,:pipe_no] .== p), :][!,:d][1]] * inputs["pLoss_tonne_per_tonne_CO2_Pipe"][p] for  p in CO2_Pipe_Map[CO2_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))
        
#         @expression(EP, eCO2Loss_Pipes[t=1:T,z=1:Z], sum(vCO2PipeFlow_neg[p,t,CO2_Pipe_Map[(CO2_Pipe_Map[!,:Zone] .== z) .& (CO2_Pipe_Map[!,:pipe_no] .== p), :][!,:d][1]] * inputs["pLoss_tonne_per_tonne_CO2_Pipe"][p] for  p in CO2_Pipe_Map[CO2_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))
#         @expression(EP, eCO2Loss_Pipes_zt[z=1:Z,t=1:T], sum(vCO2PipeFlow_neg[p,t,CO2_Pipe_Map[(CO2_Pipe_Map[!,:Zone] .== z) .& (CO2_Pipe_Map[!,:pipe_no] .== p), :][!,:d][1]] * inputs["pLoss_tonne_per_tonne_CO2_Pipe"][p] for  p in CO2_Pipe_Map[CO2_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))
#     else
#         # If not modeling CO2 loss from pipe
#         @expression(EP, eCO2Loss_Pipes[t=1:T,z=1:Z], 0)
#         @expression(EP, eCO2Loss_Pipes_zt[z=1:Z,t=1:T], 0)
#     end

    

#     #Calculate net flow at each pipe-zone interfrace
#     @expression(EP, eCO2PipeFlow_net[p = 1:CO2_P, t = 1:T, d = [-1,1]],  vCO2PipeFlow_pos[p,t,d] - vCO2PipeFlow_neg[p,t,d]*(1-inputs["pLoss_tonne_per_tonne_CO2_Pipe"][p]))

#     # CO2 balance - net flows of CO2 from between z and zz via pipeline p over time period t
#     @expression(EP, ePipeZoneCO2Demand_No_Loss[t=1:T,z=1:Z],
#         sum(eCO2PipeFlow_net[p,t, CO2_Pipe_Map[(CO2_Pipe_Map[!,:Zone] .== z) .& (CO2_Pipe_Map[!,:pipe_no] .== p), :][!,:d][1]] for p in CO2_Pipe_Map[CO2_Pipe_Map[!,:Zone].==z,:][!,:pipe_no]))

#     # CO2 balance - net flows of CO2 from between z and zz via pipeline p over time period t
#     @expression(EP, ePipeZoneCO2Demand[t=1:T,z=1:Z],ePipeZoneCO2Demand_No_Loss[t,z] - eCO2Loss_Pipes[t,z])

#     #EP[:eCaptured_CO2_Balance] -= eCO2Loss_Pipes #No need as we have already deducted the loss from the balance
#     EP[:eCaptured_CO2_Balance] += ePipeZoneCO2Demand

#     if setup["ParameterScale"] ==1 
#         #Pipe flow constraint
#         @constraint(EP, cMinCO2Pipeflow[d in [-1,1], p in 1:CO2_P, t=1:T], EP[:eCO2PipeFlow_net][p,t,d] >= -EP[:vCO2NPipe][p] * inputs["pCO2_Pipe_Max_Flow"][p]/ModelScalingFactor)
#         @constraint(EP, cMaxCO2Pipeflow[d in [-1,1], p in 1:CO2_P, t=1:T], EP[:eCO2PipeFlow_net][p,t,d] <= EP[:vCO2NPipe][p] * inputs["pCO2_Pipe_Max_Flow"][p]/ModelScalingFactor)
    
#         #Constrain positive and negative pipe flows
#         @constraint(EP, cMaxPositiveCO2Flow[d in [-1,1], p in 1:CO2_P, t=1:T], vCO2NPipe[p] * inputs["pCO2_Pipe_Max_Flow"][p] >= vCO2PipeFlow_pos[p,t,d]/ModelScalingFactor)
#         @constraint(EP, cMaxNegativeCO2Flow[d in [-1,1], p in 1:CO2_P, t=1:T], vCO2NPipe[p] * inputs["pCO2_Pipe_Max_Flow"][p] >= vCO2PipeFlow_neg[p,t,d]/ModelScalingFactor)
        
#         #Pipe level constraint
#         @constraint(EP, cMinCO2PipeLevel[p in 1:CO2_P, t=1:T], vCO2PipeLevel[p,t] >= inputs["pCO2_Pipe_Min_Cap"][p] * vCO2NPipe[p]/ModelScalingFactor)
#         @constraint(EP, cMaxCO2PipeLevel[p in 1:CO2_P, t=1:T], vCO2PipeLevel[p,t] <= inputs["pCO2_Pipe_Max_Cap"][p] * vCO2NPipe[p]/ModelScalingFactor)
#     else
#         #Pipe flow constraint
#         @constraint(EP, cMinCO2Pipeflow[d in [-1,1], p in 1:CO2_P, t=1:T], EP[:eCO2PipeFlow_net][p,t,d] >= -EP[:vCO2NPipe][p] * inputs["pCO2_Pipe_Max_Flow"][p])
#         @constraint(EP, cMaxCO2Pipeflow[d in [-1,1], p in 1:CO2_P, t=1:T], EP[:eCO2PipeFlow_net][p,t,d] <= EP[:vCO2NPipe][p] * inputs["pCO2_Pipe_Max_Flow"][p])
        
#         #Constrain positive and negative pipe flows
#         @constraint(EP, cMaxPositiveCO2Flow[d in [-1,1], p in 1:CO2_P, t=1:T], vCO2NPipe[p] * inputs["pCO2_Pipe_Max_Flow"][p] >= vCO2PipeFlow_pos[p,t,d])
#         @constraint(EP, cMaxNegativeCO2Flow[d in [-1,1], p in 1:CO2_P, t=1:T], vCO2NPipe[p] * inputs["pCO2_Pipe_Max_Flow"][p] >= vCO2PipeFlow_neg[p,t,d])

#         #Pipe level constraint
#         @constraint(EP, cMinCO2PipeLevel[p in 1:CO2_P, t=1:T], vCO2PipeLevel[p,t] >= inputs["pCO2_Pipe_Min_Cap"][p] * vCO2NPipe[p])
#         @constraint(EP, cMaxCO2PipeLevel[p in 1:CO2_P, t=1:T], vCO2PipeLevel[p,t] <= inputs["pCO2_Pipe_Max_Cap"][p] * vCO2NPipe[p])
#     end

#     #CO2 Balance in pipe
#     @constraint(EP, cCO2PipeBalanceStart[p in 1:CO2_P, t in START_SUBPERIODS], vCO2PipeLevel[p,t] == vCO2PipeLevel[p,t + hours_per_subperiod - 1] - eCO2PipeFlow_net[p,t, -1] - eCO2PipeFlow_net[p,t,1])

#     @constraint(EP, cCO2PipeBalanceInterior[p in 1:CO2_P, t in INTERIOR_SUBPERIODS], vCO2PipeLevel[p,t] == vCO2PipeLevel[p,t - 1] - eCO2PipeFlow_net[p,t, -1] - eCO2PipeFlow_net[p,t,1])

#     @constraint(EP, cCO2PipesMaxNumber[p in 1:CO2_P], vCO2NPipe[p] <= inputs["pCO2_Pipe_No_Max"][p])

# 	return EP
# end
