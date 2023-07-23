----------------------------------------------------------------------
-- Thanks for supporting AngelicXS Scripts!							--
-- Support can be found at: https://discord.gg/tQYmqm4xNb			--
-- More paid scripts at: https://angelicxs.tebex.io/ 				--
-- More FREE scripts at: https://github.com/GouveiaXS/ 				--
----------------------------------------------------------------------
-- Model info: https://docs.fivem.net/docs/game-references/ped-models/
-- Blip info: https://docs.fivem.net/docs/game-references/blips/

Config = {}

Config.UseESX = false						-- Use ESX Framework
Config.UseQBCore = true						-- Use QBCore Framework (Ignored if Config.UseESX = true)

Config.NHInput = false						-- Use NH-Input [https://github.com/nerohiro/nh-keyboard]
Config.NHMenu = false						-- Use NH-Menu [https://github.com/nerohiro/nh-context]
Config.QBInput = true						-- Use QB-Input (Ignored if Config.NHInput = true) [https://github.com/qbcore-framework/qb-input]
Config.QBMenu = true						-- Use QB-Menu (Ignored if Config.NHMenu = true) [https://github.com/qbcore-framework/qb-menu]
Config.OXLib = false						-- Use the OX_lib (Ignored if Config.NHInput or Config.QBInput = true) [https://github.com/overextended/ox_lib]  !! must add shared_script '@ox_lib/init.lua' and lua54 'yes' to fxmanifest!!

Config.UseCustomNotify = false				-- Use a custom notification script, must complete event below.
-- Only complete this event if Config.UseCustomNotify is true; mythic_notification provided as an example
RegisterNetEvent('angelicxs-gangTerritory:CustomNotify')
AddEventHandler('angelicxs-gangTerritory:CustomNotify', function(message, type)
    --exports.mythic_notify:SendAlert(type, message, 4000)
end)

-- Visual Preference
Config.Use3DText = true 					-- Use 3D text for interactions; only turn to false if Config.UseThirdEye is turned on and IS working.
Config.UseThirdEye = true 					-- Enables using a third eye (third eye requires the following arguments debugPoly, useZ, options {event, icon, label}, distance)
Config.ThirdEyeName = 'qb-target' 			-- Name of third eye aplication

-- Configuration
Config.UseAddOnGang = true					-- If true must add database table angelicxs_gangterritorylist, allows players to make own gangs.
Config.CostToJoin = 10000					-- If Config.UseAddOnGang = true, cost to join a gang
Config.CostToLeave = 10000					-- If Config.UseAddOnGang = true, cost to willing leave a gang
Config.NotifyEnteringTerritory = true		-- If true, notifies a player when they enter any gang territory
Config.GangManager = {
    Coords = vector4(282.92, 322.37, 105.64, 271.15),	-- Coords where the gang manager ped will spawn
    Model = 'g_m_m_casrn_01'							-- Model of the gang manager ped
}
Config.TerritoryItemName = 'territorymarker'			-- Item name to be used to create gang territory marker
Config.TerritoryPurchaseCost = 100000					-- Initial cost/value of the territory marker purchase 
Config.TerritorySize = 100								-- Default territory size
Config.TerritoryMarker = 'ex_prop_crate_money_bc'		-- Object spawned when using territory marker
Config.TerritoryRangeOnMap = true						-- If true will put a range of the territory on the map (colours randomized)

Config.IncreaseTerritoryOnServerRestart = true			-- If true, territories will slowly gain size every server restart
Config.TerritoryIncrease = 100							-- If Config.IncreaseTerritoryOnServerRestart = true size territory increases by

-- Buff Configuration
Config.TimeBetweenRegen = 1 							-- Time in seconds between buff activations
Config.Health = {
	enabled = true,										-- If true, enables the buff
	gain = 10,											-- How much will be gained every activation
	max = 200,											-- What is the maximum value the buff will get the player to
}
Config.Armour = {
	enabled = true,										-- If true, enables the buff
	gain = 5,											-- How much will be gained every activation
	max = 50,											-- What is the maximum value the buff will get the player to
}
Config.Stamina = {
	enabled = true,										-- If true, enables the buff
	gain = 50,											-- How much will be gained every activation
	max = 100,											-- What is the maximum value the buff will get the player to
}

-- Language Configuration
Config.LangType = {
	['error'] = 'error',
	['success'] = 'success',
	['info'] = 'primary'
}

Config.Lang = {
	['ganglist_header'] = 'Gangs with territory in the city:',
	['set_up_new_gang_header'] = 'Gang Information:',
	['set_up_gang_name'] = 'Gang Name',
	['increase_value_header'] = 'Value Increase:',
	['gang_exists'] = 'There is already a gang with that name in the city.',
	['set_up_gang_submit'] = 'Submit',
	['new_gang_intro'] = 'So you want to make a new gang huh? Give me the info.',
	['gang_list'] = 'These folks got a presence in the city.',
	['LookUpCurrentGangs'] = 'Look up who is in the city.',
	['MakeNewGang'] = 'Make a new gang.',
	['low_money'] = 'Listen you need cold hard cash to make a new gang. It will cost you $',
	['low_money_join'] = 'Listen you need cold hard cash to join a new gang. It will cost you $',
	['low_money_leave'] = 'Listen you need cold hard cash to leave a gang. It will cost you $',
	['low_money_increase'] = 'Listen you need cold hard cash to make increase the value.',
	['gang_made'] = 'I will spread the word about the new gang in town, the ',
	['place_item'] = 'Make sure to place this down at your gang\'s spot. It marks the center of your territory and needs to be defended. You can also spend cash to make it difficult to remove.',
	['used'] = 'You have placed the territory marker!',
	['one_gang_only'] = 'You can only be the boss of one gang!',
	['enemy_territory'] = ' You have entered a gang territory!',
	['friendly_territory'] = ' You have entered your gang territory!',
	['3d_gang_interact'] = "Press ~r~E~w~ to increase gang territory value \nPress ~r~G~w~ to pay and destory gang territory",
	['3d_gangboss_interact'] = "Press ~r~E~w~ to lookup current gangs in the city \nPress ~r~G~w~ to make a new gang",
	['3d_gang_interact_e'] = "You are not part of the gang and can not increase the value!",
	['3d_gang_interact_g'] = "You are part of the gang you can not destroy the territory!",
	['3eye_increase'] = "Increase Territory Value",
	['3eye_buyout'] = "Destroy Territory",
	['zero_error'] = 'You must set input a value larger than 0!', 
	['value_increased'] = 'You increased the value of your gang territory!', 
	['low_money_buyout'] = 'You need cold hard cash to buy out a territory! This place is worth $',
	['terri_buyout'] = 'You bought out this territory!', 
	['one_gang_only_member'] = 'You can only be part of one gang at a time!',
	['join_gang'] = 'You have joined the following gang: ',
	['not_in_gang'] = 'You are not in a gang!',
	['not_in_this_gang'] = 'You are not in this gang!',
	['leave_gang'] = 'You have left the gang!',
	['not_boss'] = 'Only the boss of the gang can do this!',
	['member_removed'] = 'You have removed the member from the gang!',
	['join'] = 'Join Gang',
	['leave'] = 'Leave Gang',
	['manage'] = 'Manage Gang',
	['not_gang_manage'] = 'You cannot see the members of a rival gang!',
	['not_boss_manage'] = 'Only the boss can manage his gang!',
	['remove_menu_header'] = 'Select a name to kick them from the gang.',

	





	
}