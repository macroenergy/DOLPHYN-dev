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
    load_co2_cap_hsc(setup::Dict, path::AbstractString, sep::AbstractString, inputs_co2_hsc::Dict)

Function for reading input parameters related to CO$_2$ emissions cap constraints in hydrogen supply chain only.
"""
function load_co2_cap_hsc(setup::Dict, path::AbstractString, sep::AbstractString, inputs_co2_hsc::Dict)

    # Definition of Cap requirements by zone (as Max Mtonnes)
    dfH2CO2Cap = DataFrame(
        CSV.File(joinpath(path, "HSC_CO2_cap.csv"), header = true),
        copycols = true,
    )

    inputs_co2_hsc["dfH2CO2Cap"] = dfH2CO2Cap

    cap = count(
        s -> startswith(String(s), "CO_2_Cap_Zone"),
        names(inputs_co2_hsc["dfH2CO2Cap"]),
    )
    first_col = findall(s -> s == "CO_2_Cap_Zone_1", names(inputs_co2_hsc["dfH2CO2Cap"]))[1]
    last_col =
        findall(s -> s == "CO_2_Cap_Zone_$cap", names(inputs_co2_hsc["dfH2CO2Cap"]))[1]

    inputs_co2_hsc["dfH2CO2CapZones"] =
        Matrix{Float64}(inputs_co2_hsc["dfH2CO2Cap"][:, first_col:last_col])
    inputs_co2_hsc["H2NCO2Cap"] = cap # Number of CO2 emissions constraints

    # Emission limits
    if setup["H2CO2Cap"] == 1
        #  CO2 emissions cap in mass
        first_col = findall(s -> s == "CO_2_Max_Mtons_1", names(inputs_co2_hsc["dfH2CO2Cap"]))[1]
        last_col = findall(s -> s == "CO_2_Max_Mtons_$cap", names(inputs_co2_hsc["dfH2CO2Cap"]))[1]
        # note the default inputs is in million tonnes

        inputs_co2_hsc["dfH2MaxCO2"] =
            Matrix{Float64}(inputs_co2_hsc["dfH2CO2Cap"][:, first_col:last_col]) * (1e6)
        # when not scaled, the constraint unit is tonne


    elseif (setup["H2CO2Cap"] == 2 || setup["H2CO2Cap"] == 3)
        #  CO2 emissions rate applied per MWh
        first_col = findall(s -> s == "CO_2_Max_tons_p_MWh_1", names(inputs_co2_hsc["dfH2CO2Cap"]))[1]
        last_col = findall(s -> s == "CO_2_Max_tons_p_MWh_$cap", names(inputs_co2_hsc["dfH2CO2Cap"]))[1]

        inputs_co2_hsc["dfH2MaxCO2Rate"] = Matrix{Float64}(inputs_co2_hsc["dfH2CO2Cap"][:, first_col:last_col])
        # when not scaled, the constraint unit is tonne/MWh


    elseif setup["H2CO2Cap"] == 4 # Carbon emissions penalized via a carbon price on total emissions
        #  CO2 emissions cap in mass
        first_col = findall(s -> s == "CO_2_Price_1", names(inputs_co2_hsc["dfH2CO2Cap"]))[1]
        last_col = findall(s -> s == "CO_2_Price_$cap", names(inputs_co2_hsc["dfH2CO2Cap"]))[1]
        # note the default inputs is in million tonnes

        inputs_co2_hsc["dfH2CO2Price"] = Matrix{Float64}(inputs_co2_hsc["dfH2CO2Cap"][:, first_col:last_col])
        # when not scaled, the price unit is million$/tonne
    end
    print_and_log(" -- HSC_CO2_cap.csv Successfully Read!")
    return inputs_co2_hsc
end
