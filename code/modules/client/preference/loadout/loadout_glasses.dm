/datum/gear/glasses
	subtype_path = /datum/gear/glasses
	slot = ITEM_SLOT_EYES
	sort_category = "Glasses"

/datum/gear/glasses/sunglasses
	index_name = "cheap sunglasses"
	path = /obj/item/clothing/glasses/sunglasses_fake

/datum/gear/glasses/eyepatch
	index_name = "Eyepatch"
	path = /obj/item/clothing/glasses/eyepatch

/datum/gear/glasses/blindfold
	index_name = "Blindfold"
	path = /obj/item/clothing/glasses/sunglasses/blindfold

/datum/gear/glasses/blindfold/New()
	..()
	gear_tweaks += new /datum/gear_tweak/color(parent = src)

/datum/gear/glasses/blindfold_fake
	index_name = "Fake blindfold"
	path = /obj/item/clothing/glasses/sunglasses/blindfold_fake

/datum/gear/glasses/blindfold_fake/New()
	..()
	gear_tweaks += new /datum/gear_tweak/color(parent = src)

/datum/gear/glasses/hipster
	index_name = "Hipster glasses"
	path = /obj/item/clothing/glasses/regular/hipster

/datum/gear/glasses/monocle
	index_name = "Monocle"
	path = /obj/item/clothing/glasses/monocle

/datum/gear/glasses/prescription
	index_name = "Prescription glasses"
	path = /obj/item/clothing/glasses/regular

/datum/gear/glasses/sectacticool
	index_name = "Security tactical glasses"
	path = /obj/item/clothing/glasses/hud/security/sunglasses/tacticool
	allowed_roles = list(JOB_TITLE_HOS, JOB_TITLE_WARDEN, JOB_TITLE_OFFICER, JOB_TITLE_PILOT)

/datum/gear/glasses/medhudpatch
	index_name = "Medical HUD eyepatch"
	path = /obj/item/clothing/glasses/hud/health/patch
	allowed_roles = list(JOB_TITLE_CMO, JOB_TITLE_DOCTOR, JOB_TITLE_INTERN, JOB_TITLE_CHEMIST, JOB_TITLE_PSYCHIATRIST, JOB_TITLE_PARAMEDIC, JOB_TITLE_VIROLOGIST, JOB_TITLE_BRIGDOC, JOB_TITLE_CORONER)

/datum/gear/glasses/sechudpatch
	index_name = "Security HUD eyepatch"
	path = /obj/item/clothing/glasses/hud/security/patch
	allowed_roles = list(JOB_TITLE_HOS, JOB_TITLE_WARDEN, JOB_TITLE_OFFICER, JOB_TITLE_PILOT, JOB_TITLE_JUDGE, JOB_TITLE_DETECTIVE)

/datum/gear/glasses/sechudpatch/read_only
	index_name = "Security HUD eyepatch (read only)"
	path = /obj/item/clothing/glasses/hud/security/patch/read_only
	allowed_roles = list(JOB_TITLE_LAWYER)

/datum/gear/glasses/hydrohudpatch
	index_name = "Hydroponic HUD eyepatch"
	path = /obj/item/clothing/glasses/hud/hydroponic/patch
	allowed_roles = list(JOB_TITLE_BOTANIST)

/datum/gear/glasses/diaghudpatch
	index_name = "Diagnostic HUD eyepatch"
	path = /obj/item/clothing/glasses/hud/diagnostic/patch
	allowed_roles = list(JOB_TITLE_ROBOTICIST, JOB_TITLE_RD)

/datum/gear/glasses/skillhudpatch
	index_name = "Skills HUD eyepatch"
	path = /obj/item/clothing/glasses/hud/skills/patch
	allowed_roles = list(JOB_TITLE_HOP, JOB_TITLE_CAPTAIN)

