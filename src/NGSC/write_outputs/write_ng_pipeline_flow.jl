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
    write_ng_pipeline_flow(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the ng flow via pipeliens.    
"""
function write_ng_pipeline_flow(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    T = inputs["T"]     # Number of time steps (hours)
    NG_P= inputs["NG_P"] # Number of Hydrogen Pipelines
    NG_Pipe_Map = inputs["NG_Pipe_Map"]

    ## Power balance for each zone
    dfPowerBalance = Array{Any}
    rowoffset=3
    for p in 1:NG_P
        dfTemp1 = Array{Any}(nothing, T+rowoffset, 3)
        dfTemp1[1,1:size(dfTemp1,2)] = ["Source_Zone_NG_Net", "Sink_Zone_NG_Net", "Pipe_Level"]

        dfTemp1[2,1:size(dfTemp1,2)] = repeat([p],size(dfTemp1,2))
        
        zone_value1 = filter.(isdigit, ([NG_Pipe_Map[(NG_Pipe_Map[!,:d] .== 1) .& (NG_Pipe_Map[!,:pipe_no] .== p), :][!,:zone_str][1]][1]))
        zone_value2 = filter.(isdigit, ([NG_Pipe_Map[(NG_Pipe_Map[!,:d] .== -1) .& (NG_Pipe_Map[!,:pipe_no] .== p), :][!,:zone_str][1]][1])) 
        dfTemp1[3,1:size(dfTemp1,2)] = [zone_value1,zone_value2,"NA"]

        for t in 1:T
            dfTemp1[t+rowoffset,1]= value.(EP[:eNGPipeFlow_net][p,t,1])
            dfTemp1[t+rowoffset,2] = value.(EP[:eNGPipeFlow_net][p,t,-1])
            dfTemp1[t+rowoffset,3] = value.(EP[:vNGPipeLevel][p,t])
        end

        if p==1
            dfPowerBalance =  hcat(vcat(["", "Pipe", "Zone"], ["t$t" for t in 1:T]), dfTemp1)
        else
            dfPowerBalance = hcat(dfPowerBalance, dfTemp1)
        end
    end

    dfPowerBalance = DataFrame(dfPowerBalance, :auto)
    CSV.write(joinpath(path, "NGSC_ng_pipeline_flow.csv"), dfPowerBalance, writeheader=false)
end
