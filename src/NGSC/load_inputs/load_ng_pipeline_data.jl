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
    load_ng_pipeline_data(setup::Dict, path::AbstractString, sep::AbstractString, inputs_nw::Dict)

Function for reading input parameters related to the hydrogen transmission network via pipelines.
"""
function load_ng_pipeline_data(
    setup::Dict,
    path::AbstractString,
    sep::AbstractString,
    inputs_nw::Dict,
)

    Z = inputs_nw["Z"]

    # Network zones inputs and Network topology inputs
    pipeline_var = DataFrame(
        CSV.File(string(path, sep, "NGSC_Pipelines.csv"), header = true),
        copycols = true,
    )

    # Number of NG Pipelines = L
    inputs_nw["NG_P"] = size(collect(skipmissing(pipeline_var[!, :NG_Pipelines])), 1)
 
    # Find first column of pipe map table
    start = findall(s -> s == "z1", names(pipeline_var))[1]

    # Select pipe map L x N matrix  where L is number of pipelines and N is number of nodes
    pipe_map = pipeline_var[1:inputs_nw["NG_P"], start:start+inputs_nw["Z"]-1]

    # Create pipe number column
    pipe_map[!, :pipe_no] = 1:size(pipe_map, 1)
    # Pivot table
    pipe_map = stack(pipe_map, 1:inputs_nw["Z"])
    # Create zone column
    pipe_map[!, :Zone] = parse.(Float64, SubString.(pipe_map[!, :variable], 2))
    #Remove redundant rows
    pipe_map = pipe_map[pipe_map[!, :value].!=0, :]

    #Rename column
    colnames_pipe_map = ["pipe_no", "zone_str", "d", "Zone"]
    rename!(pipe_map, Symbol.(colnames_pipe_map))

    inputs_nw["NG_Pipe_Map"] = pipe_map


    # Number of pipelines routes in the network
    inputs_nw["NG_P"] = size(collect(skipmissing(pipeline_var[!, :NG_Pipelines])), 1)

    # Length in miles of each pipeline
    inputs_nw["pPipe_length_miles"] =
        convert(Array{Float64}, collect(skipmissing(pipeline_var[!, :Pipe_length_miles])))

    # Length between two booster compressor stations in miles
    inputs_nw["len_bw_comp_mile"] =
        convert(Array{Float64}, collect(skipmissing(pipeline_var[!, :len_bw_comp_mile])))

    # Number of booster compressors between source and sink
    # DEV NOTE: we should make the total number of compressors if the ratio is less than 1 for a particular line
    inputs_nw["no_booster_comp_stations"] =
        inputs_nw["pPipe_length_miles"] ./ inputs_nw["len_bw_comp_mile"]
    # floor.(inputs_nw["pPipe_length_miles"] ./ inputs_nw["len_bw_comp_mile"])
    #Maximum number of pipelines
    inputs_nw["pNG_Pipe_No_Max"] =
        convert(Array{Float64}, collect(skipmissing(pipeline_var[!, :Max_No_Pipe])))

    #Current number of pipelines
    inputs_nw["pNG_Pipe_No_Curr"] =
        convert(Array{Float64}, collect(skipmissing(pipeline_var[!, :Existing_No_Pipe])))

    #Maxiumum Pipe Flow per Pipe
    inputs_nw["pNG_Pipe_Max_Flow"] = convert(
        Array{Float64},
        collect(skipmissing(pipeline_var[!, :Max_Flow_MMBtu_p_Hr_Per_Pipe])),
    )

    #Maximum Pipeline storage capacity in MMBtu per pipe
    inputs_nw["pNG_Pipe_Max_Cap"] =
        convert(
            Array{Float64},
            collect(skipmissing(pipeline_var[!, :NGPipeCap_MMBtu_per_mile])),
        ) .* inputs_nw["pPipe_length_miles"]

    #Minimum Pipeline storage capacity in MMBtu per pipe
    inputs_nw["pNG_Pipe_Min_Cap"] =
        convert(
            Array{Float64},
            collect(skipmissing(pipeline_var[!, :Min_pipecap_stor_frac])),
        ) .* inputs_nw["pNG_Pipe_Max_Cap"]

    #Capital Cost Per Pipe
    inputs_nw["pCAPEX_NG_Pipe"] =
        convert(
            Array{Float64},
            collect(skipmissing(pipeline_var[!, :NGPipe_Inv_Cost_per_mile_yr])),
        ) .* inputs_nw["pPipe_length_miles"]

    #Capital cost associated with booster compressors per pipe= capex per MMBtu/hour flow rate x pipe max flow rate (MMBtu/hour) x number of booster compressor stations per pipe route
    inputs_nw["pCAPEX_Comp_NG_Pipe"] =
        inputs_nw["pNG_Pipe_Max_Flow"] .* (
            convert(
                Array{Float64},
                collect(skipmissing(pipeline_var[!, :NGPipeCompCapex])),
            ) .+
            inputs_nw["no_booster_comp_stations"] .* convert(
                Array{Float64},
                collect(skipmissing(pipeline_var[!, :BoosterCompCapex_per_MMBtu_p_hr_yr])),
            )
        )

    #Compression energy requirement Per Pipe  = MWh electricity per MMBtu of gas flow rate x number of compressor stations enroute a pipeline route
    inputs_nw["pComp_MWh_per_MMBtu_Pipe"] =
        convert(
            Array{Float64},
            collect(skipmissing(pipeline_var[!, :NGPipeCompEnergy]))
        ) .+ 
        inputs_nw["no_booster_comp_stations"] .* convert(
            Array{Float64},
            collect(skipmissing(pipeline_var[!, :BoosterCompEnergy_MWh_per_MMBtu])),
        )

    print_and_log(" -- NGSC_Pipelines.csv Successfully Read!")

    return inputs_nw
end