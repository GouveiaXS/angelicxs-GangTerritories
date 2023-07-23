ESX = nil
QBcore = nil

PlayerData = nil
IntGangs = {}
GangLocations = nil
GangName = nil
inZone = false
boss = false

NPC = nil

CreateThread(function()
    if Config.UseESX then
        ESX = exports["es_extended"]:getSharedObject()

        while not ESX.IsPlayerLoaded() do
            Wait(100)
        end

        PlayerData = ESX.GetPlayerData()
        CreateThread(function()
            while true do
                if PlayerData ~= nil then
                    GangName = PlayerData.job.name
                    GangCheck()
                    break
                end
                Wait(100)
            end
        end)

        RegisterNetEvent('esx:setJob', function(job)
            GangName = job.name
            GangCheck()
        end)

        ESX.TriggerServerCallback('angelicxs-gangTerritory:GangGrab:ESX', function(cb)
            GangLocations = cb
        end)

    elseif Config.UseQBCore then
        QBCore = exports['qb-core']:GetCoreObject()

        CreateThread(function ()
			while true do
                PlayerData = QBCore.Functions.GetPlayerData()
				if PlayerData.citizenid ~= nil then
                    GangName = PlayerData.job.name
                    if PlayerData.gang.name ~= 'none' then
                        GangName = PlayerData.gang.name
                    end
                    GangCheck()
					break
				end
				Wait(100)
			end
		end)

        RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
            PlayerData = QBCore.Functions.GetPlayerData()
            GangName = PlayerData.job.name
            if PlayerData.gang.name ~= 'none' then
                GangName = PlayerData.gang.name
            end
            GangCheck()
        end)

        QBCore.Functions.TriggerCallback('angelicxs-gangTerritory:GangGrab:QBCore', function(cb)
            GangLocations = cb
        end)
    end
    while not GangLocations do Wait(1000) end
    for k, v in pairs (GangLocations) do
        local data = v
        if Config.TerritoryRangeOnMap then
            SetBlip(data)
        end
        TerritorySetUp(data)
    end
    CreateThread(function()
        while true do
            local sleep = (Config.TimeBetweenRegen*1000)
            if not inZone then
                sleep = 5000
            else
                local Player = PlayerPedId()
                if Config.Health.enabled then
                    local value = GetEntityHealth(Player)
                    if value - Config.Health.gain < Config.Health.max then
                        SetEntityHealth(Player, value + Config.Health.gain)
                    end
                    
                end
                if Config.Armour.enabled then
                    local value = GetPedArmour(Player)
                    if value - Config.Armour.gain < Config.Armour.max then
                        SetPedArmour(Player, value + Config.Armour.gain)
                    end
                end
                if Config.Stamina.enabled then
                    local PiD = PlayerId()
                    local value = GetPlayerStamina(PiD)
                    if value - Config.Stamina.gain < Config.Stamina.max then
                        SetPlayerStamina(PiD, value + Config.Stamina.gain)
                    end
                end
    
            end
            Wait(sleep)
        end
    end)
end)


RegisterNetEvent('angelicxs-gangTerritory:Notify', function(message, type)
	if Config.UseCustomNotify then
        TriggerEvent('angelicxs-gangTerritory:CustomNotify',message, type)
	elseif Config.UseESX then
		ESX.ShowNotification(message)
	elseif Config.UseQBCore then
		QBCore.Functions.Notify(message, type)
	end
end)

CreateThread(function()
    local PedSpawned = false
    while true do
        local Pos = GetEntityCoords(PlayerPedId())
        local NPCPos = vector3(Config.GangManager.Coords.x, Config.GangManager.Coords.y, Config.GangManager.Coords.z)
        local Dist = #(Pos - NPCPos)
        if Dist <= 50 and not PedSpawned then
            TriggerEvent('angelicxs-gangTerritory:SpawnGangManager')
            PedSpawned = true
        elseif DoesEntityExist(NPC) and PedSpawned then
            local Dist2 = #(Pos - GetEntityCoords(NPC))
            if Dist2 > 50 then
                DeleteEntity(NPC)
                PedSpawned = false
            end
        end
        Wait(2000)
    end
end)

RegisterNetEvent('angelicxs-gangTerritory:SpawnGangManager',function()
    local data = Config.GangManager
    local hash = HashGrabber(data.Model)
    NPC = CreatePed(3, hash, data.Coords[1], data.Coords[2], (data.Coords[3]-1), data.Coords[4], false, false)
    SetEntityHeading(NPC, data.Coords[4])
    FreezeEntityPosition(NPC, true)
    SetEntityInvincible(NPC, true)
    SetBlockingOfNonTemporaryEvents(NPC, true)
    TaskStartScenarioInPlace(NPC, 'WORLD_HUMAN_AA_SMOKE', 0, false)
    SetModelAsNoLongerNeeded(data.Model)
    if Config.UseThirdEye then
        exports[Config.ThirdEyeName]:AddEntityZone('GangManager', NPC, {
            name="GangManager",
            debugPoly=false,
            useZ = true
                }, {
                options = {
                    {
                        event = 'angelicxs-gangTerritory:LookUpCurrentGangs', 
                        icon = 'fas fa-magnifying-glass', 
                        label = Config.Lang['LookUpCurrentGangs'],
                    },   
                    {
                        event = 'angelicxs-gangTerritory:MakeNewGang', 
                        icon = 'fas fa-clipboard', 
                        label = Config.Lang['MakeNewGang'],
                    },   
                },
            distance = 3
        })  
    end
    if Config.Use3DText then
        while true do
            local Sleep = 2000
            local Player = PlayerPedId()
            local Pos = GetEntityCoords(PlayerPedId())
            local Dist = #(Pos - vector3(data.Coords[1], data.Coords[2], data.Coords[3]))
            if Dist <= 20 then
                Sleep = 500
                if Dist <= 3 then
                    Sleep = 0
                    DrawText3Ds(data.Coords[1], data.Coords[2], data.Coords[3], Config.Lang['3d_gangboss_interact'])
                    if IsControlJustReleased(0, 38) then
                        TriggerEvent('angelicxs-gangTerritory:LookUpCurrentGangs')
                    elseif IsControlJustReleased(0,47) then
                        TriggerServerEvent('angelicxs-gangTerritory:MakeNewGang')
                    end
                end
            end
            if not DoesEntityExist(NPC) then
                break
            end
            Wait(Sleep)
        end
    end
end)

RegisterNetEvent('angelicxs-gangTerritory:LookUpCurrentGangs',function()
    GangCheck()
    TriggerEvent('angelicxs-gangTerritory:Notify', Config.Lang['gang_list'], Config.LangType['info'])
    Wait(500)
    local GangList = {}
    if Config.NHMenu then
        table.insert(GangList, {
            header = Config.Lang['ganglist_header'], 
        })
    elseif Config.QBMenu then
        table.insert(GangList, {
            header = Config.Lang['ganglist_header'], 
            isMenuHeader = true
        })
    end
    for Gang, Details in pairs(IntGangs) do
        if Config.NHMenu then
            table.insert(GangList, {
                header = tostring(Details.gang), 
                event = 'angelicxs-gangTerritory:GangOptions',
                args = Details.gang
            })
        elseif Config.QBMenu then
            table.insert(GangList, {
                header = tostring(Details.gang),
                params = {
                    event = 'angelicxs-gangTerritory:GangOptions',
                    args = Details.gang
                }
            })
        elseif Config.OXLib then
            table.insert(GangList, {
                label = tostring(Details.gang),
                args = { gang = Details.gang}
            })
        end
    end
    if Config.NHMenu then
        TriggerEvent("nh-context:createMenu", GangList)
    elseif Config.QBMenu then
        TriggerEvent("qb-menu:client:openMenu", GangList)
    elseif Config.OXLib then
        lib.registerMenu({
            id = 'GangList_ox',
            title = Config.Lang['ganglist_header'],
            options = GangList,
            position = 'top-right',
        }, function(selected, scrollIndex, args)
            TriggerEvent('angelicxs-gangTerritory:GangOptions', args.gang)
        end)
        lib.showMenu('GangList_ox')
    end
end)

RegisterNetEvent('angelicxs-gangTerritory:GangOptions',function(gang)
    if not Config.UseAddOnGang then return end
    local GangList = {}
    if Config.NHMenu then
        table.insert(GangList, {
            header = tostring(gang), 
        })
        table.insert(GangList, {
            header = Config.Lang['join'], 
            event = 'angelicxs-gangTerritory:JoinGang',
            args = gang
        })
        table.insert(GangList, {
            header = Config.Lang['leave'], 
            event = 'angelicxs-gangTerritory:LeaveGang',
            args = gang
        })
        table.insert(GangList, {
            header = Config.Lang['manage'], 
            event = 'angelicxs-gangTerritory:ManageGang',
            args = gang
        })
    elseif Config.QBMenu then
        table.insert(GangList, {
            header = tostring(gang), 
            isMenuHeader = true
        })
        table.insert(GangList, {
            header = Config.Lang['join'], 
            params = {
                event = 'angelicxs-gangTerritory:JoinGang',
                args = gang
            }
        })
        table.insert(GangList, {
            header = Config.Lang['leave'], 
            params = {
                event = 'angelicxs-gangTerritory:LeaveGang',
                args = gang
            }
        })
        table.insert(GangList, {
            header = Config.Lang['manage'], 
            params = {
                event = 'angelicxs-gangTerritory:ManageGang',
                args = gang
            }
        })
    elseif Config.OXLib then
        table.insert(GangList, {
            label = Config.Lang['join'],
            args = { gang = gang, join = true}
        })
        table.insert(GangList, {
            label = Config.Lang['leave'],
            args = { gang = gang}
        })
        table.insert(GangList, {
            label = Config.Lang['manage'],
            args = { gang = gang, manage = true}
        })
    end
    if Config.NHMenu then
        TriggerEvent("nh-context:createMenu", GangList)
    elseif Config.QBMenu then
        TriggerEvent("qb-menu:client:openMenu", GangList)
    elseif Config.OXLib then
        lib.registerMenu({
            id = 'GangListOption_ox',
            title = tostring(gang),
            options = GangList,
            position = 'top-right',
        }, function(selected, scrollIndex, args)
            if args.join then
                TriggerEvent('angelicxs-gangTerritory:JoinGang', args.gang)
            elseif args.manage then
                TriggerEvent('angelicxs-gangTerritory:ManageGang', args.gang)
            else
                TriggerEvent('angelicxs-gangTerritory:LeaveGang', args.gang)
            end
        end)
        lib.showMenu('GangListOption_ox')
    end
end)

RegisterNetEvent('angelicxs-gangTerritory:ManageGang',function(gang)
    if not Config.UseAddOnGang then return end
    if gang ~= GangName then TriggerEvent('angelicxs-gangTerritory:Notify', Config.Lang['not_gang_manage'], Config.LangType['error']) return end
    if not boss then TriggerEvent('angelicxs-gangTerritory:Notify', Config.Lang['not_boss_manage'], Config.LangType['info']) return end
    local GangList = nil
    local GangMenu = {}
    if Config.UseESX then
        ESX.TriggerServerCallback('angelicxs-gangTerritory:GetGangMembers:ESX', function(cb)
            GangList = cb
        end, gang)
    elseif Config.UseQBCore then
        QBCore.Functions.TriggerCallback('angelicxs-gangTerritory:GetGangMembers:QBCore', function(cb)
            GangList = cb
        end, gang)
    end
    while not GangList do Wait(10) end
    if Config.NHMenu then
        table.insert(GangMenu, {
            header = Config.Lang['remove_menu_header'],
        })
    elseif Config.QBMenu then
        table.insert(GangMenu, {
                header = Config.Lang['remove_menu_header'],
                isMenuHeader = true
            })
    end
    for _, GangDetails in pairs(GangList) do
        local name = GangDetails.name
        local id = GangDetails.identifier
        if Config.NHMenu then
            table.insert(GangMenu, {
                header = name,
                event = 'angelicxs-gangTerritory:client:removeGangMember',
                args = id
            })
        elseif Config.QBMenu then
            table.insert(GangMenu, {
                    header = name,
                    params = {
                        event = 'angelicxs-gangTerritory:client:removeGangMember',
                        args = id
                    }
                })
        elseif Config.OXLib then
            table.insert(GangMenu, {
                label = name,
                args = { oId = id}
            })
        end
    end
    if Config.NHMenu then
        TriggerEvent("nh-context:createMenu", GangMenu)
    elseif Config.QBMenu then
        TriggerEvent("qb-menu:client:openMenu", GangMenu)
    elseif Config.OXLib then
        lib.registerMenu({
            id = 'gangremovemenu_ox',
            title = Config.Lang['remove_menu_header'],
            options = GangMenu,
            position = 'top-right',
        }, function(selected, scrollIndex, args)
            TriggerEvent('angelicxs-gangTerritory:client:removeGangMember', args.oId)
        end)
        lib.showMenu('gangremovemenu_ox')
    end
end)
RegisterNetEvent('angelicxs-gangTerritory:client:removeGangMember',function(id)
    if not Config.UseAddOnGang or not boss then return end
    TriggerServerEvent('angelicxs-gangTerritory:server:RemoveGangMember',id)
end)
RegisterNetEvent('angelicxs-gangTerritory:JoinGang',function(gang)
    if not Config.UseAddOnGang then return end
    TriggerServerEvent('angelicxs-gangTerritory:server:JoinNewGang',gang)
end)
RegisterNetEvent('angelicxs-gangTerritory:LeaveGang',function(gang)
    if not Config.UseAddOnGang then return end
    TriggerServerEvent('angelicxs-gangTerritory:server:LeaveGang', gang)
end)

RegisterNetEvent('angelicxs-gangTerritory:MakeNewGang',function()
    GangCheck()
    TriggerEvent('angelicxs-gangTerritory:Notify', Config.Lang['new_gang_intro'], Config.LangType['info'])
    Wait(500)
    local ganginfo = {}
    if not Config.UseAddOnGang then
        local newgangname = string.upper(tostring(GangName))
        if NewGangNameCheck(newgangname) then
            TriggerServerEvent('angelicxs-gangTerritory:server:MakeNewGang', newgangname)
        else
            TriggerEvent('angelicxs-gangTerritory:Notify', Config.Lang['gang_exists'], Config.LangType['error'])
        end
    else
        if Config.NHInput then
            local keyboard, a = exports["nh-keyboard"]:Keyboard({
                header = Config.Lang['set_up_new_gang_header'],
                rows = {Config.Lang['set_up_gang_name']} 
            })
            if keyboard then
                local newgangname = string.upper(tostring(a))
                if NewGangNameCheck(newgangname) then
                    TriggerServerEvent('angelicxs-gangTerritory:server:MakeNewGang', newgangname)
                else
                    TriggerEvent('angelicxs-gangTerritory:Notify', Config.Lang['gang_exists'], Config.LangType['error'])
                end
            end
        elseif Config.QBInput then
            local info = exports['qb-input']:ShowInput({
                header = Config.Lang['set_up_new_gang_header'],
                submitText = Config.Lang['set_up_gang_submit'], 
                inputs = {
                    {
                        type = 'text',
                        isRequired = true,
                        name = 'name',
                        text = Config.Lang['set_up_gang_name'],
                    },
                }
            })    
            if info then
                local newgangname = string.upper(tostring(info.name))
                if NewGangNameCheck(newgangname) then
                    TriggerServerEvent('angelicxs-gangTerritory:server:MakeNewGang', newgangname)
                else
                    TriggerEvent('angelicxs-gangTerritory:Notify', Config.Lang['gang_exists'], Config.LangType['error'])
                end
            end
        elseif Config.OXLib then
            local input = lib.inputDialog(Config.Lang['set_up_new_gang_header'], {Config.Lang['set_up_new_gang_header']})
            if not input then return end
            local newgangname = string.upper(tostring(input[1]))
            if NewGangNameCheck(newgangname) then
                TriggerServerEvent('angelicxs-gangTerritory:server:MakeNewGang', newgangname)
            else
                TriggerEvent('angelicxs-gangTerritory:Notify', Config.Lang['gang_exists'], Config.LangType['error'])
            end
        end
    end
end)

RegisterNetEvent('angelicxs-gangTerritory:IncreaseValue',function(gang)
    local ganginfo = {}
    if Config.NHInput then
        local keyboard, a = exports["nh-keyboard"]:Keyboard({
            header = Config.Lang['increase_value_header'],
            rows = {Config.Lang['increase_value_header']} 
        })
        if keyboard then
            local value = tonumber(a)

            if value > 0 then
                TriggerServerEvent('angelicxs-gangTerritory:server:IncreaseValue', value, gang)
            else
                TriggerEvent('angelicxs-gangTerritory:Notify', Config.Lang['zero_error'], Config.LangType['error'])
            end
        end
    elseif Config.QBInput then
        local info = exports['qb-input']:ShowInput({
            header = Config.Lang['increase_value_header'],
            submitText = Config.Lang['set_up_gang_submit'], 
            inputs = {
                {
                    type = 'number',
                    isRequired = true,
                    name = 'number',
                    text = Config.Lang['increase_value_header'],
                },
            }
        })    
        if info then
            local value = tonumber(info.number)

            if value > 0 then
                TriggerServerEvent('angelicxs-gangTerritory:server:IncreaseValue', value, gang)
            else
                TriggerEvent('angelicxs-gangTerritory:Notify', Config.Lang['zero_error'], Config.LangType['error'])
            end
        end
    elseif Config.OXLib then
        local input = lib.inputDialog(Config.Lang['increase_value_header'], {Config.Lang['increase_value_header']})
        if not input then return end
        local value = tonumber(input[1])

        if value > 0 then
            TriggerServerEvent('angelicxs-gangTerritory:server:IncreaseValue', value, gang)
        else
            TriggerEvent('angelicxs-gangTerritory:Notify', Config.Lang['zero_error'], Config.LangType['error'])
        end
    end
end)

RegisterNetEvent('angelicxs-gangTerritory:client:newGangOnline', function(data)
    TerritorySetUp(data)
end)

RegisterNetEvent('angelicxs-gangTerritory:PlaceMarker', function()
    local Player = PlayerPedId()
    FreezeEntityPosition(Player, true)
    RequestAnimDict("anim@amb@clubhouse@tutorial@bkr_tut_ig3@")
    while not HasAnimDictLoaded("anim@amb@clubhouse@tutorial@bkr_tut_ig3@") do
        Wait(10)
    end
    TaskPlayAnim(Player,"anim@amb@clubhouse@tutorial@bkr_tut_ig3@","machinic_loop_mechandplayer",1.0, -1.0, -1, 49, 0, 0, 0, 0)
    Wait(7500)	
    ClearPedTasks(Player)
    FreezeEntityPosition(Player, false)
    RemoveAnimDict("anim@amb@clubhouse@tutorial@bkr_tut_ig3@")
    local coord = GetEntityCoords(Player)
    local pos = vector3(coord.x,coord.y,coord.z-1)
    TriggerServerEvent('angelicxs-gangTerritory:server:PlaceMarker', pos, GetEntityHeading(Player))
end)

RegisterNetEvent('angelicxs-gangTerritory:BurnAnim', function()
    local Player = PlayerPedId()
    FreezeEntityPosition(Player, true)
    RequestAnimDict("anim@amb@clubhouse@tutorial@bkr_tut_ig3@")
    while not HasAnimDictLoaded("anim@amb@clubhouse@tutorial@bkr_tut_ig3@") do
        Wait(10)
    end
    TaskPlayAnim(Player,"anim@amb@clubhouse@tutorial@bkr_tut_ig3@","machinic_loop_mechandplayer",1.0, -1.0, -1, 49, 0, 0, 0, 0)
    Wait(7500)	
    ClearPedTasks(Player)
    FreezeEntityPosition(Player, false)
end)

RegisterNetEvent('angelicxs-gangTerritory:BurnObj', function(sObj)
    local obj = NetworkGetEntityFromNetworkId(sObj)
    if DoesEntityExist(obj) then
        local vec = GetEntityCoords(obj)
        Wait(9500)
        AddExplosion(vec.x, vec.y, vec.z, 9, 0.0, true, false, false, true)
    end
end)


function NewGangNameCheck(newname)
    for Gang, Data in pairs(IntGangs) do
        if Gang == newname then
            return false
        end
    end
    return true
end


function GangCheck()
    if Config.UseESX then
        ESX.TriggerServerCallback('angelicxs-gangTerritory:GangCheck:ESX', function(cb, name, level)
            for Line, Data in pairs(cb) do 
                IntGangs[Data.gang] = true
            end
            if Config.UseAddOnGang and name then
                GangName = name
                boss = level
            end
        end)
    elseif Config.UseQBCore then
        QBCore.Functions.TriggerCallback('angelicxs-gangTerritory:GangCheck:QBCore', function(cb, name, level)
            for Line, Data in pairs(cb) do 
                IntGangs[Data.gang] = true
            end
            if Config.UseAddOnGang and name then
                GangName = name
                boss = level
            end
        end)
    end
end

function SetBlip(data)
    local p = AddBlipForRadius(data.loc.x, data.loc.y, data.loc.z, data.size+0.01)
    SetBlipHighDetail(p, true)
    SetBlipColour(p, data.colour)
    SetBlipAlpha(p, 160)
    SetBlipAsShortRange(p, true)
end

function TerritorySetUp(data)
    CreateThread(function()
        if not data['netid'] then return end
        CreateThread(function()
            ObjectSetUp(data['netid'], data.gang, data['obj'], data['loc']) 
        end)
        if not Config.NotifyEnteringTerritory and string.upper(tostring(GangName)) ~= data.gang then return end
        if Config.TerritoryRangeOnMap then
            SetBlip(data)
        end
        local gangMember = true
        if string.upper(tostring(GangName)) ~= data.gang then gangMember = false end
        local notify = false
        while true do
            local sleep = 2000
            local dist = #(GetEntityCoords(PlayerPedId())-data.loc)
            if dist > 0 +data.size then
                if gangMember then
                    inZone = false
                end
                notify = false
                Wait(sleep)
            end
            if dist <= 20+data.size then
                sleep = 1000
                if dist <= data.size then
                    sleep = 0
                    if not notify then
                        notify = true
                        if not gangMember then
                            TriggerEvent('angelicxs-gangTerritory:Notify', Config.Lang['enemy_territory'], Config.LangType['info'])
                        else
                            TriggerEvent('angelicxs-gangTerritory:Notify', Config.Lang['friendly_territory'], Config.LangType['info'])
                        end
                    end
                    if gangMember then
                        inZone = true
                    end
                end
            end
            Wait(sleep)
        end
    end)
end

function ObjectSetUp(netid, gang, sObj, loc)
    local obj = NetworkGetEntityFromNetworkId(netid)
    while not DoesEntityExist(obj) do
        local pos = #(GetEntityCoords(PlayerPedId())-loc)
        if pos <= 100 then
            obj = NetworkGetEntityFromNetworkId(netid)
        end
        Wait(10000)
    end
    if Config.UseThirdEye then
        if Config.ThirdEyeName == 'ox_target' then
            local eye_options = {
                {
                    onSelect = function()
                        TriggerEvent('angelicxs-gangTerritory:IncreaseValue', gang)
                    end,
                    label = Config.Lang['3eye_increase'],
                    icon = '',
                    canInteract = function()
                        return string.upper(tostring(GangName)) == gang
                    end,
                }, {
                    onSelect = function()
                        TriggerServerEvent('angelicxs-gangTerritory:server:BuyOut', gang, sObj)
                    end,
                    label = Config.Lang['3eye_buyout'],
                    icon = '',
                    canInteract = function()
                        return string.upper(tostring(GangName)) ~= gang
                    end,
                },
            }
            exports.ox_target:addLocalEntity(obj, eye_options)
        else
            exports[Config.ThirdEyeName]:AddEntityZone('gangobj'..gang, obj, {
                name = 'gangobj'..gang,
            },{
                options = {{
                    action = function()
                        TriggerEvent('angelicxs-gangTerritory:IncreaseValue', gang)
                    end,
                    label = Config.Lang['3eye_increase'],
                    icon = 'fas fa-dollar',
                    canInteract = function()
                        return string.upper(tostring(GangName)) == gang
                    end,
                },  {
                    action = function()
                        TriggerServerEvent('angelicxs-gangTerritory:server:BuyOut', gang, sObj)
                    end,
                    label = Config.Lang['3eye_buyout'],
                    icon = 'fas fa-fire',
                    canInteract = function()
                        return string.upper(tostring(GangName)) ~= gang
                    end,
                }},                     
                distance = 2
            })       
        end 
    end
    while Config.Use3DText do
        local Sleep = 2000
        local Player = PlayerPedId()
        local Pos = GetEntityCoords(Player)
        local objPos = GetEntityCoords(obj)
        local Dist = #(Pos - GetEntityCoords(obj))
        if Dist <= 50 then
            Sleep = 500
            if Dist <= 3 then
                Sleep = 0
                DrawText3Ds(objPos.x, objPos.y, objPos.z, Config.Lang['3d_gang_interact'])
                if IsControlJustReleased(0, 38) then
                    if string.upper(tostring(GangName)) ~= gang then
                        TriggerEvent('angelicxs-gangTerritory:Notify', Config.Lang['3d_gang_interact_e'], Config.LangType['error'])
                    else
                        TriggerEvent('angelicxs-gangTerritory:IncreaseValue', gang)
                    end
                elseif IsControlJustReleased(0,47) then
                    if string.upper(tostring(GangName)) == gang then
                        TriggerEvent('angelicxs-gangTerritory:Notify', Config.Lang['3d_gang_interact_g'], Config.LangType['error'])
                    else
                        TriggerServerEvent('angelicxs-gangTerritory:server:BuyOut', gang, sObj)
                    end
                end
            end
        end
        Wait(Sleep)
    end
end

function HashGrabber(model)
    local hash = GetHashKey(model)
    if not HasModelLoaded(hash) then
        RequestModel(hash)
        Wait(10)
    end
    while not HasModelLoaded(hash) do
      Wait(10)
    end
    return hash
end

function DrawText3Ds(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    SetTextScale(0.30, 0.30)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 370
    DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 41, 11, 41, 68)
end

AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() == resource then
        if DoesEntityExist(NPC) then
            DeleteEntity(NPC)
        end
    end
end)