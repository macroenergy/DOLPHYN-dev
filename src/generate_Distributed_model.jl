"""
DOLPHYN: Decision Optimization for Low-carbon Power and Hydrogen Networks
Copyright (C) 2022,  Massachusetts Institute of Technology
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
A complete copy of the GNU General Public License v2 (GPLv2) is available
in LICENSE.txt.  Users uncompressing this from an archive may not have
received this license file.  If not, see <http://www.gnu.org/licenses/>.
"""



## generate_Distributed_model(setup::Dict,inputs::Dict,OPTIMIZER::MOI.OptimizerWithAttributes,modeloutput = nothing)
################################################################################
##
## description: Sets up and solves constrained optimization model of electricity
## system capacity expansion and operation problem and extracts solution variables
## for later processing
##
## returns: Model EP object containing the entire optimization problem model to be solved by SolveModel.jl
##
################################################################################
function generate_Distributed_model(setup::Dict, inputs::Dict, OPTIMIZER::MOI.OptimizerWithAttributes, modeloutput=nothing)

     T = inputs["T"]     # Number of time steps (hours)
     Z = inputs["Z"]     # Number of zones - assumed to be same for power and hydrogen system

     ## Start pre-solve timer
     presolver_start_time = time()

     # Generate Energy Portfolio (EP) Model
     EP = Model(OPTIMIZER)

     # Introduce dummy variable fixed to zero to ensure that expressions like eTotalCap,
     # eTotalCapCharge, eTotalCapEnergy and eAvail_Trans_Cap all have a JuMP variable
     @variable(EP, vZERO == 0)

     # Initialize Objective Function Expression
     @expression(EP, eObj, 0)
     # Note: CO2 balance related expressions, to be handled
     # Power supply by z and timestep - used in emissions constraints
     @expression(EP, eGenerationByZone[z=1:Z, t=1:T], 0)  #Note: to be split
     #@expression(EP, eTransmissionByZone[z=1:Z, t=1:T], 0) # NOTE: expression from Main branch. Seems not being used.
     #@expression(EP, eDemandByZone[t=1:T, z=1:Z], inputs["pD"][t, z])  # NOTE: expression from Main branch. Seems not being used.
     # Additional demand by z and timestep - used to record power consumption in other sectors like hydrogen and carbon
     #@expression(EP, eAdditionalDemandByZone[t=1:T, z=1:Z], 0)# NOTE: expression from Main branch. Seems not being used.

     # Note: This expression is used by one model from H2, even the rest are GenX
     # Energy Share Requirement
     if setup["EnergyShareRequirement"] >= 1
          @expression(EP, eESR[ESR=1:inputs["nESR"]], 0)
     end

     generate_Hub!(EP, setup, inputs)


     if setup["Model_GenX"] == 1
          generate_GenX!(EP, setup, inputs)
          #@constraint(EP, cPowerBalance[t=1:T, z=1:Z], EP[:ePowerBalance][t,z] == inputs["pD"][t,z] )
          if setup["SystemCO2Constraint"] == 1 && setup["CO2Cap"] != 0
               # CO2 constraint for power system imposed separately
               co2_cap!(EP, inputs, setup)
          end
     else
          @constraint(EP, c_GenX2Hub[t=1:T, z=1:Z], EP[:vElec_GenX2Hub][t, z] == 0)
     end

     if setup["ModelH2"] == 1
          generate_HSC!(EP, setup, inputs)
          if setup["SystemCO2Constraint"] == 1 && setup["H2CO2Cap"] != 0
               # HSC constraint for power system imposed separately
               EP = co2_cap_hsc(EP, inputs, setup)
          end
          ### Note: Check the physical meaning further. Electricity related. eAdditionalDemandByZone is not used. eH2NetpowerConsumptionByAll is for CO2 calculation
          # EP[:eAdditionalDemandByZone] += EP[:eH2NetpowerConsumptionByAll] #Note: to be checked
     else
          @constraint(EP, c_HSC2Hub_Elec[t=1:T, z=1:Z], EP[:vElec_HSC2Hub][t, z] == 0)
          @constraint(EP, c_HSC2Hub_H2[t=1:T, z=1:Z], EP[:vH2_HSC2Hub][t, z] == 0)
     end

     if setup["ModelCSC"] == 1
          generate_CSC!(EP, setup, inputs)
     else
          @constraint(EP, c_CSC2Hub_Elec[t=1:T, z=1:Z], EP[:vElec_CSC2Hub][t, z] == 0)
     end

     if setup["ModelLiquidFuels"] == 1
          generate_LFSC!(EP, setup, inputs)
     else
          @constraint(EP, c_LFSC2Hub_Elec[t=1:T, z=1:Z], EP[:vElec_LFSC2Hub][t, z] == 0)
          @constraint(EP, c_LFSC2Hub_H2[t=1:T, z=1:Z], EP[:vH2_LFSC2Hub][t, z] == 0)
     end


     ################  Policies #####################3
     # CO2 emissions limits for the power sector only


     # if (setup["CO2Cap"] < 4) & (setup["CO2Cap"] > 0)
     #      if setup["ModelH2"] == 0
     #           co2_cap!(EP, inputs, setup)
     #      elseif setup["ModelH2"] == 1
     #           EP = co2_cap_power_hsc(EP, inputs, setup)
     #      end
     # end

     # Energy Share Requirement
     ### Note: cannot be put into GenX directly because EP[:eESR] is resvised inside HSC
     if setup["EnergyShareRequirement"] == 1
          energy_share_requirement!(EP, inputs, setup)
     end

     #Capacity Reserve Margin
     ### Note: This is a linking file between GenX and H2 through EP[:vP2G]
     if setup["CapacityReserveMargin"] > 0
          cap_reserve_margin(EP, inputs, setup)
     end

     ### Note: this is a constraints for both CSC and LFSC. To be split
     if setup["ModelCSC"] == 1
          ###Captured CO2 Balanace constraints
          @constraint(EP, cCapturedCO2Balance[t=1:T, z=1:Z], EP[:eCaptured_CO2_Balance][t, z] == 0)
     end

     generate_Hub_Constraints!(EP, setup, inputs)

     ## Define the objective function
     @objective(EP, Min, EP[:eObj])

     ## Record pre-solver time
     presolver_time = time() - presolver_start_time
     #### Question - What do we do with this time now that we've split this function into 2?
     if setup["PrintModel"] == 1
          if modeloutput === nothing
               filepath = joinpath(pwd(), "YourModel.lp")
               JuMP.write_to_file(EP, filepath)
          else
               filepath = joinpath(modeloutput, "YourModel.lp")
               JuMP.write_to_file(EP, filepath)
          end
          print_and_log("Model Printed")
     end

     return EP
end
