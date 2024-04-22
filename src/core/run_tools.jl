

# Methods to simplify the process of running DOLPHYN cases

"""
    load_settings(settings_path::AbstractString) :: Dict{Any, Any}

Loads Global, GenX and HSC settings and returns a merged settings dict called mysetup
"""
function load_settings(settings_path::AbstractString)
    genx_settings_path = joinpath(settings_path, "genx_settings.yml") #Settings YAML file path for GenX
    mysetup_genx = configure_settings(genx_settings_path) # mysetup dictionary stores GenX-specific parameters

    hsc_settings_path = joinpath(settings_path, "hsc_settings.yml") #Settings YAML file path for HSC  model
    if isfile(hsc_settings_path)
        mysetup_hsc = YAML.load(open(hsc_settings_path)) # mysetup dictionary stores H2 supply chain-specific parameters
    else
        mysetup_hsc = Dict()
    end

    csc_settings_path = joinpath(settings_path, "csc_settings.yml") #Settings YAML file path for CSC model
    if isfile(csc_settings_path)
        mysetup_csc = YAML.load(open(csc_settings_path)) # mysetup dictionary stores CSC supply chain-specific parameters
    else
        mysetup_csc = Dict()
    end 

    lf_settings_path = joinpath(settings_path, "lf_settings.yml") #Settings YAML file path for LF model
    if isfile(lf_settings_path)
        mysetup_lf = YAML.load(open(lf_settings_path)) # mysetup dictionary stores CSC supply chain-specific parameters
    else
        mysetup_lf = Dict()
    end 

    global_settings_path = joinpath(settings_path, "global_model_settings.yml") # Global settings for inte
    mysetup_global = YAML.load(open(global_settings_path)) # mysetup dictionary stores global settings

    mysetup = Dict{Any,Any}()
    mysetup = merge(mysetup_hsc, mysetup_genx, mysetup_csc, mysetup_lf, mysetup_global) #Merge dictionary - value of common keys will be overwritten by value in global_model_settings
    mysetup = configure_settings(mysetup)

    ModelScalingFactor = 1e+3
    mysetup["ParameterScale"]==1 ? mysetup["scaling"] = ModelScalingFactor : mysetup["scaling"] = 1.0

    return mysetup
end

function setup_logging(mysetup::Dict{Any, Any})
    # Start logging
    global Log = mysetup["Log"]
    if Log
        logger = FileLogger(mysetup["LogFile"])
        return global_logger(logger)
    end
    return nothing
end

function setup_TDR(inputs_path::String, settings_path::String, mysetup::Dict{Any,Any})
    TDRpath = joinpath(inputs_path, mysetup["TimeDomainReductionFolder"])
    if mysetup["TimeDomainReduction"] == 1
        if mysetup["ModelH2"] == 1
            if (!isfile(TDRpath*"/Load_data.csv")) || (!isfile(TDRpath*"/Generators_variability.csv")) || (!isfile(TDRpath*"/Fuels_data.csv")) || (!isfile(TDRpath*"/HSC_generators_variability.csv")) || (!isfile(TDRpath*"/HSC_load_data.csv"))
                print_and_log("Clustering Time Series Data...")
                cluster_inputs(inputs_path, settings_path, mysetup)
            else
                print_and_log("Time Series Data Already Clustered.")
            end
        else
            if (!isfile(TDRpath*"/Load_data.csv")) || (!isfile(TDRpath*"/Generators_variability.csv")) || (!isfile(TDRpath*"/Fuels_data.csv"))
                print_and_log("Clustering Time Series Data...")
                cluster_inputs(inputs_path, settings_path, mysetup)
            else
                print_and_log("Time Series Data Already Clustered.")
            end
        end
    end

    if mysetup["ModelCSC"] == 1
        print_and_log("CSC and SF TDR not implemented.")
    end
end

function run_single_case()
    return nothing
end

function benchmark_single_case(inputs_path::String, settings_path::String, return_results::Bool=false)
    # Load settings
    mysetup = load_settings(settings_path)

    # Setup logging 
    global_logger = setup_logging(mysetup)

    # Setup time domain reduction and cluster inputs if necessary
    setup_TDR(inputs_path, settings_path, mysetup)

    ### Configure solver
    print_and_log("Configuring Solver")

    OPTIMIZER = configure_solver(mysetup["Solver"], settings_path)

    ### Load inputs
    myinputs = load_inputs(mysetup, inputs_path)

    ### Load H2 inputs if modeling the hydrogen supply chain
    if mysetup["ModelH2"] == 1
        myinputs = load_h2_inputs(myinputs, mysetup, inputs_path)
    end

    ### Generate model
    EP = generate_model(mysetup, myinputs, OPTIMIZER)

    ### Solve model
    EP, solve_time = solve_model(EP, mysetup)
    myinputs["solve_time"] = solve_time # Store the model solve time in myinputs

    ### Write power system output

    # print_and_log("Writing Output")
    outpath = joinpath(inputs_path,"Results")
    outpath_GenX = write_outputs(EP, outpath, mysetup, myinputs)

    # Write hydrogen supply chain outputs
    # if mysetup["ModelH2"] == 1
    write_HSC_outputs(EP, outpath_GenX, mysetup, myinputs)
    # end
    if return_results
        return EP, mysetup, myinputs
    else
        return nothing
    end
end

function benchmark_generate_case(inputs_path::String, settings_path::String)
    # Load settings
    mysetup = load_settings(settings_path)

    # Setup logging 
    global_logger = setup_logging(mysetup)

    # Setup time domain reduction and cluster inputs if necessary
    setup_TDR(inputs_path, settings_path, mysetup)

    # ### Configure solver
    print_and_log("Configuring Solver")

    OPTIMIZER = configure_solver(mysetup["Solver"], settings_path)

    # ### Load inputs
    myinputs = load_inputs(mysetup, inputs_path)

    # ### Load H2 inputs if modeling the hydrogen supply chain
    if mysetup["ModelH2"] == 1
        myinputs = load_h2_inputs(myinputs, mysetup, inputs_path)
    end

    ### Generate model
    EP, bm_results = @benchmarked generate_model($mysetup, $myinputs, $OPTIMIZER) seconds=30 samples=1000 evals=1

    outpath = joinpath(inputs_path,"Results")
    mkpath(outpath)

    ## Generate csv file for  benchmark results if flag is set to be true
    generate_benchmark_csv(outpath, bm_results)

    return nothing
end