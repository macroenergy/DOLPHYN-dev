# HSC Database Documentation

## 1 Model setup parameters

Model settings parameters are specified in a `hsc_Settings.yml` file which should be located in the current working directory (or to specify an alternative location, edit the `settings_path` variable in your `Run.jl` file). Settings include those related to model structure, solution strategy and outputs, policy constraints, and others. Model structure related settings parameter affects the formulation of the model constraint and objective functions. Computational performance related parameters affect the accuracy of the solution. Policy related parameters specify the policy type and policy goal. Network related parameters specify settings related to transmission network expansion and losses. Note that all settings parameters are case sensitive.

###### Table 1a: Summary of the Model settings parameters
---
|**Settings Parameter** | **Description**|
| :------------ | :-----------|
|**Model structure related**||
|ModelH2 | Flag to turn or off Hydrogen Supply Chain modelling capabilities.|
||0 = no hydrogen supply chain modeling.
||1 = modeling hydrogen supply chain.|
|NetworkExpansion | Flag for activating or deactivating inter-regional transmission expansion.|
||1 = active|
||0 = modeling single zone or for multi-zone problems, inter regional transmission expansion is not allowed.|
|ModelH2Pipelines | Whether to model pipeline in hydrogen supply chain. |
||0 = not modeling hydrogen pipelines (no transmission).|
||1 = modeling hydrogen pipelines (with transmission).|
|H2PipeInteger |Whether to model pipeline capacity as discrete or integer. |
||0 = continuous capacity of hydrogen pipeline.|
||1 = discrete capacity of hydrogen pipeline.|
|ModelH2Trucks | Whether to model truck in hydrogen supply chain. |
||0 = not modeling hydrogen trucks. |
||1 = modeling hydrogen trucks. |
|H2GenCommit | Select technical resolution of of modeling thermal generators.|
||0 = no unit commitment.|
||1 = unit commitment with integer clustering.|
||2 = unit commitment with linearized clustering.|
|H2G2PCommit | Select technical resolution of modeling gas to power generators.|
||0 = no unit commitment.|
||1 = unit commitment with integer clustering.|
||2 = unit commitment with linearized clustering.|
|**Policy related**||
|H2CO2Cap | Flag for specifying the type of CO2 emission limit constraint.|
|| 0 = no CO2 emission limit|
|| 1 = mass-based emission limit constraint|
|| 2 = load + rate-based emission limit constraint|
|| 3 = generation + rate-based emission limit constraint|
|TimeMatchingRequirement | Flag for specifying type of time-matching requirement (TMR). |
|| 0 = no time matching requirement active|
|| 1 = Hourly time-matching with excess sales|
|| 2 = Hourly time-matching without excess sales|
|| 3 = Annual time-matching|
|TMRSalestoESR | Flag for specifying whether excess sales from resources contracted for TMR can be used to meet ESR requirements. |
|| 0 = Excess sales from TMR eligible resources not allowed|
|| 1 = Excess sales from TMR eligible resources allowed|

## 2 Inputs

All input files are in CSV format. Running the GenX submodule requires a minimum of five input files. Additionally, the user may need to specify five more input files based on model configuration and type of scenarios of interest. Names of the input files and their functionality is given below. Note that names of the input files are case sensitive.


###### Table 2: Summary of the input files
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|**Mandatory Files**||
|HSC\_pipelines.csv |Specify network topology, transmission fixed costs, capacity and loss parameters.|
|HSC\_load\_data.csv |Specify time-series of load profiles for each model zone, weights for each time step, hydrogen load shedding costs, and optional time domain reduction parameters.|
|HSC\_generators\_variability.csv |Specify time-series of capacity factor/availability for each resource.|
|HSC\_generation.csv |Specify cost and performance data for generation and storage resources.|
|**Settings-specific Files**||
|HSC\_CO2\_cap.csv |Specify regional CO2 emission limits.|


### 2.1 Mandatory input data
#### 2.1.2 HSC_pipelines.csv

This input file contains input parameters related to: 1) definition of pipeline network (regions between which pipelines are explicitly modeled and can be constructed) and 2) definition of pipeline construction costs, booster compressors (for pressure losses along the pipe), and main compressors (compression from hydrogen production pressure to desired pipeline pressure). The following table describes each of the mandatory parameter inputs that need to be specified to run an instance of the model, along with comments for the model configurations when they are needed.

###### Table 3: Structure of the HSC_pipelines.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|**Settings-specific Columns**|
|**Multiple zone model**||
|H2_Pipelines | Index number of existing and candidate hydrogen pipelines.|
|Max_No_Pipe | Maximum number of hydrogen pipelines.|
|Existing_No_Pipe | Existing number of hydrogen pipelines.|
|Max_Flow_Tonne_p_Hr_Per_Pipe | Maximum capacity (flow rate) per hydrogen pipeline.|
|H2Pipe_Inv_Cost_per_mile_yr | Annulized capital investment cost per pipeline-mile.|
|Pipe_length_miles | Hydrogen pipeline length in miles.|
|H2PipeCap_tonne_per_mile | Maximum storage capacity per hydrogen pipeline per mile.|
|Min_pipecap_stor_frac | Minimum storage capacity per hydrogen pipeline in percentage of maximum.|
|len_bw_comp_mile | Length between two booster compressors in miles.|
|BoosterCompCapex_per_tonne_p_hr_yr | Annulized investment cost of booster compressors per tonne/hr.|
|BoosterCompEnergy_MWh_per_tonne | Electricity consumption of booster compressor per tonne of hydrogen in MWh.|
|H2PipeCompCapex | Annulized investment cost for main compressor (at pipeline entrance).|
|H2PipeCompEnergy | Energy consumption for main compressor.|

#### 2.1.3 HSC\_load\_data.csv

This file includes parameters to characterize model temporal resolution to approximate annual operations, hydrogen demand for each time step for each zone, and cost of load shedding. Note that DOLPHYN is designed to model hourly time steps. With some care and effort, finer (e.g. 15 minute) or courser (e.g. 2 hour) time steps can be modeled so long as all time-related parameters are scaled appropriately (e.g. time period weights, heat rates, ramp rates and minimum up and down times for generators, variable costs, etc).

###### Table 4: Structure of the HSC\_Load\_data.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|**Mandatory Columns**|
|Voll |Value of lost hydrogen load in \$/tonne-H$_2$.|
|Demand\_Segment |Number of demand curtailment/lost load segments with different cost and capacity of curtailable demand for each segment. User-specified demand segments. Integer values starting with 1 in the first row. Additional segements added in subsequent rows.|
|Cost\_of\_Demand\_Curtailment\_per\_Tonne |Cost of non-served energy/demand curtailment (for each segment), reported as a fraction of value of lost load. If *Demand\_Segment = 1*, then this parameter is a scalar and equal to one. In general this parameter is a vector of length equal to the length of Demand\_Segment.|
|Max\_Demand\_Curtailment| Maximum time-dependent demand curtailable in each segment, reported as % of the demand in each zone and each period. *If Demand\_Segment = 1*, then this parameter is a scalar and equal to one. In general this parameter is a vector of length given by length of Demand\_segment.|
|Time\_Index |Index defining time step in the model.|
|Load\_H2\_tonne\_per\_hr\_z* |Load profile of a zone z* in tonne/hr; if multiple zones, this parameter will be a matrix with columns equal to number of zones (each column named appropriate zone number appended to parameter) and rows equal to number of time periods of grid operations being modeled.|

#### 2.1.4 HSC\_generator\_variability.csv

This file contains the time-series of capacity factors / availability of each resource included in the `HSC_generators_data.csv` file for each time step (e.g. hour) modeled.

• first column: The first column contains the time index of each row (starting in the second row) from 1 to N.

• Second column onwards: Resources are listed from the second column onward with headers matching each resource name in the `HSC_generators_data.csv` file in any order. The availability for each resource at each time step is defined as a fraction of installed capacity and should be between 0 and 1. 

#### 2.1.5 HSC\_generation.csv

This file contains cost and performance parameters for various generators and other resources like hydrogen storage included in the model formulation.

###### Table 5: Mandatory columns in the HSC\_generation.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|H2_Resource | This column contains **unique** names of resources available to the model. Resources can include different types of generators and storage.|
|Zone | Integer representing zone number where the resource is located. |
|**Technology type flags**|
|New\_Build | {-1, 0, 1}, Flag for resource (storage, generation) eligibility for capacity expansion.|
||New\_Build = 1: eligible for capacity expansion and retirement. |
||New\_Build = 0: not eligible for capacity expansion, eligible for retirement.|
||New\_Build = -1: not eligible for capacity expansion or retirement.|
|H2_GEN_TYPE | {0, 1, 2}, Flag to indicate membership in set of resources for unit commitment (e.g. thermal resources like steam methane reforming)|
||H2\_GEN\_TYPE = 0: Not part of set (default) |
||H2\_GEN\_TYPE = 1: If the power plant relies on thermal energy input and subject to unit commitment constraints/decisions if `UCommit >= 1` (e.g. cycling decisions/costs/constraints). |
||H2\_GEN\_TYPE = 2: If the power plant relies on thermal energy input and is subject to simplified economic dispatch constraints (ramping limits but no cycling decisions/costs/constraints). |
|H2_LIQ | {0, 1, 2, 3, 4}, Flag to indicate membership in set of liquid resources for unit commitment (e.g. liquifiers and evaporators)|
||H2\_LIQ = 0: Not part of set (default) |
||H2\_LIQ = 1: For liquifiers subject to unit commitment constraints/decisions if `UCommit >= 1` (e.g. cycling decisions/costs/constraints). |
||H2\_LIQ = 2: For liquifiers subject to simplified economic dispatch constraints. |
||H2\_LIQ = 3: For evaporators subject to unit commitment constraints/decisions if `UCommit >= 1` (e.g. cycling decisions/costs/constraints). |
||H2\_LIQ = 4: For evaporators subject to simplified economic dispatch constraints. |
|Cap\_Size\_tonne\_p\_hr | Size (tonne/hr) of a single generating unit. This is used only for resources with integer unit commitment (`H2_GEN_TYPE = 1`) - not relevant for other resources.|
|H2\_STOR | {0, 1, 2}, Flag to indicate membership in set of storage resources and designate which type of storage resource formulation to employ.|
||H2\_STOR = 0: Not part of set (default) |
||H2\_STOR = 1: Charging power capacity and energy capacity are the investment decision variables; discharge is not considered - applies for compressed gas storage.|
||H2\_STOR = 2: For liquid storage resources. |
|H2\_FLEX | {0, 1}, Flag to indicate membership in set of flexible demand-side resources (e.g. scheduleable or time shiftable loads such as smart thermostat systems, irrigating pumping loads etc).|
||H2\_FLEX = 0: Not part of set (default) |
||H2\_FLEX = 1: Flexible demand resource.|
|LDS | {0, 1}, Defining whether H$_2$ storage is modeled as long-duration or short-duration storage |
||LDS = 0: short-duration storage (inter-period energy transfer disallowed) |
||LDS = 1: long-duration storage (inter-period energy transfer allowed) |
|**Existing technology capacity**|
|Existing\_Cap\_tonne\_p\_hr |The existing capacity of a power plant in tonne/hr.|
|Existing\_Energy\_Cap\_tonne |The existing capacity of storage in tonne where `H2_STOR = 1` or `H2_STOR = 2`.|
|Existing\_Charge\_Cap\_p\_hr |The existing charging capacity for resources where `H2_STOR = 1`.|
|**Capacity/Energy requirements**|
|Max\_Cap\_tonne\_p\_hr |-1 (default) – no limit on maximum discharge capacity of the resource. If non-negative, represents maximum allowed discharge capacity (in tonne/hr) of the resource.|
|Max\_Energy\_Cap\_tonne |-1 (default) – no limit on maximum energy capacity of the resource. If non-negative, represents maximum allowed energy capacity (in tonne) of the resource with `H2_STOR = 1` or `H2_STOR = 2`.|
|Max\_Charge\_Cap\_tonne\_p\_hr |-1 (default) – no limit on maximum charge capacity of the resource. If non-negative, represents maximum allowed charge capacity (in tonne/hr) of the resource with `H2_STOR = 2`.|
|Min\_Energy\_Cap\_tonne |-1 (default) – no limit on minimum discharge capacity of the resource. If non-negative, represents minimum allowed discharge capacity (in tonne/hr) of the resource.|
|Min\_Cap\_tonne\_p\_hr| -1 (default) – no limit on minimum energy capacity of the resource. If non-negative, represents minimum allowed energy capacity (in tonne) of the resource with `H2_STOR = 1` or `H2_STOR = 2`.|
|Min\_Charge\_Cap\_tonne\_p\_hr |-1 (default) – no limit on minimum charge capacity of the resource. If non-negative, represents minimum allowed charge capacity (in tonne/hr) of the resource with `H2_STOR = 2`.|
|**Cost parameters**|
|Inv\_Cost\_p\_tonne\_p\_hr\_yr | Annualized capacity investment cost of a technology (\$/tonne/hr/year). |
|Inv\_Cost\_Energy\_p\_tonne\_yr | Annualized investment cost of the energy capacity for a storage technology (e.g. a tank) (\$/tonne/hr/year), applicable to either `H2_STOR = 1` or `H2_STOR = 2`. |
|Inv\_Cost\_Charge\_p\_tonne\_p\_hr\_yr | Annualized capacity investment cost for the charging portion of a storage technology (e.g. compressor) with `H2_STOR = 1` (\$/tonne/hr/year). |
|Fixed\_OM\_Cost\_p\_tonne\_p\_hr\_yr | Fixed operations and maintenance cost of a technology (\$/tonne/hr/year). |
|Fixed\_OM\_Cost\_Energy\_p\_tonne\_yr | Fixed operations and maintenance cost of the energy component of a storage technology (\$/tonne/year). |
|Fixed\_OM\_Cost\_Charge\_p\_tonne\_p\_hr\_yr | Fixed operations and maintenance cost of the charging component of a storage technology of type `H2_STOR = 1`. |
|Var\_OM\_Cost\_p\_tonne | Variable operations and maintenance cost of a technology (\$/tonne). |
|Var\_OM\_Cost\_Charge\_p\_tonne | Variable operations and maintenance cost of the charging aspect of a storage technology with `H2_STOR = 1`. |
|**Technical performance parameters**|
|etaFuel\_MMBtu\_p\_tonne  |Heat rate of a generator or MMBtu of fuel consumed per tonne of electricity generated for export (net of on-site house loads). The heat rate is the inverse of the efficiency: a lower heat rate is better. Should be consistent with fuel prices in terms of reporting on higher heating value (HHV) or lower heating value (LHV) basis. |
|Fuel  |Fuel needed for a generator. The names should match with the ones in the `Fuels_data.csv`. |
|etaP2G\_MWh\_p\_tonne | Energy required per tonne of hydrogen generation.|
|H2Stor\_self\_discharge\_rate\_p\_hour |[0,1], The energy loss of storage technologies per hour (fraction loss per hour)- only applies to storage techs (e.g. boiloff fraction).|
|H2Gen\_min\_output |[0,1], The minimum generation level for a unit as a fraction of total capacity. |
|H2Stor\_min\_level |[0,1], The minimum storage level for a unit as a fraction of total capacity. |
|H2Stor\_max\_level |[0,1], The maximum storage level for a unit as a fraction of total capacity. |
|H2Stor\_Charge\_MWh\_p\_tonne | Energy consumption for charging hydrogen into storage devices for all storage types. |
|H2Stor\_Charge\_MMBtu\_p\_tonne | Fuel consumption for charging hydrogen into storage devices for all storage types. |
|Ramp\_Up\_Percentage |[0,1], Maximum increase in power output from between two periods (typically hours), reported as a fraction of nameplate capacity. Applies to thermal plants.|
|Ramp\_Dn\_Percentage |[0,1], Maximum decrease in power output from between two periods (typically hours), reported as a fraction of nameplate capacity. Applies to thermal plants.|
|H2Stor\_eff\_charge  |[0,1], Efficiency of charging storage – applies to storage technologies (all storage types). |
|H2Stor\_eff\_discharge  |[0,1], Efficiency of discharging storage – applies to storage technologies (all storage types). |
|**Optional for writing outputs**|
|region | Name of the model region|
|cluster | Number of the cluster when representing multiple clusters of a given technology in a given region.  |

###### Table 6: Settings-specific columns in the HSC\_generation.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|**H2GenCommit >= 1** | The following settings apply only to thermal plants with unit commitment constraints (`H2_GEN_TYPE = 1`).|
|Up\_Time| Minimum amount of time a resource has to stay in the committed state.|
|Down\_Time |Minimum amount of time a resource has to remain in the shutdown state.|
|Start\_Cost\_per\_tonne\_p\_hr |Cost per tonne/hr of nameplate capacity to start a generator (\$/tonne/hr per start). Multiplied by the number of generation units (each with a pre-specified nameplate capacity) that is turned on.|

### 2.2 Optional input data

#### 2.2.1 HSC\_CO2\_cap.csv

This file contains inputs specifying CO2 emission limits policies (e.g. emissions cap and permit trading programs). This file is needed if `H2CO2Cap` flag is activated in the YAML file `hsc_settings.yml`. `h2CO2Cap` flag set to 1 represents mass-based (tCO2 ) emission target. `CO2Cap` flag set to 2 is specified when emission target is given in terms of rate (tCO2/tonne-H$_2$) and is based on total demand met. `H2CO2Cap` flag set to 3 is specified when emission target is given in terms of rate (tCO2 /tonne-H$_2$) and is based on total generation. Note that there is also a global setting available to set one CO2 constraint for both power and hydrogen, in which case the limits in this file can be set to zero. 

###### Table 6: Structure of the HSC\_CO2\_cap.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|Network\_zones| zone number represented as z*|
|CO\_2\_Cap\_Zone* |If a zone is eligible for the emission limit constraint, then this column is set to 1, else 0.|
|CO\_2\_Max\_tons\_ton* |Emission limit in terms of rate|
|CO\_2\_Max\_Mtons* |Emission limit in absolute values, in Million of tons |
| | where in the above inputs, * represents the number of the emission limit constraints. For example, if the model has 2 emission limit constraints applied separately for 2 zones, the above CSV file will have 2 columns for specifying emission limit in terms of rate: CO\_2\_Max\_tons\_ton\_1 and CO\_2\_Max\_tons\_ton_\_2.|

#### 2.2.2 HSC\_G2P.csv

This file contains cost and performance parameters for various hydrogen to power resources included in the model formulation.

###### Table 7: Mandatory columns in the HSC\_G2P.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|H2_Resource | This column contains **unique** names of resources available to the model. Resources are generators that use hydrogen to produce electricity like fuel cells or CCGT. |
|Zone | Integer representing zone number where the resource is located. |
|**Technology type flags**|
|Commit | {0, 1}, Flag to indicate membership in set of resources for unit commitment (e.g. thermal resources like CCGT)|
||Commit = 0: Not part of set (default) |
||Commit = 1: If the power plant relies on thermal energy input and subject to unit commitment constraints/decisions if `UCommit >= 1` (e.g. cycling decisions/costs/constraints). |
|New\_Build | {-1, 0, 1}, Flag for resource (storage, generation) eligibility for capacity expansion.|
||New\_Build = 1: eligible for capacity expansion and retirement. |
||New\_Build = 0: not eligible for capacity expansion, eligible for retirement.|
||New\_Build = -1: not eligible for capacity expansion or retirement.|
|Cap\_size\_MW | Size (MW) of a single generating unit. This is used only for resources with integer unit commitment - not relevant for other resources.|
|**Existing technology capacity**|
|Existing\_Cap\_MW |The existing capacity of a power plant in MW.|
|**Capacity/Energy requirements**|
|Max\_Cap\_MW |-1 (default) – no limit on maximum capacity of the resource. If non-negative, represents maximum allowed discharge capacity (in MW) of the resource.|
|Min\_Cap\_MW | -1 (default) – no limit on minimum power capacity of the resource. If non-negative, represents minimum allowed power capacity (in MW) of the resource.|
|**Cost parameters**|
|Inv\_Cost\_p\_MW\_p\_yr | Annualized capacity investment cost of a technology (\$/MW/year). |
|Fixed\_OM\_p\_MW\_yr | Fixed operations and maintenance cost of a technology (\$/MW/year). |
|Var\_OM\_Cost\_p\_MWh | Variable operations and maintenance cost of a technology (\$/MWh). |
|**Technical performance parameters**|
|etaG2P\_MWh\_p\_tonne | Power generation per tonne of hydrogen consumption.|
|G2P\_min\_output |[0,1], The minimum generation level for a unit as a fraction of total capacity. |
|Ramp\_Up\_Percentage |[0,1], Maximum increase in power output from between two periods (typically hours), reported as a fraction of nameplate capacity. Applies to thermal plants.|
|Ramp\_Dn\_Percentage |[0,1], Maximum decrease in power output from between two periods (typically hours), reported as a fraction of nameplate capacity. Applies to thermal plants.|
|**Optional for writing outputs**|
|region | Name of the model region|
|cluster | Number of the cluster when representing multiple clusters of a given technology in a given region. |

###### Table 8: Settings-specific columns in the HSC\_G2P.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|**H2G2PCommit >= 1** | The following settings apply only to thermal plants with unit commitment constraints.|
|Up\_Time| Minimum amount of time a resource has to stay in the committed state.|
|Down\_Time |Minimum amount of time a resource has to remain in the shutdown state.|
|Start\_Cost\_per\_MW |Cost per tonne/hr of nameplate capacity to start a generator (\$/tonne/hr per start). Multiplied by the number of generation units (each with a pre-specified nameplate capacity) that is turned on.|

#### 2.2.3 HSC\_g2p\_generators\_variability.csv

This file contains the time-series of capacity factors / availability of each resource included in the `HSC_g2p.csv` file for each time step (e.g. hour) modeled.

• first column: The first column contains the time index of each row (starting in the second row) from 1 to N.

• Second column onwards: Resources are listed from the second column onward with headers matching each resource name in the `HSC_generators_data.csv` file in any order. The availability for each resource at each time step is defined as a fraction of installed capacity and should be between 0 and 1.

#### 2.2.4 HSC\_trucks.csv

This file contains cost and performance parameters for various hydrogen to power resources included in the model formulation.

###### Table 7: Mandatory columns in the HSC\_trucks.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|H2TruckType | This column contains **unique** names of hydrogen truck resources available to the model.|
|**Technology type flags**|
|LDS | {0, 1}, Defining whether H$_2$ storage is modeled as long-duration or short-duration storage |
||LDS = 0: short-duration storage (inter-period energy transfer disallowed) |
||LDS = 1: long-duration storage (inter-period energy transfer allowed) |
|New\_Build | {-1, 0, 1}, Flag for resource (storage, generation) eligibility for capacity expansion.|
||New\_Build = 1: eligible for capacity expansion and retirement. |
||New\_Build = 0: not eligible for capacity expansion, eligible for retirement.|
||New\_Build = -1: not eligible for capacity expansion or retirement.|
|TruckCap\_tonne\_per\_unit | Size (tonne/unit) of a single truck unit. |
|**Existing technology capacity**|
|Existing\_Number |The existing capacity of a type of hydrogen truck. |
|Existing\_Energy\_Cap\_tonne\_z* | The existing capacity of truck loading station compression in tonne. |
|**Capacity/Energy requirements**|
|Max\_Energy\_Cap\_tonne | -1 (default) – no limit on maximum compression capacity of the resource. If non-negative, represents maximum allowed compression capacity (in tonne/hr) of the resource.|
|Min\_Energy\_Cap\_tonne | 0 (default) – minimum compression capacity of the resource. If non-negative, represents minimum allowed compression capacity (in tonne/hr) of the resource. |
|H2TruckCompressionEnergy | Compression energy requirements for hydrogen per tonne.|
|**Cost parameters**|
|Inv\_Cost\_p\_unit\_p\_yr | Annualized capacity investment cost of a type of truck (\$/unit/year). |
|Inv\_Cost\_Energy\_p\_tonne\_yr | Annualized capacity investment cost of compression stations for trucks. | 
|Fixed\_OM\_p\_MW\_yr | Fixed operations and maintenance cost of a truck (\$/unit/year). |
|Fixed\_OM\_Cost\_Energy\_p\_tonne\_yr | Fixed operations and maintenance cost of compression stations for trucks. |
|H2TruckCompressionUnitOpex | Variable cost for compression for hydrogen per tonne.|
|H2TruckUnitOpex\_per\_mile\_full | Variable cost for full truck operation. |
|H2TruckUnitOpex\_per\_mile\_empty | Variable cost for empty truck operation. |
|**Technical performance parameters**|
|Full\_weight\_tonne\_per\_unit | Full truck weight per unit in tonne. |
|Empty\_weight\_tonne\_per\_unit | Empty truck weight per unit in tonne. |
|AvgTruckSpeed\_mile\_per\_hour | Average truck speed mile per hour. |
|H2TLoss\_per\_mile | Hydrogen loss percentage per mile in operation. |
|lifetime | Lifetime of truck. |
|Fuel | Fuel type of truck. |
|Fuel\_MMBTU\_per\_mile | Fuel consumption for truck in operation per mile if it burns fuels. |
|Power\_MW\_per\_mile | Power consumption for truck in operation per mile if it feeds on power. |
|H2\_tonne\_per\_mile | H$_2$ consumption for truck in operation per mile if it feeds on hydrogen. |

#### 2.2.5 HSC\_load\_data\_liquid.csv

This optional file includes parameters to characterize model temporal resolution to approximate annual operations for hydrogen liquid demand for each time step for each zone, and cost of load shedding. It is to be used when modeling liquid hydrogen. 

###### Table 8: Structure of the HSC\_load\_data\_liquid.csv file
---
|**Column Name** | **Description**|
| :------------ | :-----------|
|**Mandatory Columns**|
|Voll |Value of lost hydrogen load in \$/tonne-H$_2$.|
|Demand\_Segment |Number of demand curtailment/lost load segments with different cost and capacity of curtailable demand for each segment. User-specified demand segments. Integer values starting with 1 in the first row. Additional segements added in subsequent rows.|
|Cost\_of\_Demand\_Curtailment\_per\_Tonne |Cost of non-served energy/demand curtailment (for each segment), reported as a fraction of value of lost load. If *Demand\_Segment = 1*, then this parameter is a scalar and equal to one. In general this parameter is a vector of length equal to the length of Demand\_Segment.|
|Max\_Demand\_Curtailment| Maximum time-dependent demand curtailable in each segment, reported as % of the demand in each zone and each period. *If Demand\_Segment = 1*, then this parameter is a scalar and equal to one. In general this parameter is a vector of length given by length of Demand\_segment.|
|Time\_Index |Index defining time step in the model.|
|Load\_liqH2\_tonne\_per\_hr\_z* |Load profile of a zone z* in tonne/hr; if multiple zones, this parameter will be a matrix with columns equal to number of zones (each column named appropriate zone number appended to parameter) and rows equal to number of time periods of grid operations being modeled.|


## 3 Outputs

The table below summarizes the output variables reported as part of the various CSV files produced after each model run. The reported units are also provided. When the model is run with time domain reduction, if a result file includes time-dependent values (e.g. for each model time step), the value will not include the hour weight in it. An annual sum ("AnnualSum") column/row will be provided whenever it is possible (e.g., `emissions.csv`), and this value takes the time-weights into account. 

### 3.1 Default output files


#### 3.1.1 HSC_generation_storage_capacity.csv

Reports optimal values of investment variables (except StartCap, which is an input)

###### Table 9: Structure of the HSC_generation_storage_capacity.csv file
---
|**Output** |**Description** |**Units** |
| :------------ | :-----------|:-----------|
| StartCap |Initial H$_2$ production or discharge capacity (for storage units) of each resource type in each zone; this is an input |H$_2$ Tonnes / Hr |
| RetCap |Retired H$_2$ production or discharge capacity (for storage units) of each resource type in each zone |Tonnes / Hr |
| NewCap |Installed H$_2$ production or discharge capacity (for storage units) of each resource type in each zone |Tonnes / Hr|
| EndCap| Total H$_2$ production or discharge capacity of each resource type in each zone |Tonnes / Hr |
| StartEnergyCap |Initial H$_2$ energy capacity of each resource type in each zone; this is an input and applies only to H$_2$ storage tech.| Tonnes |
| RetEnergyCap |Retired H$_2$ energy capacity of each resource type in each zone; applies only to H$_2$ storage tech. |Tonnes |
| NewEnergyCap| Installed energy capacity of each resource type in each zone; applies only to H$_2$ storage tech. |Tonnes |
| EndEnergyCap |Total installed energy capacity of each resource type in each zone; applies only to H$_2$ storage tech. |Tonnes |
| StartChargeCap| Initial H$_2$ charging capacity of `H2_STOR = 1` resource type in each zone; this is an input |Tonnes / Hr |
| RetChargeCap |Retired H$_2$ charging capacity of `H2_STOR = 1` resource type in each zone |Tonnes / Hr |
| NewChargeCap |Installed H$_2$ charging capacity of each resource type in each zone |Tonnes / Hr |
| EndChargeCap |Total H$_2$ charging capacity of each resource type in each zone |Tonnes / Hr|


#### 3.1.2 HSC_emissions.csv

Reports CO2 emissions for each zone and each hour by H$_2$ Resources; an annual sum row will be provided (in tonnes). 

#### 3.1.4 HSC_nse.csv

Reports H$_2$ non-served energy for every model zone, time step and cost-segment.

#### 3.1.5 HSC_generation_discharge.csv

Reports H$_2$ discharged by each H$_2$ production resource (generation, storage) in each model time step, as well as the annual sum (in tonnes). 

#### 3.1.6 HSC_h2_balance.csv

Reports the use (tonnes/hour or tonnes) of each H$_2$ resource type (Generation, Flexible Demand, Storage Charge & Discharge, Nonserved Energy, H$_2$ Pipeline Import/Export, H$_2$ Truck Import/Export, G2P Demand, and Demand) for each zone and each time step, as well as the annual sum. 

#### 3.1.7 HSC_costs.csv

Reports HSC costs for each zone, including sum of fixed costs, variable costs, NSE (non-served energy) costs, start-up costs (for generators), network expansion cost of pipelines, and total costs. 

### 3.2 HSC Optional Output Files

#### 3.2.1 HSC_g2p_capacity.csv

Reports optimal values of investment variables (except StartCap, which is an input) for each G2P resource. 

###### Table 10: Structure of the HSC_g2p_capacity.csv file
---
|**Output** |**Description** |**Units** |
| :------------ | :-----------|:-----------|
| StartCap |Initial G2P Capacity in of each resource type in each zone; this is an input |MW |
| RetCap |Retired G2P capacity of each resource type in each zone |MW |
| NewCap |Installed G2P capacity of each resource type in each zone |MW |
| EndCap| Total G2P capacity of each resource type in each zone |MW |

#### 3.2.2 HSC_G2P_H2_consumption.csv

Reports H$_2$ required (in tonnes) by G2P for each zone and each model time step, as well as the annual sum. 

#### 3.2.3 HSC_charge.csv

Reports H$_2$ charging (i.e flow in tonnes for each hour) for storage resources for each zone and time step, as well as the annual sum. 

#### 3.2.4 HSC_storage.csv

Reports storage level (i.e amount of H$_2$ in tonnes) for storage resources for each zone and time step. 

#### 3.2.5 HSC_h2_pipeline_flow.csv

Reports H$_2$ level (in tonnes/hour) in each pipeline for each time step, as well as the amount of hydrogen (in tonnes) sent from the source or arrived at the sink. 

#### 3.2.6 HSC_h2_pipeline_level.csv

Reports H$_2$ level (in tonnes/hour) in each pipeline for each time step. 

#### 3.2.7 TRUCKS

Reports hydrogen transmission trucks related variables in ```h2_truck_capacity.csv``` and other outputs in several subfolders including
- H2TruckTransit: recording different truck transition status of arrive, depart and travel according to types
- H2TruckFlow: recording hydrogen flow according to types 
- H2TruckNumber: recording the number of different truck states of full and empty according to types
- H2TruckState: recording the different truck states of available full and available empty and charged or discharged at each zone

##### 3.2.7.1 H2 Truck Capacity

This file reports truck capacity and related compression capacity. The columns are separated by different truck types and ended with a total column recording total capacity over different types of trucks.

###### Table 11: Structure of the h2_truck_capacity.csv file
---
|**Output** |**Description** |**Units** |
| :------------ | :-----------|:-----------|
| StartTruck | Initial truck capacity of each truck type; this is an input |tonne-H$_2$ |
| NewTruck | Newly invested truck capacity of each truck type; this is a decision variable |tonne-H$_2$|
| RetTruck | Retired truck capacity of each truck type; this is a decision variable |tonne-H$_2$ |
| EndTruck | Total truck capacity of each truck type |tonne-H$_2$ |
|StartTruckEnergyZone{zone index}| Initial truck compression capacity of each truck type in zone {zone index}; this is an input |tonne-H$_2$/hour|
|NewTruckEnergyZone{zone index}| Newly invested truck compression capacity of each truck type in zone {zone index}; this is a decision variable|tonne-H$_2$/hour|
|RetTruckEnergyZone{zone index}| Retired truck compression capacity of each truck type in zone {zone index}; this is a decision variable|tonne-H$_2$/hour|
|EndTruckEnergyZone{zone index}| Total truck compreession capacity of each truck type in zone {zone index}|tonne-H$_2$/hour|
|StartTruckEnergy| Total initial truck compression capacity of each truck type; this is an input|tonne-H$_2$/hour|
|NewTruckEnergy| Total newly invested truck compression capacity of each truck type; this is a decision variable |tonne-H$_2$/hour|
|RetTruckEnergy| Total retired truck compression capacity of each truck type; this is a decision variable|tonne-H$_2$/hour|
|EndTruckEnergy| Total truck compreession capacity of each truck type|tonne-H$_2$/hour|

##### 3.2.7.2 H2TruckTransit Folder
This folder contains output files reporting variables of different transition statuses (arrive, depart and travel) in combination with loading statuses (full and empty). Each file is named after the pattern like H2Truck{transition}{loading}.csv like H2TruckArriveFull.csv reports total number of arriving trucks. The columns are separated by truck types and indexed with time steps. Other files have the same logic of reporting outputs.

##### 3.2.7.3 H2TruckFlow Folder
This folder contains output files reporting variables of hydrogen flow through different types of trucks. Each file is named after the pattern like H2TruckFlow_{type}.csv like H2TruckFlow_Gas.csv. H2TruckFlow_Gas.csv reports hydrogen flow through different types of hydrogen trucks. The columns are separated by zones and indexed with time steps. Other files have the same logic of reporting outputs.

##### 3.2.7.4 H2TruckNumber Folder
This folder contains output files reporting variables of total hydrogen truck number in different loading statuses. Each file is named after the pattern like H2TruckNumber{loading}.csv like H2TruckNumberFull.csv. The columns are separated by different truck types and indexed with time steps. Other files have the same logic of reporting outputs.

##### 3.2.7.5 H2TruckState Folder
This folder contains output files reporting variables of total hydrogen truck state in different statuses. Each file is named after the pattern like H2Truck{state}.csv. Candidate states are in *AvailEmpty*, *AvailFull*, *Charged* and *Discharged*. The columns are separated by combination of zones and different truck types and indexed with time steps. Other files have the same logic of reporting outputs.
