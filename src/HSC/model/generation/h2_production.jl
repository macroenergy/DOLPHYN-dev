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
    h2_production(EP::Model, inputs::Dict, setup::Dict)

This module creates decision variables, expressions, and constraints related to various hydrogen generation technologies (electrolyzers, natural gas reforming etc.)

This module uses the following 'helper' functions in separate files: ```h2_production_commit()``` for thermal resources subject to unit commitment decisions and constraints (if any) and ```h2_production_no_commit()``` for thermal hydrogen generation resources not subject to unit commitment (if any).
"""
function h2_production(EP::Model, inputs::Dict, setup::Dict)

    print_and_log(" -- H2 Production Module")
    
    if !isempty(inputs["H2_GEN"])
        # expressions, variables and constraints common to all types of hydrogen generation technologies
        EP = h2_production_all_investmentConstraints(EP::Model, inputs::Dict, setup::Dict)
        EP = h2_production_all(EP::Model, inputs::Dict, setup::Dict) #constraints for operations
    end

    if setup["ModelH2Liquid"] == 1
        H2_GEN_COMMIT = union(inputs["H2_GEN_COMMIT"], inputs["H2_LIQ_COMMIT"], inputs["H2_EVAP_COMMIT"])
        H2_GEN_NO_COMMIT = union(inputs["H2_GEN_NO_COMMIT"], inputs["H2_LIQ_NO_COMMIT"], inputs["H2_EVAP_NO_COMMIT"])
    else
        H2_GEN_COMMIT = inputs["H2_GEN_COMMIT"]
        H2_GEN_NO_COMMIT = inputs["H2_GEN_NO_COMMIT"]
    end
    dfH2Gen = inputs["dfH2Gen"]  # Input H2 generation and storage data
    Z = inputs["Z"]  # Model demand zones - assumed to be same for H2 and electricity
    T = inputs["T"]     # Model operating time steps

    if !isempty(H2_GEN_COMMIT)
        EP = h2_production_commit(EP::Model, inputs::Dict, setup::Dict)
    end

    if !isempty(H2_GEN_NO_COMMIT)
        EP = h2_production_no_commit(EP::Model, inputs::Dict, setup::Dict)
    end

    ## For CO2 Policy constraint right hand side development - H2 Generation by zone and each time step
    @expression(EP, eH2GenerationByZone[z=1:Z, t=1:T], # the unit is MWh/hour
    sum(EP[:vH2Gen][y,t] for y in intersect(inputs["H2_GEN"], dfH2Gen[dfH2Gen[!,:Zone].==z,:R_ID]))
    )


    EP[:eH2GenerationByZone] += eH2GenerationByZone

    return EP
end
