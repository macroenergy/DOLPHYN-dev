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
    bio_liquid_fuels(EP::Model, inputs::Dict, setup::Dict)

This module defines the bio gasoline, jetfuel, and diesel production decision variables $x_{r,t}^{\textrm{E,Bio}} \forall r\in \mathcal{R}, t \in \mathcal{T}$, $x_{r,t}^{\textrm{H,Bio}} \forall r\in \mathcal{R}, t \in \mathcal{T}$, $x_{r,t}^{\textrm{Gasoline,Bio}} \forall r\in \mathcal{R}, t \in \mathcal{T}$, $x_{r,t}^{\textrm{Jetfuel,Bio}} \forall r\in \mathcal{R}, t \in \mathcal{T}$, $x_{r,t}^{\textrm{Diesel,Bio}} \forall r\in \mathcal{R}, t \in \mathcal{T}$ representing bio electricity, hydrogen, gasoline, jetfuel, and diesel produced by resource $r$ at time period $t$.

This module also constraints the amount of each type of non conventional fuels deployment based on user specifications (if any).

This function creates expression to add the CO2 emissions of biofuel utilization in each zone, which is subsequently added to the total emissions. 

**Minimum and Maximum biomass input to biorefinery resource**

```math
\begin{equation*}
	x_{r,t}^{\textrm{B,Bio}} \geq \underline{R_{r}^{\textrm{B,Bio}}} \times y_{r}^{\textrm{B,Bio}} \quad \forall r \in \mathcal{R}, t \in \mathcal{T}
\end{equation*}
```

```math
\begin{equation*}
	x_{r,t}^{\textrm{B,Bio}} \leq \overline{R_{r,t}^{\textrm{B,Bio}}} \times y_{r}^{\textrm{B,Bio}} \quad \forall r \in \mathcal{R}, t \in \mathcal{T}
\end{equation*}
```

**Maximum herb biomass utilization**

The total amount of biomass consumed by biorefinery with herbaceous biomass input cannot be greater than available herbaceous biomass in zone $z$ at time $t$.

```math
\begin{equation*}
	\sum_{r \in z \in herb} x_{r,t}^{\textrm{B,Bio}} \leq  \overline{x}_{z}^{\textrm{\textrm{B,Herb}}} \quad \forall r \in \mathcal{R}, \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

**Maximum wood biomass utilization**

The total amount of biomass consumed by biorefinery with woody biomass input cannot be greater than available woody biomass in zone $z$ at time $t$.

```math
\begin{equation*}
	\sum_{r \in z \in wood} x_{r,t}^{\textrm{B,Bio}} \leq  \overline{x}_{z}^{\textrm{\textrm{B,Wood}}} \quad \forall r \in \mathcal{R}, \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```
"""
function bio_liquid_fuels(EP::Model, inputs::Dict, setup::Dict)
	
	println(" -- Bio Liquid Fuels Production Module")

	dfBioLF = inputs["dfBioLF"]
	BIO_LF_RES_ALL = inputs["BIO_LF_RES_ALL"]

	Z = inputs["Z"]
	T = inputs["T"]
	
	BIO_LF_RES_ALL = inputs["BIO_LF_RES_ALL"]
	BIO_LF_HERB = inputs["BIO_LF_HERB"]
	BIO_LF_WOOD = inputs["BIO_LF_WOOD"]
	BIO_LF_AGRI_RES = inputs["BIO_LF_AGRI_RES"]
	BIO_LF_AGRI_PROCESS_WASTE = inputs["BIO_LF_AGRI_PROCESS_WASTE"]
	BIO_LF_FOREST = inputs["BIO_LF_FOREST"]


	#Initialize variables
	#Power required by bioenergy plant i (MW)
	@variable(EP,vPower_BIO_LF[i=1:BIO_LF_RES_ALL, t = 1:T] >= 0)

	#NG required by bioenergy plant i (MMBtu/h)
	@variable(EP,vNG_BIO_LF[i=1:BIO_LF_RES_ALL, t = 1:T] >= 0)

	#####################################################################################################################################
	#################################################### Biomass Consumed in Biorefinery ################################################
	#####################################################################################################################################

	#Herbaceous energy crops biomass consumed per zone
	@expression(EP, eTotal_herb_biomass_consumed_per_zone_per_time_LF[t in 1:T, z in 1:Z],
	sum(EP[:vBiomass_consumed_per_plant_per_time_LF][i,t] for i in intersect(BIO_LF_HERB, dfBioLF[dfBioLF[!,:Zone].==z,:][!,:R_ID])))

	#Subtract from supply
	EP[:eEnergy_Crops_Herb_Biomass_Supply] -= EP[:eTotal_herb_biomass_consumed_per_zone_per_time_LF]

	#####################################################################################################################################
	#Woody energy crops biomass consumed per zone
	@expression(EP, eTotal_wood_biomass_consumed_per_zone_per_time_LF[t in 1:T, z in 1:Z],
	sum(EP[:vBiomass_consumed_per_plant_per_time_LF][i,t] for i in intersect(BIO_LF_WOOD, dfBioLF[dfBioLF[!,:Zone].==z,:][!,:R_ID])))

	#Subtract from supply
	EP[:eEnergy_Crops_Wood_Biomass_Supply] -= EP[:eTotal_wood_biomass_consumed_per_zone_per_time_LF]

	#####################################################################################################################################
	#Agriculture residue biomass consumed per zone
	@expression(EP, eTotal_agri_res_biomass_consumed_per_zone_per_time_LF[t in 1:T, z in 1:Z],
	sum(EP[:vBiomass_consumed_per_plant_per_time_LF][i,t] for i in intersect(BIO_LF_AGRI_RES, dfBioLF[dfBioLF[!,:Zone].==z,:][!,:R_ID])))

	#Subtract from supply
	EP[:eAgri_Res_Biomass_Supply] -= EP[:eTotal_agri_res_biomass_consumed_per_zone_per_time_LF]

	#####################################################################################################################################
	#Agriculture process waste biomass consumed per zone
	@expression(EP, eTotal_agri_process_waste_biomass_consumed_per_zone_per_time_LF[t in 1:T, z in 1:Z],
	sum(EP[:vBiomass_consumed_per_plant_per_time_LF][i,t] for i in intersect(BIO_LF_AGRI_PROCESS_WASTE, dfBioLF[dfBioLF[!,:Zone].==z,:][!,:R_ID])))

	#Subtract from supply
	EP[:eAgri_Process_Waste_Biomass_Supply] -= EP[:eTotal_agri_process_waste_biomass_consumed_per_zone_per_time_LF]

	#####################################################################################################################################
	#Forest biomass consumed per zone
	@expression(EP, eTotal_forest_biomass_consumed_per_zone_per_time_LF[t in 1:T, z in 1:Z],
	sum(EP[:vBiomass_consumed_per_plant_per_time_LF][i,t] for i in intersect(BIO_LF_FOREST, dfBioLF[dfBioLF[!,:Zone].==z,:][!,:R_ID])))

	#Subtract from supply
	EP[:eForest_Biomass_Supply] -= EP[:eTotal_forest_biomass_consumed_per_zone_per_time_LF]

	#####################################################################################################################################
	########################################## Power/NG consumption and Plant Operational Constraints ###################################
	#####################################################################################################################################
	
	#Power constraint
	@constraint(EP, cBio_LF_Plant_Power_Consumption[i in 1:BIO_LF_RES_ALL, t in 1:T], EP[:vPower_BIO_LF][i,t] == EP[:vBiomass_consumed_per_plant_per_time_LF][i,t] * dfBioLF[!,:Power_consumption_MWh_per_tonne][i])

	#NG constraint
	@constraint(EP, cBio_LF_Plant_NG_Consumption[i in 1:BIO_LF_RES_ALL, t in 1:T], EP[:vNG_BIO_LF][i,t] == EP[:vBiomass_consumed_per_plant_per_time_LF][i,t] * dfBioLF[!,:NG_consumption_MMBtu_per_tonne][i])

	#Include constraint of min bioenergy operation
	@constraint(EP,cMin_biomass_consumed_per_plant_per_time_LF[i in 1:BIO_LF_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time_LF][i,t] >= EP[:vCapacity_BIO_LF_per_type][i] * dfBioLF[!,:Biomass_min_consumption][i])

	#Include constraint of max bioenergy operation
	@constraint(EP,cMax_biomass_consumed_per_plant_per_time_LF[i in 1:BIO_LF_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time_LF][i,t] <= EP[:vCapacity_BIO_LF_per_type][i] * dfBioLF[!,:Biomass_max_consumption][i])

	########################################################### Power Consumption #######################################################

	#Format for power balance
	@expression(EP, eBio_LF_Plant_Power_consumption_per_time_per_zone[t=1:T, z=1:Z], sum(EP[:vPower_BIO_LF][i,t] for i in dfBioLF[dfBioLF[!,:Zone].==z,:][!,:R_ID]))

	#Format for output
	@expression(EP, eBio_LF_Plant_Power_consumption_per_zone_per_time[z=1:Z,t=1:T], sum(EP[:vPower_BIO_LF][i,t] for i in dfBioLF[dfBioLF[!,:Zone].==z,:][!,:R_ID]))

	#Add to power balance to take power away from generated
	EP[:ePowerBalance] += -EP[:eBio_LF_Plant_Power_consumption_per_time_per_zone]

	##For CO2 Polcy constraint right hand side development - power consumption by zone and each time step
	EP[:eBioNetpowerConsumptionByAll] += EP[:eBio_LF_Plant_Power_consumption_per_time_per_zone]

	########################################################### NG Consumption ##########################################################

	if setup["ModelNGSC"] == 1
		#Format for NG balance
		@expression(EP, eBio_LF_Plant_NG_consumption_per_time_per_zone[t=1:T, z=1:Z], sum(EP[:vNG_BIO_LF][i,t] for i in dfBioLF[dfBioLF[!,:Zone].==z,:][!,:R_ID]))

		#Format for output
		@expression(EP, eBio_LF_Plant_NG_consumption_per_zone_per_time[z=1:Z,t=1:T], sum(EP[:vNG_BIO_LF][i,t] for i in dfBioLF[dfBioLF[!,:Zone].==z,:][!,:R_ID]))

		#Add to NG balance
		EP[:eNGBalance] += -EP[:eBio_LF_Plant_NG_consumption_per_time_per_zone]
		EP[:eBESCNetNGConsumptionByAll] += EP[:eBio_LF_Plant_NG_consumption_per_time_per_zone]
	end

	#####################################################################################################################################
	######################################################## Bioenergy Conversion #######################################################
	#####################################################################################################################################
	
	#Original bio liquid fuel production
	@expression(EP,eBiogasoline_original_produced_MMBtu_per_plant_per_time[i in 1:BIO_LF_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time_LF][i,t] * dfBioLF[!,:Biomass_energy_MMBtu_per_tonne][i] * dfBioLF[!,:Biorefinery_efficiency][i] * dfBioLF[!,:BioGasoline_fraction][i])
	@expression(EP,eBiojetfuel_original_produced_MMBtu_per_plant_per_time[i in 1:BIO_LF_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time_LF][i,t] * dfBioLF[!,:Biomass_energy_MMBtu_per_tonne][i] * dfBioLF[!,:Biorefinery_efficiency][i] * dfBioLF[!,:BioJetfuel_fraction][i])
	@expression(EP,eBiodiesel_original_produced_MMBtu_per_plant_per_time[i in 1:BIO_LF_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time_LF][i,t] * dfBioLF[!,:Biomass_energy_MMBtu_per_tonne][i] * dfBioLF[!,:Biorefinery_efficiency][i] * dfBioLF[!,:BioDiesel_fraction][i])

	#Bio electricity credit production
	@expression(EP,eBioLF_Power_credit_produced_MWh_per_plant_per_time[i in 1:BIO_LF_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time_LF][i,t] * dfBioLF[!,:Biomass_energy_MMBtu_per_tonne][i] * dfBioLF[!,:Biorefinery_efficiency][i] * dfBioLF[!,:BioElectricity_fraction][i] * MMBtu_to_MWh)
	@expression(EP,eBioLF_Power_credit_produced_MWh_per_time_per_zone[t in 1:T,z in 1:Z], sum(EP[:eBioLF_Power_credit_produced_MWh_per_plant_per_time][i,t] for i in intersect(1:BIO_LF_RES_ALL, dfBioLF[dfBioLF[!,:Zone].==z,:][!,:R_ID])))

	EP[:ePowerBalance] += EP[:eBioLF_Power_credit_produced_MWh_per_time_per_zone]

	if setup["ModelFlexBioLiquidFuels"] == 1

		@variable(EP, vBioGasoline_To_Jetfuel[i in 1:BIO_LF_RES_ALL, t in 1:T] >= 0 )
		@variable(EP, vBioGasoline_To_Diesel[i in 1:BIO_LF_RES_ALL, t in 1:T] >= 0 )

		@variable(EP, vBioJetfuel_To_Gasoline[i in 1:BIO_LF_RES_ALL, t in 1:T] >= 0 )
		@variable(EP, vBioJetfuel_To_Diesel[i in 1:BIO_LF_RES_ALL, t in 1:T] >= 0 )

		@variable(EP, vBioDiesel_To_Gasoline[i in 1:BIO_LF_RES_ALL, t in 1:T] >= 0 )
		@variable(EP, vBioDiesel_To_Jetfuel[i in 1:BIO_LF_RES_ALL, t in 1:T] >= 0 )

		@expression(EP,eBiogasoline_produced_MMBtu_per_plant_per_time[i in 1:BIO_LF_RES_ALL, t in 1:T], EP[:eBiogasoline_original_produced_MMBtu_per_plant_per_time][i,t] + vBioJetfuel_To_Gasoline[i,t] + vBioDiesel_To_Gasoline[i,t] - vBioGasoline_To_Jetfuel[i,t] - vBioGasoline_To_Diesel[i,t])
		@expression(EP,eBiojetfuel_produced_MMBtu_per_plant_per_time[i in 1:BIO_LF_RES_ALL, t in 1:T], EP[:eBiojetfuel_original_produced_MMBtu_per_plant_per_time][i,t] + vBioGasoline_To_Jetfuel[i,t] + vBioDiesel_To_Jetfuel[i,t] - vBioJetfuel_To_Gasoline[i,t] - vBioJetfuel_To_Diesel[i,t])
		@expression(EP,eBiodiesel_produced_MMBtu_per_plant_per_time[i in 1:BIO_LF_RES_ALL, t in 1:T], EP[:eBiodiesel_original_produced_MMBtu_per_plant_per_time][i,t] + vBioGasoline_To_Diesel[i,t] + vBioJetfuel_To_Diesel[i,t] - vBioDiesel_To_Gasoline[i,t] - vBioDiesel_To_Jetfuel[i,t])

		#Gasoline
		@constraints(EP, begin 
			[i = 1:BIO_LF_RES_ALL, t in 1:T], EP[:vBioGasoline_To_Jetfuel][i,t] <= setup["Max_Bio_Gasoline_To_Jetfuel_Frac"] * EP[:eBiogasoline_original_produced_MMBtu_per_plant_per_time][i,t]
		end)

		@constraints(EP, begin 
			[i = 1:BIO_LF_RES_ALL, t in 1:T], EP[:vBioGasoline_To_Diesel][i,t] <= setup["Max_Bio_Gasoline_To_Diesel_Frac"] * EP[:eBiogasoline_original_produced_MMBtu_per_plant_per_time][i,t]
		end)

		#Jetfuel
		@constraints(EP, begin 
			[i = 1:BIO_LF_RES_ALL, t in 1:T], EP[:vBioJetfuel_To_Gasoline][i,t] <= setup["Max_Bio_Jetfuel_To_Gasoline_Frac"] * EP[:eBiojetfuel_original_produced_MMBtu_per_plant_per_time][i,t]
		end)

		@constraints(EP, begin 
			[i = 1:BIO_LF_RES_ALL, t in 1:T], EP[:vBioJetfuel_To_Diesel][i,t] <= setup["Max_Bio_Jetfuel_To_Diesel_Frac"] * EP[:eBiojetfuel_original_produced_MMBtu_per_plant_per_time][i,t]
		end)

		#Diesel
		@constraints(EP, begin 
			[i = 1:BIO_LF_RES_ALL, t in 1:T], EP[:vBioDiesel_To_Gasoline][i,t] <= setup["Max_Bio_Diesel_To_Gasoline_Frac"] * EP[:eBiodiesel_original_produced_MMBtu_per_plant_per_time][i,t]
		end)

		@constraints(EP, begin 
			[i = 1:BIO_LF_RES_ALL, t in 1:T], EP[:vBioDiesel_To_Jetfuel][i,t] <= setup["Max_Bio_Diesel_To_Jetfuel_Frac"] * EP[:eBiodiesel_original_produced_MMBtu_per_plant_per_time][i,t]
		end)

	else
		#If not using flexible bio liquid fuels
		@expression(EP,eBiogasoline_produced_MMBtu_per_plant_per_time[i in 1:BIO_LF_RES_ALL, t in 1:T], EP[:eBiogasoline_original_produced_MMBtu_per_plant_per_time][i,t])
		@expression(EP,eBiojetfuel_produced_MMBtu_per_plant_per_time[i in 1:BIO_LF_RES_ALL, t in 1:T], EP[:eBiojetfuel_original_produced_MMBtu_per_plant_per_time][i,t])
		@expression(EP,eBiodiesel_produced_MMBtu_per_plant_per_time[i in 1:BIO_LF_RES_ALL, t in 1:T], EP[:eBiodiesel_original_produced_MMBtu_per_plant_per_time][i,t])
	end

	#Zone fuels balance
	@expression(EP,eBiogasoline_produced_MMBtu_per_time_per_zone[t in 1:T, z in 1:Z], sum(EP[:eBiogasoline_produced_MMBtu_per_plant_per_time][i,t] for i in intersect(1:BIO_LF_RES_ALL, dfBioLF[dfBioLF[!,:Zone].==z,:][!,:R_ID])))
	@expression(EP,eBiojetfuel_produced_MMBtu_per_time_per_zone[t in 1:T, z in 1:Z], sum(EP[:eBiojetfuel_produced_MMBtu_per_plant_per_time][i,t] for i in intersect(1:BIO_LF_RES_ALL, dfBioLF[dfBioLF[!,:Zone].==z,:][!,:R_ID])))
	@expression(EP,eBiodiesel_produced_MMBtu_per_time_per_zone[t in 1:T, z in 1:Z], sum(EP[:eBiodiesel_produced_MMBtu_per_plant_per_time][i,t] for i in intersect(1:BIO_LF_RES_ALL, dfBioLF[dfBioLF[!,:Zone].==z,:][!,:R_ID])))
	
	EP[:eSBFGasolineBalance] += EP[:eBiogasoline_produced_MMBtu_per_time_per_zone]
	EP[:eSBFJetfuelBalance] += EP[:eBiojetfuel_produced_MMBtu_per_time_per_zone]
	EP[:eSBFDieselBalance] += EP[:eBiodiesel_produced_MMBtu_per_time_per_zone]

    return EP

end
