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
    biorefinery_investment(EP::Model, inputs::Dict, UCommit::Int, Reserves::Int)

This module defines the built capacity and the total fixed cost (Investment + Fixed O&M) of biorefinery resource $k$.

"""
function biorefinery_investment(EP::Model, inputs::Dict, setup::Dict)
	
	println("Biorefinery Fixed Cost module")

	dfbiorefinery = inputs["dfbiorefinery"]
	BIO_RES_ALL = inputs["BIO_RES_ALL"]
	BIO_H2 = inputs["BIO_H2"]

	Z = inputs["Z"]
	T = inputs["T"]
	
	#General variables for non-piecewise and piecewise cost functions
	@variable(EP,vCapacity_BIO_per_type[i in 1:BIO_RES_ALL])
	@variable(EP,vCAPEX_BIO_per_type[i in 1:BIO_RES_ALL])

	if setup["ParameterScale"] == 1
		BIO_Capacity_Min_Limit = dfbiorefinery[!,:Min_capacity_tonne_per_hr]/ModelScalingFactor
		BIO_Capacity_Max_Limit = dfbiorefinery[!,:Max_capacity_tonne_per_hr]/ModelScalingFactor
	else
		BIO_Capacity_Min_Limit = dfbiorefinery[!,:Min_capacity_tonne_per_hr]
		BIO_Capacity_Max_Limit = dfbiorefinery[!,:Max_capacity_tonne_per_hr]
	end
		
	if setup["ParameterScale"] == 1
		BIO_Inv_Cost_per_tonne_per_hr_yr = dfbiorefinery[!,:Inv_Cost_per_tonne_per_hr_yr]/ModelScalingFactor # $M/kton
		BIO_Fixed_OM_Cost_per_tonne_per_hr_yr = dfbiorefinery[!,:Fixed_OM_Cost_per_tonne_per_hr_yr]/ModelScalingFactor # $M/kton
	else
		BIO_Inv_Cost_per_tonne_per_hr_yr = dfbiorefinery[!,:Inv_Cost_per_tonne_per_hr_yr]
		BIO_Fixed_OM_Cost_per_tonne_per_hr_yr = dfbiorefinery[!,:Fixed_OM_Cost_per_tonne_per_hr_yr]
	end

	#Min and max capacity constraints
	@constraint(EP,cMinCapacity_per_unit_BIO[i in 1:BIO_RES_ALL], EP[:vCapacity_BIO_per_type][i] >= BIO_Capacity_Min_Limit[i])
	@constraint(EP,cMaxCapacity_per_unit_BIO[i in 1:BIO_RES_ALL], EP[:vCapacity_BIO_per_type][i] <= BIO_Capacity_Max_Limit[i])

	#Investment cost = CAPEX
	@expression(EP, eCAPEX_BIO_per_type[i in 1:BIO_RES_ALL], EP[:vCapacity_BIO_per_type][i] * BIO_Inv_Cost_per_tonne_per_hr_yr[i])

	#Fixed OM cost
	@expression(EP, eFixed_OM_BIO_per_type[i in 1:BIO_RES_ALL], EP[:vCapacity_BIO_per_type][i] * BIO_Fixed_OM_Cost_per_tonne_per_hr_yr[i])

	#Total fixed cost = CAPEX + Fixed OM
	@expression(EP, eFixed_Cost_BIO_per_type[i in 1:BIO_RES_ALL], EP[:eFixed_OM_BIO_per_type][i] + EP[:eCAPEX_BIO_per_type][i])

	#Total cost
	#Expression for total CAPEX for all resoruce types (For output)
	@expression(EP,eCAPEX_BIO_total, sum(EP[:eCAPEX_BIO_per_type][i] for i in 1:BIO_RES_ALL))

	#Expression for total Fixed OM for all resoruce types (For output)
	@expression(EP,eFixed_OM_BIO_total, sum(EP[:eFixed_OM_BIO_per_type][i] for i in 1:BIO_RES_ALL))

	#Expression for total Fixed Cost for all resoruce types (For output and to add to objective function)
	@expression(EP,eFixed_Cost_BIO_total, sum(EP[:eFixed_Cost_BIO_per_type][i] for i in 1:BIO_RES_ALL))

	EP[:eObj] += EP[:eFixed_Cost_BIO_total]

	#####################################################################################################################################
	#For Bio-H2 to use in LCOH calculations
	#Investment cost of Bio H2
	#if setup["Bio_H2_On"] == 1
	#	@expression(EP, eCAPEX_BIO_H2_per_type[i in BIO_H2], EP[:vCapacity_BIO_per_type][i] * BIO_Inv_Cost_per_tonne_per_hr_yr[i])

		#Fixed OM cost of Bio H2
	#	@expression(EP, eFixed_OM_BIO_H2_per_type[i in BIO_H2], EP[:vCapacity_BIO_per_type][i] * BIO_Fixed_OM_Cost_per_tonne_per_hr_yr[i])

		#Total fixed cost of Bio H2
	#	@expression(EP, eFixed_Cost_BIO_H2_per_type[i in BIO_H2], EP[:eFixed_OM_BIO_H2_per_type][i] + EP[:eCAPEX_BIO_H2_per_type][i])

		#Expression for total Fixed Cost for Bio H2 (For output in LCOH)
	#	@expression(EP,eFixed_Cost_BIO_H2_total, sum(EP[:eFixed_Cost_BIO_H2_per_type][i] for i in BIO_H2))
	#end

    return EP

end
