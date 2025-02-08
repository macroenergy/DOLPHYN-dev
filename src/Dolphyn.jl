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

module Dolphyn

export compare_results
export print_and_log
export configure_settings
export load_settings
export load_all_inputs
export setup_logging
export setup_TDR
export configure_solver
export load_inputs
export load_h2_inputs
export load_co2_inputs
export load_liquid_fuels_inputs
export load_bio_inputs
export load_ng_inputs
export generate_model
export solve_model
export run_case
export write_all_outputs
export write_outputs
export write_HSC_outputs
export write_CSC_outputs
export write_liquid_fuels_outputs
export write_bio_outputs
export write_ng_outputs
export cluster_inputs
export mga
export h2_inherit_clusters

using JuMP # used for mathematical programming
using DataFrames #This package allows put together data into a matrix
using CSV
using StatsBase
using LinearAlgebra
using YAML
using Dates
using Clustering
using Distances
using Combinatorics
using Revise
using Glob
using LoggingExtras

using Random
using RecursiveArrayTools
using Statistics

# HiGHS is the default solver, but there is an option to employ other optimizers
using HiGHS

# Global scaling factor used when ParameterScale is on to shift values from MW to GW
# DO NOT CHANGE THIS (Unless you do so very carefully)
# To translate MW to GW, divide by ModelScalingFactor
# To translate $ to $M, multiply by ModelScalingFactor^2
# To translate $/MWh to $M/GWh, multiply by ModelScalingFactor
const ModelScalingFactor = 1e+3

# MMBtu to MWh conversion for bioenergy to electricity
const MMBtu_to_MWh = 0.293071 # MWh per MMBtu

# Logging flag
Log = true

function find_all_to_include(dir::String, file_type::String=".jl", recursive::Bool=false)::Vector{String}
    if recursive
        result = String[]
        for (root, dirs, files) in walkdir(dir)
            append!(result, filter!(f -> occursin(file_type, f), joinpath.(root, files)))
        end
        return result
    else
        search_string = "*$(file_type)"
        return glob(search_string, dir)
    end
end

function include_from_dir(dir::String, file_type::String=".jl", exclusions::Vector{String}=String[])::Nothing
    files = find_all_to_include(dir, file_type, true)
    files_to_exclude = String[]
    for exclusion in exclusions
        if isdir(exclusion)
            # If it's a directory, remove all files in that directory
            push!(files_to_exclude, find_all_to_include(exclusion, ".jl", true)...)
        else
            # Otherwise, just remove the file
            push!(files_to_exclude, exclusion)
        end
    end
    if length(files_to_exclude) > 0
        println(" --- The following files are not being included from $dir: --- ")
        for file in files_to_exclude
            println("Excluding $file")
        end
        println(" --- End of excluded files --- ")
    end
    # Filter out all the files we want to exclude
    filter!(x -> !(x in files_to_exclude), files)
    # Include the remaining files
    for file in files
        include(file)
    end
end

# We can't easily run GenX.jl because that creates a module
# which doesn't export all the functions we need.
# Instead, we'll include all the GenX functions and then overwrite them
genxsubmod_path = joinpath(@__DIR__,"GenX","src")
genx_to_exclude = [
    joinpath(genxsubmod_path,"GenX.jl"),
    joinpath(genxsubmod_path,"simple_operation.jl"),
    joinpath(genxsubmod_path,"time_domain_reduction","time_domain_reduction.jl"),
    joinpath(genxsubmod_path,"model","solve_model.jl"),
    joinpath(genxsubmod_path,"model","generate_model.jl"),
    joinpath(genxsubmod_path,"configure_solver"),
    joinpath(genxsubmod_path,"write_outputs","write_capacity.jl"),
    joinpath(genxsubmod_path,"write_outputs","write_capacityfactor.jl"),
    joinpath(genxsubmod_path,"write_outputs","write_charging_cost.jl"),
    joinpath(genxsubmod_path,"write_outputs","write_energy_revenue.jl"),
    joinpath(genxsubmod_path,"write_outputs","write_net_revenue.jl"),
    joinpath(genxsubmod_path,"write_outputs","write_nw_expansion.jl"),
    joinpath(genxsubmod_path,"write_outputs","write_outputs.jl"),
    joinpath(genxsubmod_path,"write_outputs","write_price.jl"),
    joinpath(genxsubmod_path,"write_outputs","write_reliability.jl"),
    joinpath(genxsubmod_path,"write_outputs","write_storage.jl"),
    joinpath(genxsubmod_path,"write_outputs","write_storagedual.jl"),
    joinpath(genxsubmod_path,"write_outputs","write_subsidy_revenue.jl"),
    joinpath(genxsubmod_path,"model","core","emissions.jl"),
    joinpath(genxsubmod_path,"model","policies","co2_cap.jl"),
    joinpath(genxsubmod_path,"model","policies","cap_reserve_margin.jl"),
    joinpath(genxsubmod_path,"model","resources","thermal","thermal_commit.jl"),
    # joinpath(genxsubmod_path,"configure_settings") # DOLPHYN and GenX are using different approaches, so we need both
]
include_from_dir(genxsubmod_path, ".jl", genx_to_exclude)

# Load time domain reduction related scripts
tdr_path = joinpath(@__DIR__,"time_domain_reduction")
include_from_dir(tdr_path, ".jl", [joinpath(tdr_path,"PreCluster.jl")])

# Extensions to GenX
include_from_dir(joinpath(@__DIR__,"GenX_extensions"), ".jl")

# Load all .jl files from the HSC directory
include_from_dir(joinpath(@__DIR__,"HSC"), ".jl")

# Load all .jl files from the LFSC directory
include_from_dir(joinpath(@__DIR__,"LFSC"), ".jl")

# Load all .jl files from the BESC directory
include_from_dir(joinpath(@__DIR__,"BESC"), ".jl")

# Load all .jl files from the NGSC directory
include_from_dir(joinpath(@__DIR__,"NGSC"), ".jl")

# Load all .jl files from the core directory
include_from_dir(joinpath(@__DIR__,"core"), ".jl")

# Configure settings
include_from_dir(joinpath(@__DIR__,"configure_settings"), ".jl")

# Configure optimizer instance
include_from_dir(joinpath(@__DIR__,"configure_solver"), ".jl")

# Files which involve multiple sectors
include_from_dir(joinpath(@__DIR__,"multisector"), ".jl")

# Files which involve multiple sectors
include_from_dir(joinpath(@__DIR__,"CSC"), ".jl")

# Load model generation and solving scripts
include(joinpath(@__DIR__,"generate_model.jl"))
include(joinpath(@__DIR__, "solve_model.jl"))

end
