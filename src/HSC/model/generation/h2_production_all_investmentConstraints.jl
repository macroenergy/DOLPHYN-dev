### Split the Investment constraints from h2_production_all for Bender

function h2_production_all_investmentConstraints(EP::Model, inputs::Dict, setup::Dict)
    
    H2_GEN_RET_CAP = inputs["H2_GEN_RET_CAP"]
    H =inputs["H2_RES_ALL"]
    dfH2Gen = inputs["dfH2Gen"]

    if setup["ModelH2Liquid"] ==1
        H2_GEN_NO_COMMIT= union(inputs["H2_GEN_NO_COMMIT"], inputs["H2_LIQ_NO_COMMIT"], inputs["H2_EVAP_NO_COMMIT"])
        H2_GEN_COMMIT = union(inputs["H2_GEN_COMMIT"], inputs["H2_LIQ_COMMIT"], inputs["H2_EVAP_COMMIT"])
        H2_GEN = union(inputs["H2_GEN"], inputs["H2_LIQ"], inputs["H2_EVAP"])
    else
        H2_GEN_COMMIT = inputs["H2_GEN_COMMIT"]
        H2_GEN_NO_COMMIT = inputs["H2_GEN_NO_COMMIT"]
        H2_GEN = inputs["H2_GEN"]    
    end

    ## Constraints on retirements and capacity additions
    # Cannot retire more capacity than existing capacity
    @constraint(EP, cH2GenMaxRetNoCommit[k in setdiff(H2_GEN_RET_CAP, H2_GEN_NO_COMMIT)], EP[:vH2GenRetCap][k] <= dfH2Gen[!,:Existing_Cap_tonne_p_hr][k])
    @constraint(EP, cH2GenMaxRetCommit[k in intersect(H2_GEN_RET_CAP, H2_GEN_COMMIT)], dfH2Gen[!,:Cap_Size_tonne_p_hr][k] * EP[:vH2GenRetCap][k] <= dfH2Gen[!,:Existing_Cap_tonne_p_hr][k])

    ## Constraints on new built capacity
    # Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
    # DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MW is >= Max_Cap_MW and lead to infeasabilty
    @constraint(EP, cH2GenMaxCap[k in intersect(dfH2Gen[dfH2Gen.Max_Cap_tonne_p_hr.>0,:R_ID], 1:H)],EP[:eH2GenTotalCap][k] <= dfH2Gen[!,:Max_Cap_tonne_p_hr][k])
    
    return EP

end