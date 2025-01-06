@doc raw"""
	write_liquid_fuel_balance_dual(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

Function for reporting the liquid fuels balance dual of resources across different zones with time for each type of fuels.
"""
function write_liquid_fuel_balance_dual(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

	T = inputs["T"]     # Number of time steps (hours)
	Z = inputs["Z"]     # Number of zones

	omega = inputs["omega"] # Time step weights

	if setup["Liquid_Fuels_Regional_Demand"] == 1 && setup["Liquid_Fuels_Hourly_Demand"] == 1
		dfGasolineBalanceDual = DataFrame(Zone = 1:Z)
		dual_values = transpose(dual.(EP[:cLFGasolineBalance_T_Z]) ./ omega)
		
		dfGasolineBalanceDual=hcat(dfGasolineBalanceDual, DataFrame(dual_values, :auto))
		rename!(dfGasolineBalanceDual,[Symbol("Zone");[Symbol("t$t") for t in 1:T]])
		
		CSV.write(string(path,sep,"LFSC_gasoline_balance_dual.csv"), dftranspose(dfGasolineBalanceDual, false), writeheader=false)

		
		dfJetfuelBalanceDual = DataFrame(Zone = 1:Z)
		dual_values = transpose(dual.(EP[:cLFJetfuelBalance_T_Z]) ./ omega)

		dfJetfuelBalanceDual=hcat(dfJetfuelBalanceDual, DataFrame(dual_values, :auto))
		rename!(dfJetfuelBalanceDual,[Symbol("Zone");[Symbol("t$t") for t in 1:T]])

		CSV.write(string(path,sep,"LFSC_jetfuel_balance_dual.csv"), dftranspose(dfJetfuelBalanceDual, false), writeheader=false)


		dfDieselBalanceDual = DataFrame(Zone = 1:Z)
		dual_values = transpose(dual.(EP[:cLFDieselBalance_T_Z]) ./ omega)

		dfDieselBalanceDual=hcat(dfDieselBalanceDual, DataFrame(dual_values, :auto))
		rename!(dfDieselBalanceDual,[Symbol("Zone");[Symbol("t$t") for t in 1:T]])

		CSV.write(string(path,sep,"LFSC_diesel_balance_dual.csv"), dftranspose(dfDieselBalanceDual, false), writeheader=false)

	elseif setup["Liquid_Fuels_Regional_Demand"] == 1 && setup["Liquid_Fuels_Hourly_Demand"] == 0

		dfGasolineBalanceDual = DataFrame(Zone = 1:Z)
		dual_values = dual.(EP[:cLFGasolineBalance_Z])

		dfGasolineBalanceDual = hcat(dfGasolineBalanceDual, DataFrame(DualValue = dual_values))

    	CSV.write(string(path, sep, "LFSC_gasoline_balance_dual.csv"), dfGasolineBalanceDual, writeheader=false)


		dfJetfuelBalanceDual = DataFrame(Zone = 1:Z)
		dual_values = dual.(EP[:cLFJetfuelBalance_Z])

		dfJetfuelBalanceDual = hcat(dfJetfuelBalanceDual, DataFrame(DualValue = dual_values))

    	CSV.write(string(path, sep, "LFSC_jetfuel_balance_dual.csv"), dfJetfuelBalanceDual, writeheader=false)


		dfDieselBalanceDual = DataFrame(Zone = 1:Z)
		dual_values = dual.(EP[:cLFDieselBalance_Z])

		dfDieselBalanceDual = hcat(dfDieselBalanceDual, DataFrame(DualValue = dual_values))

    	CSV.write(string(path, sep, "LFSC_diesel_balance_dual.csv"), dfDieselBalanceDual, writeheader=false)

	elseif setup["Liquid_Fuels_Regional_Demand"] == 0 && setup["Liquid_Fuels_Hourly_Demand"] == 1

		dfGasolineBalanceDual = DataFrame(TimeStep = 1:T)
		dual_values = dual.(EP[:cLFGasolineBalance_T]) ./ omega
	
		dfGasolineBalanceDual = hcat(dfGasolineBalanceDual, DataFrame(DualValue = dual_values))
	
		CSV.write(string(path, sep, "LFSC_gasoline_balance_dual.csv"), dfGasolineBalanceDual, writeheader=false)


		dfJetfuelBalanceDual = DataFrame(TimeStep = 1:T)
		dual_values = dual.(EP[:cLFJetfuelBalance_T]) ./ omega
	
		dfJetfuelBalanceDual = hcat(dfJetfuelBalanceDual, DataFrame(DualValue = dual_values))
	
		CSV.write(string(path, sep, "LFSC_jetfuel_balance_dual.csv"), dfJetfuelBalanceDual, writeheader=false)


		dfDieselBalanceDual = DataFrame(TimeStep = 1:T)
		dual_values = dual.(EP[:cLFDieselBalance_T]) ./ omega
	
		dfDieselBalanceDual = hcat(dfDieselBalanceDual, DataFrame(DualValue = dual_values))
	
		CSV.write(string(path, sep, "LFSC_diesel_balance_dual.csv"), dfDieselBalanceDual, writeheader=false)

	elseif setup["Liquid_Fuels_Regional_Demand"] == 0 && setup["Liquid_Fuels_Hourly_Demand"] == 0

		dual_value = dual(EP[:cLFGasolineBalance])
		dfGasolineBalanceDual = DataFrame(DualValue = [dual_value])
	
		CSV.write(string(path, sep, "LFSC_gasoline_balance_dual.csv"), dfGasolineBalanceDual, writeheader=true)


		dual_value = dual(EP[:cLFJetfuelBalance])
		dfJetfuelBalanceDual = DataFrame(DualValue = [dual_value])
	
		CSV.write(string(path, sep, "LFSC_jetfuel_balance_dual.csv"), dfJetfuelBalanceDual, writeheader=true)


		dual_value = dual(EP[:cLFDieselBalance])
		dfDieselBalanceDual = DataFrame(DualValue = [dual_value])
	
		CSV.write(string(path, sep, "LFSC_diesel_balance_dual.csv"), dfDieselBalanceDual, writeheader=true)

	end

end
