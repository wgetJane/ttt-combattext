resource.AddWorkshop("2791060001")

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
local combattext_npcinfl = true
local combattext_lineofsight = true
local dingaling_lasthit_allowed = true

local pre
for _, v in ipairs({
{
	"bodyarmor", 1,
	[[TTT: Prevent damage text from revealing if the target is wearing body armor
   (1 = except against detectives and fellow traitors, 2 = no exceptions)]],
	function(_,_, new)
		combattext_bodyarmor = tonumber(new) or 1
	end,
	"combattext",
},
{
	"disguise", 0,
	[[TTT: Don't show damage text if target is disguised
   (1 = still let hitsound play, 2 = don't let hitsound play too)]],
	function(_,_, new)
		combattext_disguise = tonumber(new) or 0
	end
},
{
	"npcinfl", 1,
	"Show damage dealt by NPCs on a player's behalf",
	function(_,_, new)
		combattext_npcinfl = tonumber(new) ~= 0
	end
},
{
	"lineofsight", 1,
	"Don't show damage text if the target cannot be seen",
	function(_,_, new)
		combattext_lineofsight = tonumber(new) ~= 0
	end
},
{
	"lasthit_allowed", 1,
	"Allow players to enable kill sounds",
	function(_,_, new)
		dingaling_lasthit_allowed = tonumber(new) ~= 0
	end,
	"dingaling"
},
}) do
	pre = v[5] or pre
	local k = "ttt_" .. pre .. "_" .. v[1]

	v[4](k, "", CreateConVar(k, v[2], FCVAR_ARCHIVE + FCVAR_NOTIFY, v[3]):GetString())

	cvars.AddChangeCallback(k, v[4])
end

util.AddNetworkString("ttt_combattext")

local function updateplayerinfo(_, ply)
	if not ply then
		return
	end

	local cl_cvars = ply.ttt_combattext_cvars
	if not cl_cvars then
		cl_cvars = {true, false, false, false}
		ply.ttt_combattext_cvars = cl_cvars
	end

	cl_cvars[1] = ply:GetInfoNum("ttt_combattext", 1) == 1
	cl_cvars[2] = ply:GetInfoNum("ttt_dingaling", 0) == 1
	cl_cvars[3] = ply:GetInfoNum("ttt_dingaling_lasthit", 0) == 1
	cl_cvars[4] = ply:GetInfoNum("ttt_combattext_unreliable", 0) == 1

	return cl_cvars
end

net.Receive("ttt_combattext", updateplayerinfo)

local function IsDetect(e)
	if e.IsDetectiveTeam then
		return e:IsDetectiveTeam()
	elseif e.GetDetective then
		return e:GetDetective()
	end
end

hook.Add("EntityTakeDamage", "ttt_combattext_EntityTakeDamage", function(victim, dmginfo)
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

	data.bodyarmor = data.bodyarmor2 or false
	data.bodyarmor2 = false

	if combattext_bodyarmor ~= 0
		and not TTT2
		and victim.HasEquipmentItem
		and victim:HasEquipmentItem(EQUIP_ARMOR)
		and not (combattext_bodyarmor ~= 2 and IsDetect(victim))
		and dmginfo:IsBulletDamage()
	then
		data.bodyarmor = 1 / 0.7
	end

	data.disguise = combattext_disguise > 0
		and victim:GetNWBool("disguised", false)
end)

hook.Add("PostGamemodeLoaded", "ttt_combattext_PostGamemodeLoaded", function()
	if not TTT2 then
		return
	end

	AddCSLuaFile("terrortown/menus/gamemode/combattext.lua")
	AddCSLuaFile("terrortown/menus/gamemode/combattext/combattext.lua")

	if not (ARMOR and ARMOR.HandlePlayerTakeDamage) then
		return
	end

	-- pretty hacky, but there's no other way since there's no hook for this and hooks are called in arbitrary order

	ttt_combattext_HandlePlayerTakeDamage = ttt_combattext_HandlePlayerTakeDamage or ARMOR.HandlePlayerTakeDamage

	function ARMOR:HandlePlayerTakeDamage(ply, infl, att, amount, dmginfo)
		local scale = dmginfo:GetDamage()

		ttt_combattext_HandlePlayerTakeDamage(self, ply, infl, att, amount, dmginfo)

		if combattext_bodyarmor == 0 then
			return
		end

		scale = scale / dmginfo:GetDamage()

		if scale == 1 then
			return
		end

		if combattext_bodyarmor ~= 2 and (
			ply.GetSubRoleData and ply:GetSubRoleData().isPublicRole
			or ply.RoleKnown and ply:RoleKnown()
		) then
			return
		end

		local data = ply.ttt_combattext_hitdata

		if not data then
			data = {}
			ply.ttt_combattext_hitdata = data
		end

		data.bodyarmor = scale
		data.bodyarmor2 = scale
	end
end)

local function IsTraitor(e)
	if e.IsTraitorTeam then
		return e:IsTraitorTeam()
	elseif e.GetTraitor then
		return e:GetTraitor()
	end
end

-- indices from 1 up to maxplayers are reserved for players, so net messages can be optimised for players
local maxplayers_bits = math.ceil(math.log(game.MaxPlayers()) / math.log(2))
local maxplayers = 2 ^ maxplayers_bits

local tracedata

hook.Add("PostEntityTakeDamage", "ttt_combattext_PostEntityTakeDamage", function(victim, dmginfo, took)
	local accum = victim.ttt_combattext_accumdamage or 0

	victim.ttt_combattext_accumdamage = victim:GetInternalVariable("m_flDamageAccumulator")

	if not (
		victim.ttt_combattext_tookdamage
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

	if not combattext_npcinfl then
		local infl = dmginfo:GetInflictor()

		if infl ~= attacker
			and IsValid(infl)
			and (infl:IsNPC() or infl:IsNextBot())
		then
			return
		end
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
		and not IsTraitor(attacker)
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
	if attacker_alive and combattext_lineofsight then
		local infl = dmginfo:IsDamageType(
				-- attacker obviously had line of sight for hitscan weapons
				DMG_BULLET + DMG_CLUB + DMG_SLASH
			) and dmginfo:GetInflictor()

		if not IsValid(infl) or infl ~= attacker and infl ~= attacker:GetActiveWeapon() then
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
	end

	damage = math.floor(damage + accum)

	if data and data.bodyarmor
		and not (combattext_bodyarmor ~= 2 and IsTraitor(attacker))
	then
		damage = damage * data.bodyarmor
	end

	net.Start("ttt_combattext", cl_cvars[4])

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
