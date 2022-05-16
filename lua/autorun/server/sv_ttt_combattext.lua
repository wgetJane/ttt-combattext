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

local combattext_bodyarmor = 1
local combattext_disguise = 0
local combattext_lineofsight = true
local combattext_rounding = 1
local dingaling_lasthit_allowed = true

local pre
for _, v in ipairs({
{
	"bodyarmor", 1,
	FCVAR_ARCHIVE + FCVAR_NOTIFY,
	[[TTT: Prevent damage text from revealing if the target is wearing body armor
   (1 = except against detectives and fellow traitors, 2 = no exceptions)]],
	function(_,_, new)
		combattext_bodyarmor = tonumber(new) or 1
	end,
	"combattext",
},
{
	"disguise", 0,
	FCVAR_ARCHIVE + FCVAR_NOTIFY,
	[[TTT: Don't show damage text if target is disguised
   (1 = still let hitsound play, 2 = don't let hitsound play too)]],
	function(_,_, new)
		combattext_disguise = tonumber(new) or 0
	end
},
{
	"lineofsight", 1,
	FCVAR_ARCHIVE + FCVAR_NOTIFY,
	"Don't show damage text if the target cannot be seen",
	function(_,_, new)
		combattext_lineofsight = tonumber(new) == 1
	end
},
{
	"rounding", 1,
	FCVAR_ARCHIVE,
	[[0: round down (floor)
 - 1: round to nearest integer
 - 2: round up (ceiling)]],
	function(_,_, new)
		combattext_rounding = tonumber(new) or 1
	end
},
{
	"lasthit_allowed", 1,
	FCVAR_ARCHIVE + FCVAR_NOTIFY,
	"Allow players to enable kill sounds",
	function(_,_, new)
		dingaling_lasthit_allowed = tonumber(new) == 1
	end,
	"dingaling"
},
}) do
	pre = v[6] or pre
	local k = "ttt_" .. pre .. "_" .. v[1]

	v[5](k, "", CreateConVar(k, v[2], v[3], v[4]):GetString())

	cvars.AddChangeCallback(k, v[5])
end

util.AddNetworkString("ttt_combattext")

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
	if not IsValid(victim) then
		return
	end

	victim.ttt_combattext_tookdamage = victim:GetInternalVariable("m_takedamage") > 1

	if not victim:IsPlayer() then
		return
	end

	-- store certain information that might not be available in the PostEntityTakeDamage hook
	local data = victim.ttt_combattext_hitdata

	if not data then
		data = {}
		victim.ttt_combattext_hitdata = data
	end

	data.vicpos = victim:GetPos()

	data.bodyarmor = false

	if combattext_bodyarmor < 1 then
	elseif TTT2 then
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

		if not dmginfo:IsDamageType(DMG_BULLET + DMG_CLUB) then
			goto done
		end

		if victim:LastHitGroup() == HITGROUP_HEAD
			and cv.item_armor_block_headshots
			and not cv.item_armor_block_headshots:GetBool()
		then
			goto done
		end

		data.bodyarmor = 1 / 0.7

		::done::
	elseif victim.HasEquipmentItem
		and victim:HasEquipmentItem(EQUIP_ARMOR)
		and not (combattext_bodyarmor ~= 2
			and victim.GetDetective
			and victim:GetDetective())
		and dmginfo:IsBulletDamage()
	then
		data.bodyarmor = 1 / 0.7
	end

	data.disguise = combattext_disguise > 0
		and victim:GetNWBool("disguised", false)
end)

-- indices from 1 up to maxplayers are reserved for players, so net messages can be optimised for players
local maxplayers_bits = math.ceil(math.log(game.MaxPlayers()) / math.log(2))
local maxplayers = 2 ^ maxplayers_bits

local tracedata

hook.Add("PostEntityTakeDamage", "ttt_combattext_PostEntityTakeDamage", function(victim, dmginfo, took)
	if not (
		IsValid(victim)
		and victim.ttt_combattext_tookdamage
		and (
			victim:IsPlayer()
			or took
			and (
				victim:IsNPC()
				or victim:IsNextBot()
			)
		)
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
		or updateplayerinfo(nil, attacker)

	local combattext_on, dingaling_on, lasthit_on =
		cl_cvars[1], cl_cvars[2], cl_cvars[3]

	local lasthit_allowed = lasthit_on
		and dingaling_lasthit_allowed
		or false

	if not (combattext_on or dingaling_on or lasthit_allowed) then
		return
	end

	local hidetext = false

	local attacker_alive = attacker:Alive()

	local data = victim.ttt_combattext_hitdata

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
		and not dmginfo:IsDamageType( -- attacker obviously had line of sight for hitscan weapons
			DMG_BULLET + DMG_CLUB + DMG_SLASH)
	then
		local pos = dmginfo:GetDamagePosition()
		if pos:IsZero() then
			pos = victim:WorldSpaceCenter()
		end

		local td = tracedata or {
			mask = CONTENTS_SOLID + CONTENTS_MOVEABLE,
			output = {},
		}
		tracedata = td

		td.start = attacker:EyePos()
		td.endpos = pos
		td.filter = attacker

		if util.TraceLine(td).Hit then
			-- perform a second trace
			td.endpos = victim:EyePos()

			if util.TraceLine(td).Hit then
				if not (dingaling_on or lasthit_allowed) then
					return
				end

				hidetext = true
			end
		end
	end

	-- fix rounding (so a number like 0.49999999 won't get rounded down)
	local x10k = damage * 10000
	if x10k % 1 ~= 0 then
		damage = math.floor(x10k + 0.5) * (1 / 10000)
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
			kill = not victim:Alive()
		elseif victim.Health then -- npcs
			kill = victim:Health() <= 0
		end

		net.WriteBool(kill)
	end

	if combattext_on then
		if hidetext then
			net.WriteUInt(0, 2)

			goto done
		end

		local idx = victim:EntIndex()

		-- use only 1-7 bits for players, use 16 bits for npcs
		if idx > 0 and idx <= maxplayers then
			if victim.Alive and not victim:Alive()
				and data and data.vicpos
			then
				net.WriteUInt(3, 2)

				net.WriteUInt(idx - 1, maxplayers_bits)

				net.WriteVector(data.vicpos)
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

		::done::
	end

	net.Send(attacker)
end)
