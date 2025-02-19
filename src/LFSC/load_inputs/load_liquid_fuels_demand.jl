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
	load_liquid_fuels_demand(setup::Dict, path::AbstractString, sep::AbstractString, inputs::Dict)

Function for reading input parameters related to liquid fuel load (demand) and emissions of each zone for each type of fuel (Gasoline, Jetfuel, Diesel).
"""
function load_liquid_fuels_demand(setup::Dict, path::AbstractString, sep::AbstractString, inputs::Dict)
    
	data_directory_diesel = joinpath(path, setup["TimeDomainReductionFolder"])
	if setup["TimeDomainReduction"] == 1  && isfile(joinpath(data_directory_diesel,"LFSC_Diesel_Demand.csv")) # Use Time Domain Reduced data for GenX
		LFSC_Diesel_Demand_in = DataFrame(CSV.File(string(joinpath(data_directory_diesel,"LFSC_Diesel_Demand.csv")), header=true), copycols=true)
	else # Run without Time Domain Reduction OR Getting original input data for Time Domain Reduction
		LFSC_Diesel_Demand_in = DataFrame(CSV.File(string(path,sep,"LFSC_Diesel_Demand.csv"), header=true), copycols=true)
	end

    # Demand in tonnes per hour for each zone
	#println(names(load_in))
	start_diesel = findall(s -> s == "Load_mmbtu_z1", names(LFSC_Diesel_Demand_in))[1] #gets the start_dieseling column number of all the columns, with header "Load_H2_z1"
	
	# Demand in Tonnes per hour
	inputs["Liquid_Fuels_Diesel_D"] =Matrix(LFSC_Diesel_Demand_in[1:inputs["T"],start_diesel:start_diesel-1+inputs["Z"]]) #form a matrix with columns as the different zonal load H2 demand values and rows as the hours
    
    inputs["Global_conventional_diesel_price_per_mmbtu"] = LFSC_Diesel_Demand_in[!, "Global_conventional_diesel_price_per_mmbtu"][1]
	inputs["Conventional_diesel_co2_per_mmbtu"] = LFSC_Diesel_Demand_in[!, "Conventional_diesel_co2_per_mmbtu"][1]
    inputs["Syn_diesel_co2_per_mmbtu"] = LFSC_Diesel_Demand_in[!, "Syn_diesel_co2_per_mmbtu"][1]
	inputs["Bio_diesel_co2_per_mmbtu"] = LFSC_Diesel_Demand_in[!, "Bio_diesel_co2_per_mmbtu"][1]

	println(" -- LFSC_Diesel_Demand.csv Successfully Read!")

	###########################################################################################################################################

	data_directory_jetfuel = joinpath(path, setup["TimeDomainReductionFolder"])
	if setup["TimeDomainReduction"] == 1 && isfile(joinpath(data_directory_jetfuel,"LFSC_Jetfuel_Demand.csv")) # Use Time Domain Reduced data for GenX
		LFSC_Jetfuel_Demand_in = DataFrame(CSV.File(string(joinpath(data_directory_jetfuel,"LFSC_Jetfuel_Demand.csv")), header=true), copycols=true)
	else # Run without Time Domain Reduction OR Getting original input data for Time Domain Reduction
		LFSC_Jetfuel_Demand_in = DataFrame(CSV.File(string(path,sep,"LFSC_Jetfuel_Demand.csv"), header=true), copycols=true)
	end

	# Demand in tonnes per hour for each zone
	#println(names(load_in))
	start_jetfuel = findall(s -> s == "Load_mmbtu_z1", names(LFSC_Jetfuel_Demand_in))[1] #gets the start_jetfueling column number of all the columns, with header "Load_H2_z1"

	# Demand in Tonnes per hour
	inputs["Liquid_Fuels_Jetfuel_D"] =Matrix(LFSC_Jetfuel_Demand_in[1:inputs["T"],start_jetfuel:start_jetfuel-1+inputs["Z"]]) #form a matrix with columns as the different zonal load H2 demand values and rows as the hours
	
	inputs["Global_conventional_jetfuel_price_per_mmbtu"] = LFSC_Jetfuel_Demand_in[!, "Global_conventional_jetfuel_price_per_mmbtu"][1]
	inputs["Conventional_jetfuel_co2_per_mmbtu"] = LFSC_Jetfuel_Demand_in[!, "Conventional_jetfuel_co2_per_mmbtu"][1]
	inputs["Syn_jetfuel_co2_per_mmbtu"] = LFSC_Jetfuel_Demand_in[!, "Syn_jetfuel_co2_per_mmbtu"][1]
	inputs["Bio_jetfuel_co2_per_mmbtu"] = LFSC_Jetfuel_Demand_in[!, "Bio_jetfuel_co2_per_mmbtu"][1]

	println(" -- LFSC_Jetfuel_Demand.csv Successfully Read!")

	###########################################################################################################################################

	data_directory_gasoline = joinpath(path, setup["TimeDomainReductionFolder"])
	if setup["TimeDomainReduction"] == 1  && isfile(joinpath(data_directory_gasoline,"LFSC_Gasoline_Demand.csv")) # Use Time Domain Reduced data for GenX
		LFSC_Gasoline_Demand_in = DataFrame(CSV.File(string(joinpath(data_directory_gasoline,"LFSC_Gasoline_Demand.csv")), header=true), copycols=true)
	else # Run without Time Domain Reduction OR Getting original input data for Time Domain Reduction
		LFSC_Gasoline_Demand_in = DataFrame(CSV.File(string(path,sep,"LFSC_Gasoline_Demand.csv"), header=true), copycols=true)
	end

    # Demand in tonnes per hour for each zone
	#println(names(load_in))
	start_gasoline = findall(s -> s == "Load_mmbtu_z1", names(LFSC_Gasoline_Demand_in))[1] #gets the start_gasolineing column number of all the columns, with header "Load_H2_z1"
	
	# Demand in Tonnes per hour
	inputs["Liquid_Fuels_Gasoline_D"] = Matrix(LFSC_Gasoline_Demand_in[1:inputs["T"],start_gasoline:start_gasoline-1+inputs["Z"]]) #form a matrix with columns as the different zonal load H2 demand values and rows as the hours
    
    inputs["Global_conventional_gasoline_price_per_mmbtu"] = LFSC_Gasoline_Demand_in[!, "Global_conventional_gasoline_price_per_mmbtu"][1]
	inputs["Conventional_gasoline_co2_per_mmbtu"] = LFSC_Gasoline_Demand_in[!, "Conventional_gasoline_co2_per_mmbtu"][1]
    inputs["Syn_gasoline_co2_per_mmbtu"] = LFSC_Gasoline_Demand_in[!, "Syn_gasoline_co2_per_mmbtu"][1]
	inputs["Bio_gasoline_co2_per_mmbtu"] = LFSC_Gasoline_Demand_in[!, "Bio_gasoline_co2_per_mmbtu"][1]

	println(" -- LFSC_Gasoline_Demand.csv Successfully Read!")

    return inputs

end

