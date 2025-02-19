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
	load_bio_electricity(setup::Dict, path::AbstractString, sep::AbstractString, inputs_bioenergy::Dict)

Function for reading input parameters related to bio electricity resources in the bioenergy supply chain.
"""
function load_bio_electricity(setup::Dict, path::AbstractString, sep::AbstractString, inputs_bioenergy::Dict)

	
	bioELEC = DataFrame(CSV.File(string(path,sep,"BESC_Bio_Electricity.csv"), header=true), copycols=true)

	# Add Resource IDs after reading to prevent user errors
	bioELEC[!,:R_ID] = 1:size(collect(skipmissing(bioELEC[!,1])),1)

	# Store DataFrame of capture units/resources input data for use
	inputs_bioenergy["dfBioELEC"] = bioELEC

	# Index of BIO resources - can be either commit, no_commit capture technologies, demand side, G2P, or storage resources
	inputs_bioenergy["BIO_ELEC_RES_ALL"] = size(collect(skipmissing(bioELEC[!,:R_ID])),1)

	inputs_bioenergy["BIO_ELEC_RESOURCES_NAME"] = collect(skipmissing(bioELEC[!,:Biorefinery][1:inputs_bioenergy["BIO_ELEC_RES_ALL"]]))

	# Resource identifiers by zone (just zones in resource order + resource and zone concatenated)
	bio_zones = collect(skipmissing(bioELEC[!,:Zone][1:inputs_bioenergy["BIO_ELEC_RES_ALL"]]))
	inputs_bioenergy["BIO_ELEC_R_ZONES"] = bio_zones
	inputs_bioenergy["BIO_ELEC_RESOURCE_ZONES"] = inputs_bioenergy["BIO_ELEC_RESOURCES_NAME"] .* "_z" .* string.(bio_zones)

	##############################################################################################################################################

	# Set of plants accepting herbaceous biomass
	inputs_bioenergy["BIO_ELEC_HERB"] = bioELEC[bioELEC.Biomass_type.== 1 ,:R_ID]

	# Set of plants accepting woody biomass
	inputs_bioenergy["BIO_ELEC_WOOD"] = bioELEC[bioELEC.Biomass_type.== 2 ,:R_ID]

	# Set of plants accepting agriculture residue biomass
	inputs_bioenergy["BIO_ELEC_AGRI_RES"] = bioELEC[bioELEC.Biomass_type.== 3 ,:R_ID]

	# Set of plants accepting agriculture process waste
	inputs_bioenergy["BIO_ELEC_AGRI_PROCESS_WASTE"] = bioELEC[bioELEC.Biomass_type.== 4 ,:R_ID]

	# Set of plants accepting forest biomass
	inputs_bioenergy["BIO_ELEC_FOREST"] = bioELEC[bioELEC.Biomass_type.== 5 ,:R_ID]

	println(" -- BESC_Bio_Electricity.csv Successfully Read!")

    return inputs_bioenergy

end

