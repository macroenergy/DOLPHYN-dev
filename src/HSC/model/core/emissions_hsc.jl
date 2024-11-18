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
    emissions_hsc(EP::Model, inputs::Dict, setup::Dict)

This function creates expression to add the CO2 emissions for hydrogen supply chain in each zone, which is subsequently added to the total emissions.

**Cost expressions**

```math
\begin{equation*}
    \textrm{C}^{\textrm{H,EMI}} = \omega_t \times \sum_{z \in \mathcal{Z}} \sum_{t \in \mathcal{T}} \textrm{c}_{z}^{\textrm{H,EMI}} x_{z,t}^{\textrm{H,EMI}}
\end{equation*}
```
"""
function emissions_hsc(EP::Model, inputs::Dict, setup::Dict)

    print_and_log(" -- H2 Emissions Module for CO2 Policy modularization")

    dfH2Gen = inputs["dfH2Gen"]

    H = inputs["H2_RES_ALL"]     # Number of resources (generators, storage, flexible demand)
    T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Number of zones

    # HOTFIX - If CCS_Rate is not in the dfGen, then add it and set it to 0
	if "CCS_Rate" ∉ names(dfH2Gen)
		dfH2Gen[!,:CCS_Rate] .= 0
	end

    # Adjustment of Fuel_CO2 units carried out in load_fuels_data.jl
    @expression(
        EP,
        eH2EmissionsByPlant[k = 1:H, t = 1:T],
        if (dfH2Gen[!, :H2Stor_Charge_MMBtu_p_tonne][k] > 0) # IF storage consumes fuel during charging or not - not a default parameter input so hence the use of if condition
            inputs["fuel_CO2"][dfH2Gen[!, :Fuel][k]] *
            dfH2Gen[!, :etaFuel_MMBtu_p_tonne][k] *
            EP[:vH2Gen][k, t] * (1-dfH2Gen[!, :CCS_Rate][k])+
            inputs["fuel_CO2"][dfH2Gen[!, :Fuel][k]] *
            dfH2Gen[!, :H2Stor_Charge_MMBtu_p_tonne][k] *
            EP[:vH2_CHARGE_STOR][k, t] * (1-dfH2Gen[!, :CCS_Rate][k])
        else
            inputs["fuel_CO2"][dfH2Gen[!, :Fuel][k]] *
            dfH2Gen[!, :etaFuel_MMBtu_p_tonne][k] *
            EP[:vH2Gen][k, t] * (1-dfH2Gen[!, :CCS_Rate][k])
        end
    )

    @expression(
        EP,
        eCO2CaptureByH2Plant[k = 1:H, t = 1:T],
        if (dfH2Gen[!, :H2Stor_Charge_MMBtu_p_tonne][k] > 0) # IF storage consumes fuel during charging or not - not a default parameter input so hence the use of if condition
            inputs["fuel_CO2"][dfH2Gen[!, :Fuel][k]] *
            dfH2Gen[!, :etaFuel_MMBtu_p_tonne][k] *
            EP[:vH2Gen][k, t] * 
            (dfH2Gen[!, :CCS_Rate][k]) +
            inputs["fuel_CO2"][dfH2Gen[!, :Fuel][k]] *
            dfH2Gen[!, :H2Stor_Charge_MMBtu_p_tonne][k] *
            EP[:vH2_CHARGE_STOR][k, t] * 
            (dfH2Gen[!, :CCS_Rate][k])
        else
            inputs["fuel_CO2"][dfH2Gen[!, :Fuel][k]] *
            dfH2Gen[!, :etaFuel_MMBtu_p_tonne][k] *
            EP[:vH2Gen][k, t] * 
            (dfH2Gen[!, :CCS_Rate][k])
        end
    )

    @expression(EP, eHydrogen_CO2_captured_per_plant_per_time[y=1:H,t=1:T], EP[:eCO2CaptureByH2Plant][y,t])
    @expression(EP, eHydrogen_CO2_captured_per_zone_per_time[z=1:Z, t=1:T], sum(eHydrogen_CO2_captured_per_plant_per_time[y,t] for y in dfH2Gen[(dfH2Gen[!,:Zone].==z),:R_ID]))
    @expression(EP, eHydrogen_CO2_captured_per_time_per_zone[t=1:T, z=1:Z], sum(eHydrogen_CO2_captured_per_plant_per_time[y,t] for y in dfH2Gen[(dfH2Gen[!,:Zone].==z),:R_ID]))

    if setup["ModelNGSC"] == 1
        #If NGSC is modeled, not using fuel from the fuels input, so have to account for CO2 captured from CCS of NG utilization in plant separately
        @expression(EP,eNGCO2CaptureByH2Plant[k = 1:H, t = 1:T],
            if (dfH2Gen[!, :H2Stor_Charge_NG_MMBtu_p_tonne][k] > 0) # IF storage consumes fuel during charging or not - not a default parameter input so hence the use of if condition
                inputs["ng_co2_per_mmbtu"] *
                dfH2Gen[!, :etaNG_MMBtu_p_tonne][k] *
                EP[:vH2Gen][k, t] * 
                (dfH2Gen[!, :CCS_Rate][k]) +
                inputs["ng_co2_per_mmbtu"] *
                dfH2Gen[!, :H2Stor_Charge_NG_MMBtu_p_tonne][k] *
                EP[:vH2_CHARGE_STOR][k, t] * 
                (dfH2Gen[!, :CCS_Rate][k])
            else
                inputs["ng_co2_per_mmbtu"] *
                dfH2Gen[!, :etaNG_MMBtu_p_tonne][k] *
                EP[:vH2Gen][k, t] * 
                (dfH2Gen[!, :CCS_Rate][k])
            end
        )
        @expression(EP, eHydrogen_NG_CO2_captured_per_plant_per_time[y=1:H,t=1:T], EP[:eNGCO2CaptureByH2Plant][y,t])
        @expression(EP, eHydrogen_NG_CO2_captured_per_zone_per_time[z=1:Z, t=1:T], sum(eHydrogen_NG_CO2_captured_per_plant_per_time[y,t] for y in dfH2Gen[(dfH2Gen[!,:Zone].==z),:R_ID]))
        @expression(EP, eHydrogen_NG_CO2_captured_per_time_per_zone[t=1:T, z=1:Z], sum(eHydrogen_NG_CO2_captured_per_plant_per_time[y,t] for y in dfH2Gen[(dfH2Gen[!,:Zone].==z),:R_ID]))

        ### For output purpose only
		#Although CO2 emissions are accounted for in total NG utilization, we still want to show how much raw CO2 H2 sector (Before CCS) produces in the output files
        @expression(EP,eNGCO2EmissionByH2Plant[k = 1:H, t = 1:T],
            if (dfH2Gen[!, :H2Stor_Charge_NG_MMBtu_p_tonne][k] > 0) # IF storage consumes fuel during charging or not - not a default parameter input so hence the use of if condition
                inputs["ng_co2_per_mmbtu"] *
                dfH2Gen[!, :etaNG_MMBtu_p_tonne][k] *
                EP[:vH2Gen][k, t] +
                inputs["ng_co2_per_mmbtu"] *
                dfH2Gen[!, :H2Stor_Charge_NG_MMBtu_p_tonne][k] *
                EP[:vH2_CHARGE_STOR][k, t]
            else
                inputs["ng_co2_per_mmbtu"] *
                dfH2Gen[!, :etaNG_MMBtu_p_tonne][k] *
                EP[:vH2Gen][k, t]
            end
        )
        @expression(EP, eHydrogen_NG_CO2_emission_per_plant_per_time[y=1:H,t=1:T], EP[:eNGCO2EmissionByH2Plant][y,t])
        @expression(EP, eHydrogen_NG_CO2_emission_per_zone_per_time[z=1:Z, t=1:T], sum(eHydrogen_NG_CO2_emission_per_plant_per_time[y,t] for y in dfH2Gen[(dfH2Gen[!,:Zone].==z),:R_ID]))
    end

    @expression(
        EP,
        eH2EmissionsByZone[z = 1:Z, t = 1:T],
        sum(eH2EmissionsByPlant[y, t] for y in dfH2Gen[(dfH2Gen[!, :Zone].==z), :R_ID])
    )

    # If CO2 price is implemented in HSC balance or Power Balance and SystemCO2 constraint is active (independent or joint), then need to add cost penalty due to CO2 prices
    if (setup["H2CO2Cap"] == 4 && setup["SystemCO2Constraint"] == 1)
        # Use CO2 price for HSC supply chain
        # Emissions penalty by zone - needed to report zonal cost breakdown
        @expression(
            EP,
            eCH2EmissionsPenaltybyZone[z = 1:Z],
            sum(
                inputs["omega"][t] * sum(
                    eH2EmissionsByZone[z, t] * inputs["dfH2CO2Price"][z, cap] for
                    cap in findall(x -> x == 1, inputs["dfH2CO2CapZones"][z, :])
                ) for t = 1:T
            )
        )
        # Sum over each policy type, each zone and each time step
        @expression(
            EP,
            eCH2EmissionsPenaltybyPolicy[cap = 1:inputs["H2NCO2Cap"]],
            sum(
                inputs["omega"][t] * sum(
                    eH2EmissionsByZone[z, t] * inputs["dfH2CO2Price"][z, cap] for
                    z in findall(x -> x == 1, inputs["dfH2CO2CapZones"][:, cap])
                ) for t = 1:T
            )
        )
        # Total emissions penalty across all policy constraints
        @expression(
            EP,
            eCH2GenTotalEmissionsPenalty,
            sum(eCH2EmissionsPenaltybyPolicy[cap] for cap = 1:inputs["H2NCO2Cap"])
        )

        # Add total emissions penalty associated with direct emissions from H2 generation technologies
        EP[:eObj] += eCH2GenTotalEmissionsPenalty


    elseif (setup["CO2Cap"] == 4 && setup["SystemCO2Constraint"] == 2)
        # Use CO2 price for power system as the global CO2 price
        # Emissions penalty by zone - needed to report zonal cost breakdown
        @expression(
            EP,
            eCH2EmissionsPenaltybyZone[z = 1:Z],
            sum(
                inputs["omega"][t] * sum(
                    eH2EmissionsByZone[z, t] * inputs["dfCO2Price"][z, cap] for
                    cap in findall(x -> x == 1, inputs["dfCO2CapZones"][z, :])
                ) for t = 1:T
            )
        )
        # Sum over each policy type, each zone and each time step
        @expression(
            EP,
            eCH2EmissionsPenaltybyPolicy[cap = 1:inputs["NCO2Cap"]],
            sum(
                inputs["omega"][t] * sum(
                    eH2EmissionsByZone[z, t] * inputs["dfCO2Price"][z, cap] for
                    z in findall(x -> x == 1, inputs["dfCO2CapZones"][:, cap])
                ) for t = 1:T
            )
        )
        @expression(
            EP,
            eCH2GenTotalEmissionsPenalty,
            sum(eCH2EmissionsPenaltybyPolicy[cap] for cap = 1:inputs["NCO2Cap"])
        )

        # Add total emissions penalty associated with direct emissions from H2 generation technologies
        EP[:eObj] += eCH2GenTotalEmissionsPenalty

    end

    return EP
end
