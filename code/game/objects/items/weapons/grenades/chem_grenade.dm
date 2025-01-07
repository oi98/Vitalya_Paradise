#define EMPTY 0
#define WIRED 1
#define READY 2

/obj/item/grenade/chem_grenade
	name = "grenade casing"
	desc = "A do it yourself grenade casing!"
	var/bomb_state = "chembomb"
	var/payload_name = null // used for spawned grenades
	w_class = WEIGHT_CLASS_SMALL
	force = 2
	var/prime_sound = 'sound/items/screwdriver2.ogg'
	var/stage = EMPTY
	var/list/beakers = list()
	var/list/allowed_containers = list(/obj/item/reagent_containers/glass/beaker, /obj/item/reagent_containers/glass/bottle)
	var/affected_area = 3
	var/obj/item/assembly_holder/nadeassembly = null
	var/label = null
	var/assemblyattacher
	var/ignition_temp = 10 // The amount of heat added to the reagents when this grenade goes off.
	var/threatscale = 1 // Used by advanced grenades to make them slightly more worthy.
	var/no_splash = FALSE //If the grenade deletes even if it has no reagents to splash with. Used for slime core reactions.
	var/contained = "" // For logging
	var/cores = "" // Also for logging


/obj/item/grenade/chem_grenade/Initialize(mapload)
	. = ..()
	create_reagents(1000)
	if(payload_name)
		payload_name += " " // formatting, ignore me
	update_appearance(UPDATE_ICON|UPDATE_NAME)
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)


/obj/item/grenade/chem_grenade/Destroy()
	QDEL_NULL(nadeassembly)
	if (!no_splash)
		QDEL_LIST(beakers)
	return ..()


/obj/item/grenade/chem_grenade/examine(mob/user)
	display_timer = (stage == READY && !nadeassembly)	//show/hide the timer based on assembly state
	. = ..()


/obj/item/grenade/chem_grenade/proc/get_trigger()
	if(!nadeassembly) return null
	for(var/obj/O in list(nadeassembly.a_left, nadeassembly.a_right))
		if(!O || isigniter(O)) continue
		return O
	return null


/obj/item/grenade/chem_grenade/update_icon_state()
	if(nadeassembly)
		icon = 'icons/obj/assemblies/new_assemblies.dmi'
		icon_state = bomb_state
		return

	icon = initial(icon)

	switch(stage)
		if(EMPTY)
			icon_state = "[initial(icon_state)]_unlocked"
		if(WIRED)
			icon_state = "[initial(icon_state)]_ass"
		if(READY)
			icon_state = "[initial(icon_state)][active ? "_active" : null]"


/obj/item/grenade/chem_grenade/update_overlays()
	. = ..()
	underlays.Cut()

	if(nadeassembly)
		underlays += "[nadeassembly.a_left.icon_state]_left"
		for(var/O in nadeassembly.a_left.attached_overlays)
			underlays += "[O]_l"

		underlays += "[nadeassembly.a_right.icon_state]_right"
		for(var/O in nadeassembly.a_right.attached_overlays)
			underlays += "[O]_r"


/obj/item/grenade/chem_grenade/update_name(updates)
	. = ..()

	if(nadeassembly)
		if(stage != READY)
			name = "bomb casing[label]"

		else
			var/obj/item/assembly/A = get_trigger()
			if(!A)
				name = "[payload_name]de-fused bomb[label]" // this should not actually happen
			else
				name = payload_name + A.bomb_name + label // time bombs, remote mines, etc

		return .

	switch(stage)
		if(EMPTY)
			name = "grenade casing[label]"
		if(WIRED)
			name = "grenade casing[label]"
		if(READY)
			name = payload_name + "grenade" + label


/obj/item/grenade/chem_grenade/attack_self(mob/user)
	if(active || stage != READY)
		return

	if(nadeassembly)
		nadeassembly.attack_self(user)
		update_appearance(UPDATE_ICON)

	else if(clown_check(user))
		// This used to go before the assembly check, but that has absolutely zero to do with priming the damn thing.  You could spam the admins with it.
		investigate_log("[key_name_log(usr)] has primed a [name] for detonation [contained].", INVESTIGATE_BOMB)
		add_attack_logs(user, src, "has primed (contained [contained])", ATKLOG_FEW)
		to_chat(user, span_warning("You prime the [name]! [det_time / 10] second\s!"))
		playsound(user.loc, 'sound/weapons/armbomb.ogg', 60, TRUE)
		active = TRUE
		update_appearance(UPDATE_ICON_STATE)

		if(iscarbon(user))
			var/mob/living/carbon/C = user
			C.throw_mode_on()

		addtimer(CALLBACK(src, PROC_REF(prime), user), det_time)


/obj/item/grenade/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = ITEM_ATTACK)
	var/obj/item/projectile/P = hitby
	if(damage && attack_type == PROJECTILE_ATTACK && P.damage_type != STAMINA && prob(15))
		owner.visible_message("<span class='danger'>[attack_text] hits [owner]'s [src], setting it off! What a shot!</span>")
		add_attack_logs(P.firer, owner, "A projectile ([hitby]) detonated a grenade held", ATKLOG_FEW)
		prime()
		return 1 //It hit the grenade, not them


/obj/item/grenade/chem_grenade/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/hand_labeler))
		add_fingerprint(user)
		var/obj/item/hand_labeler/labeler = I

		if(length(labeler.label))
			label = " ([labeler.label])"
			update_appearance(UPDATE_NAME)
			to_chat(user, span_notice("You apply new label to [src]."))
			playsound(user.loc, 'sound/items/handling/component_pickup.ogg', 20, TRUE)
			return ATTACK_CHAIN_PROCEED_SUCCESS|ATTACK_CHAIN_NO_AFTERATTACK

		label = null
		update_appearance(UPDATE_NAME)
		to_chat(user, span_notice("You remove the label from [src]."))
		playsound(user.loc, 'sound/items/handling/component_pickup.ogg', 20, TRUE)
		return ATTACK_CHAIN_PROCEED_SUCCESS|ATTACK_CHAIN_NO_AFTERATTACK

	switch(stage)
		if(WIRED)
			if(!is_type_in_list(I, allowed_containers))
				return ..()
			add_fingerprint(user)
			if(length(beakers) >= 2)
				to_chat(user, span_notice("The [name] can not hold more containers."))
				return ATTACK_CHAIN_PROCEED
			if((!I.reagents || !I.reagents.total_volume) && !istype(I, /obj/item/slime_extract))
				to_chat(user, span_notice("The [I.name] is empty."))
				return ATTACK_CHAIN_PROCEED
			if(!user.drop_transfer_item_to_loc(I, src))
				return ..()
			beakers += I
			to_chat(user, span_notice("You add [I] to the assembly."))
			return ATTACK_CHAIN_BLOCKED_ALL

		if(EMPTY)
			if(istype(I, /obj/item/assembly_holder))
				add_fingerprint(user)
				var/obj/item/assembly_holder/new_assembly = I
				if(!new_assembly.secured)
					to_chat(user, span_warning("The [new_assembly.name] should be secured."))
					return ATTACK_CHAIN_PROCEED
				if(isigniter(new_assembly.a_left) == isigniter(new_assembly.a_right))
					to_chat(user, span_warning("The [new_assembly.name] should hold only one igniter."))
					return ATTACK_CHAIN_PROCEED
				if(!user.drop_transfer_item_to_loc(I, src))
					return ..()
				nadeassembly = new_assembly
				if(nadeassembly.has_prox_sensors())
					AddComponent(/datum/component/proximity_monitor)
				nadeassembly.master = src
				assemblyattacher = user.ckey
				stage = WIRED
				to_chat(user, span_notice("You have added [nadeassembly] to [src]."))
				update_appearance(UPDATE_ICON|UPDATE_NAME)
				return ATTACK_CHAIN_BLOCKED_ALL

			if(iscoil(I))
				add_fingerprint(user)
				var/obj/item/stack/cable_coil/coil = I
				if(!coil.use(1))
					to_chat(user, span_warning("You need more cable length."))
					return ATTACK_CHAIN_PROCEED
				stage = WIRED
				update_appearance(UPDATE_ICON_STATE|UPDATE_NAME)
				to_chat(user, span_notice("You rig [src]."))
				return ATTACK_CHAIN_PROCEED_SUCCESS

	return ..()


/obj/item/grenade/chem_grenade/wirecutter_act(mob/living/user, obj/item/I)
	if(stage != READY)
		return FALSE
	. = TRUE
	if(!I.use_tool(src, user, volume = I.tool_volume))
		return .
	to_chat(user, span_notice("You unlock the assembly."))
	stage = WIRED
	update_appearance(UPDATE_ICON_STATE|UPDATE_NAME)


/obj/item/grenade/chem_grenade/wrench_act(mob/living/user, obj/item/I)
	if(stage != WIRED)
		return FALSE
	. = TRUE
	if(!I.use_tool(src, user, volume = I.tool_volume))
		return .
	to_chat(user, span_notice("You open the grenade and remove the contents."))
	stage = EMPTY
	payload_name = null
	label = null
	var/atom/drop_loc = drop_location()
	if(nadeassembly)
		nadeassembly.forceMove(drop_loc)
		nadeassembly.master = null
		nadeassembly = null
		qdel(GetComponent(/datum/component/proximity_monitor))
	else
		new /obj/item/stack/cable_coil(drop_loc, 1)
	if(length(beakers))
		for(var/obj/item/beaker as anything in beakers)
			beaker.forceMove(drop_loc)
		beakers = list()
	update_appearance(UPDATE_ICON_STATE|UPDATE_NAME)


/obj/item/grenade/chem_grenade/screwdriver_act(mob/living/user, obj/item/I)
	if(stage != WIRED && stage != READY && stage != EMPTY)
		return FALSE

	. = TRUE

	switch(stage)
		if(EMPTY)
			to_chat(user, span_notice("You need to add an activation mechanism."))

		if(READY)
			if(nadeassembly)
				to_chat(user, span_notice("You cannot modify timer when [nadeassembly] is attached."))
				return .
			det_time = det_time == 5 SECONDS ? 3 SECONDS : 5 SECONDS
			to_chat(user, span_notice("You modify the time delay. It's set for [det_time / 10] second\s."))

		if(WIRED)
			if(!length(beakers))
				to_chat(user, span_notice("You need to add at least one beaker before locking the assembly."))
				return .
			to_chat(user, span_notice("You lock the assembly."))
			playsound(loc, prime_sound, 25, TRUE, -3)
			stage = READY
			update_appearance(UPDATE_ICON_STATE|UPDATE_NAME)
			contained = ""
			cores = "" // clear them out so no recursive logging by accidentally
			for(var/obj/item/thing as anything in beakers)
				if(!thing.reagents)
					continue
				if(istype(thing, /obj/item/slime_extract))
					cores += " [thing.name]"
				for(var/datum/reagent/reagent as anything in thing.reagents.reagent_list)
					contained += "[reagent.volume] [reagent], "
			if(contained)
				if(cores)
					contained = "\[[cores]; [contained]\]"
				else
					contained = "\[ [contained]\]"
			var/turf/bombturf = get_turf(src)
			add_attack_logs(user, src, "has completed with [contained]", ATKLOG_MOST)
			log_game("[key_name(usr)] has completed [name] at [bombturf.x], [bombturf.y], [bombturf.z]. [contained]")


//assembly stuff
/obj/item/grenade/chem_grenade/receive_signal(datum/signal/signal)
	prime(signal?.user)

/obj/item/grenade/chem_grenade/HasProximity(atom/movable/AM)
	if(nadeassembly)
		nadeassembly.HasProximity(AM)

/obj/item/grenade/chem_grenade/Move(atom/newloc, direct = NONE, glide_size_override = 0, update_dir = TRUE) // prox sensors and infrared care about this
	. = ..()
	if(nadeassembly)
		nadeassembly.process_movement()

/obj/item/grenade/chem_grenade/pickup()
	. = ..()
	if(nadeassembly)
		nadeassembly.process_movement()


/obj/item/grenade/chem_grenade/proc/on_entered(datum/source, atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER

	if(nadeassembly)
		nadeassembly.assembly_crossed(arrived, old_loc)


/obj/item/grenade/chem_grenade/on_found(mob/finder)
	if(nadeassembly)
		nadeassembly.on_found(finder)

/obj/item/grenade/chem_grenade/hear_talk(mob/living/M, list/message_pieces)
	if(nadeassembly)
		nadeassembly.hear_talk(M, message_pieces)

/obj/item/grenade/chem_grenade/hear_message(mob/living/M, msg)
	if(nadeassembly)
		nadeassembly.hear_message(M, msg)

/obj/item/grenade/chem_grenade/Bump(atom/bumped_atom)
	. = ..()
	if(!nadeassembly)
		return .
	nadeassembly.process_movement()

/obj/item/grenade/chem_grenade/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum) // called when a throw stops
	..()
	if(nadeassembly)
		nadeassembly.process_movement()


/obj/item/grenade/chem_grenade/prime(mob/user)
	. = ..()
	if(stage != READY)
		return

	var/turf/source_turf = get_turf(src)
	if(!source_turf)
		return

	update_mob()

	var/list/datum/reagents/reactants = list()
	for(var/obj/item/reagent_containers/container as anything in beakers)
		reactants += container.reagents

	if(!chem_splash(source_turf, affected_area, reactants, ignition_temp, threatscale) && !no_splash)
		playsound(loc, 'sound/items/screwdriver2.ogg', 50, TRUE)
		if(length(beakers))
			for(var/obj/item/reagent_containers/container as anything in beakers)
				container.forceMove(source_turf)
			beakers = list()
		stage = EMPTY
		update_appearance(UPDATE_ICON_STATE|UPDATE_NAME)
		return

	if(nadeassembly)
		var/mob/M = get_mob_by_ckey(assemblyattacher)
		var/mob/last = get_mob_by_ckey(nadeassembly.fingerprintslast)
		message_admins("grenade primed by an assembly, [user ? "triggered by [key_name_admin(user)] and" : ""] attached by [key_name_admin(M)] [last ? "and last touched by [key_name_admin(last)]" : ""] ([nadeassembly.a_left.name] and [nadeassembly.a_right.name]) at [ADMIN_VERBOSEJMP(src)]. [contained]")
		add_game_logs("grenade primed by an assembly, [user ? "triggered by [key_name_log(user)] and" : ""] attached by [key_name_log(M)] [last ? "and last touched by [key_name_log(last)]" : ""] ([nadeassembly.a_left.name] and [nadeassembly.a_right.name]) at [AREACOORD(src)]. [contained]", user)

	qdel(src)

/obj/item/grenade/chem_grenade/proc/CreateDefaultTrigger(var/typekey)
	if(ispath(typekey,/obj/item/assembly))
		nadeassembly = new(src)
		if(nadeassembly.has_prox_sensors())
			AddComponent(/datum/component/proximity_monitor)
		nadeassembly.a_left = new /obj/item/assembly/igniter(nadeassembly)
		nadeassembly.a_left.holder = nadeassembly
		nadeassembly.a_left.secured = 1
		nadeassembly.a_right = new typekey(nadeassembly)
		if(!nadeassembly.a_right.secured)
			nadeassembly.a_right.toggle_secure() // necessary because fuxing prock_sensors
		nadeassembly.a_right.holder = nadeassembly
		nadeassembly.secured = 1
		nadeassembly.master = src
		nadeassembly.update_icon()
		stage = READY
		update_appearance(UPDATE_ICON|UPDATE_NAME)


//Large chem grenades accept slime cores and use the appropriately.
/obj/item/grenade/chem_grenade/large
	name = "large grenade casing"
	desc = "A custom made large grenade. It affects a larger area."
	icon_state = "large_grenade"
	bomb_state = "largebomb"
	allowed_containers = list(
		/obj/item/reagent_containers/glass,
		/obj/item/reagent_containers/food/condiment,
		/obj/item/reagent_containers/food/drinks,
		/obj/item/slime_extract,
	)
	origin_tech = "combat=3;engineering=3"
	affected_area = 5
	ignition_temp = 25 // Large grenades are slightly more effective at setting off heat-sensitive mixtures than smaller grenades.
	threatscale = 1.1	// 10% more effective.

/obj/item/grenade/chem_grenade/large/prime(mob/user)
	if(stage != READY)
		return

	for(var/obj/item/slime_extract/S in beakers)
		if(S.Uses)
			for(var/obj/item/reagent_containers/glass/G in beakers)
				G.reagents.trans_to(S, G.reagents.total_volume)

			//If there is still a core (sometimes it's used up)
			//and there are reagents left, behave normally,
			//otherwise drop it on the ground for timed reactions like gold.

			if(S)
				if(S.reagents && S.reagents.total_volume)
					for(var/obj/item/reagent_containers/glass/G in beakers)
						S.reagents.trans_to(G, S.reagents.total_volume)
				else
					S.forceMove(get_turf(src))
					no_splash = TRUE
	..(user)


/obj/item/grenade/chem_grenade/cryo // Intended for rare cryogenic mixes. Cools the area moderately upon detonation.
	name = "cryo grenade"
	desc = "A custom made cryogenic grenade. It rapidly cools its contents upon detonation."
	icon_state = "cryog"
	affected_area = 2
	ignition_temp = -100

/obj/item/grenade/chem_grenade/pyro // Intended for pyrotechnical mixes. Produces a small fire upon detonation, igniting potentially flammable mixtures.
	name = "pyro grenade"
	desc = "A custom made pyrotechnical grenade. It heats up and ignites its contents upon detonation."
	icon_state = "pyrog"
	origin_tech = "combat=4;engineering=4"
	affected_area = 3
	ignition_temp = 500 // This is enough to expose a hotspot.

/obj/item/grenade/chem_grenade/adv_release // Intended for weaker, but longer lasting effects. Could have some interesting uses.
	name = "advanced release grenade"
	desc = "A custom made advanced release grenade. It is able to be detonated more than once. Can be configured using a multitool."
	icon_state = "timeg"
	origin_tech = "combat=3;engineering=4"
	var/unit_spread = 10 // Amount of units per repeat. Can be altered with a multitool.

/obj/item/grenade/chem_grenade/adv_release/multitool_act(mob/user, obj/item/I)
	. = TRUE
	if(!I.use_tool(src, user, 0, volume = I.tool_volume))
		return
	switch(unit_spread)
		if(0 to 24)
			unit_spread += 5
		if(25 to 99)
			unit_spread += 25
		else
			unit_spread = 5
	to_chat(user, "<span class='notice'> You set the time release to [unit_spread] units per detonation.</span>")

/obj/item/grenade/chem_grenade/adv_release/prime(mob/user)
	if(stage != READY)
		return

	var/total_volume = 0
	for(var/obj/item/reagent_containers/RC in beakers)
		total_volume += RC.reagents.total_volume
	if(!total_volume)
		qdel(src)
		qdel(nadeassembly)
		return
	var/fraction = unit_spread/total_volume
	var/datum/reagents/reactants = new(unit_spread)
	reactants.my_atom = src
	for(var/obj/item/reagent_containers/RC in beakers)
		RC.reagents.trans_to(reactants, RC.reagents.total_volume*fraction, threatscale, 1, 1)
	chem_splash(get_turf(src), affected_area, list(reactants), ignition_temp, threatscale)

	if(nadeassembly)
		var/mob/M = get_mob_by_ckey(assemblyattacher)
		var/mob/last = get_mob_by_ckey(nadeassembly.fingerprintslast)
		message_admins("grenade primed by an assembly, [user ? "triggered by [key_name_admin(user)] and" : ""] attached by [key_name_admin(M)] [last ? "and last touched by [key_name_admin(last)]" : ""] ([nadeassembly.a_left.name] and [nadeassembly.a_right.name]) at [ADMIN_VERBOSEJMP(src)]. [contained]")
		add_game_logs("grenade primed by an assembly, [user ? "triggered by [key_name_log(user)] and" : ""] attached by [key_name_log(M)] [last ? "and last touched by [key_name_log(last)]" : ""] ([nadeassembly.a_left.name] and [nadeassembly.a_right.name]) at [AREACOORD(src)]. [contained]")
	else
		addtimer(CALLBACK(src, PROC_REF(prime)), det_time)
	var/turf/DT = get_turf(src)
	var/area/DA = get_area(DT)
	add_game_logs("A grenade detonated at [DA.name] [COORD(DT)]")

/obj/item/grenade/chem_grenade/metalfoam
	payload_name = "metal foam"
	desc = "Used for emergency sealing of air breaches."
	stage = READY

/obj/item/grenade/chem_grenade/metalfoam/Initialize(mapload)
	. = ..()

	var/obj/item/reagent_containers/glass/beaker/B1 = new(src)
	var/obj/item/reagent_containers/glass/beaker/B2 = new(src)

	B1.reagents.add_reagent("aluminum", 30)
	B2.reagents.add_reagent("fluorosurfactant", 10)
	B2.reagents.add_reagent("sacid", 10)

	beakers += B1
	beakers += B2


/obj/item/grenade/chem_grenade/firefighting
	payload_name = "fire fighting grenade"
	desc = "Can help to put out dangerous fires from a distance."
	icon = 'icons/obj/weapons/grenade.dmi'
	icon_state = "firefighting"
	stage = READY

/obj/item/grenade/chem_grenade/firefighting/Initialize(mapload)
	. = ..()

	var/obj/item/reagent_containers/glass/beaker/B1 = new(src)
	var/obj/item/reagent_containers/glass/beaker/B2 = new(src)

	B1.reagents.add_reagent("firefighting_foam", 30)
	B2.reagents.add_reagent("firefighting_foam", 30)

	beakers += B1
	beakers += B2

/obj/item/grenade/chem_grenade/incendiary
	payload_name = "incendiary"
	desc = "Used for clearing rooms of living things."
	stage = READY

/obj/item/grenade/chem_grenade/incendiary/Initialize(mapload)
	. = ..()

	var/obj/item/reagent_containers/glass/beaker/large/B1 = new(src)
	var/obj/item/reagent_containers/glass/beaker/large/B2 = new(src)

	B1.reagents.add_reagent("phosphorus", 25)
	B2.reagents.add_reagent("plasma", 25)
	B2.reagents.add_reagent("sacid", 25)


	beakers += B1
	beakers += B2


/obj/item/grenade/chem_grenade/antiweed
	payload_name = "weed killer"
	desc = "Used for purging large areas of invasive plant species. Contents under pressure. Do not directly inhale contents."
	icon = 'icons/obj/weapons/grenade.dmi'
	icon_state = "antiweed"
	stage = READY

/obj/item/grenade/chem_grenade/antiweed/Initialize(mapload)
	. = ..()

	var/obj/item/reagent_containers/glass/beaker/large/B1 = new(src)
	var/obj/item/reagent_containers/glass/beaker/large/B2 = new(src)

	B1.reagents.add_reagent("atrazine", 85)
	B1.reagents.add_reagent("potassium", 15)
	B2.reagents.add_reagent("phosphorus", 15)
	B2.reagents.add_reagent("sugar", 15)
	B2.reagents.add_reagent("atrazine", 70)

	beakers += B1
	beakers += B2


/obj/item/grenade/chem_grenade/cleaner
	payload_name = "cleaner"
	desc = "BLAM!-brand foaming space cleaner. In a special applicator for rapid cleaning of wide areas."
	icon = 'icons/obj/weapons/grenade.dmi'
	icon_state = "cleaner"
	stage = READY

/obj/item/grenade/chem_grenade/cleaner/Initialize(mapload)
	. = ..()

	var/obj/item/reagent_containers/glass/beaker/B1 = new(src)
	var/obj/item/reagent_containers/glass/beaker/B2 = new(src)

	B1.reagents.add_reagent("fluorosurfactant", 40)
	B2.reagents.add_reagent("cleaner", 10)
	B2.reagents.add_reagent("water", 40) //when you make pre-designed foam reactions that carry the reagents, always add water last

	beakers += B1
	beakers += B2


/obj/item/grenade/chem_grenade/teargas
	payload_name = "teargas"
	desc = "Used for nonlethal riot control. Contents under pressure. Do not directly inhale contents."
	icon = 'icons/obj/weapons/grenade.dmi'
	icon_state = "teargas"
	stage = READY

/obj/item/grenade/chem_grenade/teargas/Initialize(mapload)
	. = ..()

	var/obj/item/reagent_containers/glass/beaker/large/B1 = new(src)
	var/obj/item/reagent_containers/glass/beaker/large/B2 = new(src)

	B1.reagents.add_reagent("condensedcapsaicin", 85)
	B1.reagents.add_reagent("potassium", 15)
	B2.reagents.add_reagent("phosphorus", 15)
	B2.reagents.add_reagent("sugar", 15)
	B2.reagents.add_reagent("condensedcapsaicin", 70)

	beakers += B1
	beakers += B2

/obj/item/grenade/chem_grenade/facid
	payload_name = "acid smoke"
	desc = "Use to chew up opponents from the inside out."
	stage = READY

/obj/item/grenade/chem_grenade/facid/Initialize(mapload)
	. = ..()

	var/obj/item/reagent_containers/glass/beaker/large/B1 = new(src)
	var/obj/item/reagent_containers/glass/beaker/large/B2 = new(src)

	B1.reagents.add_reagent("facid", 85)
	B1.reagents.add_reagent("potassium", 15)
	B2.reagents.add_reagent("phosphorus", 15)
	B2.reagents.add_reagent("sugar", 15)
	B2.reagents.add_reagent("facid", 70)

	beakers += B1
	beakers += B2

/obj/item/grenade/chem_grenade/saringas
	payload_name = "sarin gas"
	desc = "Contains sarin gas; extremely deadly and fast acting; use with extreme caution."
	stage = READY

/obj/item/grenade/chem_grenade/saringas/Initialize(mapload)
	. = ..()

	var/obj/item/reagent_containers/glass/beaker/B1 = new(src)
	var/obj/item/reagent_containers/glass/beaker/B2 = new(src)

	B1.reagents.add_reagent("sarin", 85)
	B1.reagents.add_reagent("potassium", 15)
	B2.reagents.add_reagent("phosphorus", 15)
	B2.reagents.add_reagent("sugar", 15)
	B2.reagents.add_reagent("sarin", 70)

	beakers += B1
	beakers += B2

#undef EMPTY
#undef WIRED
#undef READY
