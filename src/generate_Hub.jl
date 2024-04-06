

function generate_Hub!(EP::Model, setup::Dict, inputs::Dict)

     T = inputs["T"]     # Number of time steps (hours)
     Z = inputs["Z"]     # Number of zones
     L = inputs["L"]

     # Power flow on each transmission line "l" at hour "t"
     @variable(EP, vFLOW[l=1:L, t=1:T])

     ### Creating expressions and variables for electricity and H2 balance ###

     ### Creating Expressions for Hub Balance
     @expression(EP, eElec_Hub[t=1:T, z=1:Z], 0)
     # createemptyexpression!(EP, :eElec_Hub, (T,Z))
     @expression(EP, eH2_Hub[t=1:T, z=1:Z], 0)

     ### Creating Variables for Hub Balance

     # # GenX -> Hub exports
     # #@expression(EP, eElec_GenX2Hub[z=1:Z, t=1:T], 0)
     @variable(EP, vElec_GenX2Hub[t=1:T, z=1:Z], start = 0)

     # # HSC -> Hub exports
     # @expression(EP, eElec_HSC2Hub[z=1:Z, t=1:T], 0)
     @variable(EP, vElec_HSC2Hub[t=1:T, z=1:Z], start = 0)
     @variable(EP, vH2_HSC2Hub[t=1:T, z=1:Z], start = 0)

     # # LFSC -> Hub exports
     # #@expression(EP, eElec_LFSC2Hub[z=1:Z, t=1:T], 0)
     @variable(EP, vElec_LFSC2Hub[t=1:T, z=1:Z], start = 0)
     @variable(EP, vH2_LFSC2Hub[t=1:T, z=1:Z], start = 0)

     # #CSC  -> Hub exports
     @variable(EP, vElec_CSC2Hub[t=1:T, z=1:Z], start = 0)

     # # Slack variable 
     # @variable(EP, vElec_slack[t=1:T, z=1:Z], start = 0)
     # @variable(EP, vH2_slack[t=1:T, z=1:Z], start = 0)


     ### Creating variables for CO2 emisisons ###

     ### Creating Expressions for Hub to confine CO2
     @expression(EP, eCO2cap_Hub[cap=1:inputs["NCO2Cap"]], 0) ## RHS of CO2 constraints
     @expression(EP, eCO2emission_Hub[cap=1:inputs["NCO2Cap"]], 0) ## LHS of CO2 constraints

     # ### Creating Variables for Hub to take CO2 values from each domain
     # To be implemented with variables

     # # # GenX -> Hub exports
     # @variable(EP, vCO2cap_GenX2Hub[cap=1:inputs["NCO2Cap"]], start = 0) ## RHS of CO2 constraints
     # @variable(EP, vCO2emission_GenX2Hub[cap=1:inputs["NCO2Cap"]], start = 0) ## LHS of CO2 constraints

     # # # HSC -> Hub exports
     # @variable(EP, vCO2cap_HSC2Hub[cap=1:inputs["NCO2Cap"]], start = 0) ## RHS of CO2 constraints
     # @variable(EP, vCO2emission_HSC2Hub[cap=1:inputs["NCO2Cap"]], start = 0) ## LHS of CO2 constraints

     # # # LFSC -> Hub exports
     # @variable(EP, vCO2cap_LFSC2Hub[cap=1:inputs["NCO2Cap"]], start = 0) ## RHS of CO2 constraints
     # @variable(EP, vCO2emission_LFSC2Hub[cap=1:inputs["NCO2Cap"]], start = 0) ## LHS of CO2 constraints

     # # #CSC  -> Hub exports
     # @variable(EP, vCO2cap_CSC2Hub[cap=1:inputs["NCO2Cap"]], start = 0) ## RHS of CO2 constraints
     # @variable(EP, vCO2emission_CSC2Hub[cap=1:inputs["NCO2Cap"]], start = 0) ## LHS of CO2 constraints

     return EP
end

