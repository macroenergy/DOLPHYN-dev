function generate_CSC!(EP::Model, setup::Dict, inputs::Dict)

     T = inputs["T"]     # Number of time steps (hours)
     Z = inputs["Z"]     # Number of zones
     L = inputs["L"]

     @expression(EP, ePowerBalance_CSC[t=1:T, z=1:Z], 0)

     # Initialize CO2 Capture Balance Expression
     @expression(EP, eCaptured_CO2_Balance[t=1:T, z=1:Z], 0)

     # Net Power consumption by CSC supply chain by z and timestep - used in emissions constraints
     @expression(EP, eCSCNetpowerConsumptionByAll[t=1:T, z=1:Z], 0)

     # Variable costs and carbon captured per DAC resource "k" and time "t"
     EP = DAC_var_cost(EP, inputs, setup)

     # Fixed costs of DAC
     EP = DAC_investment(EP, inputs, setup)

     #model CO2 capture
     EP = co2_capture(EP, inputs, setup)

     # Fixed costs of storage storage

     EP = co2_storage_investment(EP, inputs, setup)

     if !isempty(inputs["CO2_STORAGE"])
          #model CO2 injection
          EP = co2_injection(EP, inputs, setup)
     end

     # Fixed costs of carbon capture compression

     EP = co2_capture_compression_investment(EP, inputs, setup)

     if !isempty(inputs["CO2_CAPTURE_COMP"])
          #model CO2 capture
          EP = co2_capture_compression(EP, inputs, setup)
     end

     if setup["ModelCO2Pipelines"] == 1
          # model CO2 transmission via pipelines
          EP = co2_pipeline(EP, inputs, setup)
     end

     # Direct emissions of various carbon capture sector resources
     EP = emissions_csc(EP, inputs, setup)

     @constraint(EP, cPowerBalance_CSC[t=1:T, z=1:Z], EP[:ePowerBalance_CSC][t, z] == EP[:vElec_CSC2Hub][t, z])

     ### Note: seems not being used :eAdditionalDemandByZone
     ### Note: Check the physical meaning further. Electricity related. eAdditionalDemandByZone is not used. the latter is for CO2 calculation
     #EP[:eAdditionalDemandByZone] += EP[:eCSCNetpowerConsumptionByAll]
end