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
	conventional_ng_share(EP::Model, inputs::Dict, setup::Dict)

This function establishes constraints that can be flexibily applied to define alternative forms of policies that require generation of a quantity of conventional ng in the entire system across the entire year

	"""
function conventional_ng_share(EP::Model, inputs::Dict, setup::Dict)
	println(" -- Conventional NG Share Requirement Policies Module")
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	Conv_NG_Share = setup["Conv_NG_Share"]

	### NG
	if setup["Conventional_NG_Share_Requirement"] == 1

		## Conventional NG Share Requirements
		@expression(EP, eAnnualGlobalSBNG, sum(sum(inputs["omega"][t] * EP[:eSB_NG_Balance][t,z] for z = 1:Z) for t = 1:T))

		@expression(EP, AnnualeGlobalConvNG, sum(sum(inputs["omega"][t] * EP[:vConv_NG_Demand][t,z] for z = 1:Z) for t = 1:T))
		
		@constraint(EP, cConvNGShare, (1-Conv_NG_Share) * EP[:AnnualeGlobalConvNG] == Conv_NG_Share * EP[:eAnnualGlobalSBNG])

	end

	return EP
end
