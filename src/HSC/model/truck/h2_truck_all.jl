"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
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
    h2_truck_all(EP::Model, inputs::Dict, setup::Dict)

This function defines a series of operating variables,expressions and constraints in truck scheduling and routing model.

**Variables**

The sum of full and empty trucks should equal the total number of invested trucks.
```math
\begin{equation*}
    v_{j, t}^{\textrm{F}}+v_{j, t}^{\textrm{E}}=V_{j} \quad \forall j \in \mathbb{J}, t \in \mathbb{T}
\end{equation*}    
```
    
The full (empty) trucks include full (empty) trucks in transit and staying at each zones.
```math
\begin{aligned}
    v_{j, t}^{\textrm{F}}=\sum_{z \rightarrow z^{\prime} \in \mathbb{B}} u_{z \rightarrow z^{\prime}, t}^{\textrm{F}}+\sum_{z \in \mathbb{Z}} q_{z, j, t}^{\textrm{F}} \\
    v_{j, t}^{\textrm{E}}=\sum_{z \rightarrow z^{\prime} \in \mathbb{B}} u_{z \rightarrow z^{\prime}, t}^{\textrm{E}}+\sum_{z \in \mathbb{Z}} q_{z, j, t}^{\textrm{E}} \quad \forall j \in \mathbb{J}, t \in \mathbb{T}
\end{aligned}    
```
    
**Expressions**
    
The change of the total number of full (empty) available trucks at zone z should equal the number of charged (discharged) trucks minus the number of discharged (charged) trucks at zone z plus the number of full (empty) trucks that just arrived minus the number of full (empty) trucks that just departed:
```math
\begin{aligned}
    q_{z, j, t}^{\textrm{F}}-q_{z, j, t-1}^{\textrm{F}}=& q_{z, j, t}^{\textrm{CHA}}-q_{z, j, t}^{\textrm{DIS}} \\
    &+\sum_{z^{\prime} \in \mathbb{Z}}\left(-x_{z \rightarrow z^{\prime}, j, t-1}^{\textrm{F}}+y_{z \rightarrow z^{\prime}, j, t-1}^{\textrm{F}}\right) \\
    q_{z, j, t}^{\textrm{E}}-q_{z, j, t-1}^{\textrm{E}}=&-q_{z, j, t}^{\textrm{CHA}}+q_{z, j, t}^{\textrm{DIS}} \\
    &+\sum_{z^{\prime} \in \mathbb{Z}}\left(-x_{z \rightarrow z^{\prime}, j, t-1}^{\textrm{E}}+y_{z \rightarrow z^{\prime} j, t-1}^{\textrm{E}}\right) \\
    \quad \forall z \in \mathbb{Z}, j \in \mathbb{J}, t \in \mathbb{T}
\end{aligned}
```
    
The change of the total number of full (empty) trucks in transit from zone z to zone zz should equal the number of full (empty) trucks that just departed from zone z minus the number of full (empty) trucks that just arrived at zone zz:
```math
\begin{aligned}
    u_{z \rightarrow z^{\prime}, j, t}^{\textrm{F}}-u_{z \rightarrow z^{\prime}, j, t-1}^{\textrm{F}} & =x_{z \rightarrow z^{\prime}, j, t-1}^{\textrm{F}}-y_{z \rightarrow z^{\prime}, j, t-1}^{\textrm{F}} \\
    u_{z \rightarrow z^{\prime}, j, t}^{\textrm{E}}-u_{z \rightarrow z^{\prime}, j, t-1}^{\textrm{E}} & =x_{z \rightarrow z^{\prime}, j, t-1}^{\textrm{E}}-y_{z \rightarrow z^{\prime}, j, t-1}^{\textrm{E}} \\
    & \quad \forall z \rightarrow z^{\prime} \in \mathbb{B}, j \in \mathbb{J}, t \in \mathbb{T}
\end{aligned}    
```
    
The amount of H2 delivered to zone z should equal the truck capacity times the number of discharged trucks minus the number of charged trucks, adjusted by theH2 boil-off loss during truck transportation and compression.
```math
\begin{aligned}
    x_{z, j, t}^{\textrm{H,TRU}}=\left[\left(1-\sigma_{j}\right) q_{z, j, t}^{\textrm{DIS}}-q_{z, j, t}^{\textrm{CHA}}\right] \overline{\textrm{E}}_{j}^{\textrm{H,TRU}} \\
    \quad \forall z \rightarrow z^{\prime} \in \mathbb{B}, j \in \mathbb{J}, t \in \mathbb{T}
\end{aligned}    
```

Contributions to the hydrogen balance expression from gas trucking flows are defined as:
HydrogenBalGas_{GEN} = \sum_{k \in \mathcal{UC}} x_{k,z,t}^{\textrm{H,GEN}}

```math
\begin{equation*}
	HydrogenBalGas_{TRU} = \sum_{j \in \mathcal{J}} x_{j,z,t}^{\textrm{H,TRU,Gas}} \quad \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```
Liquid hydrogen balance contributions are defined in a similar manner, for liquid trucks: 

```math
\begin{equation*}
	HydrogenBalLiq_{TRU} = \sum_{j \in \mathcal{J}} x_{j,z,t}^{\textrm{H,TRU,Liq}}  \quad \forall z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

The minimum travelling time delay is modelled as follows.
```math
\begin{aligned}
    u_{z \rightarrow z^{\prime}, j, t}^{\textrm{F}} \geq \sum_{e=t-\Delta_{z \rightarrow z^{\prime}+1}}^{e=t} x_{z \rightarrow z^{\prime}, j, e}^{\textrm{F}} \\
    u_{z \rightarrow z^{\prime}, j, t}^{\textrm{E}} \geq \sum_{e=t-\Delta_{z \rightarrow z^{\prime}+1}}^{e=t} x_{z \rightarrow z, j, e}^{\textrm{E}} \quad \forall z \rightarrow z^{\prime} \in \mathbb{B}, j \in \mathbb{J}, t \in \mathbb{T}
\end{aligned}
```
    
```math
\begin{aligned}
    u_{z \rightarrow z^{\prime}, j, t}^{\textrm{F}} \geq \sum_{e=t+1}^{e=t+\Delta_{z \rightarrow z^{\prime}}} y_{z \rightarrow z^{\prime} j, e}^{\textrm{F}} \\
    u_{z \rightarrow z, j, t}^{\textrm{E}} \geq \sum_{e=t+1}^{e=t+\Delta_{z \rightarrow z^{\prime}}} y_{z \rightarrow z^{\prime} j, e}^{\textrm{E}} \\
    \quad \forall z \rightarrow z^{\prime} \in \mathbb{B}, j \in \mathbb{J}, t \in \mathbb{T}
\end{aligned}   
```

**Constraints**
    
The charging capability of truck stations is limited by their compression or liquefaction capacity.
```math
\begin{equation*}
    q_{z, j, t}^{\textrm{CHA}} \overline{\textrm{E}}_{j}^{\textrm{H,TRU}} \leq H_{z, j}^{\textrm{H,TRU}} \quad \forall z \in \mathbb{Z}, j \in \mathbb{J}, t \in \mathbb{T}
\end{equation*}    
```   
"""
function h2_truck_all(EP::Model, inputs::Dict, setup::Dict)

    # Setup variables, constraints, and expressions common to all hydrogen truck resources
    print_and_log(" -- H2 Truck Core Resources Module")

    dfH2Truck = inputs["dfH2Truck"]
    H2_TRUCK_TYPES = inputs["H2_TRUCK_TYPES"] # Set of h2 truck types
    H2_TRUCK_GAS = inputs["H2_TRUCK_GAS"]
    H2_TRUCK_LIQ = inputs["H2_TRUCK_LIQ"]

    T = inputs["T"] # Number of time steps (hours)
    Z = inputs["Z"] # Number of zones
    max_route_time = zeros(length(H2_TRUCK_TYPES))

    START_SUBPERIODS = inputs["START_SUBPERIODS"] # Starting subperiod index for each representative period
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"] # Index of interior subperiod for each representative period

    fuels = inputs["fuels"]
    fuel_costs = inputs["fuel_costs"]
    fuel_CO2 = inputs["fuel_CO2"]

    # Set max time for a trucking routes based on speed
    for j in H2_TRUCK_TYPES
        max_route_time[j] = setup["H2TrucksMaxDistance"]/dfH2Truck[!, :"AvgTruckSpeed_mile_per_hour"][j]
    end

    ### Variables ###

    # Truck flow volume [MWh] through type 'j' at time 't' on zone 'z'
    @variable(EP, vH2TruckFlow[z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T])

    # Number of available full truck type 'j' in transit at time 't' on zone 'z'
    @variable(EP, vH2Navail_full[z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T] >= 0)
    # Number of travel, arrive and deaprt full truck type 'j' in transit at time 't' from zone 'zz' to 'z'
    @variable(EP, vH2Ntravel_full[zz = 1:Z, z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T] >= 0)
    @variable(EP, vH2Narrive_full[zz = 1:Z, z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T] >= 0)
    @variable(EP, vH2Ndepart_full[zz = 1:Z, z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T] >= 0)

    # Number of available empty truck type 'j' in transit at time 't' on zone 'z'
    @variable(EP, vH2Navail_empty[z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T] >= 0)
    # Number of travel, arrive and deaprt empty truck type 'j' in transit at time 't' from zone 'zz' to 'z'
    @variable(EP, vH2Ntravel_empty[zz = 1:Z, z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T] >= 0)
    @variable(EP, vH2Narrive_empty[zz = 1:Z, z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T] >= 0)
    @variable(EP, vH2Ndepart_empty[zz = 1:Z, z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T] >= 0)

    # Number of charged truck type 'j' at time 't' on zone 'z'
    @variable(EP, vH2Ncharged[z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T] >= 0)
    # Number of discharged truck type 'j' at time 't' on zone 'z'
    @variable(EP, vH2Ndischarged[z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T] >= 0)
    # Number of full truck type 'j' at time 't'
    @variable(EP, vH2N_full[j in H2_TRUCK_TYPES, t = 1:T] >= 0)
    # Number of empty truck type 'j' at time 't'
    @variable(EP, vH2N_empty[j in H2_TRUCK_TYPES, t = 1:T] >= 0)

    ### Expressions ###
    ## Objective Function Expressions ##

    #Operating expenditure for truck type "j" during hour "t" on route "zz" -> "z"
    #  ParameterScale = 1 --> objective function is in million $
    #  ParameterScale = 0 --> objective function is in $

    # Operating expenditure for full and empty trucks
    if setup["ParameterScale"] == 1
        @expression(
            EP,
            OPEX_Truck,
            sum(
                inputs["omega"][t] *
                ((vH2Narrive_full[zz, z, j, t] + vH2Narrive_empty[zz, z, j, t]) *
                inputs["fuel_costs"][dfH2Truck[!, :Fuel][j]][t] *
                dfH2Truck[!, :Fuel_MMBTU_per_mile][j] + 
                vH2Narrive_full[zz, z, j, t] * dfH2Truck[!, :H2TruckUnitOpex_per_mile_full][j] +
                vH2Narrive_empty[zz, z, j, t] * dfH2Truck[!, :H2TruckUnitOpex_per_mile_empty][j]) * 
                inputs["RouteLength"][zz, z] for
                zz = 1:Z, z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T if zz != z
            ) / ModelScalingFactor^2
        )
    else
        @expression(
            EP,
            OPEX_Truck,
            sum(
                inputs["omega"][t] *
                ((vH2Narrive_full[zz, z, j, t] + vH2Narrive_empty[zz, z, j, t]) *
                inputs["fuel_costs"][dfH2Truck[!, :Fuel][j]][t] *
                dfH2Truck[!, :Fuel_MMBTU_per_mile][j] +
                vH2Narrive_full[zz, z, j, t] * dfH2Truck[!, :H2TruckUnitOpex_per_mile_full][j] +
                vH2Narrive_empty[zz, z, j, t] * dfH2Truck[!, :H2TruckUnitOpex_per_mile_empty][j]) * 
                inputs["RouteLength"][zz, z] for
                zz = 1:Z, z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T if zz != z
            )
        )
    end
    EP[:eObj] += OPEX_Truck

    # Operating expenditure for truck h2 compression
    if setup["ParameterScale"] == 1
        @expression(
            EP,
            OPEX_Truck_Compression,
            sum(
                inputs["omega"][t] *
                (vH2TruckFlow[z, j, t] * dfH2Truck[!, :H2TruckCompressionUnitOpex][j]) for
                z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T
            )
        ) / ModelScalingFactor^2
    else
        @expression(
            EP,
            OPEX_Truck_Compression,
            sum(
                inputs["omega"][t] *
                (vH2TruckFlow[z, j, t] * dfH2Truck[!, :H2TruckCompressionUnitOpex][j]) for
                z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T
            )
        )
    end
    EP[:eObj] += OPEX_Truck_Compression
    ## End Objective Function Expressions ##

    ## Balance Expressions ##
    # H2 Power Compression Consumption balance
    @expression(
        EP,
        ePowerbalanceH2TruckCompression[t = 1:T, z = 1:Z],
        if setup["ParameterScale"] == 1 # If ParameterScale = 1, power system operation/capacity modeled in GWh rather than MWh
            sum(
                vH2Ncharged[z, j, t] *
                dfH2Truck[!, :TruckCap_MWh_per_unit][j] *
                dfH2Truck[!, :H2TruckCompressionEnergy][j] for j in H2_TRUCK_TYPES
            ) / ModelScalingFactor
        else
            sum(
                vH2Ncharged[z, j, t] *
                dfH2Truck[!, :TruckCap_MWh_per_unit][j] *
                dfH2Truck[!, :H2TruckCompressionEnergy][j] for j in H2_TRUCK_TYPES
            )
        end
    )

    EP[:ePowerBalance_HSC] += -ePowerbalanceH2TruckCompression
    EP[:eH2NetpowerConsumptionByAll] += ePowerbalanceH2TruckCompression
    
    # H2 Power Truck Travelling Consumption balance
    @expression(
        EP,
        ePowerbalanceH2TruckTravel[t = 1:T, z = 1:Z],
        if setup["ParameterScale"] == 1
            sum(
                (vH2Narrive_full[zz, z, j, t] + vH2Narrive_empty[zz, z, j, t]) *
                dfH2Truck[!, :Power_MW_per_mile][j] *
                inputs["RouteLength"][zz, z] for
                zz = 1:Z, j in H2_TRUCK_TYPES if zz != z
            ) / ModelScalingFactor
        else
            sum(
                (vH2Narrive_full[zz, z, j, t] + vH2Narrive_empty[zz, z, j, t]) *
                dfH2Truck[!, :Power_MW_per_mile][j] *
                inputs["RouteLength"][zz, z] for
                zz = 1:Z, j in H2_TRUCK_TYPES if zz != z
            )
        end
    )

    EP[:ePowerBalance_HSC] += -ePowerbalanceH2TruckTravel
    EP[:eH2NetpowerConsumptionByAll] += ePowerbalanceH2TruckTravel

    # H2 balance
    @expression(
        EP,
        eH2TruckFlow[t = 1:T, z = 1:Z],
        sum(vH2TruckFlow[z, j, t] for j in H2_TRUCK_GAS)
    )
    EP[:eH2Balance] += eH2TruckFlow

    # H2 liquid balance
    if setup["ModelH2Liquid"]==1
        @expression(
            EP,
            eH2TruckLiqFlow[t = 1:T, z = 1:Z],
            sum(vH2TruckFlow[z, j, t] for j in H2_TRUCK_LIQ)
        )
        EP[:eH2LiqBalance] += eH2TruckLiqFlow
    end

    # H2 Truck Traveling Consumption balance
    @expression(
        EP,
        eH2TruckTravelConsumption[t = 1:T, z = 1:Z],
        sum(
            (vH2Narrive_full[zz, z, j, t] + vH2Narrive_empty[zz, z, j, t]) *
            dfH2Truck[!, :H2_MWh_per_mile][j] *
            inputs["RouteLength"][zz, z] for
            zz = 1:Z, j in H2_TRUCK_TYPES if zz != z
        )
    )

    EP[:eH2Balance] += -eH2TruckTravelConsumption

    # H2 truck emission penalty
    @expression(
        EP,
        Truck_carbon_emission,
        sum(
            inputs["omega"][t] *
            (vH2Narrive_full[zz, z, j, t] + vH2Narrive_empty[zz, z, j, t]) *
            inputs["fuel_CO2"][dfH2Truck[!, :Fuel][j]] *
            dfH2Truck[!, :Fuel_MMBTU_per_mile][j] *
            inputs["RouteLength"][zz, z] for
            zz = 1:Z, z = 1:Z, j in H2_TRUCK_TYPES, t = 1:T if zz != z
        )
    )
    # EP[:eCarbonBalance] += Truck_carbon_emission
    ## End Balance Expressions ##
    ### End Expressions ###

    ### Constraints ###

    ## Total number
    @constraint(
        EP,
        cH2TruckTotalNumber[j in H2_TRUCK_TYPES, t in 1:T],
        vH2N_full[j, t] + vH2N_empty[j, t] == EP[:eTotalH2TruckNumber][j]
    )

    # No truck in transit should have the same start and end 
    @constraints(
        EP,
        begin
            cH2TruckSameZoneTravelFull[zz in 1:Z, z = zz, j in H2_TRUCK_TYPES, t in 1:T],
            vH2Ntravel_full[zz, z, j, t] == 0
            cH2TruckSameZoneTravelEmpty[zz in 1:Z, z = zz, j in H2_TRUCK_TYPES, t in 1:T],
            vH2Ntravel_empty[zz, z, j, t] == 0
            cH2TruckSameZoneArriveFull[zz in 1:Z, z = zz, j in H2_TRUCK_TYPES, t in 1:T],
            vH2Narrive_full[zz, z, j, t] == 0
            cH2TruckSameZoneArriveEmpty[zz in 1:Z, z = zz, j in H2_TRUCK_TYPES, t in 1:T],
            vH2Narrive_empty[zz, z, j, t] == 0
            cH2TruckSameZoneDepartFull[zz in 1:Z, z = zz, j in H2_TRUCK_TYPES, t in 1:T],
            vH2Ndepart_full[zz, z, j, t] == 0
            cH2TruckSameZoneDepartEmpty[zz in 1:Z, z = zz, j in H2_TRUCK_TYPES, t in 1:T],
            vH2Ndepart_empty[zz, z, j, t] == 0
        end
    )

    #No truck should travel more than 500km or 8.3 hours (at 60 kph)
    #(to avoid issues with TDR time periods of 24 hours and to simplify the problem)
    for zz in 1:Z, z in 1:Z, j in H2_TRUCK_TYPES
        if inputs["TD"][j][zz, z] > max_route_time[j]
            for t in 1:T
                fix(vH2Ntravel_full[zz, z, j, t], 0; force = true)
                fix(vH2Ntravel_empty[zz, z, j, t], 0; force = true)
                fix(vH2Narrive_full[zz, z, j, t], 0; force = true)
                fix(vH2Narrive_empty[zz, z, j, t], 0; force = true)
                fix(vH2Ndepart_full[zz, z, j, t], 0; force = true)
                fix(vH2Ndepart_empty[zz, z, j, t], 0; force = true)
            end
        end
    end

    
    # The number of total full and empty trucks
    @constraints(
        EP,
        begin
            cH2TruckTotalFull[j in H2_TRUCK_TYPES, t in 1:T],
            vH2N_full[j, t] ==
            sum(vH2Ntravel_full[zz, z, j, t] for zz = 1:Z, z = 1:Z if zz != z) +
            sum(vH2Navail_full[z, j, t] for z = 1:Z)

            cH2TruckTotalEmpty[j in H2_TRUCK_TYPES, t in 1:T],
            vH2N_empty[j, t] ==
            sum(vH2Ntravel_empty[zz, z, j, t] for zz = 1:Z, z = 1:Z if zz != z) +
            sum(vH2Navail_empty[z, j, t] for z = 1:Z)
        end
    )

    t_arrive = 1
    t_depart = 1

    # Change of the number of full available trucks
    @constraints(
        EP,
        begin
            cH2TruckChangeFullAvailInterior[
                z in 1:Z,
                j in H2_TRUCK_TYPES,
                t in INTERIOR_SUBPERIODS,
            ],
            vH2Navail_full[z, j, t] - vH2Navail_full[z, j, t-1] ==
            vH2Ncharged[z, j, t] - vH2Ndischarged[z, j, t] +
            sum(vH2Narrive_full[zz, z, j, t-t_arrive] for zz = 1:Z if zz != z) -
            sum(vH2Ndepart_full[z, zz, j, t-t_depart] for zz = 1:Z if zz != z) + 0
            cH2TruckChangeFullAvailStart[
                z in 1:Z,
                j in H2_TRUCK_TYPES,
                t in START_SUBPERIODS,
            ],
            vH2Navail_full[z, j, t] -
            vH2Navail_full[z, j, t+inputs["hours_per_subperiod"]-1] ==
            vH2Ncharged[z, j, t] - vH2Ndischarged[z, j, t] + sum(
                vH2Narrive_full[zz, z, j, t+inputs["hours_per_subperiod"]-1] for
                zz = 1:Z if zz != z
            ) - sum(
                vH2Ndepart_full[z, zz, j, t+inputs["hours_per_subperiod"]-1] for
                zz = 1:Z if zz != z
            )
        end
    )

    # Change of the number of empty available trucks
    @constraints(
        EP,
        begin
            cH2TruckChangeEmptyAvailInterior[
                z in 1:Z,
                j in H2_TRUCK_TYPES,
                t in INTERIOR_SUBPERIODS,
            ],
            vH2Navail_empty[z, j, t] - vH2Navail_empty[z, j, t-1] ==
            -vH2Ncharged[z, j, t] +
            vH2Ndischarged[z, j, t] +
            sum(vH2Narrive_empty[zz, z, j, t-t_arrive] for zz = 1:Z if zz != z) -
            sum(vH2Ndepart_empty[z, zz, j, t-t_depart] for zz = 1:Z if zz != z)
            cH2TruckChangeEmptyAvailStart[
                z in 1:Z,
                j in H2_TRUCK_TYPES,
                t in START_SUBPERIODS,
            ],
            vH2Navail_empty[z, j, t] -
            vH2Navail_empty[z, j, t+inputs["hours_per_subperiod"]-1] ==
            -vH2Ncharged[z, j, t] +
            vH2Ndischarged[z, j, t] +
            sum(
                vH2Narrive_empty[zz, z, j, t+inputs["hours_per_subperiod"]-1] for
                zz = 1:Z if zz != z
            ) - sum(
                vH2Ndepart_empty[z, zz, j, t+inputs["hours_per_subperiod"]-1] for
                zz = 1:Z if zz != z
            )
        end
    )

    # Change of the number of full traveling trucks
    @constraints(
        EP,
        begin
            cH2TruckChangeFullTravelInterior[
                z in 1:Z,
                zz in 1:Z,
                j in H2_TRUCK_TYPES,
                t in INTERIOR_SUBPERIODS,
            ],
            vH2Ntravel_full[z, zz, j, t] - vH2Ntravel_full[z, zz, j, t-1] ==
            vH2Ndepart_full[z, zz, j, t-t_depart] - vH2Narrive_full[z, zz, j, t-t_arrive]
            cH2TruckChangeFullTravelStart[
                z in 1:Z,
                zz in 1:Z,
                j in H2_TRUCK_TYPES,
                t in START_SUBPERIODS,
            ],
            vH2Ntravel_full[z, zz, j, t] -
            vH2Ntravel_full[z, zz, j, t+inputs["hours_per_subperiod"]-1] ==
            vH2Ndepart_full[z, zz, j, t+inputs["hours_per_subperiod"]-1] -
            vH2Narrive_full[z, zz, j, t+inputs["hours_per_subperiod"]-1]
        end
    )

    # Change of the number of empty traveling trucks
    @constraints(
        EP,
        begin
            cH2TruckChangeEmptyTravelInterior[
                z in 1:Z,
                zz in 1:Z,
                j in H2_TRUCK_TYPES,
                t in INTERIOR_SUBPERIODS,
            ],
            vH2Ntravel_empty[z, zz, j, t] - vH2Ntravel_empty[z, zz, j, t-1] ==
            vH2Ndepart_empty[z, zz, j, t-t_depart] - vH2Narrive_empty[z, zz, j, t-t_arrive]
            cH2TruckChangeEmptyTravelStart[
                z in 1:Z,
                zz in 1:Z,
                j in H2_TRUCK_TYPES,
                t in START_SUBPERIODS,
            ],
            vH2Ntravel_empty[z, zz, j, t] -
            vH2Ntravel_empty[z, zz, j, t+inputs["hours_per_subperiod"]-1] ==
            vH2Ndepart_empty[z, zz, j, t+inputs["hours_per_subperiod"]-1] -
            vH2Narrive_empty[z, zz, j, t+inputs["hours_per_subperiod"]-1]
        end
    )

    # Travel delay
    @constraints(
        EP,
        begin
            [zz in 1:Z, z in 1:Z, j in H2_TRUCK_TYPES, t in 1:T],
            vH2Ntravel_full[zz, z, j, t] >= sum(
                vH2Narrive_full[zz, z, j, tt] for
                tt = (t+1):(t+inputs["TD"][j][zz, z]) if t + inputs["TD"][j][zz, z] >=
                (t % inputs["hours_per_subperiod"]) * inputs["hours_per_subperiod"] + 1 &&
                    t + inputs["TD"][j][zz, z] <=
                    (t % inputs["hours_per_subperiod"]) *
                    (inputs["hours_per_subperiod"] + 1) &&
                    t + 1 <= t + inputs["TD"][j][zz, z] &&
                    inputs["TD"][j][zz, z] < 20
            )
            [zz in 1:Z, z in 1:Z, j in H2_TRUCK_TYPES, t in 1:T],
            vH2Ntravel_empty[zz, z, j, t] >= sum(
                vH2Ndepart_empty[zz, z, j, tt] for
                tt = (t-inputs["TD"][j][zz, z]+1):t if t + inputs["TD"][j][zz, z] >=
                (t % inputs["hours_per_subperiod"]) * inputs["hours_per_subperiod"] + 1 &&
                    t + inputs["TD"][j][zz, z] <=
                    (t % inputs["hours_per_subperiod"]) *
                    (inputs["hours_per_subperiod"] + 1) &&
                    t + 1 <= t + inputs["TD"][j][zz, z] &&
                    tt >=1 &&
                    inputs["TD"][j][zz, z] < 20
            )
        end
    )

    @constraints(
        EP,
        begin
            [zz in 1:Z, z in 1:Z, j in H2_TRUCK_TYPES, t in INTERIOR_SUBPERIODS],
            vH2Ntravel_full[zz, z, j, t] >= sum(
                vH2Narrive_full[zz, z, j, tt] for
                tt = (t+1):(t+inputs["TD"][j][zz, z]) if t + inputs["TD"][j][zz, z] >=
                (t % inputs["hours_per_subperiod"]) * inputs["hours_per_subperiod"] + 1 &&
                    t + inputs["TD"][j][zz, z] <=
                    (t % inputs["hours_per_subperiod"]) *
                    (inputs["hours_per_subperiod"] + 1) &&
                    t + 1 <= t + inputs["TD"][j][zz, z] &&
                    inputs["TD"][j][zz, z] < 20
            )
            [zz in 1:Z, z in 1:Z, j in H2_TRUCK_TYPES, t in INTERIOR_SUBPERIODS],
            vH2Ntravel_empty[zz, z, j, t] >= sum(
                vH2Narrive_empty[zz, z, j, tt] for
                tt = (t+1):(t+inputs["TD"][j][zz, z]) if t + inputs["TD"][j][zz, z] >=
                (t % inputs["hours_per_subperiod"]) * inputs["hours_per_subperiod"] + 1 &&
                    t + inputs["TD"][j][zz, z] <=
                    (t % inputs["hours_per_subperiod"]) *
                    (inputs["hours_per_subperiod"] + 1) &&
                    t + 1 <= t + inputs["TD"][j][zz, z] &&
                    inputs["TD"][j][zz, z] < 20
            )
        end
    )

    # Capacity constraints
    @constraint(
        EP,
        [z in 1:Z, j in H2_TRUCK_TYPES, t in 1:T],
        vH2Ncharged[z, j, t] * dfH2Truck[!, :TruckCap_MWh_per_unit][j] <=
        EP[:eTotalH2TruckChargePower][z, j]
    )

    # H2 truck flow balance
    @constraint(
        EP,
        cH2TruckFlow[z in 1:Z, j in H2_TRUCK_TYPES, t in 1:T],
        vH2TruckFlow[z, j, t] ==
        vH2Ndischarged[z, j, t] *
        dfH2Truck[!, :TruckCap_MWh_per_unit][j] *
        (1 - dfH2Truck[!, :H2TLoss_per_mile][j]) -
        vH2Ncharged[z, j, t] * dfH2Truck[!, :TruckCap_MWh_per_unit][j]
    )

    ### End Constraints ###

    return EP
end

# # Truck travel delay - reserved for backup
# if t + inputs["TD"][j][zz, z] >=
#    (t % inputs["hours_per_subperiod"]) * inputs["hours_per_subperiod"] + 1 &&
#    t + inputs["TD"][j][zz, z] <= t + inputs["hours_per_subperiod"] - 1 &&
#    t + 1 <= t + inputs["TD"][j][zz, z]
#     nothing
# end