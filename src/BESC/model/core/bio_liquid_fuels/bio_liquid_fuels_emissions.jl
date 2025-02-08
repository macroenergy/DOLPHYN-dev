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
    bio_liquid_fuels_emissions(EP::Model, inputs::Dict, setup::Dict)

This function creates expression to add the CO2 emissions from the biorefinery, negative emissions from the biomass utilization, and add any CO2 captured from the biorefinery to the captured CO2 inventory.
"""
function bio_liquid_fuels_emissions(EP::Model, inputs::Dict, setup::Dict)

	println(" -- Bio Liquid Fuels Emissions Module for CO2 Policy modularization")

	dfBioLF = inputs["dfBioLF"]
    BIO_LF_RES_ALL = inputs["BIO_LF_RES_ALL"]

    T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

    #Bioenergy carbon balance:
    #Biomass CO2 captured = Biorefinery emissions + bioenergy capture to storage + biofuel emissions
    #Biorefinery capture to storage is added to CO2 storage balance
    #Net negative emission = Biorefinery capture to storage

    #####################################################################################################################################
    #Biomass CO2 per plant per time
    @expression(EP, eBiomass_CO2_per_plant_per_time_LF[i in 1:BIO_LF_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time_LF][i,t] * dfBioLF[!,:Biomass_carbon_tonne_CO2_per_tonne][i])

    #Total biomass CO2 per zone per time
    @expression(EP, eBiomass_CO2_per_zone_per_time_LF[z in 1:Z, t in 1:T], sum(EP[:eBiomass_CO2_per_plant_per_time_LF][i,t] for i in dfBioLF[dfBioLF[!,:Zone].==z,:][!,:R_ID]))
    
    ##########################################################################
    #Plant CO2 emissions per type of resource (Biomass CO2 - Biofuel emissions) --- Before CCS
    #Split into non liquid fuels resources, and liquid fuels resources to accommodate flex fuels

    #Emissions from biofuels utilization
    Bio_gasoline_co2_per_mmbtu = inputs["Bio_gasoline_co2_per_mmbtu"]
    Bio_jetfuel_co2_per_mmbtu = inputs["Bio_jetfuel_co2_per_mmbtu"]
    Bio_diesel_co2_per_mmbtu = inputs["Bio_diesel_co2_per_mmbtu"]


    @expression(EP,eBiorefinery_CO2_Produced_LF[i in 1:BIO_LF_RES_ALL, t in 1:T], 
    EP[:eBiomass_CO2_per_plant_per_time_LF][i,t] 
    - EP[:eBiogasoline_produced_MMBtu_per_plant_per_time][i,t] * Bio_gasoline_co2_per_mmbtu
    - EP[:eBiojetfuel_produced_MMBtu_per_plant_per_time][i,t] * Bio_jetfuel_co2_per_mmbtu
    - EP[:eBiodiesel_produced_MMBtu_per_plant_per_time][i,t] * Bio_diesel_co2_per_mmbtu)

    ##########################################################################
    #Plant CO2 captured per type of resource defined by CCS rate (Add to captured CO2 balance)
    @expression(EP, eBio_LF_CO2_captured_per_plant_per_time[i in 1:BIO_LF_RES_ALL, t in 1:T], EP[:eBiorefinery_CO2_Produced_LF][i,t] * dfBioLF[!,:CCS_Rate][i])

    #Total CO2 capture to storage per zone per time
    @expression(EP, eBio_LF_CO2_captured_per_zone_per_time[z in 1:Z, t in 1:T], sum(EP[:eBio_LF_CO2_captured_per_plant_per_time][i,t] for i in dfBioLF[dfBioLF[!,:Zone].==z,:][!,:R_ID]))
    
    @expression(EP, eBio_LF_CO2_captured_per_time_per_zone[t in 1:T, z in 1:Z], sum(EP[:eBio_LF_CO2_captured_per_plant_per_time][i,t] for i in dfBioLF[dfBioLF[!,:Zone].==z,:][!,:R_ID]))

    #ADD TO CO2 BALANCE
    EP[:eCaptured_CO2_Balance] += EP[:eBio_LF_CO2_captured_per_time_per_zone]

    ##########################################################################
    #Plant CO2 emitted per type of resource --- After CCS (Add to CO2 cap policy)
    @expression(EP, eBio_LF_CO2_emissions_per_plant_per_time[i in 1:BIO_LF_RES_ALL, t in 1:T], EP[:eBiorefinery_CO2_Produced_LF][i,t] * (1 - dfBioLF[!,:CCS_Rate][i]))

    #####################################################################################################################################
    #CO2 emitted as a result of bio liquid fuels consumption for CO2 policy cap
    @expression(EP,eBio_Gasoline_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], Bio_gasoline_co2_per_mmbtu * EP[:eBiogasoline_produced_MMBtu_per_time_per_zone][t,z])
    @expression(EP,eBio_Jetfuel_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], Bio_jetfuel_co2_per_mmbtu * EP[:eBiojetfuel_produced_MMBtu_per_time_per_zone][t,z])
    @expression(EP,eBio_Diesel_CO2_Emissions_By_Zone[z = 1:Z,t=1:T], Bio_diesel_co2_per_mmbtu * EP[:eBiodiesel_produced_MMBtu_per_time_per_zone][t,z])
    @expression(EP,eBio_LF_Plant_CO2_emissions_per_zone_per_time[z in 1:Z, t in 1:T], sum(EP[:eBio_LF_CO2_emissions_per_plant_per_time][i,t] for i in dfBioLF[dfBioLF[!,:Zone].==z,:][!,:R_ID]))
        
return EP
end
