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
	write_bio_forest_supply_dual(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the dual of the forest biomass purchased from different resources across zones with time.
"""

function write_bio_forest_supply_dual(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
	
	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	omega = inputs["omega"] # Time step weights

	dfForestSupplyBalanceDual = DataFrame(Zone = 1:Z)
	dual_values = transpose(dual.(EP[:cForestBiomassBalance]) ./ omega)

	dfForestSupplyBalanceDual=hcat(dfForestSupplyBalanceDual, DataFrame(dual_values, :auto))
	rename!(dfForestSupplyBalanceDual,[Symbol("Zone");[Symbol("t$t") for t in 1:T]])

	CSV.write(string(path,sep,"BESC_agri_forest_balance_dual.csv"), dftranspose(dfForestSupplyBalanceDual, false), writeheader=false)

end