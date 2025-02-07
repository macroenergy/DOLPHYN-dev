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
    co2_cap_power_hsc(EP::Model, inputs::Dict, setup::Dict)

This policy constraints mimics the CO$_2$ emissions cap and permit trading systems, allowing for emissions trading across each zone for which the cap applies. The constraint $p \in \mathcal{P}^{CO_2}$ can be flexibly defined for mass-based or rate-based emission limits for one or more model zones, where zones can trade CO$_2$ emissions permits and earn revenue based on their CO$_2$ allowance. Note that if the model is fully linear (e.g. no unit commitment or linearized unit commitment), the dual variable of the emissions constraints can be interpreted as the marginal CO$_2$ price per tonne associated with the emissions target. Alternatively, for integer model formulations, the marginal CO$_2$ price can be obtained after solving the model with fixed integer/binary variables.

The CO$_2$ emissions limit can be defined in one of the following ways: a) a mass-based limit defined in terms of annual CO$_2$ emissions budget (in million tonnes of CO2), b) a load-side rate-based limit defined in terms of tonnes CO$_2$ per MWh of demand and c) a generation-side rate-based limit defined in terms of tonnes CO$_2$ per MWh of generation.

"""
function co2_cap_power_hsc(EP::Model, inputs::Dict, setup::Dict)

    print_and_log(" -- CO2 Policies Module for power and hydrogen system combined")

    
    SEG = inputs["SEG"]  # Number of non-served energy segments for power demand
    H2_SEG = inputs["H2_SEG"]  # Number of non-served energy segments for H2 demand
    G = inputs["G"]     # Number of resources (generators, storage, DR, and DERs)
    T = inputs["T"]     # Number of time steps (hours)
    Z = inputs["Z"]     # Number of zones

    if setup["SystemCO2Constraint"] == 1 # Independent constraints for Power and HSC
        if setup["CO2Cap"] != 0
            # CO2 constraint for power system imposed separately
            co2_cap!(EP, inputs, setup)
        end

        if setup["H2CO2Cap"] !=0
            # HSC constraint for power system imposed separately
            EP = co2_cap_hsc(EP,inputs,setup)
        end

    
    elseif setup["SystemCO2Constraint"] ==2 # Joint emissions constraint for power and HSC sector
        # In this case, we impose a single emissions constraint across both sectors
        # Constraint type to be imposed is read from genx_settings.yml 
        # NOTE: constraint type denoted by setup parameter H2CO2Cap ignored

        @expression(EP, eEmissionsConstraintLHS[cap=1:inputs["NCO2Cap"]],
            sum(inputs["omega"][t] * EP[:eEmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
        )

        if setup["ModelH2"] == 1

            @expression(EP, eEmissionsConstraintLHSH2[cap=1:inputs["NCO2Cap"]],
            sum(inputs["omega"][t] * EP[:eH2EmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
            )

            eEmissionsConstraintLHS += eEmissionsConstraintLHSH2
        end


        ## Mass-based: Emissions constraint in absolute emissions limit (tons)
        if setup["CO2Cap"] == 1
            @expression(EP, eEmissionsConstraintRHS[cap=1:inputs["NCO2Cap"]],
                sum(inputs["dfMaxCO2"][z,cap] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
            )


        elseif setup["CO2Cap"] == 2
            @expression(EP, eEmissionsConstraintRHS[cap=1:inputs["NCO2Cap"]],
                sum(
                    inputs["dfMaxCO2Rate"][z,cap] * sum(
                        inputs["omega"][t] * (inputs["pD"][t,z] - sum(EP[:vNSE][s,t,z] for s in 1:SEG)) for t=1:T
                    ) for z = findall(x->x==1, inputs["dfCO2CapZones"][:,cap])
                )
                +
                sum(
                    inputs["dfMaxCO2Rate"][z,cap] * setup["StorageLosses"] * EP[:eELOSSByZone][z] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap])
                ) 
            )
        elseif setup["CO2Cap"] == 3
            @expression(EP, eEmissionsConstraintRHS[cap=1:inputs["NCO2Cap"]],
                sum(inputs["dfMaxCO2Rate"][z,cap] * inputs["omega"][t] * EP[:eGenerationByZone][z,t] for t=1:T, z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
            )
        end

        if setup["ModelH2"] == 1

            ## Mass-based: Emissions constraint in absolute emissions limit (tons)
            if setup["CO2Cap"] == 2
                @expression(EP, eEmissionsConstraintRHSH2[cap=1:inputs["NCO2Cap"]],
                    sum(inputs["dfMaxCO2Rate"][z,cap] * H2_LHV * sum(inputs["omega"][t] * (inputs["H2_D"][t,z] + EP[:eH2DemandByZoneG2P][z,t] - sum(EP[:vH2NSE][s,t,z] for s in 1:H2_SEG)) for t=1:T) for z = findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
                )

                eEmissionsConstraintRHS += eEmissionsConstraintRHSH2
            elseif setup["CO2Cap"] == 3
                @expression(EP, eEmissionsConstraintRHSH2[cap=1:inputs["NCO2Cap"]],
                    sum(inputs["dfMaxCO2Rate"][z,cap] *H2_LHV *inputs["omega"][t] * EP[:eH2GenerationByZone][z,t] for t=1:T, z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
                )

                eEmissionsConstraintRHS += eEmissionsConstraintRHSH2
            end
        end 

        #Using an additive approach where terms are added to LHS of emissions constraint
        if setup["ModelCSC"] == 1
            @expression(EP, eEmissionsConstraintLHSCSC[cap=1:inputs["NCO2Cap"]],
                sum(inputs["omega"][t] * EP[:eCSC_Emissions_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
                - sum(inputs["omega"][t] * EP[:eDAC_CO2_Captured_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
            )

            eEmissionsConstraintLHS += eEmissionsConstraintLHSCSC

            if setup["CO2Cap"] == 2

                @expression(EP, eEmissionsConstraintRHSCSC[cap=1:inputs["NCO2Cap"]],
                    sum(inputs["dfMaxCO2Rate"][z,cap] * sum(inputs["omega"][t] * (EP[:eCSCNetpowerConsumptionByAll][t,z]) for t=1:T) for z = findall(x->x==1, inputs["dfCO2CapZones"][:,cap])) 
                )

                eEmissionsConstraintRHS += eEmissionsConstraintRHSCSC
            end 

        end
        
        #Using an additive approach where terms are added to LHS of emissions constraint
        if setup["ModelLFSC"] == 1

            if setup["Liquid_Fuels_Regional_Demand"] == 1 && setup["Liquid_Fuels_Hourly_Demand"] == 1

                #Conventional fuels global emissions
                @expression(EP, eEmissionsConstraintLHSCF[cap=1:inputs["NCO2Cap"]],
                sum(inputs["omega"][t] * EP[:eConv_Diesel_CO2_Emissions][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
                + sum(inputs["omega"][t] * EP[:eConv_Jetfuel_CO2_Emissions][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
                + sum(inputs["omega"][t] * EP[:eConv_Gasoline_CO2_Emissions][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
                )

                eEmissionsConstraintLHS += eEmissionsConstraintLHSCF
                                

            elseif setup["Liquid_Fuels_Regional_Demand"] == 1 && setup["Liquid_Fuels_Hourly_Demand"] == 0

                #Conventional fuels global emissions
                @expression(EP, eEmissionsConstraintLHSCF[cap=1:inputs["NCO2Cap"]],
                sum(EP[:eConv_Diesel_CO2_Emissions][z] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
                + sum(EP[:eConv_Jetfuel_CO2_Emissions][z] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
                + sum(EP[:eConv_Gasoline_CO2_Emissions][z] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]))
                )

                eEmissionsConstraintLHS += eEmissionsConstraintLHSCF

            elseif setup["Liquid_Fuels_Regional_Demand"] == 0 && setup["Liquid_Fuels_Hourly_Demand"] == 1

                #Conventional fuels global emissions
                @expression(EP, eEmissionsConstraintLHSCF,
                sum(inputs["omega"][t] * EP[:eConv_Diesel_CO2_Emissions][t] for t=1:T)
                + sum(inputs["omega"][t] * EP[:eConv_Jetfuel_CO2_Emissions][t] for t=1:T)
                + sum(inputs["omega"][t] * EP[:eConv_Gasoline_CO2_Emissions][t] for t=1:T)
                )
    
                #Add conventional fuels global emissions to first cap zone (if any)
                eEmissionsConstraintLHS[1] += eEmissionsConstraintLHSCF

            elseif setup["Liquid_Fuels_Regional_Demand"] == 0 && setup["Liquid_Fuels_Hourly_Demand"] == 0

                #Conventional fuels global emissions
                @expression(EP, eEmissionsConstraintLHSCF,
                EP[:eConv_Diesel_CO2_Emissions] + EP[:eConv_Jetfuel_CO2_Emissions] + EP[:eConv_Gasoline_CO2_Emissions])

                #Add conventional fuels global emissions to first cap zone (if any)
                eEmissionsConstraintLHS[1] += eEmissionsConstraintLHSCF

            end

            if setup["ModelSyntheticFuels"] == 1
                @expression(EP, eEmissionsConstraintLHSSF[cap=1:inputs["NCO2Cap"]],
                sum(inputs["omega"][t] * EP[:eSyn_Diesel_CO2_Emissions_By_Zone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
                + sum(inputs["omega"][t] * EP[:eSyn_Jetfuel_CO2_Emissions_By_Zone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
                + sum(inputs["omega"][t] * EP[:eSyn_Gasoline_CO2_Emissions_By_Zone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
                + sum(inputs["omega"][t] * EP[:eSynfuels_Production_CO2_Emissions_By_Zone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T) 
                + sum(inputs["omega"][t] * EP[:eByProdConsCO2EmissionsByZone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
                )

                eEmissionsConstraintLHS += eEmissionsConstraintLHSSF
            end

        end

        if setup["ModelNGSC"] == 1
            @expression(EP, eEmissionsConstraintLHSCNG[cap=1:inputs["NCO2Cap"]],
                sum(inputs["omega"][t] * EP[:eConv_NG_CO2_Emissions][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T))

            eEmissionsConstraintLHS += eEmissionsConstraintLHSCNG

            if setup["ModelSyntheticNG"] == 1
                @expression(EP, eEmissionsConstraintLHSSyn_NG[cap=1:inputs["NCO2Cap"]],
                sum(inputs["omega"][t] * EP[:eSyn_NG_CO2_Emissions_By_Zone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T)
                + sum(inputs["omega"][t] * EP[:eSyn_NG_Production_CO2_Emissions_By_Zone][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T))

                eEmissionsConstraintLHS += eEmissionsConstraintLHSSyn_NG
            end

            #Deduct CO2 captured by CCS technologies across sectors
            @expression(EP, eEmissionsConstraintLHSCNGCCSPower[cap=1:inputs["NCO2Cap"]],
                sum(inputs["omega"][t] * EP[:ePower_NG_CO2_captured_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T))

            eEmissionsConstraintLHS -= eEmissionsConstraintLHSCNGCCSPower


            if setup["ModelH2"] == 1
                @expression(EP, eEmissionsConstraintLHSCNGCCSH2[cap=1:inputs["NCO2Cap"]],
                    sum(inputs["omega"][t] * EP[:eHydrogen_NG_CO2_captured_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T))

                eEmissionsConstraintLHS -= eEmissionsConstraintLHSCNGCCSH2
            end

            if setup["ModelCSC"] == 1
                @expression(EP, eEmissionsConstraintLHSCNGCCSDAC[cap=1:inputs["NCO2Cap"]],
                    sum(inputs["omega"][t] * EP[:eDAC_NG_CO2_captured_per_zone_per_time][z,t] for z=findall(x->x==1, inputs["dfCO2CapZones"][:,cap]), t=1:T))

                eEmissionsConstraintLHS -= eEmissionsConstraintLHSCNGCCSDAC
            end
                
        end

        @constraint(EP, cCO2Emissions_systemwide[cap=1:inputs["NCO2Cap"]],
            eEmissionsConstraintLHS[cap] <= eEmissionsConstraintRHS[cap]
        )
    
    end
        
    return EP

end
