using Dolphyn

# This script is currently setup to use Gurobi if possible. 
# Force the code to use HiGHS using the flag below if you prefer

force_highs = false
gurobi_installed = Dolphyn.check_if_solver_installed("Gurobi")
use_TDR = true
force_TDR_recluster = true

highs_cases = [
    joinpath(@__DIR__, "SmallNewEngland", "OneZone"),
    joinpath(@__DIR__, "SmallNewEngland", "ThreeZones"),
    joinpath(@__DIR__, "SmallNewEngland", "ThreeZones_Liquid"),
    joinpath(@__DIR__, "Eastern_US_CSC", "ThreeZones"),
    joinpath(@__DIR__, "ERCOT_1stg_hourly_5GW_base_tmr"),
    joinpath(@__DIR__, "NorthSea_2030"),
    joinpath(@__DIR__, "NorthSea_2040_SF_Examples"),
]

gurobi_cases = [
    joinpath(@__DIR__, "SmallNewEngland", "ThreeZones_Gurobi"),
]

summary = []

if use_TDR
    println("Time Domain Reduction is enabled")
    force_TDR_on = true
    force_TDR_off = false
else
    println("Time Domain Reduction is disabled")
    force_TDR_on = false
    force_TDR_off = true
end

if force_TDR_recluster
    println("Forcing TDR recluster")
end

for case in highs_cases
    case_name = Dolphyn.get_case_name(case, "Example_Systems")

    println(" ------ ------ ------")
    println("Generating model for $case_name ...")
    try
        generate_model(case; force_TDR_on=force_TDR_on, force_TDR_off=force_TDR_off, force_TDR_recluster=force_TDR_recluster)
        push!(summary, "🟢 $(case_name)")
        println("Generated model for $case.")
    catch Exception
        @debug("Exception: $(Exception)")
        println("Failed to generate model for $case")
        push!(summary, "🔴 $(case_name)")
    end
    
end

if gurobi_installed
    using Gurobi
    
    for case in gurobi_cases
        case_name = Dolphyn.get_case_name(case, "Example_Systems")

        println(" ------ ------ ------")
        println("Generating model for $case_name ...")
        try
            generate_model(case; optimizer=Gurobi.Optimizer, force_TDR_on=force_TDR_on, force_TDR_off=force_TDR_off, force_TDR_recluster=force_TDR_recluster)
            push!(summary, "🟢 $(case_name)")
            println("Generated model for $case.")
        catch Exception
            @debug("Exception: $(Exception)")
            println("Failed to generate model for $case")
            push!(summary, "🔴 $(case_name)")
        end
    end
else 
    println(" ------ ------ ------")
    println("Gurobi is not installed. Skipping those cases")
end

println(" ------ ------ ------")
println("Summary of which cases were generated successfully:")
for s in summary
    println(s)
end
println(" ------ ------ ------")