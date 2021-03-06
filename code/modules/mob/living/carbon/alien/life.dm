
/mob/living/carbon/alien/check_breath(datum/gas_mixture/breath)
	if(status_flags & GODMODE)
		return

	if(!breath || (breath.total_moles() == 0))
		//Aliens breathe in vaccuum
		return 0

	var/toxins_used = 0
	var/breath_pressure = (breath.total_moles()*R_IDEAL_GAS_EQUATION*breath.temperature)/BREATH_VOLUME

	//Partial pressure of the toxins in our breath
	var/Toxins_pp = (breath.toxins/breath.total_moles())*breath_pressure

	if(Toxins_pp) // Detect toxins in air
		adjustPlasma(breath.toxins*250)
		throw_alert("alien_tox")

		toxins_used = breath.toxins

	else
		clear_alert("alien_tox")

	//Breathe in toxins and out oxygen
	breath.toxins -= toxins_used
	breath.oxygen += toxins_used

	//BREATH TEMPERATURE
	handle_breath_temperature(breath)

/mob/living/carbon/alien/handle_status_effects()
	..()
	//natural reduction of movement delay due to stun.
	if(move_delay_add > 0)
		move_delay_add = max(0, move_delay_add - rand(1, 2))

/mob/living/carbon/alien/update_sight()
	if(stat == DEAD)
		sight |= SEE_TURFS
		sight |= SEE_MOBS
		sight |= SEE_OBJS
		see_in_dark = 8
		see_invisible = SEE_INVISIBLE_LEVEL_TWO
	else
		if(x_stats.h_true_sight)
			sight |= SEE_MOBS
			sight &= ~SEE_TURFS
			sight &= ~SEE_OBJS
		else
			sight &= ~SEE_MOBS
			sight &= ~SEE_TURFS
			sight &= ~SEE_OBJS
		if(nightvision)
			see_in_dark = 8
			see_invisible = SEE_INVISIBLE_MINIMUM
		else if(!nightvision)
			see_in_dark = 4
			see_invisible = 45
		if(see_override)
			see_invisible = see_override

/mob/living/carbon/alien/handle_hud_icons()
	handle_hud_icons_health()
	handle_hud_icons_armor()
	if(islarva(src) || (isalienadult(src) && !isqueen(src)))
		queen_locator()
	if(isalienadult(src))
		updateTreatsDisplay()
		hive_locator()
		parasite_locator()

	handle_aura_icons()

	return 1

/mob/living/carbon/alien/handle_hud_icons_health()
	if(healths)
		if(stat != 2)
			var/health_100 = maxHealth
			var/health_90 = round(maxHealth*0.9)
			var/health_70 = round(maxHealth*0.7)
			var/health_50 = round(maxHealth*0.5)
			var/health_30 = round(maxHealth*0.3)
			if(health >= health_100)
				healths.icon_state = "health0"
			else if(health >= health_90)
				healths.icon_state = "health1"
			else if(health >= health_70)
				healths.icon_state = "health2"
			else if(health >= health_50)
				healths.icon_state = "health3"
			else if(health >= health_30)
				healths.icon_state = "health4"
			else if(health > 0)
				healths.icon_state = "health5"
			else
				healths.icon_state = "health6"
		else
			healths.icon_state = "health7"

/mob/living/carbon/alien/proc/handle_hud_icons_armor()
	if(armors)
		var/obj/item/organ/internal/alien/carapace/armor = getorgan(/obj/item/organ/internal/alien/carapace)
		if(armor)
			switch(armor.health)
				if(200 to INFINITY)
					armors.icon_state = "armor0"
				if(160 to 200)
					armors.icon_state = "armor1"
				if(120 to 160)
					armors.icon_state = "armor2"
				if(80 to 120)
					armors.icon_state = "armor3"
				if(40 to 80)
					armors.icon_state = "armor4"
				if(1 to 40)
					armors.icon_state = "armor5"
				else
					armors.icon_state = "armor6"

var/aura_xeno = "XENO Purple Aura"
var/aura_safe = "SAFE Blue Aura"
var/aura_caution = "CAUTION Yellow Aura"
var/aura_danger = "DANGER Red Aura"
var/aura_xenhum = "XEDA Danger Aura"

/mob/living/carbon/alien/proc/handle_aura_icons()
	if(client)
		for(var/image/I in client.images)
			if(dd_hassuffix_case(I.icon_state, "Aura"))
				client.images.Remove(I)
			if(I.icon_state == "hud_parasite")
				client.images.Remove(I)
		for(var/mob/living/L in living_mob_list)
			if((L.z == src.z) || (L.z == 0))
				var/image/I
				var/location = L
				if(L.z == 0)
					if(istype(L.loc, /obj/mecha) || isalien(L.loc) || istype(L.loc, /obj/structure/closet))
						location = L.loc
					else
						location = get_turf(L)
				if(isalien(L))
					if(isalienadult(L))
						var/mob/living/carbon/alien/humanoid/A = L
						var/pix_x = -A.custom_pixel_x_offset //Not sure why this must be inverted...
						var/pix_y = -A.custom_pixel_y_offset
						I = image('icons/Xeno/Auras.dmi', loc = location, icon_state = aura_xeno, layer = 16, pixel_x = pix_x, pixel_y = pix_y)
					else
						I = image('icons/Xeno/Auras.dmi', loc = location, icon_state = aura_xeno, layer = 16)
				else if(ishuman(L))
					var/mob/living/carbon/human/H = L
					if(H.getorgan(/obj/item/organ/internal/alien/hivenode))
						I = image('icons/Xeno/Auras.dmi', loc = location, icon_state = aura_xenhum, layer = 16)
					else if(H.getorgan(/obj/item/organ/internal/body_egg/alien_embryo))
						I = image('icons/Xeno/Auras.dmi', loc = location, icon_state = aura_xeno, layer = 16)
					else
						if((H.r_hand && istype(H.r_hand, /obj/item/weapon/gun)) || (H.l_hand && istype(H.l_hand, /obj/item/weapon/gun)))
							I = image('icons/Xeno/Auras.dmi', loc = location, icon_state = aura_danger, layer = 16)
						else if((H.r_hand && istype(H.r_hand, /obj/item/weapon)) || (H.l_hand && istype(H.l_hand, /obj/item/weapon)))
							I = image('icons/Xeno/Auras.dmi', loc = location, icon_state = aura_caution, layer = 16)
						else
							I = image('icons/Xeno/Auras.dmi', loc = location, icon_state = aura_safe, layer = 16)
				else if(ismonkey(L))
					var/mob/living/carbon/monkey/M = L
					if(M.getorgan(/obj/item/organ/internal/body_egg/alien_embryo))
						I = image('icons/Xeno/Auras.dmi', loc = location, icon_state = aura_xeno, layer = 16)
					else
						I = image('icons/Xeno/Auras.dmi', loc = location, icon_state = aura_safe, layer = 16)
				else if(istype(L, /mob/living/simple_animal/hostile/alien))
					I = image('icons/Xeno/Auras.dmi', loc = location, icon_state = aura_xenhum, layer = 16)
				else
					I = image('icons/Xeno/Auras.dmi', loc = location, icon_state = aura_safe, layer = 16)
				client.images += I

				if(L in x_stats.parasite_targets)
					I = image('icons/mob/hud.dmi', loc = location, icon_state = "hud_parasite", layer = 16)
					client.images += I


/mob/living/carbon/alien/CheckStamina()
	setStaminaLoss(max((staminaloss - 2), 0))
	return

/mob/living/carbon/alien/proc/queen_locator()
	if(hud_used)
		var/mob/living/carbon/alien/humanoid/queen/target = null
		if(hud_used.locate_queen)
			for(var/mob/living/carbon/alien/humanoid/queen/M in mob_list)
				if(M && M.stat != DEAD)
					target = M
				else
					target = null
		if(!target)
			hud_used.locate_queen.icon_state = "trackoff"
			return

		hud_used.locate_queen.dir = get_dir(src,target)
		if(target && target != src)
			if(get_dist(src, target) != 0)
				hud_used.locate_queen.icon_state = "trackon"
			else
				hud_used.locate_queen.icon_state = "trackondirect"

		//spawn(10) .()

/mob/living/carbon/alien/proc/hive_locator()
	if(hud_used && hud_used.locate_hive_1 && hud_used.locate_hive_2)
		if(x_stats.hive_1)
			var/turf/T = x_stats.hive_1
			if(T.z == src.z && get_dist(src, T) > 10)
				hud_used.locate_hive_1.dir = get_dir(src,T)
				hud_used.locate_hive_1.icon_state = "trackon"
			else
				hud_used.locate_hive_1.icon_state = "trackondirect"
		else
			hud_used.locate_hive_1.icon_state = "trackoff"

		if(x_stats.hive_2)
			var/turf/T = x_stats.hive_2
			if(T.z == src.z && get_dist(src, T) > 10)
				hud_used.locate_hive_2.dir = get_dir(src,T)
				hud_used.locate_hive_2.icon_state = "trackon"
			else
				hud_used.locate_hive_2.icon_state = "trackondirect"
		else
			hud_used.locate_hive_2.icon_state = "trackoff"

/mob/living/carbon/alien/proc/parasite_locator()
	if(hud_used && hud_used.parasiteicon)
		var/mob/living/carbon/human/target = hud_used.parasiteicon.target
		if(target)
			if(target.stat != DEAD)
				if(get_dist(src, target) != 0)
					hud_used.parasiteicon.dir = get_dir(src,target)
					hud_used.parasiteicon.icon_state = "trackon"
				else
					hud_used.parasiteicon.icon_state = "trackondirect"
			else
				hud_used.parasiteicon.target = null
		else
			hud_used.parasiteicon.icon_state = "trackoff"


		if(x_stats.hive_1)
			var/turf/T = x_stats.hive_1
			if(T.z == src.z && get_dist(src, T) > 10)
				hud_used.locate_hive_1.dir = get_dir(src,T)
				hud_used.locate_hive_1.icon_state = "trackon"
			else
				hud_used.locate_hive_1.icon_state = "trackondirect"
		else
			hud_used.locate_hive_1.icon_state = "trackoff"