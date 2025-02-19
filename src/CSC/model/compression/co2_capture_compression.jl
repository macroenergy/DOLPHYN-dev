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
	co2_capture_compression(EP::Model, inputs::Dict,setup::Dict)

The CO2 compression module creates decision variables, expressions, and constraints related to CO2 compression infrastructure for captured CO2 by DAC units.

This module defines the CO2 compression decision variable $x_{k,z,t}^{\textrm{C,COMP}} \forall k \in \mathcal{K}, z \in \mathcal{Z}, t \in \mathcal{T}$, representing CO2 compressed by resource $k$ in zone $z$ at time period $t$ after being captured by DAC.

The variable defined in this file named after ```vDAC\textunderscore{CO2}\textunderscore{Capture}\textunderscore{Compressed}$``` covers all variables $x_{k,z,t}^{\textrm{C,COMP}}$.

This module defines the power consumption decision variable $x_{z,t}^{\textrm{E,COMP}} \forall z\in \mathcal{Z}, t \in \mathcal{T}$, representing power consumed by CO2 compression in zone $z$ at time period $t$.

The variable defined in this file named after ```vPower\textunderscore{CO2}\textunderscore{Capture}\textunderscore{Compressed}``` cover variable $x_{z,t}^{E,COMP}$.

**Minimum and maximum CO2 compression output**

```math
\begin{equation*}
	x_{k,z,t}^{\textrm{C,COMP}} \geq \underline{R_{k,z}^{\textrm{C,COMP}}} \times y_{k,z}^{\textrm{C,COMP}} \quad \forall k \in \mathcal{K}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

```math
\begin{equation*}
	x_{k,z,t}^{\textrm{C,COMP}} \leq \overline{R_{k,z}^{\textrm{C,COMP}}} \times y_{k,z}^{\textrm{C,COMP}} \quad \forall k \in \mathcal{K}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```
"""
function co2_capture_compression(EP::Model, inputs::Dict,setup::Dict)

	#Rename CO2CaptureComp dataframe
	dfCO2CaptureComp = inputs["dfCO2CaptureComp"]
	CO2_CAPTURE_COMP_ALL = inputs["CO2_CAPTURE_COMP_ALL"]

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	#####################################################################################################################################
	##Variables
	#CO2 compressed after capture from carbon compression resource k (tonnes of CO2/hr) in time t
	@variable(EP, vCO2_Capture_Compressed[k=1:CO2_CAPTURE_COMP_ALL, t = 1:T] >= 0 )

	#Power required by carbon compression resource k (MW)
	@variable(EP, vPower_CO2_Capture_Comp[k=1:CO2_CAPTURE_COMP_ALL, t = 1:T] >= 0 )
	
	###############################################################################################################################

	#Power Balance
	# If ParameterScale = 1, power system operation/capacity modeled in GW rather than MW, no need to scale as MW/ton = GW/kton 
	# If ParameterScale = 0, power system operation/capacity modeled in MW so no scaling of CO2 related power consumption
	@expression(EP, ePower_Balance_CO2_Capture_Comp[t=1:T, z=1:Z],
	sum(EP[:vPower_CO2_Capture_Comp][k,t] for k in dfCO2CaptureComp[dfCO2CaptureComp[!,:Zone].==z,:][!,:R_ID]))

	#Add to power balance to take power away from generated
	EP[:ePowerBalance_CSC] += -ePower_Balance_CO2_Capture_Comp

	##For CO2 Policy constraint right hand side development - power consumption by zone and each time step
	EP[:eCSCNetpowerConsumptionByAll] += ePower_Balance_CO2_Capture_Comp

	###############################################################################################################################
	##Constraints
	#Power constraint
	@constraint(EP,cPower_Consumption_CO2_Capture_Comp[k=1:CO2_CAPTURE_COMP_ALL, t = 1:T], EP[:vPower_CO2_Capture_Comp][k,t] == EP[:vCO2_Capture_Compressed][k,t] * dfCO2CaptureComp[!,:etaPCO2_MWh_per_tonne][k])

	#Include constraint of min compression operation
	@constraint(EP,cMin_CO2_Capture_Compressed_per_type_per_time[k=1:CO2_CAPTURE_COMP_ALL, t=1:T], EP[:vCO2_Capture_Compressed][k,t] >= EP[:vCapacity_CO2_Capture_Comp_per_type][k] * dfCO2CaptureComp[!,:CO2_Capture_Compression_Min_Output][k])

	#Max carbon compression per resoruce type k at hour T
	@constraint(EP,cMax_CO2_Capture_Compressed_per_type_per_time[k=1:CO2_CAPTURE_COMP_ALL, t=1:T], EP[:vCO2_Capture_Compressed][k,t] <= EP[:vCapacity_CO2_Capture_Comp_per_type][k] * dfCO2CaptureComp[!,:CO2_Capture_Compression_Max_Output][k])

	###############################################################################################################################

	return EP

end




