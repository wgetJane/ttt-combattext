CLGAMEMODESUBMENU.base = "base_gamemodesubmenu"
CLGAMEMODESUBMENU.icon = Material("vgui/ttt/target_icon")
CLGAMEMODESUBMENU.title = "ttt_combattext.title"
CLGAMEMODESUBMENU.priority = 92

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

function CLGAMEMODESUBMENU:Populate(parent)
	local dmgtext = vgui.CreateTTT2Form(parent, "ttt_combattext.dmgtext.title")

	dmgtext:MakeHelp({
		label = "ttt_combattext.dmgtext.enable_desc"
	})
	dmgtext:MakeCheckBox({
		label = "ttt_combattext.dmgtext.enable",
		convar = "ttt_combattext",
	})

	dmgtext:MakeHelp({
		label = "ttt_combattext.dmgtext.batch_desc"
	})
	dmgtext:MakeSlider({
		label = "ttt_combattext.dmgtext.batch",
		convar = "ttt_combattext_batching_window",
		min = 0,
		max = 2,
		decimal = 2,
	})

	dmgtext:MakeHelp({
		label = "ttt_combattext.dmgtext.font_desc"
	})
	dmgtext:MakeTextEntry({
		label = "ttt_combattext.dmgtext.font",
		convar = "ttt_combattext_font",
	})

	local init_color = {hex2rgb(GetConVar("ttt_combattext_color"):GetString())}
	dmgtext:MakeHelp({
		label = "ttt_combattext.dmgtext.color_desc"
	})
	dmgtext:MakeColorMixer({
		label = "ttt_combattext.dmgtext.color",
		showAlphaBar = true,
		initial = Color(init_color[1], init_color[2], init_color[3], init_color[4]),
		OnChange = function(_, color)
			local hex = rgb2hex(color.r, color.g, color.b, color.a)
			GetConVar("ttt_combattext_color"):SetString(hex)
		end,
	})

	dmgtext:MakeHelp({
		label = "ttt_combattext.dmgtext.scale_desc"
	})
	dmgtext:MakeSlider({
		label = "ttt_combattext.dmgtext.scale",
		convar = "ttt_combattext_scale",
		min = 0,
		max = 3,
		decimal = 2,
	})

	dmgtext:MakeHelp({
		label = "ttt_combattext.dmgtext.outline_desc"
	})
	dmgtext:MakeCheckBox({
		label = "ttt_combattext.dmgtext.outline",
		convar = "ttt_combattext_outline",
	})

	dmgtext:MakeHelp({
		label = "ttt_combattext.dmgtext.shadow_desc"
	})
	dmgtext:MakeCheckBox({
		label = "ttt_combattext.dmgtext.shadow",
		convar = "ttt_combattext_shadow",
	})

	dmgtext:MakeHelp({
		label = "ttt_combattext.dmgtext.antialias_desc"
	})
	dmgtext:MakeCheckBox({
		label = "ttt_combattext.dmgtext.antialias",
		convar = "ttt_combattext_antialias",
	})

	dmgtext:MakeHelp({
		label = "ttt_combattext.dmgtext.unreliable_desc"
	})
	dmgtext:MakeCheckBox({
		label = "ttt_combattext.dmgtext.unreliable",
		convar = "ttt_combattext_unreliable",
	})



	local hitsound = vgui.CreateTTT2Form(parent, "ttt_combattext.hitsound.title")

	hitsound:MakeHelp({
		label = "ttt_combattext.hitsound.enable_desc"
	})
	hitsound:MakeCheckBox({
		label = "ttt_combattext.hitsound.enable",
		convar = "ttt_dingaling",
	})

	hitsound:MakeHelp({
		label = "ttt_combattext.hitsound.file_desc"
	})
	hitsound:MakeTextEntry({
		label = "ttt_combattext.hitsound.file",
		convar = "ttt_dingaling_file",
	})

	hitsound:MakeHelp({
		label = "ttt_combattext.hitsound.volume_desc"
	})
	hitsound:MakeSlider({
		label = "ttt_combattext.hitsound.volume",
		convar = "ttt_dingaling_volume",
		min = 0,
		max = 1,
		decimal = 2,
	})

	hitsound:MakeHelp({
		label = "ttt_combattext.hitsound.pitchmax_desc"
	})
	hitsound:MakeSlider({
		label = "ttt_combattext.hitsound.pitchmax",
		convar = "ttt_dingaling_pitchmaxdmg",
		min = 0,
		max = 200,
		decimal = 0,
	})

	hitsound:MakeHelp({
		label = "ttt_combattext.hitsound.IGModAudioChannel_desc"
	})
	hitsound:MakeCheckBox({
		label = "ttt_combattext.hitsound.IGModAudioChannel",
		convar = "ttt_dingaling_IGModAudioChannel",
	})

	-- local plySound = vgui.Create("DButtonTTT2", hitsound)

	-- plySound:SetText("ttt_combattext.hitsound.play")
	-- plySound:SetSize(100, 45)
	-- plySound:SetPos(20, 20)
	-- plySound.DoClick = function()
	-- 	entspawnscript.ResetMapToDefault()

	-- 	cvars.ChangeServerConVar("ttt_use_weapon_spawn_scripts", "1")
	-- end



	local killsound = vgui.CreateTTT2Form(parent, "ttt_combattext.killsound.title")

	killsound:MakeHelp({
		label = "ttt_combattext.killsound.enable_desc"
	})
	killsound:MakeCheckBox({
		label = "ttt_combattext.killsound.enable",
		convar = "ttt_dingaling_lasthit",
	})


	killsound:MakeHelp({
		label = "ttt_combattext.killsound.file_desc"
	})
	killsound:MakeTextEntry({
		label = "ttt_combattext.killsound.file",
		convar = "ttt_dingaling_lasthit_file",
	})

	killsound:MakeHelp({
		label = "ttt_combattext.killsound.volume_desc"
	})
	killsound:MakeSlider({
		label = "ttt_combattext.killsound.volume",
		convar = "ttt_dingaling_lasthit_volume",
		min = 0,
		max = 1,
		decimal = 2,
	})

	killsound:MakeHelp({
		label = "ttt_combattext.killsound.pitchmax_desc"
	})
	killsound:MakeSlider({
		label = "ttt_combattext.killsound.pitchmax",
		convar = "ttt_dingaling_lasthit_pitchmaxdmg",
		min = 0,
		max = 200,
		decimal = 0,
	})
end
