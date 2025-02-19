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
    write_ng_pipeline_expansion(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the expansion of ng pipelines.    
"""
function write_ng_pipeline_expansion(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

    L = inputs["NG_P"]     # Number of NG pipelines

    Existing_Trans_Cap = zeros(L)
    transcap = zeros(L) # Transmission network reinforcements in tonne/hour
    Pipes = zeros(L)
    Fixed_Cost = zeros(L)

    for i in 1:L
        Existing_Trans_Cap = inputs["pNG_Pipe_Max_Flow"].*inputs["pNG_Pipe_No_Curr"]
        transcap[i] = (value.(EP[:vNGNPipe][i]) - inputs["pNG_Pipe_No_Curr"][i]).*inputs["pNG_Pipe_Max_Flow"][i]
        Pipes[i] = value.(EP[:vNGNPipe][i])
        Fixed_Cost[i] = (value.(EP[:vNGNPipe][i]) - inputs["pNG_Pipe_No_Curr"][i]) * inputs["pCAPEX_NG_Pipe"][i]
    end
    
    dfTransCap = DataFrame(
    Line = 1:L,
    Existing_Trans_Capacity = convert(Array{Union{Missing,Float32}}, Existing_Trans_Cap),
    New_Trans_Capacity = convert(Array{Union{Missing,Float32}}, transcap),
    Total_Pipes = convert(Array{Union{Missing,Float32}}, Pipes),
    Fixed_Cost_Pipes = convert(Array{Union{Missing,Float32}}, Fixed_Cost),
    )
    
    CSV.write(joinpath(path, "NGSC_pipeline_expansion.csv"), dfTransCap)
end
