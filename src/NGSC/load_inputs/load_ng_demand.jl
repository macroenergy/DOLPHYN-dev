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
	load_ng_demand(setup::Dict, path::AbstractString, sep::AbstractString, inputs::Dict)

Function for reading input parameters related to liquid fuel load (demand) and emissions of each zone for each type of fuel (Gasoline, Jetfuel, NG).
"""
function load_ng_demand(setup::Dict, path::AbstractString, sep::AbstractString, inputs::Dict)
    
	data_directory_ng = joinpath(path, setup["TimeDomainReductionFolder"])
	if setup["TimeDomainReduction"] == 1  && isfile(joinpath(data_directory_ng,"NGSC_Demand.csv")) # Use Time Domain Reduced data for GenX
		NGSC_NG_Demand_in = DataFrame(CSV.File(string(joinpath(data_directory_ng,"NGSC_Demand.csv")), header=true), copycols=true)
	else # Run without Time Domain Reduction OR Getting original input data for Time Domain Reduction
		NGSC_NG_Demand_in = DataFrame(CSV.File(string(path,sep,"NGSC_Demand.csv"), header=true), copycols=true)
	end

    # Demand in tonnes per hour for each zone
	#println(names(load_in))
	start_ng = findall(s -> s == "Load_mmbtu_z1", names(NGSC_NG_Demand_in))[1] #gets the start column number of all the columns, with header "Load_mmbtu_z1"
	
	# Demand in Tonnes per hour
	inputs["NG_D"] =Matrix(NGSC_NG_Demand_in[1:inputs["T"],start_ng:start_ng-1+inputs["Z"]]) #form a matrix with columns as the different zonal load NG demand values and rows as the hours
    
	inputs["ng_co2_per_mmbtu"] = NGSC_NG_Demand_in[!, "ng_co2_per_mmbtu"][1]

	println(" -- NGSC_Demand.csv Successfully Read!")

    return inputs

end

