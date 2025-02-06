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
    write_h2_elec_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting electricity costs associated with hydrogen production, based on marginal electricity prices during time of generation. If GenX is configured as a mixed integer linear program, then this output is only generated if `WriteShadowPrices` flag is activated. If configured as a linear program (i.e. linearized unit commitment or economic dispatch) then output automatically available.
"""
function write_h2_elec_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

    ## Cost results
    dfH2Gen = inputs["dfH2Gen"]

    Z = inputs["Z"]     # Number of zones
    T = inputs["T"]     # Number of time steps (hours)

    # Recreate ELEC PRICE Dataframe (like in GenX, write_price function)
    # Dividing dual variable for each hour with corresponding hourly weight to retrieve marginal cost of generation

    dfPrice = DataFrame(transpose(dual.(EP[:cPowerBalance])./inputs["omega"]), :auto)

	dfP2G = DataFrame()
	dfElecCost = DataFrame()

    # Sum power usage for all generators in a given zone
    for z in 1:Z
        tempP2G = zeros(T)
        idx_set = dfH2Gen[dfH2Gen[!,:Zone].==z,:][!,:R_ID]
        if setup["ModelH2Liquid"] ==1
            for y in idx_set
                tempP2G = tempP2G .+ (y in union(inputs["H2_GEN"],inputs["H2_LIQ"],inputs["H2_EVAP"])  ? (value.(EP[:vP2G][y,:])) : zeros(T))
            end
        else
            for y in idx_set
                tempP2G = tempP2G .+ (y in inputs["H2_GEN"]  ? (value.(EP[:vP2G][y,:])) : zeros(T))
            end
        end
        tempP2G = DataFrame(transpose(tempP2G), :auto)
        append!(dfP2G, tempP2G)
    end

	# Multiply price by power usage, for each zone and each time step
	dfElecCost = dfP2G .* dfPrice .* inputs["omega"]'

    # Create Elec Cost Vector, per Zone
    ElecCostSum = zeros(Z)
    for i in 1:Z
        ElecCostSum[i] = sum(dfElecCost[i,1:T])
        #dfElecCostSum[!,:AnnualSum][i] = sum(dfElecCost[i,6:T+5])
    end

    cH2VarElec = sum(ElecCostSum)
    
    dfH2ElecCost = DataFrame()
    for z in 1:Z
        tempCVarElec = ElecCostSum[z]
        dfH2ElecCost[!,Symbol("Zone$z")] = [tempCVarElec]
    end

    CSV.write(joinpath(path, "HSC_elec_costs.csv"), dfH2ElecCost)
    
end
