"""
DOLPHYN: Decision Optimization for Low-carbon for Power and Hydrogen Networks
Copyright (C) 2023,  Massachusetts Institute of Technology
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

using Dolphyn
using Gurobi

# The directory containing your settings folder and files
settings_path = joinpath(@__DIR__, "Settings")

# The directory containing your input data
inputs_path = @__DIR__

# Load settings
mysetup = load_settings(settings_path)

# Setup logging 
global_logger = setup_logging(mysetup)

### Load DOLPHYN
println("Loading packages")

##TO ADD SYNFUEL SETTING IMPORT

# Setup time domain reduction and cluster inputs if necessary
setup_TDR(inputs_path, settings_path, mysetup)

# ### Configure solver
print_and_log("Configuring Solver")

OPTIMIZER = configure_solver(mysetup["Solver"], settings_path, Gurobi.Optimizer)

# #### Running a case

# ### Load inputs
myinputs = load_all_inputs(mysetup, inputs_path)

# ### Generate model
EP = generate_model(mysetup, myinputs, OPTIMIZER)

using JuMP

function scale_constraints!(EP::Model, max_coeff::Float64=1e6, min_coeff::Float64=1e-3)
    con_list = all_constraints(EP; include_variable_in_set_constraints=false)
    scale_constraints!(con_list, max_coeff, min_coeff)
end
function scale_constraints!(constraint_list::Vector{ConstraintRef}, max_coeff::Float64=1e6, min_coeff::Float64=1e-3)
    action_count = 0
    for con_ref in constraint_list
        con_obj = constraint_object(con_ref)
        coefficients = abs.(append!(con_obj.func.terms.vals, normalized_rhs(con_ref)))
        # coefficients[coefficients .< min_coeff / 100] .= 0 # Set any coefficients less than min_coeff / 100 to zero
        coefficients = coefficients[coefficients .> 0] # Ignore constraints which equal zero
        if length(coefficients) == 0
            continue
        end
        max_ratio = maximum(coefficients) / max_coeff
        min_ratio = min_coeff / minimum(coefficients)
        if max_ratio > 1 && min_ratio < 1
            if min_ratio / max_ratio < 1
                for (key, val) in con_obj.func.terms
                    set_normalized_coefficient(con_ref, key, val / max_ratio)
                end
                set_normalized_rhs(con_ref, normalized_rhs(con_ref) / max_ratio)
                action_count += 1
            end
        elseif min_ratio > 1 && max_ratio < 1
            if max_ratio * min_ratio < 1
                for (key, val) in con_obj.func.terms
                    set_normalized_coefficient(con_ref, key, val * min_ratio)
                end
                set_normalized_rhs(con_ref, normalized_rhs(con_ref) * min_ratio)
                action_count += 1
            end
        end
    end
    return action_count
end
scale_constraints!(EP)

set_optimizer_attribute(OPTIMIZER, "BarHomogeneous", 1)
set_optimizer_attribute(OPTIMIZER, "Method", 2)

### Solve model
print_and_log("Solving Model")  
EP, solve_time = solve_model(EP, mysetup)
myinputs["solve_time"] = solve_time # Store the model solve time in myinputs

### Write power system output

print_and_log("Writing Output")
write_all_outputs(EP,mysetup, myinputs, inputs_path)