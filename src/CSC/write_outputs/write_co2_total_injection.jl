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
	write_co2_total_injection(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting CO2 storage injection.
"""
function write_co2_total_injection(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

	dfCO2Storage = inputs["dfCO2Storage"]
	capcapture = zeros(size(inputs["CO2_STORAGE_NAME"]))
	CO2_Injection_Scaling = setup["CO2InjectionScalingFactor"]

	#We calculated total co2 injection in Kt for scaling purposes
	for i in 1:inputs["CO2_STOR_ALL"]
		capcapture[i] = value(EP[:eCO2_Injected_per_year_scaled][i])*CO2_Injection_Scaling
	end

	dfCap = DataFrame(
		Resource = inputs["CO2_STORAGE_NAME"], Zone = dfCO2Storage[!,:Zone],
		Injection_tonne_per_yr = capcapture[:],
	)


	total = DataFrame(
			Resource = "Total", Zone = "n/a",
			Injection_tonne_per_yr = sum(dfCap[!,:Injection_tonne_per_yr]),
		)

	dfCap = vcat(dfCap, total)
	CSV.write(string(path,sep,"CSC_injection_per_year.csv"), dfCap)

	return dfCap
end
