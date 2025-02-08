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

	dfDAC = inputs["dfDAC"]  # Input CO2 capture data

	D = inputs["DAC_RES_ALL"]
	Z = inputs["Z"]  # Model demand zones - assumed to be same for CO2, H2 and electricity
	T = inputs["T"]	 # Model operating time steps

	EP = co2_capture_DAC(EP::Model, inputs::Dict,setup::Dict)

	#CO2 captued by power sector CCS plants
	EP[:eCaptured_CO2_Balance] += EP[:ePower_CO2_captured_per_time_per_zone]

	if setup["ModelNGSC"] == 1
		#If NGSC is modeled, NG is not in fuels input, so have to account for CO2 captured from CCS of NG utilization in plant separately
		EP[:eCaptured_CO2_Balance] += EP[:ePower_NG_CO2_captured_per_time_per_zone]
	end

	#################################################################################################################################################################

	if setup["ModelH2"] == 1

		#CO2 captued by H2 CCS plants
		EP[:eCaptured_CO2_Balance] += EP[:eHydrogen_CO2_captured_per_time_per_zone]

		if setup["ModelNGSC"] == 1
			#If NGSC is modeled, not using fuel from the fuels input, so have to account for CO2 captured from CCS of NG utilization in plant separately
			EP[:eCaptured_CO2_Balance] += EP[:eHydrogen_NG_CO2_captured_per_time_per_zone]
		end
	end
	#################################################################################################################################################################
	#CO2 captued by DAC CCS plants

    #CCS CO2 captured by fuel usage per type of resource "k"
	@expression(EP,eCO2CaptureByDACFuelPlant[k=1:D,t=1:T], 
	inputs["fuel_CO2"][dfDAC[!,:Fuel][k]] * dfDAC[!,:etaFuel_MMBtu_per_tonne][k] * EP[:vDAC_CO2_Captured][k,t] *  (dfDAC[!, :Fuel_CCS_Rate][k]))

	@expression(EP, eDAC_Fuel_CO2_captured_per_plant_per_time[y=1:D,t=1:T], EP[:eCO2CaptureByDACFuelPlant][y,t])
	@expression(EP, eDAC_Fuel_CO2_captured_per_zone_per_time[z=1:Z, t=1:T], sum(eDAC_Fuel_CO2_captured_per_plant_per_time[y,t] for y in dfDAC[(dfDAC[!,:Zone].==z),:R_ID]))
	@expression(EP, eDAC_Fuel_CO2_captured_per_time_per_zone[t=1:T, z=1:Z], sum(eDAC_Fuel_CO2_captured_per_plant_per_time[y,t] for y in dfDAC[(dfDAC[!,:Zone].==z),:R_ID]))
	
	#ADD TO CO2 BALANCE
	EP[:eCaptured_CO2_Balance] += EP[:eDAC_Fuel_CO2_captured_per_time_per_zone]

	if setup["ModelNGSC"] == 1
		 #CCS CO2 captured by fuel usage per type of resource "k"
		@expression(EP,eNGCO2CaptureByDACFuelPlant[k=1:D,t=1:T], 
		inputs["ng_co2_per_mmbtu"] * dfDAC[!,:etaNG_MMBtu_per_tonne][k] * EP[:vDAC_CO2_Captured][k,t] *  (dfDAC[!, :Fuel_CCS_Rate][k]))

		@expression(EP, eDAC_NG_CO2_captured_per_plant_per_time[y=1:D,t=1:T], EP[:eNGCO2CaptureByDACFuelPlant][y,t])
		@expression(EP, eDAC_NG_CO2_captured_per_zone_per_time[z=1:Z, t=1:T], sum(eDAC_NG_CO2_captured_per_plant_per_time[y,t] for y in dfDAC[(dfDAC[!,:Zone].==z),:R_ID]))
		@expression(EP, eDAC_NG_CO2_captured_per_time_per_zone[t=1:T, z=1:Z], sum(eDAC_NG_CO2_captured_per_plant_per_time[y,t] for y in dfDAC[(dfDAC[!,:Zone].==z),:R_ID]))

		#ADD TO CO2 BALANCE
		EP[:eCaptured_CO2_Balance] += EP[:eDAC_NG_CO2_captured_per_time_per_zone]
	end

	return EP
end
