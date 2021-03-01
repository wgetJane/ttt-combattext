local combattext = true
local combattext_batching_window = 0.25
local combattext_font = "Verdana"
local combattext_r, combattext_g, combattext_b, combattext_a = 255, 255, 0, 255
local combattext_scale = 1
local combattext_outline = true
local combattext_shadow = false
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
	return (
		a < 255 and "%02x%02x%02x%02x"
		or "%02x%02x%02x"
	):format(r, g, b, a)
end

local updateuserinfo, updatefont
local dingaling_chan, dingaling_lasthit_chan
local tkpfx, cvpfx
for _, v in ipairs({
{
	"combattext", 1,
	function(_,_, new)
		combattext = tonumber(new) == 1

		if updateuserinfo then
			updateuserinfo()
		end
	end,
	"dmgtext", true
},
{
	"batching_window", 0.25,
	function(_,_, new)
		combattext_batching_window = tonumber(new) or 0.25
	end,
	"batch_desc"
},
{
	"font", combattext_font,
	function(_,_, new)
		combattext_font = new

		updatefont = true
	end
},
{
	"color", "ffff00",
	function(_,_, new)
		combattext_r, combattext_g, combattext_b, combattext_a = hex2rgb(new)
	end
},
{
	"scale", 1,
	function(_,_, new)
		combattext_scale = tonumber(new) or 1

		updatefont = true
	end
},
{
	"outline", 1,
	function(_,_, new)
		combattext_outline = tonumber(new) == 1

		updatefont = true
	end
},
{
	"shadow", 0,
	function(_,_, new)
		combattext_shadow = tonumber(new) == 1

		updatefont = true
	end
},
{
	"antialias", 0,
	function(_,_, new)
		combattext_antialias = tonumber(new) == 1

		updatefont = true
	end
},
{
	"dingaling", 0,
	function(_,_, new)
		dingaling = tonumber(new) == 1

		if updateuserinfo then
			updateuserinfo()
		end
	end,
	"hitsound", true
},
{
	"file", dingaling_file,
	function(_,_, new)
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
{
	"volume", 0.75,
	function(_,_, new)
		dingaling_volume = tonumber(new) or 0.75

		if dingaling_IGModAudioChannel
			and IsValid(dingaling_chan)
		then
			dingaling_chan:SetVolume(dingaling_volume)
		end
	end
},
{
	"pitchmaxdmg", 50,
	function(_,_, new)
		dingaling_pitchmaxdmg = math.Clamp(
			tonumber(new) or 50,
			0, 255
		)
	end,
	"pitchmax_desc"
},
{
	"pitchmindmg", 100,
	function(_,_, new)
		dingaling_pitchmindmg = math.Clamp(
			tonumber(new) or 100,
			0, 255
		)
	end,
	"pitchmin_desc"
},
{
	"IGModAudioChannel", 0,
	function(_,_, new)
		dingaling_IGModAudioChannel = tonumber(new) == 1
	end,
	"IGModAudioChannel"
},
{
	"dingaling_lasthit", 0,
	function(_,_, new)
		dingaling_lasthit = tonumber(new) == 1

		if updateuserinfo then
			updateuserinfo()
		end
	end,
	"killsound", true
},
{
	"file", dingaling_lasthit_file,
	function(_,_, new)
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
{
	"volume", 0.75,
	function(_,_, new)
		dingaling_lasthit_volume = tonumber(new) or 0.75

		if dingaling_IGModAudioChannel
			and IsValid(dingaling_lasthit_chan)
		then
			dingaling_lasthit_chan:SetVolume(dingaling_lasthit_volume)
		end
	end
},
{
	"pitchmaxdmg", 50,
	function(_,_, new)
		dingaling_lasthit_pitchmaxdmg = math.Clamp(
			tonumber(new) or 50,
			0, 255
		)
	end,
	"pitchmax_desc"
},
{
	"pitchmindmg", 100,
	function(_,_, new)
		dingaling_lasthit_pitchmindmg = math.Clamp(
			tonumber(new) or 100,
			0, 255
		)
	end,
	"pitchmin_desc"
},
}) do
	local fc = FCVAR_ARCHIVE

	local tk, cv

	if v[5] then
		fc = fc + FCVAR_USERINFO
		tkpfx, cv = "#ttt_combattext." .. v[4] .. ".", "ttt_" .. v[1]
		tk = tkpfx .. "enable"
		cvpfx = cv .. "_"
	else
		tk, cv = v[4], v[1]
		tk = tkpfx .. (tk or cv .. "_desc")
		cv = cvpfx .. cv
	end

	v[3](cv, "",
		CreateConVar(
			cv, v[2], fc, language.GetPhrase(tk)
		):GetString()
	)

	cvars.AddChangeCallback(cv, v[3])
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
		shadow = combattext_shadow,
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
		return (ent or game.GetWorld()):EmitSound(
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

local pool_size, pool = 0

local weakkeys, weakvals = {__mode = "k"}, {__mode = "v"}

local batchvics = setmetatable({}, weakkeys)

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

	local x, y, z = pos.x, pos.y, pos.z

	local _, vmax = victim:GetCollisionBounds()
	z = z + vmax.z + RemapValClamped(
			pos:DistToSqr(attacker:GetPos()),
			0, 256 * 256,
			0, 16
		)

	if updatefont then
		updatefontfn()
	end

	local batch = combattext_batching_window > 0

	local realtime = RealTime()

	local push

	local bvic = batch and batchvics[victim] or nil
	if bvic then
		push = bvic and bvic.num

		if push then
			if bvic == push.bvic
				and realtime - push.birth
					<= combattext_batching_window
			then
				damage = bvic.dmg + damage

				bvic.dmg = damage

				if push ~= tail then
					push.moveto = tail
				end

				bvic = true

				goto push
			end

			bvic.num = nil
		end
	end

	if pool then
		push = pool

		pool = push.nxtpool

		pool_size = pool_size - 1
	else
		push = {0, 0, 0}
	end

	::push::

	push.birth = realtime
	push[1], push[2], push[3] = x, y, z
	push.str = "-" .. damage
	push.hs = net.ReadBool()

	if bvic == true then
		return
	end

	if batch then
		if not bvic then
			bvic = setmetatable({}, weakvals)
			batchvics[victim] = bvic
		end

		bvic.dmg = damage
		bvic.num = push

		push.bvic = bvic
	end

	if tail then
		tail.nxt = push
	else
		head = push
	end

	tail = push
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

	local num, prev = head

	::loop::

	local lifetime = realtime - num.birth

	local nxt = num.nxt

	if num.moveto then
		local dest = num.moveto
		num.moveto = nil

		num.nxt = dest.nxt
		dest.nxt = num

		if dest == tail then
			tail = num
		end

		num = prev

		if prev then
			prev.nxt = nxt
		else
			head = nxt
		end
	elseif lifetime > max_lifetime then
		local bvic = num.bvic
		if bvic then
			num.bvic = nil
			num.moveto = nil

			if num == bvic.num then
				bvic.num = nil
			end
		end

		if pool_size < 8 then
			num.nxtpool = pool

			pool = num

			pool_size = pool_size + 1
		else
			num.nxtpool = nil
		end

		head = nxt

		if nxt then
			num.nxt = nil
		else
			tail = nil

			return
		end
	else
		local lifeperc = lifetime / max_lifetime

		vec[1], vec[2], vec[3] =
			num[1], num[2], num[3] + lifeperc * float_height

		local pos = vec:ToScreen()

		if pos.visible then
			if num.hs ~= headshot then
				headshot = num.hs

				SetFont(headshot
					and "ttt_combattext_font_headshot"
					or "ttt_combattext_font")
			end

			SetTextPos(pos.x, pos.y)

			SetTextColor(r, g, b,
				lifeperc > 0.5 and a * (2 - 2 * lifeperc) or a)

			DrawText(num.str)
		end
	end

	prev, num = num, nxt

	if num then
		goto loop
	end
end)

local function createsettingstab(panel, onaddform)
	local f, tkpfx, cvpfx

	local function le(tk)
		return "#ttt_combattext." .. tkpfx .. "." .. tk
	end

	local function add(fn, tk, cv, ...)
		cv = cv or tk
		tk = le(tk)

		local d, lbl = f[fn](
				f, tk,
				"ttt_" .. cvpfx .. (cv == "" and "" or "_") .. cv,
				...
			)

		d:SetTooltip(tk .. "_desc")

		lbl = lbl or d.Label

		if fn == "CheckBox" then -- hackily fix wrapping
			local w, h = d:GetSize()
			local lw, lh = lbl:GetSize()
			local wdiff, hdiff = w - lw + 1, h - lh

			d:SetHeight(255)

			function d:PerformLayout(w)
				self.PerformLayout = nil

				local lbl = self.Label

				lbl:SetWidth(w - wdiff)

				function lbl.OnSizeChanged(_,_, h)
					self:SetHeight(h + hdiff)
				end

				lbl:SetAutoStretchVertical(true)
				lbl:SetWrap(true)

				function self:OnSizeChanged(w)
					self.Label:SetWidth(w - wdiff)
				end
			end
		elseif lbl then
			lbl:SetWrap(true)
		end

		return d, lbl
	end

	tkpfx, cvpfx = "dmgtext", "combattext"

	f = vgui.Create("DForm", panel)
	f:SetName(le("title"))

	add("CheckBox", "enable", "")

	add("NumSlider", "batch", "batching_window", 0, 2, 2)

	add("TextEntry", "font")

	local dhex, dhex_lbl, dmix
	local r, g, b, a = combattext_r, combattext_g, combattext_b, combattext_a
	local col = Color(r, g, b, a)
	local lock

	dhex, dhex_lbl = add("TextEntry", "color")
	dhex:SetValue(rgb2hex(r, g, b, a))
	dhex:SetUpdateOnType(true)
	function dhex:AllowInput(char)
		return char:find("%X") and true or false
	end
	function dhex:OnValueChange(val)
		col.r, col.g, col.b, col.a = hex2rgb(val)

		lock = true
		dmix:SetColor(col)
	end

	dmix = vgui.Create("DColorMixer")
	dmix:SetColor(col)
	dmix:SetHeight(92)
	function dmix:OnSizeChanged(w)
		dmix:DockMargin(w < 215 and 0 or dhex_lbl:GetWide(), 0, 0, 0)
	end
	dmix:SetAlphaBar(true)
	dmix:SetPalette(false)
	dmix:SetWangs(true)
	function dmix:ValueChanged(col)
		if lock then
			lock = false
			return
		end

		return dhex:ConVarChanged( -- inefficient
			rgb2hex(col.r, col.g, col.b, col.a)
		)
	end
	f:AddItem(dmix)

	add("NumSlider", "scale", nil, 0, 3, 2)

	add("CheckBox", "outline")

	add("CheckBox", "shadow")

	add("CheckBox", "antialias")

	panel:AddItem(f)
	if onaddform then
		onaddform(f)
	end

	local exts = {
		wav = true,
		ogg = true,
		mp3 = true,
	}
	local cache, audchan
	local function GetAutoComplete(self, val)
		if audchan ~= dingaling_IGModAudioChannel then
			audchan = dingaling_IGModAudioChannel
			cache = {}
		end

		if cache[val] then
			return cache[val]
		end

		local tbl
		local len = 0

		local sep = val:find("/", 1, true) and "/"
			or val:find("\\", 1, true) and "\\"
			or "/"--package.config[1]

		val = val:lower():gsub("[/\\]+", sep):gsub("^[/\\]", "")

		local sounded = "sound" .. sep .. val

		local files, dirs = file.Find(sounded, "GAME")

		local base = val:match("[^/\\]+$") or ""

		local dupe
		if dirs and dirs[1] == base then
			tbl = {val .. sep}
			len = 1

			dupe = base
		elseif files and files[1] == base
			and (audchan or exts[base:match("%.([^%.]+)$") or ""])
		then
			tbl = {val}
			len = 1

			dupe = base
		end

		files, dirs = file.Find(sounded .. "*", "GAME")

		local curdir = val:match("^.+[/\\]") or ""

		local pat = "^" .. base:PatternSafe()

		if dirs then
			for i = 1, #dirs do
				local dir = dirs[i]

				if dir:find(pat)
					and dir ~= dupe
				then
					len = len + 1

					tbl = tbl or {}

					tbl[len] = curdir .. dir .. sep
				end
			end
		end

		if files then
			for i = 1, #files do
				local file = files[i]

				if (audchan or exts[file:match("%.([^%.]+)$") or ""])
					and file ~= dupe
				then
					len = len + 1

					tbl = tbl or {}

					tbl[len] = curdir .. file
				end
			end
		end

		cache[val] = tbl

		return tbl
	end

	tkpfx, cvpfx = "hitsound", "dingaling"

	local lh
	::lasthit::

	f = vgui.Create("DForm", panel)
	f:SetName(le("title"))

	add("CheckBox", "enable", "")

	local dfile = add("TextEntry", "file")
	dfile.GetAutoComplete = GetAutoComplete

	add("NumSlider", "volume", nil, 0, 1, 2)

	add("NumSlider", "pitchmax", "pitchmaxdmg", 0, 200, 0)

	add("NumSlider", "pitchmin", "pitchmindmg", 0, 200, 0)

	if not lh then
		add("CheckBox", "IGModAudioChannel")
	end

	local kill = lh
	f:Button(le("play")).OnDepressed = function()
		return playhitsound(math.random(0, 150), kill)
	end

	panel:AddItem(f)
	if onaddform then
		onaddform(f)
	end

	if not lh then
		lh = true
		tkpfx, cvpfx = "killsound", "dingaling_lasthit"
		goto lasthit
	end

	if not ConVarExists("ttt_combattext_bodyarmor") then
		return
	end
	-- listen server

	tkpfx, cvpfx = "server", "combattext"

	f = vgui.Create("DForm", panel)
	f:SetName(le("title"))

	local d = add("ComboBox", "bodyarmor")
	d:SetSortItems(false)
	for i = 0, 2 do
		d:AddChoice(le("bodyarmor_choice" .. i), i)
	end

	d = add("ComboBox", "disguise")
	d:SetSortItems(false)
	for i = 0, 2 do
		d:AddChoice(le("disguise_choice" .. i), i)
	end

	add("CheckBox", "lineofsight")

	d = add("ComboBox", "rounding")
	d:SetSortItems(false)
	d:AddChoice(le("rounding_floor"), 0)
	d:AddChoice(le("rounding_nearest"), 1)
	d:AddChoice(le("rounding_ceiling"), 2)

	cvpfx = "dingaling"

	add("CheckBox", "killsounds", "lasthit_allowed")

	panel:AddItem(f)
	if onaddform then
		onaddform(f)
	end
end

hook.Add("TTTSettingsTabs", "ttt_combattext_TTTSettingsTabs", function(dtabs)
	local dsettings = vgui.Create("DPanelList", dtabs)
	dsettings:StretchToParent(0, 0, dtabs:GetPadding() * 2, 0)
	dsettings:EnableVerticalScrollbar(true)
	dsettings:SetPadding(10)
	dsettings:SetSpacing(10)

	createsettingstab(dsettings)

	dtabs:AddSheet("#ttt_combattext.title", dsettings, nil, false, false)
end)

hook.Add("AddToolMenuCategories", "ttt_combattext_AddToolMenuCategories", function()
	spawnmenu.AddToolCategory(
		"Options",
		"ttt_combattext",
		"#ttt_combattext.title"
	)
end)

hook.Add("PopulateToolMenu", "ttt_combattext_PopulateToolMenu", function()
	spawnmenu.AddToolMenuOption(
		"Options",
		"ttt_combattext",
		"ttt_combattext",
		"#ttt_combattext.spawnmenu",
		"", "",
		function(panel)
			panel:SetHeaderHeight(0)

			createsettingstab(panel, function(f)
				f:GetParent():DockPadding(0, 0, 0, 10)
			end)
		end
	)
end)

concommand.Add("combattext_settings", function()
	local dframe = vgui.Create("DFrame")
	dframe:SetTitle("#ttt_combattext.spawnmenu")
	dframe:SetDraggable(true)
	dframe:SetDeleteOnClose(true)
	dframe:ShowCloseButton(true)
	dframe:SetSizable(true)
	dframe:SetSize(640, 480)
	dframe:SetMinWidth(227)
	dframe:SetMinHeight(150)
	dframe:Center()
	dframe:MakePopup()

	local dpanel = vgui.Create("DPanel", dframe)
	dpanel:Dock(FILL)

	local dsettings = vgui.Create("DScrollPanel", dpanel)
	dsettings:Dock(FILL)
	dsettings:GetCanvas():DockPadding(8, 0, 8, 16)

	createsettingstab(dsettings, function(f)
		f:DockMargin(0, 8, 0, 8)
		f:Dock(TOP)
	end)
end)
