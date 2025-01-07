/obj/structure/blob/special // Generic type for nodes/factories/cores/resource
	// Core and node vars: claiming, pulsing and expanding
	/// The radius inside which (previously dead) blob tiles are 'claimed' again by the pulsing overmind. Very rarely used.
	var/claim_range = 0
	/// The radius inside which blobs are pulsed by this overmind. Does stuff like expanding, making blob spores from factories, make resources from nodes etc.
	var/pulse_range = 0
	/// The radius up to which this special structure naturally grows normal blobs.
	var/expand_range = 0

	// Area reinforcement vars: used by cores and nodes, for strains to modify
	/// Range this blob free upgrades to strong blobs at: for the core, and for strains
	var/strong_reinforce_range = 0
	/// Range this blob free upgrades to reflector blobs at: for the core, and for strains
	var/reflector_reinforce_range = 0

/obj/structure/blob/special/proc/reinforce_area(seconds_per_tick) // Used by cores and nodes to upgrade their surroundings
	if(strong_reinforce_range)
		if(is_there_multiz())
			for(var/obj/structure/blob/normal/B in urange_multiz(strong_reinforce_range, src))
				reinforce_tile(B, /obj/structure/blob/shield/core, seconds_per_tick)
		else
			for(var/obj/structure/blob/normal/B in range(strong_reinforce_range, src))
				reinforce_tile(B, /obj/structure/blob/shield/core, seconds_per_tick)
				
	if(reflector_reinforce_range)
		if(is_there_multiz())
			for(var/obj/structure/blob/shield/B in urange_multiz(reflector_reinforce_range, src))
				reinforce_tile(B, /obj/structure/blob/shield/reflective/core, seconds_per_tick)
		else
			for(var/obj/structure/blob/shield/B in range(reflector_reinforce_range, src))
				reinforce_tile(B, /obj/structure/blob/shield/reflective/core, seconds_per_tick)


/obj/structure/blob/special/proc/reinforce_tile(obj/structure/blob/B, type, seconds_per_tick)
	if(SPT_PROB(BLOB_REINFORCE_CHANCE, seconds_per_tick))
		B.change_to(type, overmind, B.point_return)


/obj/structure/blob/special/proc/pulse_area(mob/camera/blob/pulsing_overmind, claim_range = 10, pulse_range = 3, expand_range = 2)
	if(QDELETED(pulsing_overmind))
		pulsing_overmind = overmind
	Be_Pulsed()
	var/expanded = FALSE
	if(prob(70*(1/BLOB_EXPAND_CHANCE_MULTIPLIER)) && expand())
		expanded = TRUE
	var/list/blobs_to_affect = list()
	if(is_there_multiz())
		for(var/obj/structure/blob/blob in urange_multiz(claim_range, src, 1))
			blobs_to_affect += blob
	else
		for(var/obj/structure/blob/B in urange(claim_range, src, 1))
			blobs_to_affect += B
	shuffle_inplace(blobs_to_affect)
	for(var/L in blobs_to_affect)
		var/obj/structure/blob/B = L
		if(!is_location_within_transition_boundaries(get_turf(B)))
			continue
		if(!B.overmind && overmind && prob(30))
			B.link_to_overmind(pulsing_overmind) //reclaim unclaimed, non-core blobs.
			B.update_blob()
		var/distance = get_dist(get_turf(src), get_turf(B))
		var/expand_probablity = max(20 - distance * 8, 1)
		if(B.Adjacent(src))
			expand_probablity = 20
		if(distance <= expand_range)
			var/can_expand = TRUE
			if(blobs_to_affect.len >= 120 && !(COOLDOWN_FINISHED(B, heal_timestamp)))
				can_expand = FALSE
			if(can_expand && COOLDOWN_FINISHED(B, pulse_timestamp) && prob(expand_probablity*BLOB_EXPAND_CHANCE_MULTIPLIER))
				if(!expanded)
					var/obj/structure/blob/newB = B.expand(null, null, !expanded) //expansion falls off with range but is faster near the blob causing the expansion
					if(newB)
						expanded = TRUE
		if(distance <= pulse_range)
			B.Be_Pulsed()
