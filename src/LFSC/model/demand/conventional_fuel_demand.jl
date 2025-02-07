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

    conventional_fuel_demand(EP::Model, inputs::Dict, setup::Dict)

This module defines the conventional gasoline, jetfuel, and diesel purchase decision variables $x_{z,t}^{\textrm{Gasoline,Conv}} \forall z\in \mathcal{Z}, t \in \mathcal{T}$, $x_{z,t}^{\textrm{Jetfuel,Conv}} \forall z\in \mathcal{Z}, t \in \mathcal{T}$, $x_{z,t}^{\textrm{Diesel,Conv}} \forall z\in \mathcal{Z}, t \in \mathcal{T}$ representing  conventional gasoline, jetfuel, and diesel purchased in zone $z$ at time period $t$.

The variables defined in this file named after ```vConvLFGasolineDemand``` cover variable $x_{z,t}^{Gasoline,Conv}$, ```vConvLFJetfuelDemand``` cover variable $x_{z,t}^{Jetfuel,Conv}$, and ```vConvLFDieselDemand``` cover variable $x_{z,t}^{Diesel,Conv}$.

**Cost expressions**

This module additionally defines contributions to the objective function from variable costs of conventional fuel purchase over all time periods.

```math
\begin{equation*}
	\textrm{C}^{\textrm{Gasoline,Conv,o}} = \sum_{z \in \mathcal{Z}} \sum_{t \in \mathcal{T}} \omega_t \times \textrm{c}_{z}^{\textrm{Gasoline,Conv,VOM}} \times x_{z,t}^{\textrm{Gasoline,Conv}}
\end{equation*}
```

```math
\begin{equation*}
	\textrm{C}^{\textrm{Jetfuel,Conv,o}} = \sum_{z \in \mathcal{Z}} \sum_{t \in \mathcal{T}} \omega_t \times \textrm{c}_{z}^{\textrm{Jetfuel,Conv,VOM}} \times x_{z,t}^{\textrm{Jetfuel,Conv}}
\end{equation*}
```

```math
\begin{equation*}
	\textrm{C}^{\textrm{Diesel,Conv,o}} = \sum_{z \in \mathcal{Z}} \sum_{t \in \mathcal{T}} \omega_t \times \textrm{c}_{z}^{\textrm{Diesel,Conv,VOM}} \times x_{z,t}^{\textrm{Diesel,Conv}}
\end{equation*}
```

"""
function conventional_fuel_demand(EP::Model, inputs::Dict, setup::Dict)

    println(" -- Conventional Fuel Demand Module")

	#Define sets
    Z = inputs["Z"]     # Number of zones
	T = inputs["T"]     # Number of time steps (hours)

    if setup["Liquid_Fuels_Regional_Demand"] == 1

        if setup["Liquid_Fuels_Hourly_Demand"] == 1

            #If do conventional as regional hourly variable [t]
            @variable(EP, vConvLFGasolineDemand[t = 1:T, z = 1:Z] >= 0 )
            @variable(EP, vConvLFJetfuelDemand[t = 1:T, z = 1:Z] >= 0 )
            @variable(EP, vConvLFDieselDemand[t = 1:T, z = 1:Z] >= 0 )

            #Liquid Fuel Balance
            EP[:eCFGasolineBalance] += vConvLFGasolineDemand
            EP[:eCFJetfuelBalance] += vConvLFJetfuelDemand
            EP[:eCFDieselBalance] += vConvLFDieselDemand
            
            ### Expressions ###
            #Cost of Conventional Fuel
            #Sum up conventional Fuel Costs
            @expression(EP, eTotalCLFGasolineVarOut_Z[z = 1:Z], sum((inputs["omega"][t] * inputs["Gasoline_Price_Regional"][t,z] * vConvLFGasolineDemand[t,z]) for t in 1:T))
            @expression(EP, eTotalCLFJetfuelVarOut_Z[z = 1:Z], sum((inputs["omega"][t] * inputs["Jetfuel_Price_Regional"][t,z] * vConvLFJetfuelDemand[t,z]) for t in 1:T))
            @expression(EP, eTotalCLFDieselVarOut_Z[z = 1:Z], sum((inputs["omega"][t] * inputs["Diesel_Price_Regional"][t,z] * vConvLFDieselDemand[t,z]) for t in 1:T))

            @expression(EP, eTotalCLFGasolineVarOut, sum(EP[:eTotalCLFGasolineVarOut_Z][z] for z in 1:Z))
            @expression(EP, eTotalCLFJetfuelVarOut, sum(EP[:eTotalCLFJetfuelVarOut_Z][z] for z in 1:Z))
            @expression(EP, eTotalCLFDieselVarOut, sum(EP[:eTotalCLFDieselVarOut_Z][z] for z in 1:Z))

            #Add to objective function
            EP[:eObj] += eTotalCLFGasolineVarOut
            EP[:eObj] += eTotalCLFJetfuelVarOut
            EP[:eObj] += eTotalCLFDieselVarOut

        elseif setup["Liquid_Fuels_Hourly_Demand"] == 0

            #If do conventional as global hourly variable [t]
            @variable(EP, vConvLFGasolineDemand[z = 1:Z] >= 0 )
            @variable(EP, vConvLFJetfuelDemand[z = 1:Z] >= 0 )
            @variable(EP, vConvLFDieselDemand[z = 1:Z] >= 0 )

            #Liquid Fuel Balance
            EP[:eCFGasolineBalance] += vConvLFGasolineDemand
            EP[:eCFJetfuelBalance] += vConvLFJetfuelDemand
            EP[:eCFDieselBalance] += vConvLFDieselDemand
            
            ### Expressions ###
            #Cost of Conventional Fuel
            #Sum up conventional Fuel Costs (Take input price of first hour if not modeling price variation)

            @expression(EP, eTotalCLFGasolineVarOut_Z[z = 1:Z], inputs["Gasoline_Price_Regional"][1,z] * vConvLFGasolineDemand[z])
            @expression(EP, eTotalCLFJetfuelVarOut_Z[z = 1:Z], inputs["Jetfuel_Price_Regional"][1,z] * vConvLFJetfuelDemand[z])
            @expression(EP, eTotalCLFDieselVarOut_Z[z = 1:Z], inputs["Diesel_Price_Regional"][1,z] * vConvLFDieselDemand[z])

            @expression(EP, eTotalCLFGasolineVarOut, sum(EP[:eTotalCLFGasolineVarOut_Z][z] for z in 1:Z))
            @expression(EP, eTotalCLFJetfuelVarOut, sum(EP[:eTotalCLFJetfuelVarOut_Z][z] for z in 1:Z))
            @expression(EP, eTotalCLFDieselVarOut, sum(EP[:eTotalCLFDieselVarOut_Z][z] for z in 1:Z))

            #Add to objective function
            EP[:eObj] += eTotalCLFGasolineVarOut
            EP[:eObj] += eTotalCLFJetfuelVarOut
            EP[:eObj] += eTotalCLFDieselVarOut

        end

    elseif setup["Liquid_Fuels_Regional_Demand"] == 0
        
        if setup["Liquid_Fuels_Hourly_Demand"] == 1

            #If do conventional as global hourly variable [t]
            @variable(EP, vConvLFGasolineDemand[t = 1:T] >= 0 )
            @variable(EP, vConvLFJetfuelDemand[t = 1:T] >= 0 )
            @variable(EP, vConvLFDieselDemand[t = 1:T] >= 0 )

            #Liquid Fuel Balance
            EP[:eCFGasolineBalance] += vConvLFGasolineDemand
            EP[:eCFJetfuelBalance] += vConvLFJetfuelDemand
            EP[:eCFDieselBalance] += vConvLFDieselDemand
            
            ### Expressions ###
            #Cost of Conventional Fuel
            #Sum up conventional Fuel Costs
            @expression(EP, eTotalCLFGasolineVarOut, sum((inputs["omega"][t] * inputs["Gasoline_Price_Global"][t] * vConvLFGasolineDemand[t]) for t in 1:T))
            @expression(EP, eTotalCLFJetfuelVarOut, sum((inputs["omega"][t] * inputs["Jetfuel_Price_Global"][t] * vConvLFJetfuelDemand[t]) for t in 1:T))
            @expression(EP, eTotalCLFDieselVarOut, sum((inputs["omega"][t] * inputs["Diesel_Price_Global"][t] * vConvLFDieselDemand[t]) for t in 1:T))

            #Add to objective function
            EP[:eObj] += eTotalCLFGasolineVarOut
            EP[:eObj] += eTotalCLFJetfuelVarOut
            EP[:eObj] += eTotalCLFDieselVarOut

        elseif setup["Liquid_Fuels_Hourly_Demand"] == 0

            #If do conventional as global annual variable
            @variable(EP, vConvLFGasolineDemand >= 0 )
            @variable(EP, vConvLFJetfuelDemand >= 0 )
            @variable(EP, vConvLFDieselDemand >= 0 )

            #Liquid Fuel Balance
            EP[:eCFGasolineBalance] += vConvLFGasolineDemand
            EP[:eCFJetfuelBalance] += vConvLFJetfuelDemand
            EP[:eCFDieselBalance] += vConvLFDieselDemand

            ### Expressions ###
            #Cost of Conventional Fuel
            #Sum up conventional Fuel Costs (Take input price of first hour if not modeling price variation)
            @expression(EP, eTotalCLFGasolineVarOut, inputs["Gasoline_Price_Global"][1] * vConvLFGasolineDemand)
            @expression(EP, eTotalCLFJetfuelVarOut, inputs["Jetfuel_Price_Global"][1] * vConvLFJetfuelDemand)
            @expression(EP, eTotalCLFDieselVarOut, inputs["Diesel_Price_Global"][1] * vConvLFDieselDemand)

            #Add to objective function
            EP[:eObj] += eTotalCLFGasolineVarOut
            EP[:eObj] += eTotalCLFJetfuelVarOut
            EP[:eObj] += eTotalCLFDieselVarOut

        end
    end

	return EP

end
