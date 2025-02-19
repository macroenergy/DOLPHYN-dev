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
    write_h2_emissions(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting time-dependent CO$_2$ emissions by zone in hydrogen supply chain.
"""
function write_h2_emissions(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    dfH2Gen = inputs["dfH2Gen"]
    G = inputs["G"]     # Number of resources (generators, storage, DR, and DERs)
    T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Number of zones


    if ((setup["H2CO2Cap"] in [1,2,3]) && setup["SystemCO2Constraint"]==1)
        # Dual variable of CO2 constraint = shadow price of CO2
        tempCO2Price = zeros(Z,inputs["H2NCO2Cap"])
        if has_duals(EP) == 1
            for cap in 1:inputs["H2NCO2Cap"]
                for z in findall(x->x==1, inputs["dfH2CO2CapZones"][:,cap])
                    tempCO2Price[z,cap] = dual.(EP[:cH2CO2Emissions_systemwide])[cap]
                end
            end
        end
        dfEmissions = hcat(DataFrame(Zone = 1:Z), DataFrame(tempCO2Price, :auto), DataFrame(AnnualSum = Array{Union{Missing,Float32}}(undef, Z)))
        auxNew_Names=[Symbol("Zone"); [Symbol("CO2_Price_$cap") for cap in 1:inputs["H2NCO2Cap"]]; Symbol("AnnualSum")]
        rename!(dfEmissions,auxNew_Names)
    else
        dfEmissions = DataFrame(Zone = 1:Z, AnnualSum = Array{Union{Missing,Float32}}(undef, Z))
    end

    emissions = value.(EP[:eH2EmissionsByZone])

    dfEmissions.AnnualSum .= emissions * inputs["omega"]

    dfEmissions = hcat(dfEmissions, DataFrame(emissions, :auto))

    if ((setup["H2CO2Cap"] in [1,2,3]) && setup["SystemCO2Constraint"]==1)
        auxNew_Names=[Symbol("Zone");[Symbol("CO2_Price_$cap") for cap in 1:inputs["H2NCO2Cap"]];Symbol("AnnualSum");[Symbol("t$t") for t in 1:T]]
        rename!(dfEmissions,auxNew_Names)
        total = DataFrame(["Total" zeros(1,inputs["H2NCO2Cap"]) sum(dfEmissions[!,:AnnualSum]) fill(0.0, (1,T))], :auto)
        for t in 1:T
            if v"1.3" <= VERSION < v"1.4"
                total[!,t+inputs["H2NCO2Cap"]+2] .= sum(dfEmissions[!,Symbol("t$t")][1:Z])
            elseif v"1.4" <= VERSION < v"1.9"
                total[:,t+inputs["H2NCO2Cap"]+2] .= sum(dfEmissions[:,Symbol("t$t")][1:Z])
            end
        end
        rename!(total,auxNew_Names)
        dfEmissions = vcat(dfEmissions, total)
    else
        auxNew_Names=[Symbol("Zone"); Symbol("AnnualSum"); [Symbol("t$t") for t in 1:T]]
        rename!(dfEmissions,auxNew_Names)
        total = DataFrame(["Total" sum(dfEmissions[!,:AnnualSum]) fill(0.0, (1,T))], :auto)
        for t in 1:T
            if v"1.3" <= VERSION < v"1.4"
                total[!,t+2] .= sum(dfEmissions[!,Symbol("t$t")][1:Z])
            elseif v"1.4" <= VERSION < v"1.9"
                total[:,t+2] .= sum(dfEmissions[:,Symbol("t$t")][1:Z])
            end
        end
        rename!(total,auxNew_Names)
        dfEmissions = vcat(dfEmissions, total)
    end

    CSV.write(joinpath(path, "HSC_emissions.csv"), dftranspose(dfEmissions, false), writeheader=false)
end
