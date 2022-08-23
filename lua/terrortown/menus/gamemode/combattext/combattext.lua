CLGAMEMODESUBMENU.base = "base_gamemodesubmenu"

function CLGAMEMODESUBMENU:Populate()
	if HELPSCRN and HELPSCRN.IsVisible and HELPSCRN:IsVisible() and HELPSCRN.menuFrame and HELPSCRN.menuFrame.CloseFrame then
		HELPSCRN.menuFrame:CloseFrame()
	end

	RunConsoleCommand("combattext_settings")
end
