### This file splits the Investment decision variables for Benders Decomposition

function CO2_pipeline_investment(EP::Model, inputs::Dict, setup::Dict)
    println("CO2 Pipeline Investment Module")

    CO2_P = inputs["CO2_P"]

    @variable(EP, vCO2NPipe[p=1:CO2_P] >= 0 )

    CO2_P = inputs["CO2_P"] # Number of CO2 Pipelines


    ### Expressions ###
    #Calculate the number of new pipes
    @expression(EP, eCO2NPipeNew[p=1:CO2_P], EP[:vCO2NPipe][p] - inputs["pCO2_Pipe_No_Curr"][p])


    ## Objective Function Expressions ##
    # Capital cost of pipelines 
    #  ParameterScale = 1 --> objective function is in million $
    #  ParameterScale = 0 --> objective function is in $

    if setup["ParameterScale"] == 1
        @expression(EP, eCCO2Pipe, sum(eCO2NPipeNew[p] * inputs["pCAPEX_CO2_Pipe"][p] / (ModelScalingFactor)^2 for p = 1:CO2_P) + sum(EP[:vCO2NPipe][p] * inputs["pFixed_OM_CO2_Pipe"][p] / (ModelScalingFactor)^2 for p = 1:CO2_P))
    else
        @expression(EP, eCCO2Pipe, sum(eCO2NPipeNew[p] * inputs["pCAPEX_CO2_Pipe"][p] for p = 1:CO2_P) + sum(EP[:vCO2NPipe][p] * inputs["pFixed_OM_CO2_Pipe"][p] for p = 1:CO2_P))
    end

    EP[:eObj] += eCCO2Pipe

    # Capital cost of booster compressors located along each pipeline - more booster compressors needed for longer pipelines than shorter pipelines
    #  ParameterScale = 1 --> objective function is in million $
    #  ParameterScale = 0 --> objective function is in $
    if setup["ParameterScale"] == 1
        @expression(EP, eCCO2CompPipe, sum(eCO2NPipeNew[p] * inputs["pCAPEX_Comp_CO2_Pipe"][p] / (ModelScalingFactor)^2 for p = 1:CO2_P))

    else
        @expression(EP, eCCO2CompPipe, sum(eCO2NPipeNew[p] * inputs["pCAPEX_Comp_CO2_Pipe"][p] for p = 1:CO2_P))
    end


    EP[:eObj] += eCCO2CompPipe


    # Constraints
    if setup["CO2PipeInteger"] == 1
        for p = 1:CO2_P
            set_integer.(EP[:vCO2NPipe][p])
        end
    end

    # Modeling expansion of the pipleline network
    if setup["CO2NetworkExpansion"] == 1
        # If network expansion allowed Total no. of Pipes >= Existing no. of Pipe 
        @constraint(EP, cCO2NetworkExpansion[p in 1:CO2_P], EP[:eCO2NPipeNew][p] >= 0)
    else
        # If network expansion is not alllowed Total no. of Pipes == Existing no. of Pipe 
        @constraint(EP, cCO2NetworkExpansion[p in 1:CO2_P], EP[:eCO2NPipeNew][p] == 0)
    end
    return EP
end