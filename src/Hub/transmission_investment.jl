### This file splits the Investment decision variables for Benders Decomposition

function transmission_investment!(EP::Model, inputs::Dict, setup::Dict)

    println("Transmission Expansion Module")

	L = inputs["L"]     # Number of transmission lines

	NetworkExpansion = setup["NetworkExpansion"]
    MultiStage = setup["MultiStage"]

    if MultiStage == 1
		@variable(EP, vTRANSMAX[l=1:L] >= 0)
	end

	if NetworkExpansion == 1
		# Network lines and zones that are expandable have non-negative maximum reinforcement inputs
		EXPANSION_LINES = inputs["EXPANSION_LINES"]
	end

	### Variables ###

	if NetworkExpansion == 1
		# Transmission network capacity reinforcements per line
		@variable(EP, vNEW_TRANS_CAP[l in EXPANSION_LINES] >= 0)
	end

	### Expressions ###
	if MultiStage == 1
		@expression(EP, eTransMax[l=1:L], vTRANSMAX[l])
	else
		@expression(EP, eTransMax[l=1:L], inputs["pTrans_Max"][l])
	end
	#@expression(EP, eTransMax[l=1:L], inputs["pTrans_Max"][l]*EP[:vZERO])
	
	## Transmission power flow and loss related expressions:
	# Total availabile maximum transmission capacity is the sum of existing maximum transmission capacity plus new transmission capacity
	if NetworkExpansion == 1
		@expression(EP, eAvail_Trans_Cap[l=1:L],
			if l in EXPANSION_LINES
				eTransMax[l] + vNEW_TRANS_CAP[l]
			else
				eTransMax[l] + EP[:vZERO]
			end
		)
	else
		@expression(EP, eAvail_Trans_Cap[l=1:L], eTransMax[l] + EP[:vZERO])
	end

	## Objective Function Expressions ##

	if NetworkExpansion == 1
		@expression(EP, eTotalCNetworkExp, sum(vNEW_TRANS_CAP[l]*inputs["pC_Line_Reinforcement"][l] for l in EXPANSION_LINES))

		if MultiStage == 1
			# OPEX multiplier to count multiple years between two model stages
			# We divide by OPEXMULT since we are going to multiply the entire objective function by this term later,
			# and we have already accounted for multiple years between stages for fixed costs.
			EP[:eObj] += (1/inputs["OPEXMULT"])*eTotalCNetworkExp
		else
			EP[:eObj] += eTotalCNetworkExp
		end
	end

	## End Objective Function Expressions ##

	### Constraints ###
	if MultiStage == 1
		# Linking constraint for existing transmission capacity
		@constraint(EP, cExistingTransCap[l=1:L], vTRANSMAX[l] == inputs["pTrans_Max"][l])
	end
  	## Power flow and transmission (between zone) loss related constraints

	# If network expansion is used:
	if NetworkExpansion == 1
		# Transmission network related power flow and capacity constraints
		if MultiStage == 1 
			# Constrain maximum possible flow for lines eligible for expansion regardless of previous expansions
			@constraint(EP, cMaxFlowPossible[l in EXPANSION_LINES], eAvail_Trans_Cap[l] <= inputs["pTrans_Max_Possible"][l])
		end
		# Constrain maximum single-stage line capacity reinforcement for lines eligible for expansion
		@constraint(EP, cMaxLineReinforcement[l in EXPANSION_LINES], vNEW_TRANS_CAP[l] <= inputs["pMax_Line_Reinforcement"][l])
	end
	#END network expansion contraints


end