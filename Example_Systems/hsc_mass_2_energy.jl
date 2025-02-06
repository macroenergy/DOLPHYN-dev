using DataFrames
using CSV

# This is set up to work with the current Dolphyn example systems 
# and the higher heating value (HVV) of hydrogen

const HHV_H2 = 39.39 # MWh/tonne

round_values = true
significant_figures = 6
headers_to_round = [
    "Voll",
    "etaP2G",
    "etaG2P"
]

cases = [
    joinpath(@__DIR__,"Eastern_US","ThreeZones_NGSC_Original"),
]

hsc_gen_changes = Dict(
    "etaP2G_MWh_p_tonne" => ("etaP2G", 1/HHV_H2),
    "etaFuel_MMBtu_p_tonne" => ("etaFuel_MMBtu_p_MWh", 1/HHV_H2),
    "Inv_Cost_p_tonne_p_hr_yr" => ("Inv_Cost_p_MW_yr", 1/HHV_H2),
    "Inv_Cost_Charge_p_tonne_p_hr_yr" => ("Inv_Cost_Charge_p_MW_yr", 1/HHV_H2),
    "Inv_Cost_Energy_p_tonne_yr" => ("Inv_Cost_Energy_p_MWh_yr", 1/HHV_H2),
    "Fixed_OM_Cost_p_tonne_p_hr_yr" => ("Fixed_OM_Cost_p_MW_yr", 1/HHV_H2),
    "Fixed_OM_Cost_Charge_p_tonne_p_hr_yr" => ("Fixed_OM_Cost_Charge_p_MW_yr", 1/HHV_H2),
    "Fixed_OM_Cost_Energy_p_tonne_yr" => ("Fixed_OM_Cost_Energy_p_MWh_yr", 1/HHV_H2),
    "Var_OM_Cost_p_tonne" => ("Var_OM_Cost_p_MWh", 1/HHV_H2),
    "Var_OM_Cost_Charge_p_tonne" => ("Var_OM_Cost_Charge_p_MWh", 1/HHV_H2),
    "Max_Cap_tonne_p_hr" => ("Max_Cap_MW", HHV_H2),
    "Min_Cap_tonne_p_hr" => ("Min_Cap_MW", HHV_H2),
    "Max_Charge_Cap_tonne_p_hr" => ("Max_Charge_Cap_MW", HHV_H2),
    "Min_Charge_Cap_tonne_p_hr" => ("Min_Charge_Cap_MW", HHV_H2),
    "Max_Energy_Cap_tonne" => ("Max_Energy_Cap_MWh", HHV_H2),
    "Min_Energy_Cap_tonne" => ("Min_Energy_Cap_MWh", HHV_H2),
    "Existing_Cap_tonne_p_hr" => ("Existing_Cap_MW", HHV_H2),
    "Existing_Charge_Cap_tonne_p_hr" => ("Existing_Charge_Cap_MW", HHV_H2),
    "Existing_Energy_Cap_tonne" => ("Existing_Energy_Cap_MWh", HHV_H2),
    "Cap_Size_tonne_p_hr" => ("Cap_Size_MW", HHV_H2),
    "H2Stor_Charge_MWh_p_tonne" => ("H2Stor_Charge_MWh_p_MWh", 1/HHV_H2),
    "H2Stor_Charge_MMBtu_p_tonne" => ("H2Stor_Charge_MMBtu_p_MWh", 1/HHV_H2),
    "Start_Cost_per_tonne_p_hr" => ("Start_Cost_p_MW", 1/HHV_H2)
)

hsc_load_changes = Dict(
    "Cost_of_Demand_Curtailment_per_Tonne" => ("Segment_Cost_of_Demand_Curtailment_Fraction", 1),
    "Load_H2_tonne_per_hr_z" => ("Load_H2_MW_z", HHV_H2),
    "Voll" => ("Voll", 1/HHV_H2),
)

hsc_liquid_load_changes = Dict(
    "Cost_of_Demand_Curtailment_per_Tonne" => ("Segment_Cost_of_Demand_Curtailment_Fraction", 1),
    "Load_liqH2_tonne_per_hr_z" => ("Load_liqH2_MW_z", HHV_H2),
    "Voll" => ("Voll", 1/HHV_H2),
)

hsc_pipelines_changes = Dict(
    "Max_Flow_Tonne_p_Hr_Per_Pipe" => ("Max_Flow_MW_p_pipe", HHV_H2),
    "H2PipeCap_tonne_per_mile" => ("H2PipeCap_MWh_p_mile", HHV_H2),
    "BoosterCompCapex_per_tonne_p_hr_yr" => ("BoosterCompCapex_p_MW_yr", 1/HHV_H2),
    "BoosterCompEnergy_MWh_per_tonne" => ("BoosterCompEnergy_MWh_p_MWh", 1/HHV_H2),
    "H2PipeCompEnergy" => ("H2PipeCompEnergy_MWh_p_MWh", 1/HHV_H2),
    "H2PipeCompCapex" => ("H2PipeCompCapex", 1/HHV_H2),
)

hsc_trucks_changes = Dict(
    "Existing_Energy_Cap_tonne_z" => ("Existing_ChargePower_Cap_MW_z", HHV_H2),
    "TruckCap_tonne_per_unit" => ("TruckCap_MWh_per_unit", HHV_H2),
    "Inv_Cost_Energy_p_tonne_yr" => ("Inv_Cost_ChargePower_p_MW_yr", 1/HHV_H2),
    "Fixed_OM_Cost_Energy_p_tonne_yr" => ("Fixed_OM_Cost_ChargePower_p_MW_yr", 1/HHV_H2),
    "Max_Energy_Cap_tonne" => ("Max_Energy_Cap_MW", HHV_H2),
    "Min_Energy_Cap_tonne" => ("Min_Energy_Cap_MW", HHV_H2),
    "H2_tonne_per_mile" => ("H2_MWh_per_mile", HHV_H2),
    "H2TruckCompressionEnergy" => ("H2TruckCompressionEnergy", 1/HHV_H2),
    "H2TruckCompressionUnitOpex" => ("H2TruckCompressionUnitOpex", 1/HHV_H2),
)

hsc_g2p_changes = Dict(
    "etaG2P_MWh_p_tonne" => ("etaG2P", 1/HHV_H2),
)

hsc_co2_changes = Dict(
    "CO_2_Max_tons_ton_" => ("CO_2_Max_tons_p_MWh_", 1/HHV_H2),
)

synfuels_changes = Dict(
    "tonnes_h2_p_tonne_co2" => ("mwh_h2_p_tonne_co2", HHV_H2),
)

mass_2_energy_changes = Dict(
    "HSC_trucks.csv" => hsc_trucks_changes,
    "HSC_pipelines.csv" => hsc_pipelines_changes,
    "HSC_load_data.csv" => hsc_load_changes,
    "HSC_load_data_liquid.csv" => hsc_liquid_load_changes,
    "HSC_generation.csv" => hsc_gen_changes,
    "HSC_g2p.csv" => hsc_g2p_changes,
    "HSC_CO2_cap.csv" => hsc_co2_changes,
    "LFSC_Synfuel_Resources.csv" => synfuels_changes,
)

function update_file(case, file, mass_2_energy_changes)
    # If the file is not in the changes dictionary, skip it
    if file ∉ keys(mass_2_energy_changes)
        return nothing
    else
        changes_2_make = mass_2_energy_changes[file]
    end

    println(" -- Working on file: $file")

    # Load the file as a DataFrame
    df = DataFrame(CSV.File(joinpath(case, file), header=true), copycols=true)
    
    # Go through the column names in changes_2_make
    # If the column name starts with the old_col string,
    # Replace the first part of the column name with the new_col string
    # Multiply the column by the second element of the tuple
    for (old_col, (new_col, factor)) in changes_2_make
        N = length(old_col) + 1
        for col in names(df)
            if startswith(col, old_col)
                new_name = new_col * col[N:end]
                println("   -- Changing column: $col to $new_name")
                df[!,col] = df[!,col] .* factor
                rename!(df, col => new_name)

                # It's easier to do some after-the-fact clean-up
                # Find all entries in df[!,new_name] with the value -factor and set them to -1.0
                for idx in skipmissing(eachindex(df[!,new_name]))
                    if ismissing(df[idx,new_name])
                        continue
                    elseif df[idx,new_name] ≈ -factor
                        df[idx,new_name] = -1.0
                    elseif (startswith(col, "Cap_Size")) & (df[idx,new_name] ≈ factor)
                        df[idx,new_name] = 1.0
                    elseif (col in headers_to_round) & round_values
                        df[idx,new_name] = round(df[idx,new_name], significant_figures)
                    end
                end
            end
        end
    end

    # Save the DataFrame back to the file
    CSV.write(joinpath(case,file), df)
    return nothing
end

for case in cases
    println("Working on case: $case")

    case_files = readdir(case)
    case_files = filter(x -> endswith(x, ".csv"), case_files)

    for file in case_files
        update_file(case, file, mass_2_energy_changes)
    end

    tdr_name = "TDR_results"
    tdr_path = joinpath(case, tdr_name)
    if isdir(tdr_path)
        tdr_files = readdir(tdr_path)
        tdr_files = filter(x -> endswith(x, ".csv"), tdr_files)
        # tdr_files = [joinpath(tdr_name, x) for x in tdr_files]
        for file in tdr_files
            update_file(joinpath(case, tdr_name), file, mass_2_energy_changes)
        end
    end 
end