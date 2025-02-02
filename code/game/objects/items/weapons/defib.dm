//backpack item

/obj/item/defibrillator
	name = "defibrillator"
	desc = "Прибор, генерирующий высоковольтный импульс, позволяющий запустить остановившееся сердце."
	ru_names = list(
		NOMINATIVE = "дефибриллятор",
		GENITIVE = "дефибриллятора",
		DATIVE = "дефибриллятору",
		ACCUSATIVE = "дефибриллятор",
		INSTRUMENTAL = "дефибриллятором",
		PREPOSITIONAL = "дефибрилляторе"
	)
	icon_state = "defibunit"
	item_state = "defibunit"
	slot_flags = ITEM_SLOT_BACK
	force = 5
	throwforce = 6
	w_class = WEIGHT_CLASS_BULKY
	origin_tech = "biotech=4"
	actions_types = list(/datum/action/item_action/toggle_paddles)
	armor = list("melee" = 0, "bullet" = 0, "laser" = 0, "energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 50, "acid" = 50)
	sprite_sheets = list(
		SPECIES_VOX = 'icons/mob/clothing/species/vox/back.dmi'
		)

	/// If the paddles are currently attached to the unit.
	var/paddles_on_defib = TRUE
	/// if there's a cell in the defib with enough power for a revive; blocks paddles from reviving otherwise
	var/powered = FALSE
	/// Ref to attached paddles
	var/obj/item/twohanded/shockpaddles/paddles
	/// Ref to internal power cell.
	var/obj/item/stock_parts/cell/high/cell = null
	/// If false, using harm intent will let you zap people. Note that any updates to this after init will only impact icons.
	var/safety = TRUE
	/// If true, this can be used through hardsuits
	var/ignore_hardsuits = FALSE
	// If safety is false and combat is true, the chance that this will cause a heart attack.
	var/heart_attack_probability = 30
	/// If this is vulnerable to EMPs.
	var/hardened = FALSE
	/// If this can be emagged.
	var/emag_proof = FALSE
	/// Type of paddles that should be attached to this defib.
	var/obj/item/twohanded/shockpaddles/paddle_type = /obj/item/twohanded/shockpaddles


/obj/item/defibrillator/Initialize(mapload) // Base version starts without a cell for rnd
	. = ..()
	paddles = new paddle_type(src)
	update_icon(UPDATE_OVERLAYS)


/obj/item/defibrillator/Destroy()
	if(!paddles_on_defib)
		var/holder = get(paddles.loc, /mob/living/carbon/human)
		retrieve_paddles(holder)
	QDEL_NULL(paddles)
	QDEL_NULL(cell)
	return ..()


/obj/item/defibrillator/loaded/Initialize(mapload) // Loaded version starts with high-capacity cell.
	. = ..()
	cell = new(src)
	update_icon(UPDATE_OVERLAYS)


/obj/item/defibrillator/get_cell()
	return cell


/obj/item/defibrillator/update_icon(updates = ALL)
	update_power()
	. = ..()


/obj/item/defibrillator/examine(mob/user)
	. = ..()
	. += span_info("Используйте <b>Ctrl + ЛКМ</b>, чтобы взять лопасти.")


/obj/item/defibrillator/proc/update_power()
	if(cell)
		if(cell.charge < paddles.revivecost)
			powered = FALSE
		else
			powered = TRUE
	else
		powered = FALSE


/obj/item/defibrillator/update_overlays()
	. = ..()
	if(paddles_on_defib)
		. += "[icon_state]-paddles"
	if(powered)
		. += "[icon_state]-powered"
	if(!safety)
		. += "[icon_state]-emagged"
	if(powered && cell)
		var/ratio = cell.charge / cell.maxcharge
		ratio = CEILING(ratio*4, 1) * 25
		. += "[icon_state]-charge[ratio]"
	if(!cell)
		. += "[icon_state]-nocell"


/obj/item/defibrillator/CheckParts(list/parts_list)
	..()
	cell = locate(/obj/item/stock_parts/cell) in contents
	update_icon(UPDATE_OVERLAYS)


/obj/item/defibrillator/ui_action_click(mob/user, datum/action/action, leftclick)
	if(!ishuman(user) || !Adjacent(user))
		return

	toggle_paddles(user)


/obj/item/defibrillator/CtrlClick(mob/user)
	if(!ishuman(user) || user.incapacitated() || HAS_TRAIT(user, TRAIT_HANDS_BLOCKED) || !Adjacent(user))
		return

	toggle_paddles(user)


/obj/item/defibrillator/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stock_parts/cell))
		add_fingerprint(user)
		var/obj/item/stock_parts/cell/new_cell = I
		if(cell)
			balloon_alert(user, "слот для батареи занят!")
			return ATTACK_CHAIN_PROCEED
		if(new_cell.maxcharge < paddles.revivecost)
			balloon_alert(user, "требуется батарея большей мощности!")
			return ATTACK_CHAIN_PROCEED
		if(!user.drop_transfer_item_to_loc(new_cell, src))
			return ..()
		cell = new_cell
		update_icon(UPDATE_OVERLAYS)
		balloon_alert(user, "батарея установлена")
		return ATTACK_CHAIN_BLOCKED_ALL

	if(I == paddles)
		toggle_paddles(user)
		return ATTACK_CHAIN_BLOCKED_ALL

	return ..()


/obj/item/defibrillator/screwdriver_act(mob/living/user, obj/item/I)
	if(!cell)
		balloon_alert(user, "слот для батареи пуст!")
		return

	// we want an infinite power cell to stay inside (used in advanced compact defib)
	if(istype(cell, /obj/item/stock_parts/cell/infinite))
		balloon_alert(user, "невозможно извлечь батарею!")
		return

	cell.update_icon()
	cell.forceMove_turf()
	cell = null
	I.play_tool_sound(src)
	balloon_alert(user, "батарея извлечена")
	update_icon(UPDATE_OVERLAYS)
	return TRUE

/obj/item/defibrillator/emp_act(severity)
	if(cell)
		deductcharge(1000 / severity)
	safety = !safety
	update_icon(UPDATE_OVERLAYS)
	..()

/obj/item/defibrillator/emag_act(mob/user)
	add_attack_logs(user, src, "[safety ? "" : "un-"]emagged")
	safety = !safety
	..()
	update_icon(UPDATE_OVERLAYS)

/obj/item/defibrillator/verb/toggle_paddles_verb()
	set name = "Взять лопасти"
	set category = "Object"
	set src in oview(1)

	if(usr.incapacitated() || HAS_TRAIT(usr, TRAIT_HANDS_BLOCKED))
		return

	toggle_paddles(usr)


/obj/item/defibrillator/proc/toggle_paddles(mob/living/carbon/human/user = usr)
	if(!paddles)
		balloon_alert(user, "лопасти отсутствуют!")
		return

	if(paddles_on_defib)
		dispence_paddles(user)
	else
		retrieve_paddles(user)

	for(var/datum/action/action as anything in actions)
		action.UpdateButtonIcon()


/obj/item/defibrillator/proc/dispence_paddles(mob/living/carbon/human/user)
	if(!paddles || !paddles_on_defib || !ishuman(user) || user.incapacitated())
		return

	//Detach the paddles into the user's hands
	var/obj/item/organ/external/hand_left = user.get_organ(BODY_ZONE_PRECISE_L_HAND)
	var/obj/item/organ/external/hand_right = user.get_organ(BODY_ZONE_PRECISE_R_HAND)

	if((!hand_left || !hand_left.is_usable()) && (!hand_right || !hand_right.is_usable()))
		balloon_alert(user, "невозможно взять в руки!")
		return

	paddles_on_defib = FALSE
	paddles.loc = get_turf(src)	// we need this to play animation properly
	if(!user.put_in_hands(paddles, ignore_anim = FALSE))
		paddles.loc = src
		paddles_on_defib = TRUE
		balloon_alert(user, "руки заняты!")
		return

	paddles.update_icon(UPDATE_ICON_STATE)
	update_icon(UPDATE_OVERLAYS)


/obj/item/defibrillator/proc/retrieve_paddles(mob/user)
	if(!paddles || paddles_on_defib)
		return
	if(user?.is_in_hands(paddles))
		user.drop_item_ground(paddles)
	paddles.do_pickup_animation(src)
	paddles.forceMove(src)
	paddles_on_defib = TRUE
	update_icon(UPDATE_OVERLAYS)
	paddles.update_icon(UPDATE_ICON_STATE)


/obj/item/defibrillator/equipped(mob/user, slot)
	. = ..()
	if(slot != ITEM_SLOT_BACK)
		retrieve_paddles(user)


/obj/item/defibrillator/item_action_slot_check(slot, mob/user, datum/action/action)
	return slot == ITEM_SLOT_BACK


/obj/item/defibrillator/proc/deductcharge(chrgdeductamt)
	if(cell)
		if(cell.charge < (paddles.revivecost+chrgdeductamt))
			powered = FALSE
			update_icon(UPDATE_OVERLAYS)
		if(cell.use(chrgdeductamt))
			update_icon(UPDATE_OVERLAYS)
			return TRUE
		else
			update_icon(UPDATE_OVERLAYS)
			return FALSE

/obj/item/defibrillator/compact
	name = "compact defibrillator"
	desc = "Переносной дефибриллятор, оборудован для ношения на поясе."
	ru_names = list(
		NOMINATIVE = "компактный дефибриллятор",
		GENITIVE = "компактного дефибриллятора",
		DATIVE = "компактному дефибриллятору",
		ACCUSATIVE = "компактный дефибриллятор",
		INSTRUMENTAL = "компактным дефибриллятором",
		PREPOSITIONAL = "компактном дефибрилляторе"
	)
	icon_state = "defibcompact"
	item_state = "defibcompact"
	w_class = WEIGHT_CLASS_NORMAL
	slot_flags = ITEM_SLOT_BELT
	origin_tech = "biotech=5"
	heart_attack_probability = 10

/obj/item/defibrillator/compact/item_action_slot_check(slot, mob/user, datum/action/action)
	if(slot == ITEM_SLOT_BELT)
		return TRUE

/obj/item/defibrillator/compact/loaded/Initialize(mapload)
	. = ..()
	cell = new(src)
	update_icon(UPDATE_OVERLAYS)

/obj/item/defibrillator/compact/combat
	name = "combat defibrillator"
	desc = "Переносной дефибриллятор кроваво-красного цвета, оборудован для ношения на поясе. Не оснащён протоколами безопасности, в отличие от обычных дефибрилляторов. Может работать через скафандры."
	ru_names = list(
		NOMINATIVE = "боевой дефибриллятор",
		GENITIVE = "боевого дефибриллятора",
		DATIVE = "боевому дефибриллятору",
		ACCUSATIVE = "боевой дефибриллятор",
		INSTRUMENTAL = "боевым дефибриллятором",
		PREPOSITIONAL = "боевом дефибрилляторе"
	)
	icon_state = "defibcombat"
	item_state = "defibcombat"
	paddle_type = /obj/item/twohanded/shockpaddles/syndicate
	ignore_hardsuits = TRUE
	safety = FALSE
	heart_attack_probability = 100

/obj/item/defibrillator/compact/combat/loaded/Initialize(mapload)
	. = ..()
	cell = new(src)
	update_icon(UPDATE_OVERLAYS)

/obj/item/defibrillator/compact/advanced
	name = "advanced compact defibrillator"
	desc = "Высокотехнологичный продвинутый дефибриллятор, созданный для использования в самых экстремальных условиях. Выполнен из передовых материалов, благодаря чему его почти невозможно повредить или уничтожить. Использует экспериментальную батарею с функций самозаряда. Может работать через скафандры."
	ru_names = list(
		NOMINATIVE = "продвинутый компактный дефибриллятор",
		GENITIVE = "продвинутого компактного дефибриллятора",
		DATIVE = "продвинутому компактному дефибриллятору",
		ACCUSATIVE = "продвинутый компактный дефибриллятор",
		INSTRUMENTAL = "продвинутым компактным дефибриллятором",
		PREPOSITIONAL = "продвинутом компактном дефибрилляторе"
	)
	icon_state = "defibnt"
	item_state = "defibnt"
	paddle_type = /obj/item/twohanded/shockpaddles/advanced
	ignore_hardsuits = TRUE
	safety = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF //Objective item, better not have it destroyed.
	heart_attack_probability = 100

	var/next_emp_message //to prevent spam from the emagging message on the advanced defibrillator

/obj/item/defibrillator/compact/advanced/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/high_value_item)

/obj/item/defibrillator/compact/advanced/loaded/Initialize(mapload)
	. = ..()
	cell = new /obj/item/stock_parts/cell/infinite(src)
	update_icon(UPDATE_OVERLAYS)


/obj/item/defibrillator/compact/advanced/emp_act(severity)
	if(world.time > next_emp_message)
		atom_say("Предупреждение: зафиксирован мощный электро-магнитный импульс. Защитная система предотвратила возможное повреждение оборудования.")
		playsound(src, 'sound/machines/defib_saftyon.ogg', 50)
		next_emp_message = world.time + 5 SECONDS

//paddles

/obj/item/twohanded/shockpaddles
	name = "defibrillator paddles"
	desc = "Пара лопастей с тонкими металлическими пластинами, оснащённых пластиковыми ручками. Используются для подачи мощных ударов электрическим током."
	ru_names = list(
		NOMINATIVE = "лопасти дефибриллятора",
		GENITIVE = "лопастей дефибриллятора",
		DATIVE = "лопастям дефибриллятора",
		ACCUSATIVE = "лопасти дефибриллятора",
		INSTRUMENTAL = "лопастями дефибриллятора",
		PREPOSITIONAL = "лопастях дефибриллятора"
	)
	icon_state = "defibpaddles"
	item_state = "defibpaddles"
	force = 0
	throwforce = 6
	w_class = WEIGHT_CLASS_BULKY
	resistance_flags = INDESTRUCTIBLE
	toolspeed = 1
	item_flags = ABSTRACT
	/// Amount of power used on a shock.
	var/revivecost = 1000
	/// Active defib this is connected to.
	var/obj/item/defibrillator/defib
	/// Whether or not the paddles are on cooldown. Used for tracking icon states.
	var/on_cooldown = FALSE

/obj/item/twohanded/shockpaddles/advanced
	name = "advanced defibrillator paddles"
	desc = "Пара высокотехнологичных лопастей с тонкими пласталевыми пластинами, оснащённых пластиковыми ручками. Используются для подачи мощных ударов электрическим током, могут действовать сквозь слой брони."
	ru_names = list(
		NOMINATIVE = "лопасти продвинутого дефибриллятора",
		GENITIVE = "лопастей продвинутого дефибриллятора",
		DATIVE = "лопастям продвинутого дефибриллятора",
		ACCUSATIVE = "лопасти продвинутого дефибриллятора",
		INSTRUMENTAL = "лопастями продвинутого дефибриллятора",
		PREPOSITIONAL = "лопастях продвинутого дефибриллятора"
	)
	icon_state = "ntpaddles"
	item_state = "ntpaddles"

/obj/item/twohanded/shockpaddles/syndicate
	name = "combat defibrillator paddles"
	desc = "A pair of high-tech paddles with flat plasteel surfaces to revive deceased operatives (unless they exploded). They possess both the ability to penetrate armor and to deliver powerful or disabling shocks offensively."
	desc = "Пара высокотехнологичных лопастей с тонкими пласталевыми пластинами, оснащённых пластиковыми ручками. Используются для подачи мощных ударов электрическим током, могут действовать сквозь слой брони. Одинаково хорошо подходят как для оживления мёртвых оперативников, так и для устранения противников."
	ru_names = list(
		NOMINATIVE = "лопасти боевого дефибриллятора",
		GENITIVE = "лопастей боевого дефибриллятора",
		DATIVE = "лопастям боевого дефибриллятора",
		ACCUSATIVE = "лопасти боевого дефибриллятора",
		INSTRUMENTAL = "лопастями боевого дефибриллятора",
		PREPOSITIONAL = "лопастях боевого дефибриллятора"
	)
	icon_state = "syndiepaddles"
	item_state = "syndiepaddles"

/obj/item/twohanded/shockpaddles/New(mainunit)
	. = ..()
	add_defib_component(mainunit)

/obj/item/twohanded/shockpaddles/proc/add_defib_component(mainunit)
	if(check_defib_exists(mainunit))
		update_icon(UPDATE_ICON_STATE)
		AddComponent(/datum/component/defib, actual_unit = defib, ignore_hardsuits = defib.ignore_hardsuits, safe_by_default = defib.safety, heart_attack_chance = defib.heart_attack_probability, emp_proof = defib.hardened, emag_proof = defib.emag_proof)
	else
		AddComponent(/datum/component/defib)
	RegisterSignal(src, COMSIG_DEFIB_READY, PROC_REF(on_cooldown_expire))
	RegisterSignal(src, COMSIG_DEFIB_SHOCK_APPLIED, PROC_REF(after_shock))
	RegisterSignal(src, COMSIG_DEFIB_PADDLES_APPLIED, PROC_REF(on_application))

/obj/item/twohanded/shockpaddles/Destroy()
	defib = null
	return ..()

/// Check to see if we should abort this before we've even gotten started
/obj/item/twohanded/shockpaddles/proc/on_application(obj/item/paddles, mob/living/user, mob/living/carbon/human/target, should_cause_harm)
	SIGNAL_HANDLER  // COMSIG_DEFIB_PADDLES_APPLIED

	if(!HAS_TRAIT(src, TRAIT_WIELDED))
		balloon_alert(user, "нужно держать обеими руками!")
		return COMPONENT_BLOCK_DEFIB_MISC

	if(!defib.powered)
		return COMPONENT_BLOCK_DEFIB_DEAD


/obj/item/twohanded/shockpaddles/proc/on_cooldown_expire(obj/item/paddles)
	SIGNAL_HANDLER  // COMSIG_DEFIB_READY
	on_cooldown = FALSE
	if(defib.cell)
		if(defib.cell.charge >= revivecost)
			atom_say("Заряд готов.")
			playsound(get_turf(src), 'sound/machines/defib_ready.ogg', 50)
		else
			atom_say("Заряд исчерпан.")
			playsound(get_turf(src), 'sound/machines/defib_failed.ogg', 50, 0)
		update_icon(UPDATE_ICON_STATE)
	defib.update_icon(UPDATE_ICON_STATE)


/obj/item/twohanded/shockpaddles/proc/after_shock()
	SIGNAL_HANDLER  // COMSIG_DEFIB_SHOCK_APPLIED
	on_cooldown = TRUE
	defib.deductcharge(revivecost)
	update_icon(UPDATE_ICON_STATE)

/obj/item/twohanded/shockpaddles/update_icon_state()
	var/is_wielded = HAS_TRAIT(src, TRAIT_WIELDED)
	icon_state = "[initial(icon_state)][is_wielded][on_cooldown ? "_cooldown" : ""]"
	item_state = "[initial(icon_state)][is_wielded]"


/obj/item/twohanded/shockpaddles/suicide_act(mob/user)
	user.visible_message(span_suicide("[user] поднос[pluralize_ru(user.gender, "ит", "ят")] включенные лопасти к своей груди! Похоже, что [genderize_ru(user.gender, "он", "она", "оно", "они")] пыта[pluralize_ru(user.gender, "ет", "ют")]ся совершить самоубийство!"))
	defib.deductcharge(revivecost)
	playsound(get_turf(src), 'sound/machines/defib_zap.ogg', 50, 1, -1)
	return OXYLOSS


/obj/item/twohanded/shockpaddles/dropped(mob/user, slot, silent = FALSE)
	. = ..()
	if(defib)
		defib.toggle_paddles(user)
		if(!silent)
			balloon_alert(user, "лопасти возвращены на место")
	UnregisterSignal(user, COMSIG_MOB_CLIENT_MOVED)

/obj/item/twohanded/shockpaddles/equip_to_best_slot(mob/user, force = FALSE)
	user.drop_item_ground(src)

/obj/item/twohanded/shockpaddles/equipped(mob/user, slot, initial)
	. = ..()
	RegisterSignal(user, COMSIG_MOB_CLIENT_MOVED, PROC_REF(on_mob_move), override = TRUE)

/obj/item/twohanded/shockpaddles/on_mob_move(mob/user, dir)
	if(defib && !in_range(defib, src))
		user.drop_item_ground(src, force = TRUE)

/obj/item/twohanded/shockpaddles/proc/check_defib_exists(obj/item/defibrillator/mainunit)
	if(!mainunit || !istype(mainunit))	//To avoid weird issues from admin spawns
		qdel(src)
		return FALSE
	loc = mainunit
	defib = mainunit
	return TRUE

/obj/item/twohanded/shockpaddles/borg
	desc = "Пара встроенных лопастей с тонкими металлическими пластинами. Используются для подачи мощных ударов электрическим током."
	icon_state = "defibpaddles0"
	item_state = "defibpaddles0"
	var/safety = TRUE
	var/heart_attack_probability = 10

/obj/item/twohanded/shockpaddles/borg/dropped(mob/user, slot, silent = FALSE)
	SHOULD_CALL_PARENT(FALSE)
	// No-op.

/obj/item/twohanded/shockpaddles/borg/attack_self()
	// Standard two-handed weapon behavior is disabled.
	return

/obj/item/twohanded/shockpaddles/borg/add_defib_component(mainunit)
	var/is_combat_borg = istype(loc, /obj/item/robot_module/syndicate_medical) || istype(loc, /obj/item/robot_module/ninja)

	AddComponent(/datum/component/defib, robotic = TRUE, ignore_hardsuits = is_combat_borg, safe_by_default = safety, emp_proof = TRUE, heart_attack_chance = heart_attack_probability)

	RegisterSignal(src, COMSIG_DEFIB_READY, PROC_REF(on_cooldown_expire))
	RegisterSignal(src, COMSIG_DEFIB_SHOCK_APPLIED, PROC_REF(after_shock))

/obj/item/twohanded/shockpaddles/borg/after_shock(obj/item/defib, mob/user)
	on_cooldown = TRUE
	if(isrobot(user))
		var/mob/living/silicon/robot/R = user
		R.cell.use(revivecost)
	update_icon(UPDATE_ICON_STATE)

/obj/item/twohanded/shockpaddles/borg/on_cooldown_expire(obj/item/paddles)
	visible_message(span_notice("[capitalize(declent_ru(NOMINATIVE))] сообщает: заряд готов."))
	playsound(get_turf(src), 'sound/machines/defib_ready.ogg', 50, 0)
	on_cooldown = FALSE
	update_icon(UPDATE_ICON_STATE)

/obj/item/twohanded/shockpaddles/borg/update_icon_state()
	icon_state = "[initial(icon_state)][on_cooldown ? "_cooldown" : ""]"

