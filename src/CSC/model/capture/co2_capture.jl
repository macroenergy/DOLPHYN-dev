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

@doc raw"""
	co2_capture(EP::Model, inputs::Dict, setup::Dict)

This module models the CO2 captured by flue gas CCS units present in power, H2, and DAC plants and adds them to the total captured CO2 balance 
"""
function co2_capture(EP::Model, inputs::Dict, setup::Dict)

	CO2_CAPTURE_DAC = inputs["CO2_CAPTURE_DAC"]

	dfGen = inputs["dfGen"] #To account for the CO2 captured by power sector

	if setup["ModelH2"] == 1
		dfH2Gen = inputs["dfH2Gen"]
		H = inputs["H2_RES_ALL"]
	end

	dfDAC = inputs["dfDAC"]  # Input CO2 capture data

	D = inputs["DAC_RES_ALL"]
	G = inputs["G"]  # Number of resources (generators, storage, DR, and DERs)
	Z = inputs["Z"]  # Model demand zones - assumed to be same for CO2, H2 and electricity
	T = inputs["T"]	 # Model operating time steps

	if !isempty(CO2_CAPTURE_DAC)
		EP = co2_capture_DAC(EP::Model, inputs::Dict,setup::Dict)
	end

	#ADD CAPTURED CO2 FROM POWER SECTOR TO CO2 BALANCE
	EP[:eCaptured_CO2_Balance] += EP[:ePower_CO2_captured_per_time_per_zone]

	#################################################################################################################################################################

	if setup["ModelH2"] == 1
		#ADD CAPTURED CO2 FROM HSC TO CO2 BALANCE
		EP[:eCaptured_CO2_Balance] += EP[:eHydrogen_CO2_captured_per_time_per_zone]
	end
	#################################################################################################################################################################
	#CO2 captued by DAC CCS plants

    #CCS CO2 captured by fuel usage per type of resource "k"
    if setup["ParameterScale"] ==1
        @expression(EP,eCO2CaptureByDACFuelPlant[k=1:D,t=1:T], 
            inputs["fuel_CO2"][dfDAC[!,:Fuel][k]] * dfDAC[!,:etaFuel_MMBtu_per_tonne][k] * EP[:vDAC_CO2_Captured][k,t] *  (dfDAC[!, :Fuel_CCS_Rate][k]) * ModelScalingFactor) #As fuel CO2 is already scaled to kton/MMBtu we need to scale vDAC_CO2_Captured
    else
        @expression(EP,eCO2CaptureByDACFuelPlant[k=1:D,t=1:T], 
        inputs["fuel_CO2"][dfDAC[!,:Fuel][k]] * dfDAC[!,:etaFuel_MMBtu_per_tonne][k] * EP[:vDAC_CO2_Captured][k,t] *  (dfDAC[!, :Fuel_CCS_Rate][k]))
    end

	@expression(EP, eDAC_Fuel_CO2_captured_per_plant_per_time[y=1:D,t=1:T], EP[:eCO2CaptureByDACFuelPlant][y,t])
	@expression(EP, eDAC_Fuel_CO2_captured_per_zone_per_time[z=1:Z, t=1:T], sum(eDAC_Fuel_CO2_captured_per_plant_per_time[y,t] for y in dfDAC[(dfDAC[!,:Zone].==z),:R_ID]))
	@expression(EP, eDAC_Fuel_CO2_captured_per_time_per_zone[t=1:T, z=1:Z], sum(eDAC_Fuel_CO2_captured_per_plant_per_time[y,t] for y in dfDAC[(dfDAC[!,:Zone].==z),:R_ID]))
	
	#ADD TO CO2 BALANCE
	EP[:eCaptured_CO2_Balance] += EP[:eDAC_Fuel_CO2_captured_per_time_per_zone]


	return EP
end
