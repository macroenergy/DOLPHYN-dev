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
	write_h2_tmr_prices(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting prices related to time matching requirement.	
"""
function write_h2_tmr_prices(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

	dfGen = inputs["dfGen"] # Power sector inputs
	dfH2Gen = inputs["dfH2Gen"]
	T = inputs["T"]     # Number of time steps (hours)

	# Identify number of time matching requirements
	nH2_TMR = count(s -> startswith(String(s), "H2_TMR_"), names(dfGen))


	if (setup["TimeMatchingRequirement"] == 1 || setup["TimeMatchingRequirement"] == 2)

			## Extract dual variables of constraints
	# Electricity price: Dual variable of hourly power balance constraint = hourly price
		dfPrice = DataFrame(TMR = 1:nH2_TMR) # The unit is $/MWh

	# Dividing dual variable for each hour with corresponding hourly weight to retrieve marginal cost of generation
		dfPrice = hcat(dfPrice, DataFrame(dual.(EP[:cH2TMR])./transpose(inputs["omega"]), :auto))

		auxNew_Names=[Symbol("Zone");[Symbol("t$t") for t in 1:T]]
		rename!(dfPrice,auxNew_Names)

		## Linear configuration final output
		CSV.write(string(path,sep,"TMR_prices.csv"), dftranspose(dfPrice, false), writeheader=false)
	

	else # annual time matching scenario (TimeMatchingRequirement = 3)
	
		dfPrice = DataFrame(TMR_Price = convert(Array{Union{Missing, Float64}}, dual.(EP[:cH2TMR_Annual])))
	
		CSV.write(string(path,sep,"TMR_prices.csv"), dfPrice)

	end
	
	return dfPrice

end
