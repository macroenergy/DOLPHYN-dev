# LFSC Database Documentation

## 1 Model setup parameters

Model settings parameters are specified in a `lfsc_Settings.yml` file which should be located in the current working directory (or to specify an alternative location, edit the `settings_path` variable in your `Run.jl` file). Settings include those related to model structure, solution strategy and outputs, policy constraints, and others. Model structure related settings parameter affects the formulation of the model constraint and objective functions. Computational performance related parameters affect the accuracy of the solution. Policy related parameters specify the policy type and policy goal. Note that all settings parameters are case sensitive.

###### Table 1a: Summary of the Model settings parameters
---
|**Settings Parameter** | **Description**|
| :------------ | :-----------|
|**Model structure related**||
|ModelLFSC | Flag to turn or off CO2 Supply Chain modelling capabilities.|
||0 = no liquid fuels supply chain modeling.
||1 = modeling liquid fuels supply chain.|
|AllowConventionalDiesel | Flag for allowing purchase of conventional diesel.|
||0 = purchase of conventional diesel is not allowed.|
||1 = active|
|SpecifySynDieselPercentFlag | Flag for allowing the specification of the percentage of non-conventional diesel.|
||0 = no user specified percentage of conventional diesel.|
||1 = active|
|percent_sf_diesel | Specify the percentage value of non-conventional diesel.|
||Enter a fraction from 0 to 1.|
|AllowConventionalJetfuel | Flag for allowing purchase of conventional jetfuel.|
||0 = purchase of conventional jetfuel is not allowed.|
||1 = active|
|SpecifySynJetfuelPercentFlag | Flag for allowing the specification of the percentage of non-conventional jetfuel.|
||0 = no user specified percentage of conventional jetfuel.|
||1 = active|
|percent_sf_jetfuel | Specify the percentage value of non-conventional jetfuel.|
||Enter a fraction from 0 to 1.|
|AllowConventionalGasoline | Flag for allowing purchase of conventional gasoline.|
||0 = purchase of conventional gasoline is not allowed.|
||1 = active|
|SpecifySynGasolinePercentFlag | Flag for allowing the specification of the percentage of non-conventional gasoline.|
||0 = no user specified percentage of conventional gasoline.|
||1 = active|
|percent_sf_gasoline | Specify the percentage value of non-conventional gasoline.|
||Enter a fraction from 0 to 1.|

## 2 Inputs

All input files are in CSV format. Running the GenX submodule requires a minimum of five input files. Additionally, the user may need to specify five more input files based on model configuration and type of scenarios of interest. Names of the input files and their functionality is given below. Note that names of the input files are case sensitive.


###### Table 2: Summary of the input files
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|**Mandatory Files**||
|Liquid\_Fuels\_Diesel\_Demand.csv |Specify time-series of load profiles for each model zone, price for conventional diesel, emission factor for conventional and synthetic diesel.|
|Liquid\_Fuels\_Jetfuel\_Demand.csv |Specify time-series of load profiles for each model zone, price for conventional jetfuel, emission factor for conventional and synthetic, jetfuel.|
|Liquid\_Fuels\_Gasoline\_Demand.csv |Specify time-series of load profiles for each model zone, price for conventional gasoline, emission factor for conventional and synthetic gasoline.|
|Syn\_Fuels\_resources.csv |Specify cost and performance data for synthetic fuels resources.|

### 2.1 Mandatory input data
#### 2.1.1 Liquid\_Fuels\_Diesel\_Demand.csv

This file includes parameters to characterize model the diesel demand for each time step for each zone, the cost of conventional diesel, emission factor for conventional and synthetic diesel. Note that DOLPHYN is designed to model hourly time steps. With some care and effort, finer (e.g. 15 minute) or courser (e.g. 2 hour) time steps can be modeled so long as all time-related parameters are scaled appropriately (e.g. time period weights, heat rates, ramp rates and minimum up and down times for generators, variable costs, etc).

###### Table 1: Structure of the Liquid\_Fuels\_Diesel\_Demand.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|**Mandatory Columns**|
|Conventional\_diesel\_co2\_per\_mmbtu |Emission factor of conventional diesel (tonne-CO2/MMBtu).|
|Conventional\_diesel\_price\_per\_mmbtu |Emission factor of conventional diesel (\$/tonne-CO2).|
|Syn\_diesel\_co2\_per\_mmbtu |Emission factor of synthetic diesel (tonne-CO2/MMBtu).|
|Time\_Index |Index defining time step in the model.|
|Load\_mmbtu\_z* |Load profile of diesel in a zone z* in MMBtu/hr; if multiple zones, this parameter will be a matrix with columns equal to number of zones (each column named appropriate zone number appended to parameter) and rows equal to number of time periods of grid operations being modeled.|

#### 2.1.2 Liquid\_Fuels\_Jetfuel\_Demand.csv

This file includes parameters to characterize model the diesel demand for each time step for each zone, the cost of conventional jetfuel, emission factor for conventional and synthetic jetfuel. Note that DOLPHYN is designed to model hourly time steps. With some care and effort, finer (e.g. 15 minute) or courser (e.g. 2 hour) time steps can be modeled so long as all time-related parameters are scaled appropriately (e.g. time period weights, heat rates, ramp rates and minimum up and down times for generators, variable costs, etc).

###### Table 2: Structure of the Liquid\_Fuels\_Jetfuel\_Demand.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|**Mandatory Columns**|
|Conventional\_jetfuel\_co2\_per\_mmbtu |Emission factor of conventional jetfuel (tonne-CO2/MMBtu).|
|Conventional\_jetfuel\_price\_per\_mmbtu |Emission factor of conventional jetfuel (\$/tonne-CO2).|
|Syn\_jetfuel\_co2\_per\_mmbtu |Emission factor of synthetic jetfuel (tonne-CO2/MMBtu).|
|Time\_Index |Index defining time step in the model.|
|Load\_mmbtu\_z* |Load profile of jetfuel in a zone z* in MMBtu/hr; if multiple zones, this parameter will be a matrix with columns equal to number of zones (each column named appropriate zone number appended to parameter) and rows equal to number of time periods of grid operations being modeled.|

#### 2.1.3 Liquid\_Fuels\_Gasoline\_Demand.csv

This file includes parameters to characterize model the diesel demand for each time step for each zone, the cost of conventional jetfuel, emission factor for conventional and synthetic jetfuel. Note that DOLPHYN is designed to model hourly time steps. With some care and effort, finer (e.g. 15 minute) or courser (e.g. 2 hour) time steps can be modeled so long as all time-related parameters are scaled appropriately (e.g. time period weights, heat rates, ramp rates and minimum up and down times for generators, variable costs, etc).

###### Table 3: Structure of the Liquid\_Fuels\_Gasoline\_Demand.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|**Mandatory Columns**|
|Conventional\_gasoline\_co2\_per\_mmbtu |Emission factor of conventional gasoline (tonne-CO2/MMBtu).|
|Conventional\_gasoline\_price\_per\_mmbtu |Emission factor of conventional gasoline (\$/tonne-CO2).|
|Syn\_gasoline\_co2\_per\_mmbtu |Emission factor of synthetic gasoline (tonne-CO2/MMBtu).|
|Time\_Index |Index defining time step in the model.|
|Load\_mmbtu\_z* |Load profile of gasoline in a zone z* in MMBtu/hr; if multiple zones, this parameter will be a matrix with columns equal to number of zones (each column named appropriate zone number appended to parameter) and rows equal to number of time periods of grid operations being modeled.|

#### 2.1.4 Syn\_Fuels\_resources.csv

This file contains cost and performance parameters for various synthetic fuels resources included in the model formulation.

###### Table 4: Mandatory columns in the Syn\_Fuels\_resources.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|Syn\_Fuel\_Resource | This column contains **unique** names of resources available to the model. Resources can include different types of synthetic fuel plants.|
|Zone | Integer representing zone number where the resource is located. |
|**Capacity requirements**|
|MaxCapacity\_tonne\_p\_hr |-1 (default) – no limit on maximum CO2 input capacity of the synthetic fuel resource. If non-negative, represents maximum allowed CO2 input capacity (in tonne/hr) of the resource.|
|MinCapacity\_tonne\_p\_hr |-1 (default) – no limit on minimum CO2 input capacity of the synthetic fuel resource. If non-negative, represents miniimum allowed CO2 input capacity (in tonne/hr) of the resource.|
|**Cost parameters**|
|Inv\_Cost\_p\_tonne\_co2\_p\_hr\_yr | Annualized capacity investment cost of a technology per input CO2 capacity (\$/tonne/hr/year). |
|Fixed\_OM\_Cost\_p\_tonne\_co2\_p\_hr\_yr | Fixed operations and maintenance cost of a technology per input CO2 capacity (\$/tonne/hr/year). |
|Var\_OM\_Cost\_p\_tonne\_co2 | Variable operations and maintenance cost of a technology per tonne input CO2 (\$/tonne). |
|**Technical performance parameters**|
|mmbtu\_sf\_diesel\_p\_tonne\_co2  |MMBtu of diesel output per tonne of CO2 input by synthetic fuel resource. Should be consistent with fuel prices in terms of reporting on higher heating value (HHV) or lower heating value (LHV) basis. |
|mmbtu\_sf\_jetfuel\_p\_tonne\_co2  |MMBtu of jetfuel output per tonne of CO2 input by synthetic fuel resource. Should be consistent with fuel prices in terms of reporting on higher heating value (HHV) or lower heating value (LHV) basis. |
|mmbtu\_sf\_gasoline\_p\_tonne\_co2  |MMBtu of gasoline output per tonne of CO2 input by synthetic fuel resource. Should be consistent with fuel prices in terms of reporting on higher heating value (HHV) or lower heating value (LHV) basis. |
|tonnes\_h2\_p\_tonne\_co2 | Tonne H2 required per tonne of CO2 input by synthetic fuel resource.|
|mmbtu\_ng\_p\_tonne\_co2 | MMBtu of fuel required per tonne of CO2 input by synthetic fuel resource.|
|mwh\_p\_tonne\_co2 | MWh of electricity required per tonne of CO2 input by synthetic fuel resource.|
|co2\_out\_p\_co2\_in | Tonne CO2 released per tonne of CO2 input by synthetic fuel resource.|
|co2\_captured\_p\_co2\_in | Tonne CO2 captured per tonne of CO2 input by synthetic fuel resource and added to captured CO2 inventory.|
|**By-products parameters (if applicable only)**|
|mmbtu\_p\_tonne\_co2\_pb* | MMBtu of byproduct b output per tonne of CO2 input by synthetic fuel resource.|
|price\_p\_mmbtu\_pb* | Selling price of byproduct b (\$/MMBtu).|
|co2\_out\_p\_mmbtu\_pb* | CO2 emission rate of byproduct b (\tonne/MMBtu).|

## 3 Outputs

The table below summarizes the output variables reported as part of the various CSV files produced after each model run. The reported units are also provided. When the model is run with time domain reduction, if a result file includes time-dependent values (e.g. for each model time step), the value will not include the hour weight in it. An annual sum ("AnnualSum") column/row will be provided whenever it is possible (e.g., `LF_Diesel_Balance.csv`), and this value takes the time-weights into account. 

### 3.1 Default output files


#### 3.1.1 SynFuel_capacity.csv

Reports optimal values of investment variables for synthetic fuel resource.

###### Table 9: Structure of the SynFuel_capacity.csv file
---
|**Output** |**Description** |**Units** |
| :------------ | :-----------|:-----------|
| Capacity\_tonne\_CO2\_per\_h |Input CO2 capacity of each synthetic fuel resource type in each zone |CO$_2$ Tonnes / Hr |
| Capacity\_Syndiesel\_MMBtu\_per\_h |Maximum hourly synthetic diesel production based on built capacity |MMBtu / Hr |
| Capacity\_Synjetfuel\_MMBtu\_per\_h |Maximum hourly synthetic jetfuel production based on built capacity |MMBtu / Hr |
| Capacity\_Syngasoline\_MMBtu\_per\_h |Maximum hourly synthetic gasoline production based on built capacity |MMBtu / Hr |
| Annual\_Syndiesel\_Production |Actual annual synthetic diesel production |MMBtu |
| Annual\_Synjetfuel\_Production |Actual annual synthetic jetfuel production |MMBtu |
| Annual\_Syngasoline\_Production |Actual annual synthetic gasoline production |MMBtu |
| Max\_Annual\_CO2\_Consumption |Maximum annual CO2 input based on built capacity |CO$_2$ Tonnes |
| Annual\_CO2\_Consumption |Actual annual CO2 input |CO$_2$ Tonnes |
| Capacity\_Factor |Capacity factor by dividing actual annual CO2 input by maximum annual possible CO2 input based on built capacity | |


#### 3.1.2 SynFuel_costs.csv

Reports LFSC costs for each zone, including sum of fixed and variable costs for synthetic fuel resources, byproduct revenues (if any), conventional fuel costs and total costs. 

#### 3.1.3 Syn_Fuel_balance.csv

Reports balance of input CO2, power, and H2, as well as output synthetic diesel, jetfuel, gasoline, and byproducts (if any) for each zone and time step. 

#### 3.1.4 Syn_Fuel_Emissions_Balance.csv

Reports balance of input CO2, process and byproducts (if any) emissions, CO2 captured, and CO2 emissions from synthetic, and conventional diesel, jetfuel, gasoline utilization for each zone and time step. 

#### 3.1.5 Synfuel_diesel_production.csv

Reports production of synthetic diesel for each synthetic fuel resource and time step.

#### 3.1.6 Synfuel_jetfuel_production.csv

Reports production of synthetic jetfuel for each synthetic fuel resource and time step.

#### 3.1.7 Synfuel_gasoline_production.csv

Reports production of synthetic gasoline for each synthetic fuel resource and time step.

#### 3.1.8 LF_Diesel_balance.csv

Reports balance of synthetic and conventional diesel for each zone and time step. 

#### 3.1.9 LF_Jetfuel_balance.csv

Reports balance of synthetic and conventional jetfuel for each zone and time step. 

#### 3.1.10 LF_Gasoline_balance.csv

Reports balance of synthetic and conventional gasoline for each zone and time step. 
