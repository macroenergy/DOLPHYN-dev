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
	load_conventional_fuel_prices(setup::Dict, path::AbstractString, sep::AbstractString, inputs_bio_supply::Dict)

Function for reading input parameters related to conventional fuels regional prices.
"""
function load_conventional_fuel_prices(setup::Dict, path::AbstractString, sep::AbstractString, inputs::Dict)

	data_directory_gasoline = joinpath(path, setup["TimeDomainReductionFolder"])
	if setup["TimeDomainReduction"] == 1  && isfile(joinpath(data_directory_gasoline,"LFSC_Gasoline_Prices.csv")) # Use Time Domain Reduced data for MACRO
		Gasoline_Prices = DataFrame(CSV.File(string(joinpath(data_directory_gasoline,"LFSC_Gasoline_Prices.csv")), header=true), copycols=true)
	else # Run without Time Domain Reduction OR Getting original input data for Time Domain Reduction
		Gasoline_Prices = DataFrame(CSV.File(string(path,sep,"LFSC_Gasoline_Prices.csv"), header=true), copycols=true)
	end

	# Price in $ per MMBtu for each zone and each time period
	#println(names(load_in))
	start_gasoline = findall(s -> s == "Price_mmbtu_z1", names(Gasoline_Prices))[1] #gets the start column number of all the columns, with header "Price_mmbtu_z1"

	# Price in $ per MMBtu
	inputs["Gasoline_Price_Regional"] = Matrix(Gasoline_Prices[1:inputs["T"],start_gasoline:start_gasoline-1+inputs["Z"]]) #form a matrix with columns as the different zonal gasoline price values and rows as the hours

	global_gasoline = findall(s -> s == "Price_mmbtu_global", names(Gasoline_Prices))[1] #gets the start column number of all the columns, with header "Price_mmbtu_z1"
	inputs["Gasoline_Price_Global"] = Matrix(Gasoline_Prices[1:inputs["T"],global_gasoline:global_gasoline]) #form a matrix with columns as the different zonal gasoline price values and rows as the hours

	println(" -- Gasoline_Prices.csv Successfully Read!")

	#############################################################################

	data_directory_jetfuel = joinpath(path, setup["TimeDomainReductionFolder"])
	if setup["TimeDomainReduction"] == 1  && isfile(joinpath(data_directory_jetfuel,"LFSC_Jetfuel_Prices.csv")) # Use Time Domain Reduced data for MACRO
		Jetfuel_Prices = DataFrame(CSV.File(string(joinpath(data_directory_jetfuel,"LFSC_Jetfuel_Prices.csv")), header=true), copycols=true)
	else # Run without Time Domain Reduction OR Getting original input data for Time Domain Reduction
		Jetfuel_Prices = DataFrame(CSV.File(string(path,sep,"LFSC_Jetfuel_Prices.csv"), header=true), copycols=true)
	end
	
	# Price in $ per MMBtu for each zone and each time period
	#println(names(load_in))
	start_jetfuel = findall(s -> s == "Price_mmbtu_z1", names(Jetfuel_Prices))[1] #gets the start column number of all the columns, with header "Price_mmbtu_z1"
	
	# Price in $ per MMBtu
	inputs["Jetfuel_Price_Regional"] = Matrix(Jetfuel_Prices[1:inputs["T"],start_jetfuel:start_jetfuel-1+inputs["Z"]]) #form a matrix with columns as the different zonal jetfuel price values and rows as the hours
	
	global_jetfuel = findall(s -> s == "Price_mmbtu_global", names(Jetfuel_Prices))[1] #gets the start column number of all the columns, with header "Price_mmbtu_z1"
	inputs["Jetfuel_Price_Global"] = Matrix(Jetfuel_Prices[1:inputs["T"],global_jetfuel:global_jetfuel]) #form a matrix with columns as the different zonal jetfuel price values and rows as the hours
	
	println(" -- Jetfuel_Prices.csv Successfully Read!")
	

	#############################################################################

	data_directory_diesel = joinpath(path, setup["TimeDomainReductionFolder"])
	if setup["TimeDomainReduction"] == 1  && isfile(joinpath(data_directory_diesel,"LFSC_Diesel_Prices.csv")) # Use Time Domain Reduced data for MACRO
		Diesel_Prices = DataFrame(CSV.File(string(joinpath(data_directory_diesel,"LFSC_Diesel_Prices.csv")), header=true), copycols=true)
	else # Run without Time Domain Reduction OR Getting original input data for Time Domain Reduction
		Diesel_Prices = DataFrame(CSV.File(string(path,sep,"LFSC_Diesel_Prices.csv"), header=true), copycols=true)
	end
	
	# Price in $ per MMBtu for each zone and each time period
	#println(names(load_in))
	start_diesel = findall(s -> s == "Price_mmbtu_z1", names(Diesel_Prices))[1] #gets the start column number of all the columns, with header "Price_mmbtu_z1"
	
	# Price in $ per MMBtu
	inputs["Diesel_Price_Regional"] = Matrix(Diesel_Prices[1:inputs["T"],start_diesel:start_diesel-1+inputs["Z"]]) #form a matrix with columns as the different zonal diesel price values and rows as the hours
	
	global_diesel = findall(s -> s == "Price_mmbtu_global", names(Diesel_Prices))[1] #gets the start column number of all the columns, with header "Price_mmbtu_z1"
	inputs["Diesel_Price_Global"] = Matrix(Diesel_Prices[1:inputs["T"],global_diesel:global_diesel]) #form a matrix with columns as the different zonal diesel price values and rows as the hours
	
	println(" -- Diesel_Prices.csv Successfully Read!")
	

    return inputs

end

