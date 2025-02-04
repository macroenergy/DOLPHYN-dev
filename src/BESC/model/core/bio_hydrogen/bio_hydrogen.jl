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
    bio_hydrogen(EP::Model, inputs::Dict, setup::Dict)

This module defines the bio hydrogen production decision variables $x_{r,t}^{\textrm{E,Bio}} \forall r\in \mathcal{R}, t \in \mathcal{T}$, $x_{r,t}^{\textrm{H,Bio}} \forall r\in \mathcal{R}, t \in \mathcal{T}$, $x_{r,t}^{\textrm{Gasoline,Bio}} \forall r\in \mathcal{R}, t \in \mathcal{T}$, $x_{r,t}^{\textrm{Jetfuel,Bio}} \forall r\in \mathcal{R}, t \in \mathcal{T}$, $x_{r,t}^{\textrm{Diesel,Bio}} \forall r\in \mathcal{R}, t \in \mathcal{T}$ representing bio electricity, hydrogen, gasoline, jetfuel, and diesel produced by resource $r$ at time period $t$.

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
function bio_hydrogen(EP::Model, inputs::Dict, setup::Dict)
	
	println(" -- Bio Hydrogen Production Module")

	dfBioH2 = inputs["dfBioH2"]
	BIO_H2_RES_ALL = inputs["BIO_H2_RES_ALL"]

	Z = inputs["Z"]
	T = inputs["T"]
	
	BIO_H2_RES_ALL = inputs["BIO_H2_RES_ALL"]
	BIO_H2_HERB = inputs["BIO_H2_HERB"]
	BIO_H2_WOOD = inputs["BIO_H2_WOOD"]
	BIO_H2_AGRI_RES = inputs["BIO_H2_AGRI_RES"]
	BIO_H2_AGRI_PROCESS_WASTE = inputs["BIO_H2_AGRI_PROCESS_WASTE"]
	BIO_H2_FOREST = inputs["BIO_H2_FOREST"]

	#Initialize variables
	#Power required by bioenergy plant i (MW)
	@variable(EP,vPower_BIO_H2[i=1:BIO_H2_RES_ALL, t = 1:T] >= 0)

	#NG required by bioenergy plant i (MMBtu/h)
	@variable(EP,vNG_BIO_H2[i=1:BIO_H2_RES_ALL, t = 1:T] >= 0)

	#####################################################################################################################################
	#################################################### Biomass Consumed in Biorefinery ################################################
	#####################################################################################################################################

	#Herbaceous energy crops biomass consumed per zone
	@expression(EP, eTotal_herb_biomass_consumed_per_zone_per_time_H2[t in 1:T, z in 1:Z],
	sum(EP[:vBiomass_consumed_per_plant_per_time_H2][i,t] for i in intersect(BIO_H2_HERB, dfBioH2[dfBioH2[!,:Zone].==z,:][!,:R_ID])))

	#Subtract from supply
	EP[:eEnergy_Crops_Herb_Biomass_Supply] -= EP[:eTotal_herb_biomass_consumed_per_zone_per_time_H2]

	#####################################################################################################################################
	#Woody energy crops biomass consumed per zone
	@expression(EP, eTotal_wood_biomass_consumed_per_zone_per_time_H2[t in 1:T, z in 1:Z],
	sum(EP[:vBiomass_consumed_per_plant_per_time_H2][i,t] for i in intersect(BIO_H2_WOOD, dfBioH2[dfBioH2[!,:Zone].==z,:][!,:R_ID])))

	#Subtract from supply
	EP[:eEnergy_Crops_Wood_Biomass_Supply] -= EP[:eTotal_wood_biomass_consumed_per_zone_per_time_H2]

	#####################################################################################################################################
	#Agriculture residue biomass consumed per zone
	@expression(EP, eTotal_agri_res_biomass_consumed_per_zone_per_time_H2[t in 1:T, z in 1:Z],
	sum(EP[:vBiomass_consumed_per_plant_per_time_H2][i,t] for i in intersect(BIO_H2_AGRI_RES, dfBioH2[dfBioH2[!,:Zone].==z,:][!,:R_ID])))

	#Subtract from supply
	EP[:eAgri_Res_Biomass_Supply] -= EP[:eTotal_agri_res_biomass_consumed_per_zone_per_time_H2]

	#####################################################################################################################################
	#Agriculture process waste biomass consumed per zone
	@expression(EP, eTotal_agri_process_waste_biomass_consumed_per_zone_per_time_H2[t in 1:T, z in 1:Z],
	sum(EP[:vBiomass_consumed_per_plant_per_time_H2][i,t] for i in intersect(BIO_H2_AGRI_PROCESS_WASTE, dfBioH2[dfBioH2[!,:Zone].==z,:][!,:R_ID])))

	#Subtract from supply
	EP[:eAgri_Process_Waste_Biomass_Supply] -= EP[:eTotal_agri_process_waste_biomass_consumed_per_zone_per_time_H2]

	#####################################################################################################################################
	#Forest biomass consumed per zone
	@expression(EP, eTotal_forest_biomass_consumed_per_zone_per_time_H2[t in 1:T, z in 1:Z],
	sum(EP[:vBiomass_consumed_per_plant_per_time_H2][i,t] for i in intersect(BIO_H2_FOREST, dfBioH2[dfBioH2[!,:Zone].==z,:][!,:R_ID])))

	#Subtract from supply
	EP[:eForest_Biomass_Supply] -= EP[:eTotal_forest_biomass_consumed_per_zone_per_time_H2]
	
	#####################################################################################################################################
	########################################## Power/NG consumption and Plant Operational Constraints ###################################
	#####################################################################################################################################
	
	#Power constraint
	@constraint(EP, cBio_H2_Plant_Power_Consumption[i in 1:BIO_H2_RES_ALL, t in 1:T], EP[:vPower_BIO_H2][i,t] == EP[:vBiomass_consumed_per_plant_per_time_H2][i,t] * dfBioH2[!,:Power_consumption_MWh_per_tonne][i])

	#NG constraint
	@constraint(EP, cBio_H2_Plant_NG_Consumption[i in 1:BIO_H2_RES_ALL, t in 1:T], EP[:vNG_BIO_H2][i,t] == EP[:vBiomass_consumed_per_plant_per_time_H2][i,t] * dfBioH2[!,:NG_consumption_MMBtu_per_tonne][i])

	#Include constraint of min bioenergy operation
	@constraint(EP,cMin_biomass_consumed_per_plant_per_time_H2[i in 1:BIO_H2_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time_H2][i,t] >= EP[:vCapacity_BIO_H2_per_type][i] * dfBioH2[!,:Biomass_min_consumption][i])

	#Include constraint of max bioenergy operation
	@constraint(EP,cMax_biomass_consumed_per_plant_per_time_H2[i in 1:BIO_H2_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time_H2][i,t] <= EP[:vCapacity_BIO_H2_per_type][i] * dfBioH2[!,:Biomass_max_consumption][i])

	########################################################### Power Consumption #######################################################

	#Format for power balance
	@expression(EP, eBio_H2_Plant_Power_consumption_per_time_per_zone[t=1:T, z=1:Z], sum(EP[:vPower_BIO_H2][i,t] for i in dfBioH2[dfBioH2[!,:Zone].==z,:][!,:R_ID]))

	#Format for output
	@expression(EP, eBio_H2_Plant_Power_consumption_per_zone_per_time[z=1:Z,t=1:T], sum(EP[:vPower_BIO_H2][i,t] for i in dfBioH2[dfBioH2[!,:Zone].==z,:][!,:R_ID]))

	#Add to power balance to take power away from generated
	EP[:ePowerBalance] += -EP[:eBio_H2_Plant_Power_consumption_per_time_per_zone]

	##For CO2 Polcy constraint right hand side development - power consumption by zone and each time step
	EP[:eBioNetpowerConsumptionByAll] += EP[:eBio_H2_Plant_Power_consumption_per_time_per_zone]

	########################################################### NG Consumption ##########################################################

	if setup["ModelNGSC"] == 1
		#Format for NG balance
		@expression(EP, eBio_H2_Plant_NG_consumption_per_time_per_zone[t=1:T, z=1:Z], sum(EP[:vNG_BIO_H2][i,t] for i in dfBioH2[dfBioH2[!,:Zone].==z,:][!,:R_ID]))

		#Format for output
		@expression(EP, eBio_H2_Plant_NG_consumption_per_zone_per_time[z=1:Z,t=1:T], sum(EP[:vNG_BIO_H2][i,t] for i in dfBioH2[dfBioH2[!,:Zone].==z,:][!,:R_ID]))

		#Add to NG balance
		EP[:eNGBalance] += -EP[:eBio_H2_Plant_NG_consumption_per_time_per_zone]
		EP[:eBESCNetNGConsumptionByAll] += EP[:eBio_H2_Plant_NG_consumption_per_time_per_zone]
	end
	
	#####################################################################################################################################
	######################################################## Bioenergy Conversion #######################################################
	#####################################################################################################################################
	
	#Bio hydrogen production
	@expression(EP,eBioH2_produced_tonne_per_plant_per_time[i in 1:BIO_H2_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time_H2][i,t] * dfBioH2[!,:Biomass_energy_MMBtu_per_tonne][i] * dfBioH2[!,:Biorefinery_efficiency][i] * dfBioH2[!,:BioH2_fraction][i] * MMBtu_to_MWh/H2_HHV)
	@expression(EP,eBioH2_produced_tonne_per_time_per_zone[t in 1:T,z in 1:Z], sum(EP[:eBioH2_produced_tonne_per_plant_per_time][i,t] for i in intersect(1:BIO_H2_RES_ALL, dfBioH2[dfBioH2[!,:Zone].==z,:][!,:R_ID])))

	EP[:eH2Balance] += EP[:eBioH2_produced_tonne_per_time_per_zone]

	#Bio electricity credit production
	@expression(EP,eBioH2_Power_credit_produced_MWh_per_plant_per_time[i in 1:BIO_H2_RES_ALL, t in 1:T], EP[:vBiomass_consumed_per_plant_per_time_H2][i,t] * dfBioH2[!,:Biomass_energy_MMBtu_per_tonne][i] * dfBioH2[!,:Biorefinery_efficiency][i] * dfBioH2[!,:BioElectricity_fraction][i] * MMBtu_to_MWh)
	@expression(EP,eBioH2_Power_credit_produced_MWh_per_time_per_zone[t in 1:T,z in 1:Z], sum(EP[:eBioH2_Power_credit_produced_MWh_per_plant_per_time][i,t] for i in intersect(1:BIO_H2_RES_ALL, dfBioH2[dfBioH2[!,:Zone].==z,:][!,:R_ID])))

	EP[:ePowerBalance] += EP[:eBioH2_Power_credit_produced_MWh_per_time_per_zone]


    return EP

end
