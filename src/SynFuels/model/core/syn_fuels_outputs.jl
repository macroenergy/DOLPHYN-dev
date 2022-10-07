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
    h2_discharge(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

This module defines the production decision variable  representing hydrogen injected into the network by resource $y$ by at time period $t$.

This module additionally defines contributions to the objective function from variable costs of generation (variable O&M plus fuel cost) from all resources over all time periods.

"""

function syn_fuels_outputs(EP::Model, inputs::Dict, setup::Dict)

	println("Synthesis Fuels Generation and Storage Discharge Module")

    dfSynGen = inputs["dfSynGen"]

	#Define sets
	H = inputs["SYN_RES_ALL"] #Number of Hydrogen gen units
	T = inputs["T"]     # Number of time steps (hours)


	### Variables ###

    #H2 injected to hydrogen grid from hydrogen generation resource k (tonnes of H2/hr) in time t
	@variable(EP, vSynGen[k=1:H, t = 1:T] >= 0)

	### Expressions ###

	## Objective Function Expressions ##

    # Variable costs of "generation" for resource "y" during hour "t" = variable O&M plus fuel cost

	#  ParameterScale = 1 --> objective function is in million $ .
	## In power system case we only scale by 1000 because variables are also scaled. But here we dont scale variables.
	## Fue cost already scaled by 1000 in load_fuels_data.jl sheet, so  need to scale variable OM cost component by million and fuel cost component by 1000 here.
	#  ParameterScale = 0 --> objective function is in $

	if setup["ParameterScale"] ==1
		@expression(EP, eCSynGenVar_out[k = 1:H,t = 1:T],
		(inputs["omega"][t] * (dfSynGen[!,:Var_OM_Cost_p_tonne][k]/ModelScalingFactor^2 + inputs["fuel_costs"][dfSynGen[!,:Fuel][k]][t] * dfSynGen[!,:etaFuel_MMBtu_p_tonne][k]/ModelScalingFactor) * vH2Gen[k,t]))
	else
		@expression(EP, eCSynGenVar_out[k = 1:H,t = 1:T],
		(inputs["omega"][t] * ((dfSynGen[!,:Var_OM_Cost_p_tonne][k] + inputs["fuel_costs"][dfSynGen[!,:Fuel][k]][t] * dfSynGen[!,:etaFuel_MMBtu_p_tonne][k])) * vSynGen[k,t]))
	end

	@expression(EP, eTotalCSynGenVarOutT[t=1:T], sum(eCSynGenVar_out[k,t] for k in 1:H))
	@expression(EP, eTotalCSynGenVarOut, sum(eTotalCSynGenVarOutT[t] for t in 1:T))

	# Add total variable discharging cost contribution to the objective function
	EP[:eObj] += eTotalCSynGenVarOut

	return EP

end
