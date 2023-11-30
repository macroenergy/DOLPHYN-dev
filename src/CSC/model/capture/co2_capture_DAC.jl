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
	co2_capture_DAC(EP::Model, inputs::Dict,setup::Dict)

The DAC module creates decision variables, expressions, and constraints related to DAC capture infrastructure

This module defines the power consumption decision variable $x_{z,t}^{\textrm{E,DAC}} \forall z\in \mathcal{Z}, t \in \mathcal{T}$, representing power consumed by DAC in zone $z$ at time period $t$.

The variable defined in this file named after ```vPower\textunderscore DAC``` cover variable $x_{z,t}^{E,H-GEN}$.

This module defines the power generation decision variable $x_{z,t}^{\textrm{EGEN,DAC}} \forall z\in \mathcal{Z}, t \in \mathcal{T}$, representing power generated by DAC in zone $z$ at time period $t$.

The variable defined in this file named after ```vPower\textunderscore Produced\textunderscore DAC``` cover variable $x_{z,t}^{EGEN,DAC}$.

**Minimum and maximum DAC output**

```math
\begin{equation*}
	x_{d,z,t}^{\textrm{C,DAC}} \geq \underline{R_{d,z}^{\textrm{C,DAC}}} \times y_{d,z}^{\textrm{C,DAC}} \quad \forall d \in \mathcal{D}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

```math
\begin{equation*}
	x_{d,z,t}^{\textrm{C,DAC}} \leq \overline{R_{d,z,t}^{\textrm{C,DAC}}} \times y_{d,z}^{\textrm{C,DAC}} \quad \forall d \in \mathcal{D}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```
(See Constraints 3-4 in the code)

**Ramping limits**

DAC resources adhere to the following ramping limits on hourly changes in CO2 capture output:

```math
\begin{equation*}
	x_{d,z,t-1}^{\textrm{C,DAC}} - x_{d,z,t}^{\textrm{C,DAC}} \leq \kappa_{d,z}^{\textrm{DAC,DN}} y_{d,z}^{\textrm{C,DAC}} \quad \forall d \in \mathcal{D}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```

```math
\begin{equation*}
	x_{d,z,t}^{\textrm{C,DAC}} - x_{d,z,t-1}^{\textrm{C,DAC}} \leq \kappa_{d,z}^{\textrm{DAC,UP}} y_{d,z}^{\textrm{C,DAC}} \quad \forall d \in \mathcal{D}, z \in \mathcal{Z}, t \in \mathcal{T}
\end{equation*}
```
(See Constraints 5-8 in the code)

This set of time-coupling constraints wrap around to ensure the DAC capture output in the first time step of each year (or each representative period), $t \in \mathcal{T}^{start}$, is within the eligible ramp of the output in the final time step of the year (or each representative period), $t+\tau^{period}-1$.
"""
function co2_capture_DAC(EP::Model, inputs::Dict,setup::Dict)

	#Rename CO2Capture dataframe
	dfDAC = inputs["dfDAC"]

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones
	
	CO2_CAPTURE_DAC = inputs["CO2_CAPTURE_DAC"]
	
	#Define start subperiods and interior subperiods
	START_SUBPERIODS = inputs["START_SUBPERIODS"]
	INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]
	hours_per_subperiod = inputs["hours_per_subperiod"] #total number of hours per subperiod

	###############################################################################################################################
	##Expressions

	#CO2 Balance expressions
	@expression(EP, eDAC_CO2_captured_per_time_per_zone[t=1:T, z=1:Z],
	sum(EP[:vDAC_CO2_Captured][k,t] for k in intersect(CO2_CAPTURE_DAC, dfDAC[dfDAC[!,:Zone].==z,:][!,:R_ID])))

	#ADD TO CO2 BALANCE
	EP[:eCaptured_CO2_Balance] += eDAC_CO2_captured_per_time_per_zone

	#Power Balance
	# If ParameterScale = 1, power system operation/capacity modeled in GW, no need to scale as MW/ton = GW/kton 
	# If ParameterScale = 0, power system operation/capacity modeled in MW
	
	#Power consumption by DAC
	@expression(EP, ePower_Balance_DAC[t=1:T, z=1:Z],
	sum(EP[:vPower_DAC][k,t] for k in intersect(CO2_CAPTURE_DAC, dfDAC[dfDAC[!,:Zone].==z,:][!,:R_ID])))

	#Add to power balance to take power away from generated
	EP[:ePowerBalance] += -ePower_Balance_DAC

	##For CO2 Polcy constraint right hand side development - power consumption by zone and each time step
	EP[:eCSCNetpowerConsumptionByAll] += ePower_Balance_DAC

	#Power produced by DAC
	@expression(EP, ePower_Produced_Balance_DAC[t=1:T, z=1:Z],
	sum(EP[:vPower_Produced_DAC][k,t] for k in intersect(CO2_CAPTURE_DAC, dfDAC[dfDAC[!,:Zone].==z,:][!,:R_ID])))

	#Add to power balance to add power produced by DAC
	EP[:ePowerBalance] += ePower_Produced_Balance_DAC
	EP[:eCSCNetpowerConsumptionByAll] -= ePower_Produced_Balance_DAC

	###############################################################################################################################
	##Constraints
	#Power consumption constraint
	@constraint(EP,cPower_Consumption_DAC[k in CO2_CAPTURE_DAC, t = 1:T], EP[:vPower_DAC][k,t] == EP[:vDAC_CO2_Captured][k,t] * dfDAC[!,:etaPCO2_MWh_per_tonne][k])

	#Power production constraint
	@constraint(EP,cPower_Production_DAC[k in CO2_CAPTURE_DAC, t = 1:T], EP[:vPower_Produced_DAC][k,t] == EP[:vDAC_CO2_Captured][k,t] * dfDAC[!,:Power_Production_MWh_per_tonne][k])

	#Include constraint of min capture operation
	@constraint(EP,cMin_CO2_Captured_DAC_per_type_per_time[k in CO2_CAPTURE_DAC, t=1:T], EP[:vDAC_CO2_Captured][k,t] >= EP[:vCapacity_DAC_per_type][k] * dfDAC[!,:CO2_Capture_Min_Output][k])

	#Max carbon capture per resoruce type k at hour T
	@constraint(EP,cMax_CO2_Captured_DAC_per_type_per_time[k in CO2_CAPTURE_DAC, t=1:T], EP[:vDAC_CO2_Captured][k,t] <= EP[:vCapacity_DAC_per_type][k] * inputs["CO2_Capture_Max_Output"][k,t] )


	#Define start subperiods and interior subperiods

	@constraint(EP, cMax_Rampup_Start_DAC[k in CO2_CAPTURE_DAC, t in START_SUBPERIODS], (EP[:vDAC_CO2_Captured][k,t] - EP[:vDAC_CO2_Captured][k,(t + hours_per_subperiod-1)]) <= dfDAC[!,:Ramp_Up_Percentage][k] * EP[:vCapacity_DAC_per_type][k])

	@constraint(EP, cMax_Rampup_Interior_DAC[k in CO2_CAPTURE_DAC, t in INTERIOR_SUBPERIODS], (EP[:vDAC_CO2_Captured][k,t] - EP[:vDAC_CO2_Captured][k,t-1]) <= dfDAC[!,:Ramp_Up_Percentage][k] * EP[:vCapacity_DAC_per_type][k])

	@constraint(EP, cMax_Rampdown_Start_DAC[k in CO2_CAPTURE_DAC, t in START_SUBPERIODS], (EP[:vDAC_CO2_Captured][k,(t + hours_per_subperiod-1)] - EP[:vDAC_CO2_Captured][k,t]) <= dfDAC[!,:Ramp_Down_Percentage][k] * EP[:vCapacity_DAC_per_type][k])

	@constraint(EP, cMax_Rampdown_Interior_DAC[k in CO2_CAPTURE_DAC, t in INTERIOR_SUBPERIODS], (EP[:vDAC_CO2_Captured][k,t-1] - EP[:vDAC_CO2_Captured][k,t]) <= dfDAC[!,:Ramp_Down_Percentage][k] * EP[:vCapacity_DAC_per_type][k])

	return EP

end




