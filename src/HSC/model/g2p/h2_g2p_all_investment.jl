### Split the Investment constraints from h2_g2h_all for Bender
function h2_g2p_all_investment(EP::Model, inputs::Dict, setup::Dict)
    print_and_log("H2-g2p investment constraints")

    dfH2G2P = inputs["dfH2G2P"]
    H =inputs["H2_G2P_ALL"]
    H2_G2P_RET_CAP = inputs["H2_G2P_RET_CAP"]
    H2_G2P_NO_COMMIT= inputs["H2_G2P_NO_COMMIT"]
    H2_G2P_COMMIT = inputs["H2_G2P_COMMIT"]

    ## Constraints on new built capacity
    # Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
    # DEV NOTE: This constraint may be violated in some cases where Existing_Cap_MW is >= Max_Cap_MW and lead to infeasabilty
    @constraint(EP, cH2G2PMaxCap[k in intersect(dfH2G2P[dfH2G2P.Max_Cap_MW.>0,:R_ID], 1:H)],EP[:eH2G2PTotalCap][k] <= dfH2G2P[!,:Max_Cap_MW][k])


    ## Constraints on retirements and capacity additions
    # Cannot retire more capacity than existing capacity
    @constraint(EP, cH2G2PMaxRetNoCommit[k in setdiff(H2_G2P_RET_CAP, H2_G2P_NO_COMMIT)], EP[:vH2G2PRetCap][k] <= dfH2G2P[!,:Existing_Cap_MW][k])
    @constraint(EP, cH2G2PMaxRetCommit[k in intersect(H2_G2P_RET_CAP, H2_G2P_COMMIT)], dfH2G2P[!,:Cap_Size_MW][k] * EP[:vH2G2PRetCap][k] <= dfH2G2P[!,:Existing_Cap_MW][k])

    
    return EP
end