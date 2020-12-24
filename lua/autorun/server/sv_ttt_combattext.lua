resource.AddSingleFile("sound/ttt_combattext/hitsound.wav")

util.AddNetworkString("ttt_combattext")
util.AddNetworkString("ttt_combattext_changecvar")

local combattext_bodyarmor = CreateConVar("ttt_combattext_bodyarmor", 1,
	FCVAR_ARCHIVE + FCVAR_NOTIFY, "TTT: Prevent damage text from revealing if the target is wearing body armor"
):GetBool()
local combattext_disguise = CreateConVar("ttt_combattext_disguise", 0,
	FCVAR_ARCHIVE + FCVAR_NOTIFY, "TTT: Don't show damage text if target is disguised"
):GetBool()
local combattext_lineofsight = CreateConVar("ttt_combattext_lineofsight", 1,
	FCVAR_ARCHIVE + FCVAR_NOTIFY, "Don't show damage text if the target cannot be seen"
):GetBool()
local combattext_rounding = CreateConVar("ttt_combattext_rounding", 1,
	FCVAR_ARCHIVE, "0: round down (floor)\n - 1: round off\n - 2: round up (ceiling)"
):GetInt()
local combattext_bits = GetConVar("ttt_combattext_bits"):GetInt()

cvars.AddChangeCallback("ttt_combattext_bodyarmor", function(name, old, new)
	combattext_bodyarmor = GetConVar(name):GetBool()
end)
cvars.AddChangeCallback("ttt_combattext_disguise", function(name, old, new)
	combattext_disguise = GetConVar(name):GetBool()
end)
cvars.AddChangeCallback("ttt_combattext_lineofsight", function(name, old, new)
	combattext_lineofsight = GetConVar(name):GetBool()
end)
cvars.AddChangeCallback("ttt_combattext_rounding", function(name, old, new)
	combattext_rounding = GetConVar(name):GetInt()
end)
cvars.AddChangeCallback("ttt_combattext_bits", function(name, old, new)
	combattext_bits = GetConVar(name):GetInt()

	net.Start("ttt_combattext_changecvar")
	net.Broadcast()
end)

local function updateplayerinfo(ply)
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

net.Receive("ttt_combattext_changecvar", function(len, ply)
	updateplayerinfo(ply)
end)

hook.Add("EntityTakeDamage", "ttt_combattext_EntityTakeDamage", function(victim, dmginfo)
	if not (victim
		and victim:IsValid()
		and (victim:IsPlayer() or victim:IsNPC())
	) then
		return
	end

	local data = {}

	if combattext_bodyarmor then
		data.bodyarmor = victim.HasEquipmentItem
			and victim:HasEquipmentItem(EQUIP_ARMOR)
			and dmginfo:IsBulletDamage()
			or false
	end

	if combattext_disguise then
		data.disguise = victim:GetNWBool("disguised", false)
	end

	victim.ttt_combattext_hitdata = next(data) and data
end)

hook.Add("PostEntityTakeDamage", "ttt_combattext_PostEntityTakeDamage", function(victim, dmginfo, took)
	if not (took
		and victim
		and victim:IsValid()
		and (victim:IsPlayer() or victim:IsNPC())
	) then
		return
	end

	local attacker = dmginfo:GetAttacker()
	if not (attacker
		and attacker ~= victim
		and attacker:IsValid()
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
		cl_cvars = updateplayerinfo(attacker)
	end
	local combattext_on = cl_cvars[1]
	local dingaling_on = cl_cvars[2]
	local lasthit_on = cl_cvars[3]
	if not (combattext_on or dingaling_on or lasthit_on) then
		return
	end

	local attacker_alive = attacker:Alive()

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

		if util.TraceLine(trace).Fraction < 1 then
			-- perform a second trace
			trace.endpos = victim:EyePos()

			if util.TraceLine(trace).Fraction < 1 then
				if not (dingaling_on or lasthit_on) then
					return
				end

				combattext_on = false
			end
		end
	end

	local data = victim.ttt_combattext_hitdata
	victim.ttt_combattext_hitdata = nil

	if attacker_alive
		and data and data.disguise
		and attacker.GetTraitor
		and not attacker:GetTraitor()
	then
		if not (dingaling_on or lasthit_on) then
			return
		end

		combattext_on = false
	end

	if data and data.bodyarmor then
		-- armour damage scale is hardcoded as 0.7
		damage = damage / 0.7
	end

	local bits = combattext_bits
	local rounding = combattext_rounding

	damage = math.min(
		rounding == 1 and math.floor(damage + 0.5)
			or (rounding == 2 and math.ceil or math.floor)(damage),
		2^bits - 1
	)

	net.Start("ttt_combattext")
	net.WriteUInt(damage, bits)
	if lasthit_on then
		local kill
		if victim.Alive then
			kill = victim:Alive() ~= true
		elseif victim.Health then
			kill = victim:Health() <= 0
		end
		net.WriteBool(kill)
	end
	if combattext_on then
		net.WriteEntity(victim)
		net.WriteBool(victim.LastHitGroup
			and victim:LastHitGroup() == HITGROUP_HEAD)
	end
	net.Send(attacker)
end)
