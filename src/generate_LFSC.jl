
function generate_LFSC!(EP::Model, setup::Dict, inputs::Dict)

    T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
    
#     #Note, have not being put into usage. Creating new expression for "LFSC" power balance constraint
     @expression(EP, ePowerBalance_LFSC[t=1:T, z=1:Z], 0)
     @expression(EP, eH2Balance_LFSC[t=1:T, z=1:Z], 0)
    # Initialize Hydrogen Balance Expression
    # Expression for "baseline" H2 balance constraint
   # @expression(EP, eH2Balance_LFSC[t=1:T, z=1:Z], 0)

# Initialize Liquid Fuel Balance
@expression(EP, eLFDieselBalance[t=1:T, z=1:Z], 0)
@expression(EP, eLFJetfuelBalance[t=1:T, z=1:Z], 0)
@expression(EP, eLFGasolineBalance[t=1:T, z=1:Z], 0)


EP = syn_fuel_outputs(EP, inputs, setup)
EP = syn_fuel_investment(EP, inputs, setup)
EP = syn_fuel_resources(EP, inputs, setup)
EP = liquid_fuel_demand(EP, inputs, setup)
EP = liquid_fuel_emissions(EP, inputs, setup)

###HLiquid Fuel Demand Constraints
#Diesel

@expression(EP, eGlobalLFDieselBalance[t=1:T], sum(inputs["omega"][t] * EP[:eLFDieselBalance][t, z] for z = 1:Z))
@expression(EP, eGlobalLFDieselDemand[t=1:T], sum(inputs["omega"][t] * inputs["Liquid_Fuels_Diesel_D"][t, z] for z = 1:Z))

#Demand constraint for each time t for global liquid fuel demand
#@constraint(EP, cLFDieselBalance[t=1:T], eGlobalLFDieselBalance[t] >= eGlobalLFDieselDemand[t])

#Demand constraint for annual global liquid fuel demand
@expression(EP, eAnnualGlobalLFDieselBalance, sum(EP[:eGlobalLFDieselBalance][t] for t = 1:T))
@expression(EP, eAnnualGlobalLFDieselDemand, sum(EP[:eGlobalLFDieselDemand][t] for t = 1:T))
@constraint(EP, cLFAnnualDieselBalance, eAnnualGlobalLFDieselBalance >= eAnnualGlobalLFDieselDemand)


#Jetfuel

@expression(EP, eGlobalLFJetfuelBalance[t=1:T], sum(inputs["omega"][t] * EP[:eLFJetfuelBalance][t, z] for z = 1:Z))
@expression(EP, eGlobalLFJetfuelDemand[t=1:T], sum(inputs["omega"][t] * inputs["Liquid_Fuels_Jetfuel_D"][t, z] for z = 1:Z))

#Demand constraint for each time t for global liquid fuel demand
#@constraint(EP, cLFJetfuelBalance[t=1:T], eGlobalLFJetfuelBalance[t] >= eGlobalLFJetfuelDemand[t])

#Demand constraint for annual global liquid fuel demand
@expression(EP, eAnnualGlobalLFJetfuelBalance, sum(EP[:eGlobalLFJetfuelBalance][t] for t = 1:T))
@expression(EP, eAnnualGlobalLFJetfuelDemand, sum(EP[:eGlobalLFJetfuelDemand][t] for t = 1:T))
@constraint(EP, cLFAnnualJetfuelBalance, eAnnualGlobalLFJetfuelBalance >= eAnnualGlobalLFJetfuelDemand)


#Gasoline

@expression(EP, eGlobalLFGasolineBalance[t=1:T], sum(inputs["omega"][t] * EP[:eLFGasolineBalance][t, z] for z = 1:Z))
@expression(EP, eGlobalLFGasolineDemand[t=1:T], sum(inputs["omega"][t] * inputs["Liquid_Fuels_Gasoline_D"][t, z] for z = 1:Z))

#Demand constraint for each time t for global liquid fuel demand
#@constraint(EP, cLFGasolineBalance[t=1:T], eGlobalLFGasolineBalance[t] >= eGlobalLFGasolineDemand[t])

#Demand constraint for annual global liquid fuel demand
@expression(EP, eAnnualGlobalLFGasolineBalance, sum(EP[:eGlobalLFGasolineBalance][t] for t = 1:T))
@expression(EP, eAnnualGlobalLFGasolineDemand, sum(EP[:eGlobalLFGasolineDemand][t] for t = 1:T))


@constraint(EP, cLFAnnualGasolineBalance, eAnnualGlobalLFGasolineBalance >= eAnnualGlobalLFGasolineDemand)


### Hydrogen balance within LFSC domain
@constraint(EP, cH2Balance_LFSC[t=1:T, z=1:Z], EP[:eH2Balance_LFSC][t, z] == EP[:vH2_LFSC2Hub][t, z])
### Electricity balance within LFSC domain
@constraint(EP, cPowerBalance_LFSC[t=1:T, z=1:Z], EP[:ePowerBalance_LFSC][t, z] == EP[:vElec_LFSC2Hub][t, z])

end