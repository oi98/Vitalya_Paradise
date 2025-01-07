/////////////////////////////////////////
/////////////////Misc Designs////////////
/////////////////////////////////////////
/datum/design/design_disk
	name = "Design Storage Disk"
	desc = "Produce additional disks for storing device designs."
	id = "design_disk"
	req_tech = list("programming" = 1)
	build_type = PROTOLATHE | AUTOLATHE
	materials = list(MAT_METAL = 300, MAT_GLASS = 100)
	build_path = /obj/item/disk/design_disk
	category = list("Miscellaneous")

/datum/design/diskplantgene
	name = "Plant data disk"
	desc = "A disk for storing plant genetic data."
	id = "diskplantgene"
	req_tech = list("programming" = 4, "biotech" = 3)
	build_type = PROTOLATHE
	materials = list(MAT_METAL=200, MAT_GLASS=100)
	build_path = /obj/item/disk/plantgene
	category = list("Miscellaneous")

/datum/design/intellicard
	name = "Intellicard"
	desc = "Allows for the construction of an intellicard."
	id = "intellicard"
	req_tech = list("programming" = 3, "materials" = 3)
	build_type = PROTOLATHE
	materials = list(MAT_GLASS = 1000, MAT_GOLD = 200)
	build_path = /obj/item/aicard
	category = list("Miscellaneous")

/datum/design/paicard
	name = "Personal Artificial Intelligence Card"
	desc = "Allows for the construction of a pAI Card"
	id = "paicard"
	req_tech = list("programming" = 2)
	build_type = PROTOLATHE
	materials = list(MAT_GLASS = 500, MAT_METAL = 500)
	build_path = /obj/item/paicard
	category = list("Miscellaneous")

/datum/design/tech_disk
	name = "Technology Data Storage Disk"
	desc = "Produce additional disks for storing technology data."
	id = "tech_disk"
	req_tech = list("programming" = 1)
	build_type = PROTOLATHE | AUTOLATHE
	materials = list(MAT_METAL = 300, MAT_GLASS = 100)
	build_path = /obj/item/disk/tech_disk
	category = list("Miscellaneous")

/datum/design/digital_camera
	name = "Digital Camera"
	desc = "Produce an enhanced version of the standard issue camera."
	id = "digitalcamera"
	req_tech = list("programming" = 2, "materials" = 2)
	build_type = PROTOLATHE
	materials = list(MAT_METAL = 500, MAT_GLASS = 300)
	build_path = /obj/item/camera/digital
	category = list("Miscellaneous")

/datum/design/safety_muzzle
	name = "Safety Muzzle"
	desc = "Produce a lockable muzzle keyed to security ID cards"
	id = "safetymuzzle"
	req_tech = list("materials" = 1)
	build_type = PROTOLATHE
	materials = list(MAT_METAL=500, MAT_GLASS=50)
	build_path = /obj/item/clothing/mask/muzzle/safety
	category = list("Miscellaneous")

/datum/design/shock_muzzle
	name = "Shock Muzzle"
	desc = "Produce a modified safety muzzle that includes an electric shock pack and a slot for a trigger assembly."
	id = "shockmuzzle"
	req_tech = list("materials" = 1, "engineering" = 1)
	build_type = PROTOLATHE
	materials = list(MAT_METAL=500, MAT_GLASS=50)
	build_path = /obj/item/clothing/mask/muzzle/safety/shock
	category = list("Miscellaneous")

/datum/design/data_disk
	name = "Genetics Data Disk"
	desc = "Disk that allows you to store genetic data."
	id = "datadisk"
	req_tech = list("programming" = 3, "biotech" = 2)
	build_type = PROTOLATHE
	materials = list(MAT_METAL=300, MAT_GLASS=100)
	build_path = /obj/item/disk/data
	category = list("Miscellaneous")

/datum/design/emergency_oxygen
	name = "Empty Emergency Oxygen Tank"
	desc = "Used for emergencies. Onl contains very little oxygen once filled up."
	id = "emergencyoxygen"
	req_tech = list("toxins" = 3)
	build_type = PROTOLATHE
	materials = list(MAT_METAL=500, MAT_GLASS=100)
	build_path = /obj/item/tank/internals/emergency_oxygen/empty
	category = list("Miscellaneous")

/datum/design/extended_oxygen
	name = "Empty Extended Emergency Oxygen Tank"
	desc = "Used for emergencies. Can contain a decent amount of oxygen once filled up."
	id = "extendedoxygen"
	req_tech = list("toxins" = 4)
	build_type = PROTOLATHE
	materials = list(MAT_METAL=800, MAT_GLASS=100)
	build_path = /obj/item/tank/internals/emergency_oxygen/engi/empty
	category = list("Miscellaneous")

/datum/design/double_oxygen
	name = "Empty Double Emergency Oxygen Tank"
	desc = "Used for emergencies. Can contain a good amount of oxygen once filled up."
	id = "doubleoxygen"
	req_tech = list("toxins" = 5)
	build_type = PROTOLATHE
	materials = list(MAT_METAL=1500, MAT_GLASS=200)
	build_path = /obj/item/tank/internals/emergency_oxygen/double/empty
	category = list("Miscellaneous")

/datum/design/oxygen_tank
	name = "Empty Oxygen Tank"
	desc = "A large, empty air tank."
	id = "oxygentank"
	req_tech = list("toxins" = 5)
	build_type = PROTOLATHE
	materials = list(MAT_METAL=3000, MAT_GLASS=500)
	build_path = /obj/item/tank/internals/oxygen/empty
	category = list("Miscellaneous")

/datum/design/extinguisher_cartridge
	name = "Envirosuit Extinguisher Cartridge"
	desc = "A cartridge loaded with a compressed extinguisher mix, used to refill the automatic extinguisher on plasma envirosuits."
	id = "extinguishercartridge"
	req_tech = list("materials" = 5, "toxins" = 5)
	build_type = PROTOLATHE
	materials = list(MAT_METAL=3000, MAT_GLASS=500)
	reagents_list = list("firefighting_foam" = 1)
	build_path = /obj/item/extinguisher_refill
	category = list("Miscellaneous")

/datum/design/customat_canister
	name = "Customat Canister"
	desc = "Канистра для Кастомата."
	id = "customat_canister"
	req_tech = list("programming" = 3)
	build_type = PROTOLATHE
	materials = list(MAT_METAL = 800, MAT_GLASS = 600)
	build_path = /obj/item/vending_refill/custom
	category = list("Miscellaneous")

/datum/design/translator_chip
	name = "PVR Language Chip"
	desc = "Крошечный чип с индикатором. Устанавливается в импланты-переводчики."
	id = "pvr_language_chip"
	req_tech = list("materials" = 3, "programming" = 5, "abductor" = 1)
	build_type = PROTOLATHE
	build_path = /obj/item/translator_chip
	materials = list(MAT_METAL = 1000, MAT_GLASS = 100, MAT_TITANIUM = 500, MAT_PLASMA = 500, MAT_DIAMOND = 100)
	category = list("Miscellaneous")

/datum/design/retranslator_upgrade
	name = "PVR Storage Upgrade"
	desc = "Маленькое устройство для расширения количества слотов голосовых чипов в ретрансляторе псионического голоса."
	id = "pvr_storage_upgrade"
	req_tech = list("materials" = 5, "programming" = 6, "bluespace" = 6, "abductor" = 2)
	build_type = PROTOLATHE
	build_path = /obj/item/translator_upgrade/grey_retraslator
	materials = list(MAT_METAL = 1000, MAT_GLASS = 100, MAT_TITANIUM = 500, MAT_PLASMA = 500, MAT_DIAMOND = 100)
	category = list("Miscellaneous")

