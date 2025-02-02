// ERTs

#define ERT_TYPE_AMBER		1
#define ERT_TYPE_RED		2
#define ERT_TYPE_GAMMA		3

//Ranks

#define MEDIUM_RANK_HOURS	200
#define MAX_RANK_HOURS		500

/datum/game_mode
	var/list/datum/mind/ert = list()

GLOBAL_LIST_EMPTY(response_team_members)
GLOBAL_VAR_INIT(responseteam_age, 21) // Minimum account age to play as an ERT member
GLOBAL_DATUM(active_team, /datum/response_team)
GLOBAL_VAR_INIT(send_emergency_team, FALSE)
GLOBAL_VAR_INIT(ert_request_answered, TRUE)
GLOBAL_LIST_EMPTY(ert_request_messages)

/client/proc/response_team()
	set name = "Dispatch CentComm Response Team"
	set category = "Admin.Event"
	set desc = "Отправляет на станцию ​Отряд Быстрого Реагирования."

	if(!check_rights(R_EVENT))
		return

	if(!SSticker)
		to_chat(usr, span_warning("Игра ещё не началась!"))
		return

	if(SSticker.current_state == GAME_STATE_PREGAME)
		to_chat(usr, span_warning("Раунд ещё не начался!"))
		return

	if(GLOB.send_emergency_team)
		to_chat(usr, span_warning("Центральное Командование уже направило Отряд Быстрого Реагирования!"))
		return

	var/datum/ui_module/ert_manager/E = new()
	E.ui_interact(usr)


/mob/dead/observer/proc/JoinResponseTeam()
	if(!GLOB.send_emergency_team)
		to_chat(src, span_warning("Отряд Быстрого Реагирования не был отправлен."))
		return FALSE

	if(jobban_isbanned(src, ROLE_ERT))
		to_chat(src, span_warning("У вас джоббан на роль бойца ОБР!"))
		return FALSE

	if(jobban_isbanned(src, JOB_TITLE_OFFICER) || jobban_isbanned(src, JOB_TITLE_CAPTAIN) || jobban_isbanned(src, JOB_TITLE_CYBORG))
		to_chat(src, span_warning("Один из ваших джоббанов запрещает вам играть в ОБР!"))
		return FALSE

	var/player_age_check = check_client_age(client, GLOB.responseteam_age)
	if(player_age_check && CONFIG_GET(flag/use_age_restriction_for_antags))
		to_chat(src, span_warning("Эта роль вам пока недоступна. Вам нужно подождать ещё [player_age_check] [declension_ru(player_age_check, "день", "дня", "дней")]."))
		return FALSE

	if(cannotPossess(src))
		to_chat(src, span_boldnotice("Активировав Антаг-ХУД, вы лишились возможности присоединиться к раунду."))
		return FALSE

	return TRUE

/proc/trigger_armed_response_team(datum/response_team/response_team_type, commander_slots, security_slots, medical_slots, engineering_slots, janitor_slots, paranormal_slots, cyborg_slots)
	GLOB.response_team_members = list()
	GLOB.active_team = response_team_type
	GLOB.active_team.setSlots(commander_slots, security_slots, medical_slots, engineering_slots, janitor_slots, paranormal_slots, cyborg_slots)

	GLOB.send_emergency_team = TRUE
	var/list/ert_candidates = shuffle(SSghost_spawns.poll_candidates("Присоединиться к Отряду Быстрого Реагирования?",, GLOB.responseteam_age, 60 SECONDS, TRUE, GLOB.role_playtime_requirements[ROLE_ERT]))
	if(!ert_candidates.len)
		GLOB.active_team.cannot_send_team()
		GLOB.send_emergency_team = FALSE
		return

	// Respawnable players get first dibs
	for(var/mob/dead/observer/M in ert_candidates)
		if((M in GLOB.respawnable_list) && M.JoinResponseTeam())
			GLOB.response_team_members |= M
	// If there's still open slots, non-respawnable players can fill them
	for(var/mob/dead/observer/M in (ert_candidates - GLOB.respawnable_list))
		if(M.JoinResponseTeam())
			GLOB.response_team_members |= M

	if(!GLOB.response_team_members.len)
		GLOB.active_team.cannot_send_team()
		GLOB.send_emergency_team = FALSE
		return

	var/list/ert_prefs = list()
	for(var/mob/M in GLOB.response_team_members)
		INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(get_ert_prefs), M, ert_prefs)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(dispatch_response_team), GLOB.response_team_members, ert_prefs), 31 SECONDS) // one additional second for some client-server lags

/proc/get_ert_prefs(mob/user, list/ert_prefs)
	ert_prefs[user] = list()
	ert_prefs[user]["gender"] = tgui_input_list(user, "Выберите пол (10 секунд):","", list("Мужской", "Женский"), timeout = 10 SECONDS)
	ert_prefs[user]["roles"] = tgui_input_ranked_list(user, "Расположите роли ОБР от наиболее предпочтительных к наименее предпочтительным (20 секунд):", "", GLOB.active_team.get_slot_list(), timeout = 20 SECONDS)

/proc/dispatch_response_team(list/response_team_members, list/ert_prefs)
	var/spawn_index = 1

	while(spawn_index <= GLOB.emergencyresponseteamspawn.len)
		if(!ert_prefs.len)
			break
		var/mob/user = pick(ert_prefs)
		if(!GLOB.active_team.get_slot_list().len)
			break
		var/gender_pref = ert_prefs[user]["gender"]
		var/role_pref = ert_prefs[user]["roles"]
		if(!user || !user.client)
			ert_prefs -= user
			continue
		if(!gender_pref || !role_pref)
			// Player was afk and did not select
			ert_prefs -= user
			continue
		for(var/role in role_pref)
			if(GLOB.active_team.check_slot_available(role))
				var/mob/living/new_commando = user.client.create_response_team(gender_pref, role, GLOB.emergencyresponseteamspawn[spawn_index])
				GLOB.active_team.reduceSlots(role)
				spawn_index++
				ert_prefs -= user
				if(!user || !new_commando)
					break
				new_commando.mind.key = user.key
				new_commando.key = user.key
				new_commando.update_icons()
				new_commando.change_voice()
				break
	GLOB.send_emergency_team = FALSE

	if(GLOB.active_team.count)
		GLOB.active_team.announce_team()
		return
	// Everyone who said yes was afk
	GLOB.active_team.cannot_send_team()

/client/proc/create_response_team(new_gender, role, turf/spawn_location)
	if(role == JOB_TITLE_CYBORG)
		var/mob/living/silicon/robot/ert/R = new GLOB.active_team.borg_path(spawn_location)
		return R

	var/mob/living/carbon/human/M = new(null)
	var/obj/item/organ/external/head/head_organ = M.get_organ(BODY_ZONE_HEAD)

	if(new_gender)
		if(new_gender == "Мужской")
			M.change_gender(MALE)
		else
			M.change_gender(FEMALE)

	M.set_species(/datum/species/human, TRUE)
	M.dna.ready_dna(M)
	M.cleanSE() //No fat/blind/colourblind/epileptic/whatever ERT.
	M.overeatduration = 0

	var/hair_c = pick("#8B4513","#000000","#FF4500","#FFD700") // Brown, black, red, blonde
	var/eye_c = pick("#000000","#8B4513","1E90FF") // Black, brown, blue
	var/skin_tone = rand(-120, 20) // A range of skin colors

	head_organ.facial_colour = hair_c
	head_organ.sec_facial_colour = hair_c
	head_organ.hair_colour = hair_c
	head_organ.sec_hair_colour = hair_c
	M.change_eye_color(eye_c)
	M.s_tone = skin_tone
	head_organ.h_style = random_hair_style(M.gender, head_organ.dna.species)
	head_organ.f_style = random_facial_hair_style(M.gender, head_organ.dna.species.name)
	M.rename_character(null, "Безымянный") // Rewritten in /datum/outfit/job/centcom/response_team/pre_equip
	M.age = rand(23,35)
	M.regenerate_icons()

	//Creates mind stuff.
	M.mind = new
	M.mind.current = M
	M.mind.set_original_mob(M)
	M.mind.assigned_role = SPECIAL_ROLE_ERT
	M.mind.special_role = SPECIAL_ROLE_ERT
	if(!(M.mind in SSticker.minds))
		SSticker.minds += M.mind //Adds them to regular mind list.
	SSticker.mode.ert += M.mind
	M.forceMove(spawn_location)

	SSjobs.CreateMoneyAccount(M, role, null)

	GLOB.active_team.equip_officer(role, M)

	M.update_body()
	M.update_dna()

	return M


/datum/response_team
	var/list/slots = list(
		"Командир" = 0,
		"Боец" = 0,
		"Инженер" = 0,
		"Медик" = 0,
		"Уборщик" = 0,
		"Паранормал" = 0,
		"Борг" = 0
	)
	var/count = 0

	var/command_outfit
	var/engineering_outfit
	var/medical_outfit
	var/security_outfit
	var/janitor_outfit
	var/paranormal_outfit
	var/borg_path = /mob/living/silicon/robot/ert

	/// Whether the ERT announcement should be hidden from the station
	var/silent

/datum/response_team/proc/setSlots(com=1, sec=4, med=0, eng=0, jan=0, par=0, cyb=0)
	slots["Командир"] = com
	slots["Боец"] = sec
	slots["Медик"] = med
	slots["Инженер"] = eng
	slots["Уборщик"] = jan
	slots["Паранормал"] = par
	slots["Борг"] = cyb

/datum/response_team/proc/reduceSlots(role)
	slots[role]--
	count++

/datum/response_team/proc/get_slot_list()
	RETURN_TYPE(/list)
	var/list/slots_available = list()
	for(var/role in slots)
		if(slots[role])
			slots_available.Add(role)
	return slots_available

/datum/response_team/proc/check_slot_available(role)
	return slots[role]

/datum/response_team/proc/equip_officer(officer_type, mob/living/carbon/human/M)
	switch(officer_type)
		if("Инженер")
			M.equipOutfit(engineering_outfit)

		if("Боец")
			M.equipOutfit(security_outfit)

		if("Медик")
			M.equipOutfit(medical_outfit)

		if("Уборщик")
			M.equipOutfit(janitor_outfit)

		if("Паранормал")
			M.equipOutfit(paranormal_outfit)

		if("Командир")
			M.equipOutfit(command_outfit)

/datum/response_team/proc/cannot_send_team()
	if(silent)
		message_admins("A silent response team failed to spawn. Likely, no one signed up.")
		return
	GLOB.event_announcement.Announce("[station_name()], к сожалению, в настоящее время мы не можем направить к вам отряд быстрого реагирования.", "Оповещение: ОБР недоступен.")

/datum/response_team/proc/announce_team()
	if(silent)
		return
	GLOB.event_announcement.Announce("Внимание, [station_name()]. Мы направляем команду высококвалифицированных ассистентов для оказания помощи(?) вам. Ожидайте.", "Оповещение: ОБР в пути.")

// -- AMBER TEAM --

/datum/response_team/amber
	engineering_outfit = /datum/outfit/job/centcom/response_team/engineer/amber
	security_outfit = /datum/outfit/job/centcom/response_team/security/amber
	medical_outfit = /datum/outfit/job/centcom/response_team/medic/amber
	command_outfit = /datum/outfit/job/centcom/response_team/commander/amber
	janitor_outfit = /datum/outfit/job/centcom/response_team/janitorial/amber
	paranormal_outfit = /datum/outfit/job/centcom/response_team/paranormal/amber

/datum/response_team/amber/announce_team()
	if(silent)
		return
	GLOB.event_announcement.Announce("Внимание, [station_name()]. Мы направляем отряд быстрого реагирования кода «ЭМБЕР». Ожидайте.", "Оповещение: ОБР в пути.")

// -- RED TEAM --

/datum/response_team/red
	engineering_outfit = /datum/outfit/job/centcom/response_team/engineer/red
	security_outfit = /datum/outfit/job/centcom/response_team/security/red
	medical_outfit = /datum/outfit/job/centcom/response_team/medic/red
	command_outfit = /datum/outfit/job/centcom/response_team/commander/red
	janitor_outfit = /datum/outfit/job/centcom/response_team/janitorial/red
	paranormal_outfit = /datum/outfit/job/centcom/response_team/paranormal/red
	borg_path = /mob/living/silicon/robot/ert/red

/datum/response_team/red/announce_team()
	if(silent)
		return
	GLOB.event_announcement.Announce("Внимание, [station_name()]. Мы направляем отряд быстрого реагирования кода «РЭД». Ожидайте.", "Оповещение: ОБР в пути.")

// -- GAMMA TEAM --

/datum/response_team/gamma
	engineering_outfit = /datum/outfit/job/centcom/response_team/engineer/gamma
	security_outfit = /datum/outfit/job/centcom/response_team/security/gamma
	medical_outfit = /datum/outfit/job/centcom/response_team/medic/gamma
	command_outfit = /datum/outfit/job/centcom/response_team/commander/gamma
	janitor_outfit = /datum/outfit/job/centcom/response_team/janitorial/gamma
	paranormal_outfit = /datum/outfit/job/centcom/response_team/paranormal/gamma
	borg_path = /mob/living/silicon/robot/ert/gamma

/datum/response_team/gamma/announce_team()
	if(silent)
		return
	GLOB.event_announcement.Announce("Внимание, [station_name()]. Мы направляем отряд быстрого реагирования кода «ГАММА». Ожидайте.", "Оповещение: ОБР в пути.")

/datum/outfit/job/centcom/response_team
	name = "Response team"
	var/rt_assignment = "Emergency Response Team Member"
	var/rt_job = "This is a bug"
	var/rt_mob_job = "This is a bug" // The job set on the actual mob.
	var/special_message = "Вы подчиняетесь непосредственно <span class='red'>вашему командиру</span>. \n Исключения составляют случаи, когда ваш командир открыто действует против интересов НТ, или случаев, когда это требуется согласно приказаниям члена Защиты Активов более высокого звания, чем у вашего командира - в том числе переданного через Офицера Специальных Операций. \n В случае отсутствия командира или на время его недееспособности, командование отрядом за обычных условий переходит к старшему по званию среди вашего отряда."
	var/hours_dif = 0 // Subtracted from the total number of hours. Needs to be done that Gamma ERT/individual roles will require more hours
	var/exp_type = FALSE
	var/list/ranks = list("Min" = "Рядовой",
				"Med" = "Младший капрал",
				"Max" = "Капрал")
	allow_backbag_choice = FALSE
	allow_loadout = FALSE
	pda = /obj/item/pda/heads/ert
	id = /obj/item/card/id/ert
	l_ear = /obj/item/radio/headset/ert/alt
	box = /obj/item/storage/box/responseteam

	implants = list(/obj/item/implant/mindshield/ert)

/datum/outfit/job/centcom/response_team/pre_equip(mob/H) // Used to give specific rank
	. = ..()
	if(H.client)
		var/client/C = H.client
		var/list/all_hours = params2list(C.prefs.exp)
		var/hours = text2num(all_hours[EXP_TYPE_CREW])
		if(exp_type) // If the ERT have special exp type: EXP_TYPE_COMMAND for Leaders, EXP_TYPE_MEDICAL for medics, etc
			hours -= text2num(all_hours[exp_type])
			hours += text2num(all_hours[exp_type]) * 2
		hours *= rand(0.8, 1.2)
		if((hours - hours_dif) <= MEDIUM_RANK_HOURS)
			H.rename_character(null, "[ranks["Min"]] [H.gender==FEMALE ? pick(GLOB.last_names_female) : pick(GLOB.last_names)]")
		else if((hours - hours_dif) < MAX_RANK_HOURS)
			H.rename_character(null, "[ranks["Med"]] [H.gender==FEMALE ? pick(GLOB.last_names_female) : pick(GLOB.last_names)]")
		else
			H.rename_character(null, "[ranks["Max"]] [H.gender==FEMALE ? pick(GLOB.last_names_female) : pick(GLOB.last_names)]")
	else
		H.rename_character(null, "[ranks["Med"]] [H.gender==FEMALE ? pick(GLOB.last_names_female) : pick(GLOB.last_names)]")

/datum/outfit/job/centcom/response_team/post_equip(mob/H)
	. = ..()
	to_chat(H, special_message)

/obj/item/radio/centcom
	name = "centcomm bounced radio"
	frequency = ERT_FREQ
	icon_state = "radio"
	freqlock = TRUE
