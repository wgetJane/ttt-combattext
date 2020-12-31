## tf2-style damage numbers and hit sounds for ttt

i made this while listening to the undertale concert (it filled me with determination) and i finished it rgith when megalovania started playing (perfect timimg)

i only bothered making this because the only damage numbers mod i found on the gmod workshop is weird as hell, it's very overengineered and all its config options are serversided and it looks distracting as hell i dont wanna use that

by default, this addon shows the damage you would've dealt without armour against armoured players, since it'd be stupid if you can just shoot people in the feet to check if theyre wearing armour

this addon has the option to hide damage numbers from disguised targets, but this is disabled by default because it doesnt bother me

client cvars are archived so you only need to change them once in the console and they'll persist in any server

the default damage number font is arial, yellow, with outlines, but clients can change change colour, size, etc to whatever they want and change the font to any font installed on their computer

hitsound is disabled by default, and the default hitsound is from quake but clients can change the sound file it plays to whatever

this is made for ttt but it should probably still work with other game modes but i don't give a shit if they don't

this was also just made for a private mostly-vanilla ttt server, so i cannot care less if it doesn't work with le epic overpowered ww2 silenced awp funny jihad random tester explosive harpoon jetpack station donator golden anime deagle freddy fazbear cumshot launcher ttt addons

#### client cvars
`ttt_combattext 1` Display damage numbers  
`ttt_combattext_batching_window 0.3` Maximum delay between damage events in order to batch numbers, set to 0 to disable  
`ttt_combattext_font "Arial"` Font face used for damage numbers  
`ttt_combattext_color "ffff00"` Color of damage numbers in hex format: RRGGBBAA  
`ttt_combattext_scale 1.0` Size of damage numbers  
`ttt_combattext_outline 1` Draw damage numbers with outlines  
`ttt_combattext_antialias 0` Draw damage numbers with smooth text  

`ttt_dingaling 0` Play a sound whenever you damage an enemy  
`ttt_dingaling_file "ttt_combattext/hitsound.ogg"` The sound file to play on hit  
`ttt_dingaling_volume 0.75` Desired volume of the hit sound  
`ttt_dingaling_pitchmaxdmg 50` Desired pitch of the hit sound when a maximum damage hit (150 damage) is done  
`ttt_dingaling_pitchmindmg 100` Desired pitch of the hit sound when a minimal damage hit (0 damage) is done  

`ttt_dingaling_lasthit 0` Play a sound whenever you kill an enemy  
`ttt_dingaling_lasthit_file "ttt_combattext/killsound.ogg"` The sound file to play on kill  
`ttt_dingaling_lasthit_volume 0.75` Desired volume of the last hit sound  
`ttt_dingaling_lasthit_pitchmaxdmg 50` Desired pitch of the last hit sound when a maximum damage hit (150 damage) is done  
`ttt_dingaling_lasthit_pitchmindmg 100` Desired pitch of the last hit sound when a minimal damage hit (0 damage) is done  

#### server cvars
`ttt_combattext_bodyarmor 1` TTT: Prevent damage text from revealing if the target is wearing body armor  
`ttt_combattext_disguise 0` TTT: Don't show damage text if target is disguised  
`ttt_combattext_lineofsight 1` Don't show damage text if the target cannot be seen  
`ttt_combattext_rounding 1` 0: round down, 1: round off, 2: round up  
