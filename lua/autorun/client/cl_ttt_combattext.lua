local combattext = true
local combattext_batching_window = 0.3
local combattext_font = "Arial"
local combattext_r, combattext_g, combattext_b, combattext_a = 255, 255, 0, 255
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

local function hex2rgb(hex)
	local r, g, b, a = 0, 0, 0, 255
	local i = 0

	for x in hex:gmatch("%x%x") do
		local val = tonumber(x, 16)

		if i == 0 then
			r = val
		elseif i == 1 then
			g = val
		elseif i == 2 then
			b = val
		else
			a = val
			break
		end

		i = i + 1
	end

	return r, g, b, a
end

local function rgb2hex(r, g, b, a)
	if a < 255 then
		return ("%02x%02x%02x%02x"):format(r, g, b, a)
	else
		return ("%02x%02x%02x"):format(r, g, b)
	end
end

local function updateuserinfo()
end
local updatefont
for k, v in pairs({
ttt_combattext = {
	1, "Display damage numbers",
	function(name, old, new)
		combattext = tonumber(new) == 1
		updateuserinfo()
	end,
	FCVAR_ARCHIVE + FCVAR_USERINFO
},
ttt_combattext_batching_window = {
	0.3, "Maximum delay between damage events in order to batch numbers, set to 0 to disable",
	function(name, old, new)
		combattext_batching_window = tonumber(new) or 0.3
	end
},
ttt_combattext_font = {
	"Arial", "Font face used for damage numbers",
	function(name, old, new)
		combattext_font = new
		updatefont = true
	end
},
ttt_combattext_color = {
	"ffff00", "Color of damage numbers in hex format: RRGGBBAA",
	function(name, old, new)
		combattext_r, combattext_g, combattext_b, combattext_a = hex2rgb(new)
	end
},
ttt_combattext_scale = {
	1.0, "Size of damage numbers",
	function(name, old, new)
		combattext_scale = tonumber(new) or 1.0
		updatefont = true
	end
},
ttt_combattext_outline = {
	1, "Draw damage numbers with outlines",
	function(name, old, new)
		combattext_outline = tonumber(new) == 1
		updatefont = true
	end
},
ttt_combattext_antialias = {
	0, "Draw damage numbers with smooth text",
	function(name, old, new)
		combattext_antialias = tonumber(new) == 1
		updatefont = true
	end
},
ttt_dingaling = {
	0, "Play a sound whenever you damage an enemy",
	function(name, old, new)
		dingaling = tonumber(new) == 1
		updateuserinfo()
	end,
	FCVAR_ARCHIVE + FCVAR_USERINFO
},
ttt_dingaling_file = {
	"ttt_combattext/hitsound.ogg", "The sound file to play on hit",
	function(name, old, new)
		dingaling_file = new
	end
},
ttt_dingaling_volume = {
	0.75, "Desired volume of the hit sound",
	function(name, old, new)
		dingaling_volume = tonumber(new) or 0.75
	end
},
ttt_dingaling_pitchmaxdmg = {
	50, "Desired pitch of the hit sound when a maximum damage hit (150 damage) is done",
	function(name, old, new)
		dingaling_pitchmaxdmg = math.Clamp(tonumber(new) or 50, 0, 255)
	end
},
ttt_dingaling_pitchmindmg = {
	100, "Desired pitch of the hit sound when a minimal damage hit (0 damage) is done",
	function(name, old, new)
		dingaling_pitchmindmg = math.Clamp(tonumber(new) or 100, 0, 255)
	end
},
ttt_dingaling_lasthit = {
	0, "Play a sound whenever you kill an enemy",
	function(name, old, new)
		dingaling_lasthit = tonumber(new) == 1
		updateuserinfo()
	end,
	FCVAR_ARCHIVE + FCVAR_USERINFO
},
ttt_dingaling_lasthit_file = {
	"ttt_combattext/killsound.ogg", "The sound file to play on kill",
	function(name, old, new)
		dingaling_lasthit_file = new
	end
},
ttt_dingaling_lasthit_volume = {
	0.75, "Desired volume of the last hit sound",
	function(name, old, new)
		dingaling_lasthit_volume = tonumber(new) or 0.75
	end
},
ttt_dingaling_lasthit_pitchmaxdmg = {
	50, "Desired pitch of the last hit sound when a maximum damage hit (150 damage) is done",
	function(name, old, new)
		dingaling_lasthit_pitchmaxdmg = math.Clamp(tonumber(new) or 50, 0, 255)
	end
},
ttt_dingaling_lasthit_pitchmindmg = {
	100, "Desired pitch of the last hit sound when a minimal damage hit (0 damage) is done",
	function(name, old, new)
		dingaling_lasthit_pitchmindmg = math.Clamp(tonumber(new) or 100, 0, 255)
	end
},
}) do
	v[3](k, nil,
		CreateConVar(k, v[1], v[4] or FCVAR_ARCHIVE, v[2]):GetString()
	)
	cvars.AddChangeCallback(k, v[3])
end
updateuserinfo = function()
	net.Start("ttt_combattext")
	net.SendToServer()
end
local function updatefontfn()
	updatefont = false

	local fontdata = {
		font = combattext_font,
		size = 26 * combattext_scale,
		outline = combattext_outline,
		antialias = combattext_antialias,
	}
	surface.CreateFont("ttt_combattext_font", fontdata)

	fontdata.size = fontdata.size * (4 / 3)
	surface.CreateFont("ttt_combattext_font_headshot", fontdata)
end
updatefontfn()

local function RemapValClamped(val, a, b, c, d)
	return c + (d - c) * math.min(math.max((val - a) / (b - a), 0), 1)
end

local maxplayers_bits = math.ceil(math.log(game.MaxPlayers()) / math.log(2))

local head, tail

local RealTime = RealTime

net.Receive("ttt_combattext", function()
	local attacker = LocalPlayer()
	if not IsValid(attacker) then
		return
	end

	local damage = net.ReadUInt(net.ReadBool() and 32 or 8)

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

		attacker:EmitSound(file, 0, pitch, volume, CHAN_STATIC)
	end

	if not combattext then
		return
	end

	local uint = net.ReadUInt(2)

	local victim = uint > 1 and Entity(net.ReadUInt(maxplayers_bits) + 1)
		or uint == 1 and net.ReadEntity()
		or nil

	if not (victim and IsValid(victim)) then
		return
	end

	local pos = uint == 3 and net.ReadVector() or victim:GetPos()

	local _, vmax = victim:GetCollisionBounds()
	pos.z = pos.z + vmax.z + RemapValClamped(
			pos:DistToSqr(attacker:GetPos()),
			0, 256 * 256,
			0, 16
		)

	if updatefont then
		updatefontfn()
	end

	local num = tail

	local batch = combattext_batching_window > 0

	local realtime = RealTime()

	if num and batch
		and victim == num[7]
		and realtime - num[2] <= combattext_batching_window
	then
		damage = num[6] + damage

		num[2] = realtime
		num[3] = pos
		num[4] = ("-%d"):format(damage)
		num[5] = net.ReadBool()
		num[6] = damage

		return
	end

	tail = {
		false,
		realtime,
		pos,
		("-%d"):format(damage),
		net.ReadBool(),
		batch and damage or nil,
		batch and victim or nil,
	}

	if num then
		num[1] = tail
	else
		head = tail
	end
end)

local vec = Vector()

local SetFont, SetTextPos, SetTextColor, DrawText =
	surface.SetFont, surface.SetTextPos, surface.SetTextColor, surface.DrawText

hook.Add("HUDPaint", "ttt_combattext_HUDPaint", function()
	if not (head and combattext) then
		return
	end

	local realtime = RealTime()
	local max_lifetime = 1.5
	local float_height = 32

	local vec = vec

	local r, g, b, a = combattext_r, combattext_g, combattext_b, combattext_a
	local headshot

	local num = head
	while num do
		local lifetime = realtime - num[2]

		local nxt = num[1]

		if lifetime > max_lifetime then
			head = nxt

			if nxt then
				num[1] = false
			else
				tail = nil
				break
			end
		else
			local pos = num[3]

			local lifeperc = lifetime / max_lifetime

			vec[1] = pos[1]
			vec[2] = pos[2]
			vec[3] = pos[3] + lifeperc * float_height

			pos = vec:ToScreen()

			if pos.visible then
				if num[5] ~= headshot then
					headshot = num[5]

					SetFont(headshot
						and "ttt_combattext_font_headshot"
						or "ttt_combattext_font")
				end

				SetTextPos(pos.x, pos.y)

				SetTextColor(r, g, b,
					lifeperc > 0.5 and a * (2 - 2 * lifeperc) or a)

				DrawText(num[4])
			end
		end

		num = nxt
	end
end)

hook.Add("TTTSettingsTabs", "ttt_combattext_TTTSettingsTabs", function(dtabs)
	local dsettings = vgui.Create("DPanelList", dtabs)
	dsettings:StretchToParent(0, 0, dtabs:GetPadding() * 2, 0)
	dsettings:EnableVerticalScrollbar(true)
	dsettings:SetPadding(10)
	dsettings:SetSpacing(10)

	local f, d

	f = vgui.Create("DForm", dsettings)
	f:SetName("Damage text")

	d = f:CheckBox("Enable damage text", "ttt_combattext")
	d:SetTooltip(GetConVar("ttt_combattext"):GetHelpText())

	d = f:NumSlider("Damage text batching", "ttt_combattext_batching_window", 0, 2, 2)
	d.Label:SetWrap(true)
	d:SetTooltip(GetConVar("ttt_combattext_batching_window"):GetHelpText())

	d = f:TextEntry("Text font name", "ttt_combattext_font")
	d:SetTooltip(GetConVar("ttt_combattext_font"):GetHelpText())

	local dhex, dmix
	local r, g, b, a = combattext_r, combattext_g, combattext_b, combattext_a
	local col = Color(r, g, b, a)
	local lock

	dhex = f:TextEntry("Text color", "ttt_combattext_color")
	dhex:SetTooltip(GetConVar("ttt_combattext_color"):GetHelpText())
	dhex:SetValue(rgb2hex(r, g, b, a))
	dhex:SetUpdateOnType(true)
	function dhex:AllowInput(char)
		return char:find("%X") and true or false
	end
	function dhex:OnValueChange(val)
		local r, g, b, a = hex2rgb(val)
		col.r = r
		col.g = g
		col.b = b
		col.a = a

		lock = true
		dmix:SetColor(col)
	end

	dmix = vgui.Create("DColorMixer")
	dmix:SetColor(col)
	dmix:SetHeight(92)
	dmix:DockMargin(100, 0, 0, 0)
	dmix:SetAlphaBar(true)
	dmix:SetPalette(false)
	dmix:SetWangs(true)
	function dmix:ValueChanged(col)
		if lock then
			lock = false
			return
		end

		dhex:ConVarChanged(rgb2hex(col.r, col.g, col.b, col.a)) -- inefficient
	end
	f:AddItem(dmix)

	d = f:NumSlider("Text scale", "ttt_combattext_scale", 0, 3, 2)
	d.Label:SetWrap(true)
	d:SetTooltip(GetConVar("ttt_combattext_scale"):GetHelpText())

	d = f:CheckBox("Text outline", "ttt_combattext_outline")
	d:SetTooltip(GetConVar("ttt_combattext_outline"):GetHelpText())

	d = f:CheckBox("Text anti-aliasing", "ttt_combattext_antialias")
	d:SetTooltip(GetConVar("ttt_combattext_antialias"):GetHelpText())

	dsettings:AddItem(f)

	f = vgui.Create("DForm", dsettings)
	f:SetName("Hit sound")

	d = f:CheckBox("Enable hit sound", "ttt_dingaling")
	d:SetTooltip(GetConVar("ttt_dingaling"):GetHelpText())

	d = f:TextEntry("Sound file", "ttt_dingaling_file")
	d:SetTooltip(GetConVar("ttt_dingaling_file"):GetHelpText())

	d = f:NumSlider("Sound volume", "ttt_dingaling_volume", 0, 1, 2)
	d.Label:SetWrap(true)
	d:SetTooltip(GetConVar("ttt_dingaling_volume"):GetHelpText())

	d = f:NumSlider("High damage pitch", "ttt_dingaling_pitchmaxdmg", 0, 200, 0)
	d.Label:SetWrap(true)
	d:SetTooltip(GetConVar("ttt_dingaling_pitchmaxdmg"):GetHelpText())

	d = f:NumSlider("Low damage pitch", "ttt_dingaling_pitchmindmg", 0, 200, 0)
	d.Label:SetWrap(true)
	d:SetTooltip(GetConVar("ttt_dingaling_pitchmindmg"):GetHelpText())

	d = f:Button("Play hit sound")
	function d:OnDepressed()
		local ply = LocalPlayer()

		if not IsValid(ply)
			and not file.Exists("sounds/" .. dingaling_file, "GAME")
		then
			return
		end

		ply:EmitSound(
			dingaling_file, 0,
			RemapValClamped(
				math.random(0, 150), 0, 150,
				dingaling_pitchmindmg, dingaling_pitchmaxdmg
			),
			dingaling_volume, CHAN_STATIC
		)
	end

	dsettings:AddItem(f)

	f = vgui.Create("DForm", dsettings)
	f:SetName("Kill sound")

	d = f:CheckBox("Enable kill sound", "ttt_dingaling_lasthit")
	d:SetTooltip(GetConVar("ttt_dingaling_lasthit"):GetHelpText())

	d = f:TextEntry("Sound file", "ttt_dingaling_lasthit_file")
	d:SetTooltip(GetConVar("ttt_dingaling_lasthit_file"):GetHelpText())

	d = f:NumSlider("Sound volume", "ttt_dingaling_lasthit_volume", 0, 1, 2)
	d.Label:SetWrap(true)
	d:SetTooltip(GetConVar("ttt_dingaling_lasthit_volume"):GetHelpText())

	d = f:NumSlider("High damage pitch", "ttt_dingaling_lasthit_pitchmaxdmg", 0, 200, 0)
	d.Label:SetWrap(true)
	d:SetTooltip(GetConVar("ttt_dingaling_lasthit_pitchmaxdmg"):GetHelpText())

	d = f:NumSlider("Low damage pitch", "ttt_dingaling_lasthit_pitchmindmg", 0, 200, 0)
	d.Label:SetWrap(true)
	d:SetTooltip(GetConVar("ttt_dingaling_lasthit_pitchmindmg"):GetHelpText())

	d = f:Button("Play kill sound")
	function d:OnDepressed()
		local ply = LocalPlayer()

		if not IsValid(ply)
			and not file.Exists("sounds/" .. dingaling_lasthit_file, "GAME")
		then
			return
		end

		ply:EmitSound(
			dingaling_lasthit_file, 0,
			RemapValClamped(
				math.random(0, 150), 0, 150,
				dingaling_lasthit_pitchmindmg, dingaling_lasthit_pitchmaxdmg
			),
			dingaling_lasthit_volume, CHAN_STATIC
		)
	end

	dsettings:AddItem(f)

	if ConVarExists("ttt_combattext_bodyarmor") then
		f = vgui.Create("DForm", dsettings)
		f:SetName("Server settings")

		d = f:ComboBox("Hide body armor", "ttt_combattext_bodyarmor")
		d:SetTooltip("Prevent damage text from revealing if the target is wearing body armor")
		d:SetSortItems(false)
		d:AddChoice("Disabled", 0)
		d:AddChoice("Enabled except againt detectives and fellow traitors", 1)
		d:AddChoice("Enabled with no exceptions", 2)

		d = f:ComboBox("Disguised targets", "ttt_combattext_disguise")
		d:SetSortItems(false)
		d:AddChoice("Show damage text", 0)
		d:AddChoice("Don't show damage text", 1)
		d:AddChoice("Don't show damage text and don't play hit sound", 2)

		d = f:CheckBox("Check line of sight", "ttt_combattext_lineofsight")
		d:SetTooltip(GetConVar("ttt_combattext_lineofsight"):GetHelpText())

		d = f:ComboBox("Damage rounding", "ttt_combattext_rounding")
		d:SetSortItems(false)
		d:AddChoice("Round down", 0)
		d:AddChoice("Round off", 1)
		d:AddChoice("Round up", 2)

		d = f:CheckBox("Allow kill sounds", "ttt_dingaling_lasthit_allowed")
		d:SetTooltip(GetConVar("ttt_dingaling_lasthit_allowed"):GetHelpText())

		dsettings:AddItem(f)
	end

	dtabs:AddSheet("Combat text", dsettings, nil, false, false)
end)
