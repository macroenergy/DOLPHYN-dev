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
	load_syn_fuels_resources(setup::Dict, path::AbstractString, sep::AbstractString, inputs::Dict)

Function for reading input parameters related to synthetic fuels resources.
"""
function load_syn_fuels_resources(setup::Dict, path::AbstractString, sep::AbstractString, inputs::Dict)

	#Read in syn fuel related inputs
    syn_fuels_in = DataFrame(CSV.File(string(path,sep,"LFSC_Synfuel_Resources.csv"), header=true), copycols=true)

    # Add Resource IDs after reading to prevent user errors
	syn_fuels_in[!,:R_ID] = 1:size(collect(skipmissing(syn_fuels_in[!,1])),1)

    # Store DataFrame of generators/resources input data for use in model
	inputs["dfSynFuels"] = syn_fuels_in

    # Index of Syn Fuel resources - can be either commit, no_commit 
	inputs["SYN_FUELS_RES_ALL"] = size(collect(skipmissing(syn_fuels_in[!,:R_ID])),1)

    ###Number of by-products
	Nby_prod_excess = count(s -> startswith(String(s), "mmbtu_p_tonne_co2"), names(inputs["dfSynFuels"]))

	#Columns identifying qty of byproduct output
	first_col = findall(s -> s == "mmbtu_p_tonne_co2_p1", names(inputs["dfSynFuels"]))[1]
	last_col = findall(s -> s == "mmbtu_p_tonne_co2_p$Nby_prod_excess", names(inputs["dfSynFuels"]))[1]

	#Saving byproduct dataframe
	inputs["dfSynFuelsByProdExcess"] = Matrix{Float64}(inputs["dfSynFuels"][:,first_col:last_col])
	#Saving number of byproducts
	inputs["NSFByProd"] = Nby_prod_excess

	#Columns identifying price of byproduct output
    Nby_prod_price = count(s -> startswith(String(s), "price_p_mmbtu"), names(inputs["dfSynFuels"]))
	first_col = findall(s -> s == "price_p_mmbtu_p1", names(inputs["dfSynFuels"]))[1]
	last_col = findall(s -> s == "price_p_mmbtu_p$Nby_prod_price", names(inputs["dfSynFuels"]))[1]

	#Saving byproduct price
	inputs["dfSynFuelsByProdPrice"] = Matrix{Float64}(inputs["dfSynFuels"][:,first_col:last_col])

	#Return error if number of byproducts does not match
    if Nby_prod_excess != Nby_prod_price
        error("Syn Fuel no. of cols for syn fuel byprod diff for price and excess")
    end

	#Columns identifying price of byproduct output
    Nby_prod_emissions = count(s -> startswith(String(s), "co2_out_p_mmbtu"), names(inputs["dfSynFuels"]))
	first_col = findall(s -> s == "co2_out_p_mmbtu_p1", names(inputs["dfSynFuels"]))[1]
	last_col = findall(s -> s == "co2_out_p_mmbtu_p$Nby_prod_emissions", names(inputs["dfSynFuels"]))[1]

	#Saving byproduct price
	inputs["dfSynFuelsByProdEmissions"] = Matrix{Float64}(inputs["dfSynFuels"][:,first_col:last_col])

	#Return error if number of byproducts does not match
    if Nby_prod_emissions != Nby_prod_excess
        error("Syn Fuel no. of cols for syn fuel byprod diff for emission and excess")
    end

	# Name of Synfuel resources resources
	inputs["SYN_FUELS_RESOURCES_NAME"] = collect(skipmissing(syn_fuels_in[!,:Syn_Fuel_Resource][1:inputs["SYN_FUELS_RES_ALL"]]))
	
	# Resource identifiers by zone (just zones in resource order + resource and zone concatenated)
	syn_fuel_zones = collect(skipmissing(syn_fuels_in[!,:Zone][1:inputs["SYN_FUELS_RES_ALL"]]))
	inputs["Syn_Fuel_R_Zones"] = syn_fuel_zones
	inputs["Syn_fuel_Resource_ZONES"] = inputs["SYN_FUELS_RESOURCES_NAME"] .* "_z" .* string.(syn_fuel_zones)

	println(" -- LFSC_Synfuel_Resources.csv Successfully Read!")

    return inputs

end
