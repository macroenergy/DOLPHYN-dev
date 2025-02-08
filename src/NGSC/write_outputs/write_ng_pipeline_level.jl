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
    write_ng_pipeline_level(path::AbstractString, sep::AbstractString, inputs::Dict,setup::Dict, EP::Model)

Function for reporting ng storage level for each pipeline.
"""
function write_ng_pipeline_level(path::AbstractString, sep::AbstractString, inputs::Dict,setup::Dict, EP::Model)

    P = inputs["NG_P"]  # Number of NG pipelines
    T = inputs["T"]  # Model operating time steps

    p = zeros(P, T)
    dfNGPipelineLevel = DataFrame(Pipelines = 1:P)

    for i in 1:P
        p[i, :] = value.(EP[:vNGPipeLevel][i, :])
    end

    dfNGPipelineLevel = hcat(dfNGPipelineLevel, DataFrame(p, :auto))
    auxNew_Names=[Symbol("Pipelines");[Symbol("t$t") for t in 1:T]]
    rename!(dfNGPipelineLevel, auxNew_Names)
    CSV.write(joinpath(path, "NGSC_ng_pipeline_level.csv"), dftranspose(dfNGPipelineLevel, false), writeheader=false)
end