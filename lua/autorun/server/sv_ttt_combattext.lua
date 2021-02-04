resource.AddSingleFile("sound/ttt_combattext/hitsound.ogg")
resource.AddSingleFile("sound/ttt_combattext/killsound.ogg")

for _, v in pairs(select(2, file.Find("resource/localization/*", "GAME"))) do
	local filename = (
		"resource/localization/%s/ttt_combattext.properties"
	):format(v)

	if file.Exists(filename, "GAME") then
		resource.AddSingleFile(filename)
	end
end

util.AddNetworkString("ttt_combattext")

local combattext_bodyarmor = CreateConVar("ttt_combattext_bodyarmor", 1,
	FCVAR_ARCHIVE + FCVAR_NOTIFY, "TTT: Prevent damage text from revealing if the target is wearing body armor\n   (1 = except against detectives and fellow traitors, 2 = no exceptions)"
):GetInt()
local combattext_disguise = CreateConVar("ttt_combattext_disguise", 0,
	FCVAR_ARCHIVE + FCVAR_NOTIFY, "TTT: Don't show damage text if target is disguised\n   (1 = still let hitsound play, 2 = don't let hitsound play too)"
):GetInt()
local combattext_lineofsight = CreateConVar("ttt_combattext_lineofsight", 1,
	FCVAR_ARCHIVE + FCVAR_NOTIFY, "Don't show damage text if the target cannot be seen"
):GetBool()
local combattext_rounding = CreateConVar("ttt_combattext_rounding", 1,
	FCVAR_ARCHIVE, "0: round down (floor)\n - 1: round off\n - 2: round up (ceiling)"
):GetInt()
local dingaling_lasthit_allowed = CreateConVar("ttt_dingaling_lasthit_allowed", 1,
	FCVAR_ARCHIVE + FCVAR_NOTIFY, "Allow players to enable kill sounds"
):GetBool()

cvars.AddChangeCallback("ttt_combattext_bodyarmor", function(name, old, new)
	combattext_bodyarmor = tonumber(new) or 1
end)
cvars.AddChangeCallback("ttt_combattext_disguise", function(name, old, new)
	combattext_disguise = tonumber(new) or 0
end)
cvars.AddChangeCallback("ttt_combattext_lineofsight", function(name, old, new)
	combattext_lineofsight = tonumber(new) == 1
end)
cvars.AddChangeCallback("ttt_combattext_rounding", function(name, old, new)
	combattext_rounding = tonumber(new) or 1
end)
cvars.AddChangeCallback("ttt_dingaling_lasthit_allowed", function(name, old, new)
	dingaling_lasthit_allowed = tonumber(new) == 1
end)

local function updateplayerinfo(_, ply)
	if not ply then
		return
	end

	local cl_cvars = ply.ttt_combattext_cvars
	if not cl_cvars then
		cl_cvars = {true, false, false}
		ply.ttt_combattext_cvars = cl_cvars
	end

	cl_cvars[1] = ply:GetInfoNum("ttt_combattext", 1) == 1
	cl_cvars[2] = ply:GetInfoNum("ttt_dingaling", 0) == 1
	cl_cvars[3] = ply:GetInfoNum("ttt_dingaling_lasthit", 0) == 1

	return cl_cvars
end

net.Receive("ttt_combattext", updateplayerinfo)

hook.Add("EntityTakeDamage", "ttt_combattext_EntityTakeDamage", function(victim, dmginfo)
	if not (IsValid(victim) and victim:IsPlayer()) then
		return
	end

	-- store certain information that might not be available in the PostEntityTakeDamage hook
	local data

	if combattext_bodyarmor > 0 then
		local scale

		if TTT2 then
			local cv = ARMOR and ARMOR.cv

			if not (cv
				and cv.armor_classic
				and cv.armor_classic:GetBool()
			) then
				goto done
			end

			if combattext_bodyarmor ~= 2
				and victim:GetBaseRole() == ROLE_DETECTIVE
			then
				goto done
			end

			if GetRoundState() ~= ROUND_ACTIVE then
				goto done
			end

			local armor = victim:GetArmor()

			if armor == 0 then
				goto done
			end

			if not (
				dmginfo:IsDamageType(DMG_BULLET)
				or dmginfo:IsDamageType(DMG_CLUB)
			) then
				goto done
			end

			if victim:LastHitGroup() == HITGROUP_HEAD
				and cv.item_armor_block_headshots
				and not cv.item_armor_block_headshots:GetBool()
			then
				goto done
			end

			scale = 1 / 0.7

			::done::
		elseif victim.HasEquipmentItem
			and victim:HasEquipmentItem(EQUIP_ARMOR)
			and not (combattext_bodyarmor ~= 2
				and victim.GetDetective
				and victim:GetDetective())
			and dmginfo:IsBulletDamage()
		then
			scale = 1 / 0.7
		end

		if scale then
			if not data then
				data = {}
				victim.ttt_combattext_hitdata = data
			end

			data.bodyarmor = scale
		end
	end

	if combattext_disguise > 0
		and victim:GetNWBool("disguised", false)
	then
		if not data then
			data = {}
			victim.ttt_combattext_hitdata = data
		end

		data.disguise = true
	end
end)

-- indices from 1 up to maxplayers are reserved for players, so net messages can be optimised for players
local maxplayers_bits = math.ceil(math.log(game.MaxPlayers()) / math.log(2))
local maxplayers = 2 ^ maxplayers_bits

hook.Add("PostEntityTakeDamage", "ttt_combattext_PostEntityTakeDamage", function(victim, dmginfo, took)
	if not (IsValid(victim)
		and (victim:IsPlayer() or took and victim:IsNPC())
	) then
		return
	end

	local attacker = dmginfo:GetAttacker()
	if not (IsValid(attacker)
		and attacker ~= victim
		and attacker:IsPlayer()
	) then
		return
	end

	local damage = dmginfo:GetDamage()
	if damage <= 0 then
		return
	end

	local cl_cvars = attacker.ttt_combattext_cvars
	if not cl_cvars then
		cl_cvars = updateplayerinfo(nil, attacker)
	end
	local combattext_on = cl_cvars[1]
	local dingaling_on = cl_cvars[2]
	local lasthit_on = cl_cvars[3]
	local lasthit_allowed = lasthit_on and dingaling_lasthit_allowed or false
	if not (combattext_on or dingaling_on or lasthit_allowed) then
		return
	end

	local hidetext = false

	local attacker_alive = attacker:Alive()

	local data = victim.ttt_combattext_hitdata
	victim.ttt_combattext_hitdata = nil

	-- check if disguised
	if attacker_alive
		and data and data.disguise
		and attacker.GetTraitor
		and not attacker:GetTraitor()
	then
		if combattext_disguise == 2
			or not (dingaling_on or lasthit_allowed)
		then
			return
		end

		hidetext = true
	end

	-- check if victim is in attacker's pvs
	if attacker_alive
		and combattext_lineofsight
		and not attacker:TestPVS(victim)
	then
		if not (dingaling_on or lasthit_allowed) then
			return
		end

		hidetext = true
	end

	-- check for line of sight
	if attacker_alive
		and combattext_lineofsight
		and not ( -- attacker obviously had line of sight for hitscan weapons
			dmginfo:IsBulletDamage()
			or dmginfo:IsDamageType(DMG_CLUB)
			or dmginfo:IsDamageType(DMG_SLASH)
		)
	then
		local pos = dmginfo:GetDamagePosition()
		if pos:IsZero() then
			pos = victim:WorldSpaceCenter()
		end

		local trace = {
			start  = attacker:EyePos(),
			endpos = pos,
			mask   = CONTENTS_SOLID + CONTENTS_MOVEABLE,
			filter = attacker,
		}

		if util.TraceLine(trace).Hit then
			-- perform a second trace
			trace.endpos = victim:EyePos()

			if util.TraceLine(trace).Hit then
				if not (dingaling_on or lasthit_allowed) then
					return
				end

				hidetext = true
			end
		end
	end

	-- hacky way to fix rounding
	if damage % 1 ~= 0 then
		damage = math.floor(damage * 10000 + 0.5) * (1 / 10000)
	end

	if attacker_alive
		and data and data.bodyarmor
		and not (combattext_bodyarmor ~= 2
			and attacker.GetTraitor
			and attacker:GetTraitor())
	then
		damage = damage * data.bodyarmor
	end

	local rounding = combattext_rounding

	damage = rounding == 1 and math.floor(damage + 0.5)
		or (rounding == 2 and math.ceil or math.floor)(damage)

	net.Start("ttt_combattext")

	-- dealing more than 255 damage in one hit is rare, so use only 8 bits by default
	local bigint = damage > 255
	net.WriteBool(bigint)
	net.WriteUInt(damage, bigint and 32 or 8)

	if lasthit_on then
		local kill

		if not lasthit_allowed then
			kill = false
		elseif victim.Alive then -- players
			kill = victim:Alive() ~= true
		elseif victim.Health then -- npcs
			kill = victim:Health() <= 0
		end

		net.WriteBool(kill)
	end

	if combattext_on then
		if hidetext then
			net.WriteUInt(0, 2)
		else
			local idx = victim:EntIndex()

			-- use only 1-7 bits for players, use 16 bits for npcs
			if idx > 0 and idx <= maxplayers then
				if TTT2
					and victim.Alive
					and not victim:Alive()
					and victim.lastDeathPosition
				then
					net.WriteUInt(3, 2)

					net.WriteUInt(idx - 1, maxplayers_bits)

					net.WriteVector(victim.lastDeathPosition)
				else
					net.WriteUInt(2, 2)

					net.WriteUInt(idx - 1, maxplayers_bits)
				end
			else
				net.WriteUInt(1, 2)

				net.WriteEntity(victim)
			end

			-- in tf2, damage text is a bit larger with crits
			net.WriteBool(victim.LastHitGroup
				and victim:LastHitGroup() == HITGROUP_HEAD)
		end
	end

	net.Send(attacker)
end)
