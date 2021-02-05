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
local dingaling_IGModAudioChannel = true

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

local updateuserinfo, updatefont
local dingaling_chan, dingaling_lasthit_chan
for k, v in pairs({
ttt_combattext = {
	1, "#ttt_combattext.dmgtext.enable_desc",
	function(name, old, new)
		combattext = tonumber(new) == 1

		if updateuserinfo then
			updateuserinfo()
		end
	end,
	FCVAR_ARCHIVE + FCVAR_USERINFO
},
ttt_combattext_batching_window = {
	0.3, "#ttt_combattext.dmgtext.batch_desc",
	function(name, old, new)
		combattext_batching_window = tonumber(new) or 0.3
	end
},
ttt_combattext_font = {
	"Arial", "#ttt_combattext.dmgtext.font_desc",
	function(name, old, new)
		combattext_font = new

		updatefont = true
	end
},
ttt_combattext_color = {
	"ffff00", "#ttt_combattext.dmgtext.color_desc",
	function(name, old, new)
		combattext_r, combattext_g, combattext_b, combattext_a = hex2rgb(new)
	end
},
ttt_combattext_scale = {
	1.0, "#ttt_combattext.dmgtext.scale_desc",
	function(name, old, new)
		combattext_scale = tonumber(new) or 1.0

		updatefont = true
	end
},
ttt_combattext_outline = {
	1, "#ttt_combattext.dmgtext.outline_desc",
	function(name, old, new)
		combattext_outline = tonumber(new) == 1

		updatefont = true
	end
},
ttt_combattext_antialias = {
	0, "#ttt_combattext.dmgtext.antialias_desc",
	function(name, old, new)
		combattext_antialias = tonumber(new) == 1

		updatefont = true
	end
},
ttt_dingaling = {
	0, "#ttt_combattext.hitsound.enable_desc",
	function(name, old, new)
		dingaling = tonumber(new) == 1

		if updateuserinfo then
			updateuserinfo()
		end
	end,
	FCVAR_ARCHIVE + FCVAR_USERINFO
},
ttt_dingaling_file = {
	"ttt_combattext/hitsound.ogg", "#ttt_combattext.hitsound.file_desc",
	function(name, old, new)
		dingaling_file =
			file.Exists("sound/" .. new, "GAME")
			and new
			or nil

		if dingaling_IGModAudioChannel
			and dingaling_file
			and dingaling_chan
		then
			dingaling_chan = nil
		end
	end
},
ttt_dingaling_volume = {
	0.75, "#ttt_combattext.hitsound.volume_desc",
	function(name, old, new)
		dingaling_volume = tonumber(new) or 0.75

		if dingaling_IGModAudioChannel
			and IsValid(dingaling_chan)
		then
			dingaling_chan:SetVolume(dingaling_volume)
		end
	end
},
ttt_dingaling_pitchmaxdmg = {
	50, "#ttt_combattext.hitsound.pitchmax_desc",
	function(name, old, new)
		dingaling_pitchmaxdmg = math.Clamp(tonumber(new) or 50, 0, 255)
	end
},
ttt_dingaling_pitchmindmg = {
	100, "#ttt_combattext.hitsound.pitchmin_desc",
	function(name, old, new)
		dingaling_pitchmindmg = math.Clamp(tonumber(new) or 100, 0, 255)
	end
},
ttt_dingaling_lasthit = {
	0, "#ttt_combattext.killsound.enable_desc",
	function(name, old, new)
		dingaling_lasthit = tonumber(new) == 1

		if updateuserinfo then
			updateuserinfo()
		end
	end,
	FCVAR_ARCHIVE + FCVAR_USERINFO
},
ttt_dingaling_lasthit_file = {
	"ttt_combattext/killsound.ogg", "#ttt_combattext.killsound.file_desc",
	function(name, old, new)
		dingaling_lasthit_file =
			file.Exists("sound/" .. new, "GAME")
			and new
			or nil

		if dingaling_IGModAudioChannel
			and dingaling_lasthit_file
			and dingaling_lasthit_chan
		then
			dingaling_lasthit_chan = nil
		end
	end
},
ttt_dingaling_lasthit_volume = {
	0.75, "#ttt_combattext.killsound.volume_desc",
	function(name, old, new)
		dingaling_lasthit_volume = tonumber(new) or 0.75

		if dingaling_IGModAudioChannel
			and IsValid(dingaling_lasthit_chan)
		then
			dingaling_lasthit_chan:SetVolume(dingaling_lasthit_volume)
		end
	end
},
ttt_dingaling_lasthit_pitchmaxdmg = {
	50, "#ttt_combattext.killsound.pitchmax_desc",
	function(name, old, new)
		dingaling_lasthit_pitchmaxdmg = math.Clamp(tonumber(new) or 50, 0, 255)
	end
},
ttt_dingaling_lasthit_pitchmindmg = {
	100, "#ttt_combattext.killsound.pitchmin_desc",
	function(name, old, new)
		dingaling_lasthit_pitchmindmg = math.Clamp(tonumber(new) or 100, 0, 255)
	end
},
ttt_dingaling_IGModAudioChannel = {
	0, "#ttt_combattext.hitsound.IGModAudioChannel",
	function(name, old, new)
		dingaling_IGModAudioChannel = tonumber(new) == 1
	end
},
}) do
	v[3](k, nil,
		CreateConVar(
			k, v[1], v[4] or FCVAR_ARCHIVE, language.GetPhrase(v[2])
		):GetString()
	)

	cvars.AddChangeCallback(k, v[3])
end
function updateuserinfo()
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

local function RemapValClamped(val, a, b, c, d)
	return c + (d - c) * math.min(math.max((val - a) / (b - a), 0), 1)
end

local function playhitsound(damage, lasthit, ent)
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

	if not file then
		return
	end

	if not dingaling_IGModAudioChannel then
		return (ent or Entity(0)):EmitSound(
			file, 0, pitch, volume, CHAN_STATIC
		)
	end

	pitch = pitch * 0.01

	local chan
	if lasthit then
		chan = dingaling_lasthit_chan
	else
		chan = dingaling_chan
	end

	if IsValid(chan) then
		chan:SetPlaybackRate(pitch)

		if chan:GetState() == GMOD_CHANNEL_PLAYING then
			return chan:SetTime(0)
		end

		return chan:Play()
	end

	return sound.PlayFile("sound/" .. file, "noplay noblock", function(chan)
		if not chan then
			return
		end

		chan:SetVolume(volume)
		chan:SetPlaybackRate(pitch)
		chan:Play()

		if lasthit then
			dingaling_lasthit_chan = chan
		else
			dingaling_chan = chan
		end
	end)
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
		playhitsound(damage, lasthit, attacker)
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
	f:SetName("#ttt_combattext.dmgtext.title")

	d = f:CheckBox("#ttt_combattext.dmgtext.enable", "ttt_combattext")
	d:SetTooltip("#ttt_combattext.dmgtext.enable_desc")

	d = f:NumSlider("#ttt_combattext.dmgtext.batch", "ttt_combattext_batching_window", 0, 2, 2)
	d.Label:SetWrap(true)
	d:SetTooltip("#ttt_combattext.dmgtext.batch_desc")

	d = f:TextEntry("#ttt_combattext.dmgtext.font", "ttt_combattext_font")
	d:SetTooltip("#ttt_combattext.dmgtext.font_desc")

	local dhex, dmix
	local r, g, b, a = combattext_r, combattext_g, combattext_b, combattext_a
	local col = Color(r, g, b, a)
	local lock

	dhex = f:TextEntry("#ttt_combattext.dmgtext.color", "ttt_combattext_color")
	dhex:SetTooltip("#ttt_combattext.dmgtext.color_desc")
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

		return dhex:ConVarChanged(rgb2hex(col.r, col.g, col.b, col.a)) -- inefficient
	end
	f:AddItem(dmix)

	d = f:NumSlider("#ttt_combattext.dmgtext.scale", "ttt_combattext_scale", 0, 3, 2)
	d.Label:SetWrap(true)
	d:SetTooltip("#ttt_combattext.dmgtext.scale_desc")

	d = f:CheckBox("#ttt_combattext.dmgtext.outline", "ttt_combattext_outline")
	d:SetTooltip("#ttt_combattext.dmgtext.outline_desc")

	d = f:CheckBox("#ttt_combattext.dmgtext.antialias", "ttt_combattext_antialias")
	d:SetTooltip("#ttt_combattext.dmgtext.antialias_desc")

	dsettings:AddItem(f)

	f = vgui.Create("DForm", dsettings)
	f:SetName("#ttt_combattext.hitsound.title")

	d = f:CheckBox("#ttt_combattext.hitsound.enable", "ttt_dingaling")
	d:SetTooltip("#ttt_combattext.hitsound.enable_desc")

	d = f:TextEntry("#ttt_combattext.hitsound.file", "ttt_dingaling_file")
	d:SetTooltip("#ttt_combattext.hitsound.file_desc")
	local exts = {
		wav = true,
		ogg = true,
		mp3 = true,
	}
	local maxresults = math.huge
	local cache, audchan
	local function GetAutoComplete(self, val)
		if audchan ~= dingaling_IGModAudioChannel then
			audchan = dingaling_IGModAudioChannel

			cache = cache and #cache == 0 and cache or {}
		elseif cache[val] then
			return cache[val]
		end

		local autocomp
		local autocomp_len = 0

		local sep = val:find("/", 1, true) and "/"
			or val:find("\\", 1, true) and "\\"
			or "/"--package.config[1]

		val = val:lower():gsub("[/\\]+", sep):gsub("^[/\\]", "")

		local sounded = "sound" .. sep .. val

		local files, dirs = file.Find(sounded, "GAME")

		local basename = val:match("[^/\\]+$") or ""

		local dupe
		if dirs and dirs[1] == basename then
			autocomp = {val .. sep}
			autocomp_len = 1

			dupe = basename
		elseif files and files[1] == basename
			and (audchan or exts[basename:match("%.([^%.]+)$") or ""])
		then
			autocomp = {val}
			autocomp_len = 1

			dupe = basename
		end

		files, dirs = file.Find(sounded .. "*", "GAME")

		local curdir = val:match("^.+[/\\]") or ""

		local basename_pattern = "^" .. basename:PatternSafe()

		if dirs then
			for i = 1, #dirs do
				if autocomp_len >= maxresults then
					break
				end

				local dirname = dirs[i]

				if dirname:find(basename_pattern)
					and dirname ~= dupe
				then
					autocomp_len = autocomp_len + 1

					autocomp = autocomp or {}

					autocomp[autocomp_len] = curdir .. dirname .. sep
				end
			end
		end

		if files then
			for i = 1, #files do
				if autocomp_len >= maxresults then
					break
				end

				local filename = files[i]

				if (audchan or exts[filename:match("%.([^%.]+)$") or ""])
					and filename ~= dupe
				then
					autocomp_len = autocomp_len + 1

					autocomp = autocomp or {}

					autocomp[autocomp_len] = curdir .. filename
				end
			end
		end

		cache[val] = autocomp

		return autocomp
	end
	d.GetAutoComplete = GetAutoComplete

	d = f:NumSlider("#ttt_combattext.hitsound.volume", "ttt_dingaling_volume", 0, 1, 2)
	d.Label:SetWrap(true)
	d:SetTooltip("#ttt_combattext.hitsound.volume_desc")

	d = f:NumSlider("#ttt_combattext.hitsound.pitchmax", "ttt_dingaling_pitchmaxdmg", 0, 200, 0)
	d.Label:SetWrap(true)
	d:SetTooltip("#ttt_combattext.hitsound.pitchmax_desc")

	d = f:NumSlider("#ttt_combattext.hitsound.pitchmin", "ttt_dingaling_pitchmindmg", 0, 200, 0)
	d.Label:SetWrap(true)
	d:SetTooltip("#ttt_combattext.hitsound.pitchmin_desc")

	d = f:CheckBox("#ttt_combattext.hitsound.IGModAudioChannel", "ttt_dingaling_IGModAudioChannel")
	d:SetTooltip("#ttt_combattext.hitsound.IGModAudioChannel_desc")

	d = f:Button("#ttt_combattext.hitsound.play")
	function d:OnDepressed()
		return playhitsound(math.random(0, 150), false)
	end

	dsettings:AddItem(f)

	f = vgui.Create("DForm", dsettings)
	f:SetName("#ttt_combattext.killsound.title")

	d = f:CheckBox("#ttt_combattext.killsound.enable", "ttt_dingaling_lasthit")
	d:SetTooltip("#ttt_combattext.killsound.enable_desc")

	d = f:TextEntry("#ttt_combattext.killsound.file", "ttt_dingaling_lasthit_file")
	d:SetTooltip("#ttt_combattext.killsound.file_desc")
	d.GetAutoComplete = GetAutoComplete

	d = f:NumSlider("#ttt_combattext.killsound.volume", "ttt_dingaling_lasthit_volume", 0, 1, 2)
	d.Label:SetWrap(true)
	d:SetTooltip("#ttt_combattext.killsound.volume_desc")

	d = f:NumSlider("#ttt_combattext.killsound.pitchmax", "ttt_dingaling_lasthit_pitchmaxdmg", 0, 200, 0)
	d.Label:SetWrap(true)
	d:SetTooltip("#ttt_combattext.killsound.pitchmax_desc")

	d = f:NumSlider("#ttt_combattext.killsound.pitchmin", "ttt_dingaling_lasthit_pitchmindmg", 0, 200, 0)
	d.Label:SetWrap(true)
	d:SetTooltip("#ttt_combattext.killsound.pitchmin_desc")

	d = f:Button("#ttt_combattext.killsound.play")
	function d:OnDepressed()
		return playhitsound(math.random(0, 150), true)
	end

	dsettings:AddItem(f)

	if ConVarExists("ttt_combattext_bodyarmor") then -- listen server
		f = vgui.Create("DForm", dsettings)
		f:SetName("#ttt_combattext.server.title")

		d = f:ComboBox("#ttt_combattext.server.bodyarmor", "ttt_combattext_bodyarmor")
		d:SetTooltip("#ttt_combattext.server.bodyarmor_desc")
		d:SetSortItems(false)
		d:AddChoice("#ttt_combattext.server.bodyarmor_choice0", 0)
		d:AddChoice("#ttt_combattext.server.bodyarmor_choice1", 1)
		d:AddChoice("#ttt_combattext.server.bodyarmor_choice2", 2)

		d = f:ComboBox("#ttt_combattext.server.disguise", "ttt_combattext_disguise")
		d:SetTooltip("#ttt_combattext.server.bodyarmor_desc")
		d:SetSortItems(false)
		d:AddChoice("#ttt_combattext.server.disguise_choice0", 0)
		d:AddChoice("#ttt_combattext.server.disguise_choice1", 1)
		d:AddChoice("#ttt_combattext.server.disguise_choice2", 2)

		d = f:CheckBox("#ttt_combattext.server.lineofsight", "ttt_combattext_lineofsight")
		d:SetTooltip("#ttt_combattext.server.lineofsight_desc")

		d = f:ComboBox("#ttt_combattext.server.rounding", "ttt_combattext_rounding")
		d:SetSortItems(false)
		d:AddChoice("#ttt_combattext.server.rounding_floor", 0)
		d:AddChoice("#ttt_combattext.server.rounding_nearest", 1)
		d:AddChoice("#ttt_combattext.server.rounding_ceiling", 2)

		d = f:CheckBox("#ttt_combattext.server.killsounds", "ttt_dingaling_lasthit_allowed")
		d:SetTooltip("#ttt_combattext.server.killsounds")

		dsettings:AddItem(f)
	end

	dtabs:AddSheet("#ttt_combattext.sheet.title", dsettings, nil, false, false)
end)
