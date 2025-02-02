GLOBAL_LIST_EMPTY(sounds_cache)

/client/proc/stop_global_admin_sounds()
	set category = "Admin.Sounds"
	set name = "Stop Global Admin Sounds"
	if(!check_rights(R_SOUNDS))
		return

	var/sound/awful_sound = sound(null, repeat = 0, wait = 0, channel = CHANNEL_ADMIN)

	log_and_message_admins("stopped admin sounds.")
	for(var/mob/M in GLOB.player_list)
		M << awful_sound

/client/proc/play_sound(S as sound)
	set category = "Admin.Sounds"
	set name = "Play Global Sound"
	if(!check_rights(R_SOUNDS))	return

	var/sound/uploaded_sound = sound(S, repeat = 0, wait = 1, channel = CHANNEL_ADMIN)
	uploaded_sound.priority = 250

	GLOB.sounds_cache += S

	if(alert("Are you sure?\nSong: [S]\nNow you can also play this sound using \"Play Server Sound\".", "Confirmation request" ,"Play", "Cancel") == "Cancel")
		return

	log_and_message_admins("played sound [S]")

	for(var/mob/M in GLOB.player_list)
		if(M.client.prefs.sound & SOUND_MIDI)
			if(isnewplayer(M) && (M.client.prefs.sound & SOUND_LOBBY))
				// M.stop_sound_channel(CHANNEL_LOBBYMUSIC)
				M.client?.tgui_panel?.stop_music()
			uploaded_sound.volume = 100 * M.client.prefs.get_channel_volume(CHANNEL_ADMIN)
			SEND_SOUND(M, uploaded_sound)

	SSblackbox.record_feedback("tally", "admin_verb", 1, "Play Global Sound") //If you are copy-pasting this, ensure the 4th parameter is unique to the new proc!


/client/proc/play_local_sound(S as sound)
	set category = "Admin.Sounds"
	set name = "Play Local Sound"
	if(!check_rights(R_SOUNDS))	return

	log_and_message_admins("played a local sound [S]")
	playsound(get_turf(src.mob), S, 50, 0, 0)
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Play Local Sound") //If you are copy-pasting this, ensure the 4th parameter is unique to the new proc!


/client/proc/play_web_sound()
	set category = "Admin.Sounds"
	set name = "Play Internet Sound"
	if(!check_rights(R_SOUNDS))
		return

	if(!tgui_panel || !SSassets.initialized)
		return

	var/ytdl = CONFIG_GET(string/invoke_youtubedl)
	if(!ytdl)
		to_chat(src, span_boldwarning("yt-dlp was not configured, action unavailable"), confidential=TRUE) //Check config.txt for the INVOKE_YOUTUBEDL value
		return

	var/web_sound_input = input("Enter content URL (supported sites only, leave blank to stop playing)", "Play Internet Sound via yt-dlp") as text|null
	if(istext(web_sound_input))
		var/web_sound_path = ""
		var/web_sound_url = ""
		var/stop_web_sounds = FALSE
		var/list/music_extra_data = list()
		if(length(web_sound_input))
			web_sound_input = trim(web_sound_input)
			if(findtext(web_sound_input, ":") && !findtext(web_sound_input, GLOB.is_http_protocol))
				to_chat(src, span_boldwarning("Non-http(s) URIs are not allowed."), confidential=TRUE)
				to_chat(src, span_warning("For yt-dlp shortcuts like ytsearch: please use the appropriate full url from the website."), confidential=TRUE)
				return
			var/shell_scrubbed_input = shell_url_scrub(web_sound_input)
			var/list/output = world.shelleo("[ytdl] -x --audio-format mp3 --audio-quality 0 --geo-bypass --no-playlist -o \"cache/songs/%(id)s.%(ext)s\" --dump-single-json --no-simulate \"[shell_scrubbed_input]\"")
			var/errorlevel = output[SHELLEO_ERRORLEVEL]
			var/stdout = output[SHELLEO_STDOUT]
			var/stderr = output[SHELLEO_STDERR]
			if(!errorlevel)
				var/list/data
				try
					data = json_decode(stdout)
				catch(var/exception/e)
					to_chat(src, span_boldwarning("yt-dlp JSON parsing FAILED:"), confidential=TRUE)
					to_chat(src, span_warning("[e]: [stdout]"), confidential=TRUE)
					return

				if(data["url"])
					web_sound_path = "cache/songs/[data["id"]].mp3"
					web_sound_url = data["url"]
					var/title = "[data["title"]]"
					var/webpage_url = title
					if(data["webpage_url"])
						webpage_url = "<a href=\"[data["webpage_url"]]\">[title]</a>"
					music_extra_data["start"] = data["start_time"]
					music_extra_data["end"] = data["end_time"]
					music_extra_data["link"] = data["webpage_url"]
					music_extra_data["title"] = data["title"]
					if(data["duration"])
						var/mus_len = data["duration"] SECONDS
						if(data["start_time"])
							mus_len -= data["start_time"] SECONDS
						if(data["end_time"])
							mus_len -= (data["duration"] SECONDS - data["end_time"] SECONDS)
						SSticker.music_available = REALTIMEOFDAY + mus_len

					var/res = tgui_alert(usr, "Show the title of and link to this song to the players?\n[title]",, list("No", "Yes", "Cancel"))
					switch(res)
						if("Yes")
							to_chat(world, span_boldannounceooc("Сейчас играет: [webpage_url]"))
						if("Cancel")
							return

					SSblackbox.record_feedback("nested tally", "played_url", 1, list("[ckey]", "[web_sound_input]"))
					log_admin("[key_name(src)] played web sound: [web_sound_input]")
					message_admins("[key_name(src)] played web sound: [web_sound_input]")
			else
				to_chat(src, span_boldwarning("yt-dlp URL retrieval FAILED:"), confidential=TRUE)
				to_chat(src, span_warning("[stderr]"), confidential=TRUE)

		else //pressed ok with blank
			log_admin("[key_name(src)] stopped web sound")
			message_admins("[key_name(src)] stopped web sound")
			web_sound_path = null
			stop_web_sounds = TRUE
			SSticker.music_available = 0

		if(stop_web_sounds)
			for(var/m in GLOB.player_list)
				var/mob/M = m
				var/client/C = M.client
				if(C.prefs.toggles & SOUND_MIDI)
					C.tgui_panel?.stop_music()
		else
			var/url = web_sound_url
			switch(CONFIG_GET(string/asset_transport))
				if ("webroot")
					var/datum/asset/music/my_asset
					if(GLOB.cached_songs[web_sound_path])
						my_asset = GLOB.cached_songs[web_sound_path]
					else
						my_asset = new /datum/asset/music(web_sound_path)
						GLOB.cached_songs[web_sound_path] = my_asset
					url = my_asset.get_url()

			for(var/m in GLOB.player_list)
				var/mob/M = m
				var/client/C = M.client
				if(C.prefs.sound & SOUND_MIDI)
					C.tgui_panel?.play_music(url, music_extra_data)

	SSblackbox.record_feedback("tally", "admin_verb", 1, "Play Internet Sound")

/client/proc/play_server_sound()
	set category = "Admin.Sounds"
	set name = "Play Server Sound"
	if(!check_rights(R_SOUNDS))	return

	var/list/sounds = file2list("sound/serversound_list.txt")
	sounds += GLOB.sounds_cache

	var/melody = input("Select a sound from the server to play", "Server sound list") as null|anything in sounds
	if(!melody)	return

	play_sound(melody)
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Play Server Sound") //If you are copy-pasting this, ensure the 2nd paramter is unique to the new proc!

/client/proc/play_intercomm_sound()
	set category = "Admin.Sounds"
	set name = "Play Sound via Intercomms"
	set desc = "Plays a sound at every intercomm on the station z level. Works best with small sounds."
	if(!check_rights(R_SOUNDS))	return

	var/A = alert("This will play a sound at every intercomm, are you sure you want to continue? This works best with short sounds, beware.","Warning","Yep","Nope")
	if(A != "Yep")	return

	var/list/sounds = file2list("sound/serversound_list.txt")
	sounds += GLOB.sounds_cache

	var/melody = input("Select a sound from the server to play", "Server sound list") as null|anything in sounds
	if(!melody)	return

	var/cvol = 35
	var/inputvol = input("How loud would you like this to be? (1-70)", "Volume", "35") as num | null
	if(!inputvol)	return
	if(inputvol && inputvol >= 1 && inputvol <= 70)
		cvol = inputvol

	//Allows for override to utilize intercomms on all z-levels
	var/B = alert("Do you want to play through intercomms on ALL Z-levels, or just the station?", "Override", "All", "Station")
	var/ignore_z = 0
	if(B == "All")
		ignore_z = 1

	//Allows for override to utilize incomplete and unpowered intercomms
	var/C = alert("Do you want to play through unpowered / incomplete intercomms, so the crew can't silence it?", "Override", "Yep", "Nope")
	var/ignore_power = 0
	if(C == "Yep")
		ignore_power = 1

	for(var/O in GLOB.global_intercoms)
		var/obj/item/radio/intercom/I = O
		if(!is_station_level(I.z) && !ignore_z)
			continue
		if(!I.on && !ignore_power)
			continue
		playsound(I, melody, cvol)

/client/proc/play_direct_mob_sound(S as sound, mob/M)
	set category = "Admin.Sounds"
	set name = "Play Direct Mob Sound"
	if(!check_rights(R_SOUNDS))
		return

	if(!M)
		M = input(usr, "Choose a mob to play the sound to. Only they will hear it.", "Play Mob Sound") as null|anything in sort_names(GLOB.player_list)
	if(!M || QDELETED(M))
		return

	log_and_message_admins("played a direct mob sound [S] to [M].")
	SEND_SOUND(M, S)
