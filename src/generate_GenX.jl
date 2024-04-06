

function generate_GenX!(EP::Model, setup::Dict, inputs::Dict)

     T = inputs["T"]     # Number of time steps (hours)
     Z = inputs["Z"]     # Number of zones

     set_string_names_on_creation(EP, Bool(setup["EnableJuMPStringNames"]))
     # Introduce dummy variable fixed to zero to ensure that expressions like eTotalCap,
     # eTotalCapCharge, eTotalCapEnergy and eAvail_Trans_Cap all have a JuMP variable

     # Initialize Power Balance Expression
     # Expression for "baseline" power balance constraint
     @expression(EP, ePowerBalance[t=1:T, z=1:Z], 0)



     # Initialize Capacity Reserve Margin Expression
     if setup["CapacityReserveMargin"] > 0
          @expression(EP, eCapResMarBalance[res=1:inputs["NCapacityReserveMargin"], t=1:T], 0)
     end

     if setup["MinCapReq"] == 1
          @expression(EP, eMinCapRes[mincap=1:inputs["NumberOfMinCapReqs"]], 0)
     end

     if setup["MaxCapReq"] == 1
          @expression(EP, eMaxCapRes[maxcap=1:inputs["NumberOfMaxCapReqs"]], 0)
     end

     # Infrastructure
     discharge!(EP, inputs, setup)

     non_served_energy!(EP, inputs, setup)

     investment_discharge!(EP, inputs, setup)

     if setup["UCommit"] > 0
          ucommit!(EP, inputs, setup)
     end


     ### Note: to be confirmed
     emissions!(EP, inputs, setup)

     if setup["Reserves"] > 0
          reserves!(EP, inputs, setup)
     end

     ### Moved to Hub for balance between zones
     # if Z > 1
     # 	transmission!(EP, inputs, setup)
     #  end


     # Technologies
     # Model constraints, variables, expression related to dispatchable renewable resources
     if !isempty(inputs["VRE"])
          curtailable_variable_renewable!(EP, inputs, setup)
     end

     # Model constraints, variables, expression related to non-dispatchable renewable resources
     if !isempty(inputs["MUST_RUN"])
          must_run!(EP, inputs, setup)
     end

     # Model constraints, variables, expression related to energy storage modeling
     if !isempty(inputs["STOR_ALL"])
          storage!(EP, inputs, setup)
     end

     # Model constraints, variables, expression related to reservoir hydropower resources
     if !isempty(inputs["HYDRO_RES"])
          hydro_res!(EP, inputs, setup)
     end

     # Model constraints, variables, expression related to reservoir hydropower resources with long duration storage
     if setup["OperationWrapping"] == 1 && !isempty(inputs["STOR_HYDRO_LONG_DURATION"])
          hydro_inter_period_linkage!(EP, inputs)
     end

     # Model constraints, variables, expression related to demand flexibility resources
     if !isempty(inputs["FLEX"])
          flexible_demand!(EP, inputs, setup)
     end
     # Model constraints, variables, expression related to thermal resource technologies
     if !isempty(inputs["THERM_ALL"])
          thermal!(EP, inputs, setup)
     end

     # Model constraints, variables, expression related to retrofit technologies
     if !isempty(inputs["RETRO"])
          EP = retrofit(EP, inputs)
     end



	# Endogenous Retirements
     if setup["MultiStage"] > 0
          endogenous_retirement!(EP, inputs, setup)
     end

	

     if (setup["MinCapReq"] == 1)
          minimum_capacity_requirement(EP, inputs, setup)
     end

     if (setup["MaxCapReq"] == 1)
          maximum_capacity_requirement(EP, inputs)
     end

     # GenX -> Hub exports

     ## Power balance constraints
     # demand + exports 
     # generation + storage discharge - storage charge - demand deferral + deferred demand satisfaction - demand curtailment (NSE)
     #          + incoming power flows - outgoing power flows - flow losses - charge of heat storage + generation from NACC

	@constraint(EP, cPowerBalance_GenX[t=1:T, z=1:Z], EP[:ePowerBalance][t, z] - inputs["pD"][t, z] == EP[:vElec_GenX2Hub][t, z])

end