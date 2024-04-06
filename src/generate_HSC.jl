
function generate_HSC!(EP::Model, setup::Dict, inputs::Dict)

     T = inputs["T"]     # Number of time steps (hours)
     Z = inputs["Z"]     # Number of zones
     L = inputs["L"]
     # Creating new expression for "hydrogen" power balance constraint
     @expression(EP, ePowerBalance_HSC[t=1:T, z=1:Z], 0)

     # Initialize Hydrogen Balance Expression
     # Expression for "baseline" H2 balance constraint
     @expression(EP, eH2Balance[t=1:T, z=1:Z], 0)


     # Initialize Liquid Hydrogen Balance Expression
     if setup["ModelH2Liquid"] == 1
          # Expression for "baseline" H2 liquid balance constraint
          @expression(EP, eH2LiqBalance[t=1:T, z=1:Z], 0)
     end


     @expression(EP, eHGenerationByZone[z=1:Z, t=1:T], 0)
     @expression(EP, eHTransmissionByZone[t=1:T, z=1:Z], 0)
     @expression(EP, eHDemandByZone[t=1:T, z=1:Z], inputs["H2_D"][t, z])
     # Net Power consumption by HSC supply chain by z and timestep - used in emissions constraints
     @expression(EP, eH2NetpowerConsumptionByAll[t=1:T, z=1:Z], 0)

     # Infrastructure
     EP = h2_outputs(EP, inputs, setup)

     # Investment cost of various hydrogen generation sources
     EP = h2_investment(EP, inputs, setup)

     if !isempty(inputs["H2_GEN"])
          #model H2 generation
          EP = h2_production(EP, inputs, setup)
     end

     # Direct emissions of various hydrogen sector resources
     EP = emissions_hsc(EP, inputs, setup)

     # Model H2 non-served
     EP = h2_non_served(EP, inputs, setup)

     # Model hydrogen storage technologies
     if !isempty(inputs["H2_STOR_ALL"])
          EP = h2_storage(EP, inputs, setup)
     end

     if !isempty(inputs["H2_FLEX"])
          #model H2 flexible demand resources
          EP = h2_flexible_demand(EP, inputs, setup)
     end

     if setup["ModelH2Pipelines"] == 1
          # model hydrogen transmission via pipelines
          EP = h2_pipeline_investment(EP, inputs, setup)
          EP = h2_pipeline(EP, inputs, setup)
     end

     if setup["ModelH2Trucks"] == 1
          # model hydrogen transmission via trucks
          EP = h2_truck(EP, inputs, setup)
     end

     if setup["ModelH2G2P"] == 1
          #model H2 Gas to Power
          EP = h2_g2p(EP, inputs, setup)
     else
          # Quick fix to ensure that the H2_G2P variable is defined even if the function is not run
          # FIX ME: This needs to be handled better in co2_cap_hsc and co2_cap_power_hsc
          @expression(EP, eH2DemandByZoneG2P[z=1:Z, t=1:T], # the unit is tonne/hour
               0.0
          )
     end

     # Modeling Time matching requirement for electricity use for hydrogen production
     if setup["TimeMatchingRequirement"] > 0
          EP = time_matching_requirement(EP, inputs, setup)
     end

     if setup["GreenH2ShareRequirement"] == 1
          EP = green_h2_share_requirement(EP, inputs, setup)
     end




     # Hydrogen balance within complete hub design. Here is a correct version for Hydrogen balance
     @constraint(EP, cH2Balance_HSC[t=1:T, z=1:Z], EP[:eH2Balance][t, z] -inputs["H2_D"][t, z] == EP[:vH2_HSC2Hub][t, z])


     if setup["ModelH2Liquid"] == 1
          ###Hydrogen Liquid Balance constraints
          @constraint(EP, cH2LiqBalance[t=1:T, z=1:Z], EP[:eH2LiqBalance][t, z] == inputs["H2_D_L"][t, z])
     end

   
     # Electricity balance within HSC domain
      @constraint(EP, cPowerBalance_HSC[t=1:T, z=1:Z], EP[:ePowerBalance_HSC][t, z] == EP[:vElec_HSC2Hub][t, z])


end
