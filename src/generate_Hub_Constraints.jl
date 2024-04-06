
function generate_Hub_Constraints!(EP::Model, setup::Dict, inputs::Dict)
  T = inputs["T"]     # Number of time steps (hours)
  Z = inputs["Z"]     # Number of zones

  # Joint emissions constraint for multiple sectors
  if setup["SystemCO2Constraint"] == 2
    EP = co2_cap_power_hsc(EP, inputs, setup)
  end

  ### flow among zones through Hub
  if Z > 1
    transmission_investment!(EP, inputs, setup)
    transmission_operation!(EP, inputs, setup)
  end


  # ### Note, the dierctions of the all the energy flow in/out Hub need to be double checked.
  # ## Electricity balance between zones and domains
  EP[:eElec_Hub] += EP[:vElec_GenX2Hub]
  # #   add_similar_to_expression!(EP[:eElec_Hub],EP[:vElec_GenX2Hub])
  EP[:eElec_Hub] += EP[:vElec_HSC2Hub]
  EP[:eElec_Hub] += EP[:vElec_LFSC2Hub]
  EP[:eElec_Hub] += EP[:vElec_CSC2Hub]
  @constraint(EP, cPowerBalance[t=1:T, z=1:Z], EP[:eElec_Hub][t, z] == 0)   ##+EP[:ePowerBalance_CSC][t, z]+ EP[:ePowerBalance_LFSC][t, z] 
  #@constraint(EP, cPowerBalance[t=1:T, z=1:Z], EP[:eElec_Hub][t,z] +EP[:ePowerBalance][t, z] +EP[:ePowerBalance_HSC][t, z]== inputs["pD"][t, z])

  # ## Hydrogen balance between zones and domains
  # ## Note: Currently H2 balance has no need of following this way as LFSC only have one function changing the H2 balance
  EP[:eH2_Hub] += EP[:vH2_HSC2Hub]
  EP[:eH2_Hub] += EP[:vH2_LFSC2Hub]
  @constraint(EP, cH2Balance[t=1:T, z=1:Z], EP[:eH2_Hub][t, z] == 0)  ##+ EP[:eH2Balance_LFSC][t,z] 
  #@constraint(EP, cH2Balance[t=1:T, z=1:Z], EP[:eH2Balance][t, z]== inputs["H2_D"][t, z])

  return EP
end
