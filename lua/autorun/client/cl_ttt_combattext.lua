local combattext = true
local combattext_batching_window = 0.3
local combattext_font = "Arial"
local combattext_color = Color(255, 255, 0, 255)
local combattext_scale = 1.0
local combattext_outline = true
local combattext_antialias = false
local dingaling = false
local dingaling_file = "ttt_combattext/hitsound.ogg"
local dingaling_volume = 0.75
local dingaling_pitchmaxdmg = 50
local dingaling_pitchmindmg = 100
local dingaling_lasthit = false
local dingaling_lasthit_file = "ttt_combattext/killsound.ogg"
local dingaling_lasthit_volume = 0.75
local dingaling_lasthit_pitchmaxdmg = 50
local dingaling_lasthit_pitchmindmg = 100

do
	local cl_cvars = {}

	local function updatefont()
		local fontdata = {
			font = combattext_font,
			size = 26 * combattext_scale,
			outline = combattext_outline,
			antialias = combattext_antialias,
		}
		surface.CreateFont("ttt_combattext_font", fontdata)
		fontdata.size = fontdata.size * 4 / 3
		surface.CreateFont("ttt_combattext_font_headshot", fontdata)
	end

	for k, v in pairs({
	ttt_combattext = {
		1, "Display damage numbers",
		function(name, old, new)
			combattext = cl_cvars[name]:GetBool()
			net.Start("ttt_combattext_changecvar")
			net.SendToServer()
		end,
		{FCVAR_ARCHIVE, FCVAR_USERINFO}
	},
	ttt_combattext_batching_window = {
		0.3, "Maximum delay between damage events in order to batch numbers, set to 0 to disable",
		function(name, old, new)
			combattext_batching_window = cl_cvars[name]:GetFloat()
		end
	},
	ttt_combattext_font = {
		"Arial", "Font face used for damage numbers",
		function(name, old, new)
			combattext_font = cl_cvars[name]:GetString()
			updatefont()
		end
	},
	ttt_combattext_color = {
		"ffff00", "Color of damage numbers in hex format: RRGGBBAA",
		function(name, old, new)
			local rgba = {0, 0, 0, 255}
			local i = 0

			cl_cvars[name]:GetString():gsub("%x%x", function(x)
				i = i + 1
				rgba[i] = tonumber(x, 16)
			end, 4)

			combattext_color = Color(rgba[1], rgba[2], rgba[3], rgba[4])
		end
	},
	ttt_combattext_scale = {
		1.0, "Size of damage numbers",
		function(name, old, new)
			combattext_scale = cl_cvars[name]:GetFloat()
			updatefont()
		end
	},
	ttt_combattext_outline = {
		1, "Draw damage numbers with outlines",
		function(name, old, new)
			combattext_outline = cl_cvars[name]:GetBool()
			updatefont()
		end
	},
	ttt_combattext_antialias = {
		0, "Draw damage numbers with smooth text",
		function(name, old, new)
			combattext_antialias = cl_cvars[name]:GetBool()
			updatefont()
		end
	},
	ttt_dingaling = {
		0, "Play a sound whenever you damage an enemy",
		function(name, old, new)
			dingaling = cl_cvars[name]:GetBool()
			net.Start("ttt_combattext_changecvar")
			net.SendToServer()
		end,
		{FCVAR_ARCHIVE, FCVAR_USERINFO}
	},
	ttt_dingaling_file = {
		"ttt_combattext/hitsound.ogg", "The sound file to play on hit",
		function(name, old, new)
			dingaling_file = cl_cvars[name]:GetString()
		end
	},
	ttt_dingaling_volume = {
		0.75, "Desired volume of the hit sound",
		function(name, old, new)
			dingaling_volume = cl_cvars[name]:GetFloat()
		end
	},
	ttt_dingaling_pitchmaxdmg = {
		50, "Desired pitch of the hit sound when a maximum damage hit (150 damage) is done",
		function(name, old, new)
			dingaling_pitchmaxdmg = math.Clamp(cl_cvars[name]:GetInt(), 0, 255)
		end
	},
	ttt_dingaling_pitchmindmg = {
		100, "Desired pitch of the hit sound when a minimal damage hit (0 damage) is done",
		function(name, old, new)
			dingaling_pitchmindmg = math.Clamp(cl_cvars[name]:GetInt(), 0, 255)
		end
	},
	ttt_dingaling_lasthit = {
		0, "Play a sound whenever you kill an enemy",
		function(name, old, new)
			dingaling_lasthit = cl_cvars[name]:GetBool()
			net.Start("ttt_combattext_changecvar")
			net.SendToServer()
		end,
		{FCVAR_ARCHIVE, FCVAR_USERINFO}
	},
	ttt_dingaling_lasthit_file = {
		"ttt_combattext/killsound.ogg", "The sound file to play on kill",
		function(name, old, new)
			dingaling_lasthit_file = cl_cvars[name]:GetString()
		end
	},
	ttt_dingaling_lasthit_volume = {
		0.75, "Desired volume of the last hit sound",
		function(name, old, new)
			dingaling_lasthit_volume = cl_cvars[name]:GetFloat()
		end
	},
	ttt_dingaling_lasthit_pitchmaxdmg = {
		50, "Desired pitch of the last hit sound when a maximum damage hit (150 damage) is done",
		function(name, old, new)
			dingaling_lasthit_pitchmaxdmg = math.Clamp(cl_cvars[name]:GetInt(), 0, 255)
		end
	},
	ttt_dingaling_lasthit_pitchmindmg = {
		100, "Desired pitch of the last hit sound when a minimal damage hit (0 damage) is done",
		function(name, old, new)
			dingaling_lasthit_pitchmindmg = math.Clamp(cl_cvars[name]:GetInt(), 0, 255)
		end
	},
	}) do
		cl_cvars[k] = CreateConVar(k, v[1], v[4] or FCVAR_ARCHIVE, v[2])
		v[3](k)
		cvars.AddChangeCallback(k, v[3])
	end
end

local combattext_bits = GetConVar("ttt_combattext_bits"):GetInt()
net.Receive("ttt_combattext_changecvar", function()
	combattext_bits = GetConVar("ttt_combattext_bits"):GetInt()
end)

local function RemapValClamped(val, a, b, c, d)
	return c + (d - c) * math.min(math.max((val - a) / (b - a), 0), 1)
end

local numbers = {
	head = 0, tail = 0,
}

net.Receive("ttt_combattext", function()
	local attacker = LocalPlayer()
	if not (attacker and attacker:IsValid()) then
		return
	end

	local damage = net.ReadUInt(combattext_bits)

	local lasthit
	if dingaling_lasthit then
		lasthit = net.ReadBool()
	end

	if dingaling or lasthit then
		local file, volume, pitchmin, pitchmax

		if lasthit then
			file = dingaling_lasthit_file
			volume = dingaling_lasthit_volume
			pitchmin = dingaling_lasthit_pitchmindmg
			pitchmax = dingaling_lasthit_pitchmaxdmg
		else
			file = dingaling_file
			volume = dingaling_volume
			pitchmin = dingaling_pitchmindmg
			pitchmax = dingaling_pitchmaxdmg
		end

		local pitch = pitchmin == pitchmax and pitchmin
			or RemapValClamped(damage, 0, 150, pitchmin, pitchmax)

		attacker:EmitSound(file, SNDLVL_NONE, pitch, volume, CHAN_STATIC)
	end

	if not combattext then
		return
	end

	local victim = net.ReadEntity()
	if not (victim and victim:IsValid()) then
		return
	end

	local pos = victim:GetPos()
	local _, vmax = victim:GetCollisionBounds()
	pos.z = pos.z + vmax.z + RemapValClamped(
		pos:DistToSqr(attacker:GetPos()), 0, 65536, 0, 16)

	local tail = numbers.tail

	local realtime = RealTime()

	if numbers.head ~= tail and combattext_batching_window > 0 then
		local num = numbers[tail]

		if victim == num.victim
			and realtime - num.birth <= combattext_batching_window
		then
			num.birth = realtime
			num.pos = pos
			num.damage = num.damage + damage
			num.str = ("-%d"):format(num.damage)
			num.headshot = net.ReadBool()

			return
		end
	end

	tail = tail + 1
	numbers.tail = tail
	numbers[tail] = {
		birth = realtime,
		pos = pos,
		damage = damage,
		str = ("-%d"):format(damage),
		headshot = net.ReadBool(),
	}

	if combattext_batching_window > 0 then
		numbers[tail].victim = victim
	end
end)

local RealTime, cam, surface = RealTime, cam, surface

hook.Add("HUDPaint", "ttt_combattext_Think", function()
	if not combattext then
		return
	end

	if numbers.head == numbers.tail then
		return
	end

	local realtime = RealTime()
	local max_lifetime = 1.5
	local float_height = 32

	local r, g, b, a = combattext_color:Unpack()

	local num
	for i = numbers.head + 1, numbers.tail do
		num = numbers[i]

		local lifetime = realtime - num.birth

		if lifetime > max_lifetime then
			numbers[i] = nil

			if i == numbers.tail then
				numbers.head = 0
				numbers.tail = 0
			else
				numbers.head = i
			end
		else
			local pos = num.pos

			local lifeperc = lifetime / max_lifetime

			cam.Start3D()
			pos = Vector(pos.x, pos.y,
				pos.z + lifeperc * float_height):ToScreen()
			cam.End3D()

			surface.SetFont(num.headshot
				and "ttt_combattext_font_headshot"
				or "ttt_combattext_font")
			surface.SetTextPos(pos.x, pos.y)
			surface.SetTextColor(r, g, b,
				lifeperc > 0.5 and a * (2 - 2 * lifeperc) or a)
			surface.DrawText(num.str)
		end
	end
end)
