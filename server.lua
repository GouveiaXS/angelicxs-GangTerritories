ESX = nil
QBcore = nil

local marker = {}

if Config.UseESX then
    ESX = exports["es_extended"]:getSharedObject()
elseif Config.UseQBCore then
    QBCore = exports['qb-core']:GetCoreObject()
end
local numb = 0
CreateThread(function()
    Wait(1000)
    MySQL.Async.fetchAll('SELECT * FROM angelicxs_gangterritory', {
    }, function (result)
        local gang, x, y, z, w, size = nil, nil, nil, nil, nil, nil
        for Line, Data in pairs(result) do
            numb = numb + 1
            for column, info in pairs(Data) do
                if column == 'locationx' and info then
                    x = info
                elseif column == 'locationy' and info then
                    y = info
                elseif column == 'locationz' and info then
                    z = info
                elseif column == 'locationw' and info then
                    w = info
                elseif column == 'gang' and info then
                    gang = info
                elseif column == 'size' and info then
                    size = info
                end
            end
            if x and y and z and w and gang and size then
                local info = tostring(gang) 
                marker[info] = {}
                marker[info]['colour'] = numb
                marker[info]['gang'] = tostring(gang)
                marker[info]['size'] = size
                marker[info]['loc'] = vector3(x, y, z)
                marker[info]['obj'] = CreateObject(GetHashKey(Config.TerritoryMarker), x, y, z, true, true, false)
                while not DoesEntityExist(marker[info]['obj']) do Wait(10) end
                marker[info]['netid'] = NetworkGetNetworkIdFromEntity(marker[info]['obj'])
                SetEntityHeading(marker[info]['obj'], w)
                FreezeEntityPosition(marker[info]['obj'], true)
                gang, x, y, z, w = nil, nil, nil, nil, nil
            end
        end
    end)
    if Config.IncreaseTerritoryOnServerRestart then
        Wait(10*60*1000)
        local string = tostring('UPDATE angelicxs_gangterritory SET size = size + '..tostring(Config.TerritoryIncrease))
        MySQL.Async.execute(string,
            {}, function (rowsChanged)
        end)
    end
end)

RegisterNetEvent('angelicxs-gangTerritory:server:PlaceMarker', function(coords, head)
    local src = source
    local Player = nil
    local id = nil
    if Config.UseESX then
        Player = ESX.GetPlayerFromId(src)
        id = Player.identifier
    elseif Config.UseQBCore then
        Player = QBCore.Functions.GetPlayer(src)
        id = Player.PlayerData.citizenid
    end
    MySQL.Async.fetchAll('SELECT gang FROM angelicxs_gangterritory WHERE boss = @boss', {
    ['@boss'] = id,
    }, function (result)
        local gang = nil
        for k,v in pairs(result) do
            gang = v.gang
            break
        end
        if not gang then 
            print('Attempted gangTerritory exploit (placing item without being boss of a gang) by the follow ID and Identifiers: '..tostring(source)..' '.. tostring(id))
            DropPlayer(src)
            return
        end
        MySQL.Async.fetchAll('UPDATE angelicxs_gangterritory SET locationx = @locationx, locationy = @locationy, locationz = @locationz, locationw = @locationw AND value = @value, size = @size WHERE boss = @boss', {
            ['@locationx'] 	= coords.x,
            ['@locationy'] 	= coords.y,
            ['@locationz'] 	= coords.z,
            ['@locationw'] 	= head,
            ['@value'] 	    = Config.TerritoryPurchaseCost,
            ['@size'] 	    = Config.TerritorySize,
            ['@boss'] 	    = id,
        }, function(rowsChanged)   
        end)  
        local info = tostring(gang) 
        numb = numb + 1
        marker[info] = {}
        marker[info]['colour'] = numb
        marker[info]['gang'] = tostring(gang)
        marker[info]['loc'] = vector3(coords.x, coords.y, coords.z)
        marker[info]['obj'] = CreateObject(GetHashKey(Config.TerritoryMarker), coords.x, coords.y, coords.z, true, true, false)
        marker[info]['size'] = Config.TerritorySize
        while not DoesEntityExist(marker[info]['obj']) do Wait(10) end
        marker[info]['netid'] = NetworkGetNetworkIdFromEntity(marker[info]['obj'])
        SetEntityHeading(marker[info]['obj'], head)
        FreezeEntityPosition(marker[info]['obj'], true)
        TriggerClientEvent('angelicxs-gangTerritory:client:newGangOnline', -1, marker[info])
    end)
end)

RegisterNetEvent('angelicxs-gangTerritory:server:BuyOut', function(name, obj)
    local value = nil
    local src = source
    local limit = 5
    local Player = nil
    local id = nil
    local paid = false
    MySQL.Async.fetchAll('SELECT value FROM angelicxs_gangterritory WHERE gang = @gang', {
        ['@gang'] = name,
        }, function (result)
            for k,v in pairs(result) do
                value = v.value
                break
            end
        end)
    while not value do 
        Wait(1000) 
        limit = limit - 1
        if limit < 0 then
            limit = -69
            break
        end
    end
    if limit == -69 then print('Database collection error.') return end

    if Config.UseESX  then
        Player = ESX.GetPlayerFromId(src)
        id = Player.identifier
        if Player.getMoney() >= value then
            Player.removeMoney(value)
            paid = true
        end
    elseif Config.UseQBCore then
        Player = QBCore.Functions.GetPlayer(src)
        id = Player.PlayerData.citizenid
        local cash = Player.PlayerData.money['cash']
        if cash >= value then
            Player.Functions.RemoveMoney('cash', value, "gang-purchase")
            paid = true
        end
    end
    if not paid then
        TriggerClientEvent('angelicxs-gangTerritory:Notify', src, Config.Lang['low_money_buyout']..value, Config.Lang['error'])
    elseif paid then
        MySQL.Async.execute('DELETE FROM angelicxs_gangterritory WHERE gang = @gang',{
            ['@gang'] = name,
        }, function (rowsChanged)
        end)
        TriggerClientEvent('angelicxs-gangTerritory:BurnAnim', src)
        TriggerClientEvent('angelicxs-gangTerritory:BurnObj', -1, NetworkGetNetworkIdFromEntity(obj))
        Wait(10000)
        TriggerClientEvent('angelicxs-gangTerritory:Notify', src, Config.Lang['terri_buyout'], Config.Lang['success'])
        DeleteEntity(obj)
    end
end)

RegisterNetEvent('angelicxs-gangTerritory:server:IncreaseValue', function(amount, name)
    local src = source
    local Player = nil
    local id = nil
    local paid = false
    if Config.UseESX  then
        Player = ESX.GetPlayerFromId(src)
        id = Player.identifier
        if Player.getMoney() >= amount then
            Player.removeMoney(amount)
            paid = true
        end
    elseif Config.UseQBCore then
        Player = QBCore.Functions.GetPlayer(src)
        id = Player.PlayerData.citizenid
        local cash = Player.PlayerData.money['cash']
        if cash >= amount then
            Player.Functions.RemoveMoney('cash', amount, "gang-purchase")
            paid = true
        end
    end
    if not paid then
        TriggerClientEvent('angelicxs-gangTerritory:Notify', src, Config.Lang['low_money_increase'], Config.Lang['error'])
    elseif paid then
        MySQL.Async.fetchAll('UPDATE angelicxs_gangterritory SET value = value + @value WHERE gang = @gang', {
            ['@value'] 	    = amount,
            ['@gang'] 	    = name,
        }, function(rowsChanged) end)
        TriggerClientEvent('angelicxs-gangTerritory:Notify', src, Config.Lang['value_increased'], Config.Lang['success'])
    end
end)

RegisterNetEvent('angelicxs-gangTerritory:server:MakeNewGang', function(name)
    local allow = true
    local src = source
    local Player = nil
    local id = nil
    local paid = false
    local amount = Config.TerritoryPurchaseCost
    local fname = 'Unknown'
    if Config.UseESX  then
        Player = ESX.GetPlayerFromId(src)
        id = Player.identifier
		local result = MySQL.Sync.fetchAll('SELECT firstname, lastname FROM `users` WHERE identifier = @identifier', {['@identifier'] = id})
		if result[1] and result[1].firstname and result[1].lastname then
			fname = tostring(('%s %s'):format(result[1].firstname, result[1].lastname))
		end
    elseif Config.UseQBCore then
        Player = QBCore.Functions.GetPlayer(src)
        id = Player.PlayerData.citizenid
        fname = tostring(Player.PlayerData.charinfo.firstname..' '..Player.PlayerData.charinfo.lastname)
    end
    if Config.UseAddOnGang then
        MySQL.Async.fetchAll('SELECT * FROM angelicxs_gangterritorylist WHERE identifier = @identifier', {
        ['@identifier'] = id,
        }, function (result)
            local gangMember = false
            for k,v in pairs(result) do
                gangMember = v.gang
            end
            if gangMember then 
                allow = false
                return
            end
        end)
    end 
    if not allow then TriggerClientEvent('angelicxs-gangTerritory:Notify', src, Config.Lang['one_gang_only_member'], Config.Lang['error']) return end
    MySQL.Async.fetchAll('SELECT * FROM angelicxs_gangterritory WHERE boss = @boss', {
    ['@boss'] = id,
    }, function (result)
        local owned = false
        for k,v in pairs(result) do
            owned = v.boss
        end
        if owned then 
            TriggerClientEvent('angelicxs-gangTerritory:Notify', src, Config.Lang['one_gang_only'], Config.Lang['error'])
            return
        else
            if Config.UseESX  then
                if Player.getMoney() >= amount then
                    Player.removeMoney(amount)
                    Player.addInventoryItem(Config.TerritoryItemName, 1)
                    paid = true
                end
            elseif Config.UseQBCore then
                local cash = Player.PlayerData.money['cash']
                if cash >= amount then
                    Player.Functions.RemoveMoney('cash', amount, "gang-purchase")
                    paid = true
                    Player.Functions.AddItem(Config.TerritoryItemName, 1)
                end
            end
            if not paid then
                TriggerClientEvent('angelicxs-gangTerritory:Notify', src, Config.Lang['low_money']..tostring(amount), Config.Lang['error'])
            elseif paid then
                MySQL.Async.execute('INSERT INTO angelicxs_gangterritory (gang, boss, size, value) VALUES (@gang, @boss, @size, @value)', {
                    ['@gang'] 	    = name,
                    ['@boss'] 	    = id,
                    ['@size'] 	    = Config.TerritorySize,
                    ['@value'] 	    = amount,
                }, function(rowsChanged)   
                    TriggerClientEvent('angelicxs-gangTerritory:Notify', src, Config.Lang['gang_made']..name, Config.Lang['success'])
                    TriggerClientEvent('angelicxs-gangTerritory:Notify', src, Config.Lang['place_item'], Config.Lang['success'])
                end)
                if Config.UseAddOnGang then
                    MySQL.Async.execute('INSERT INTO angelicxs_gangterritorylist (gang, boss, identifier, name) VALUES (@gang, @boss, @identifier, @name)', {
                        ['@gang'] 	    = name,
                        ['@boss'] 	    = 'yes',
                        ['@identifier'] = id,
                        ['@name'] = fname,
                    }, function(rowsChanged)   
                    end)
                end
            end
        end
    end)
end)

RegisterNetEvent('angelicxs-gangTerritory:server:JoinNewGang', function(name)
    local src = source
    local Player = nil
    local id = nil
    local paid = false
    local fname = 'Unknown'
    if Config.UseESX  then
        Player = ESX.GetPlayerFromId(src)
        id = Player.identifier
		local result = MySQL.Sync.fetchAll('SELECT firstname, lastname FROM `users` WHERE identifier = @identifier', {['@identifier'] = id})
		if result[1] and result[1].firstname and result[1].lastname then
			fname = tostring(('%s %s'):format(result[1].firstname, result[1].lastname))
		end
    elseif Config.UseQBCore then
        Player = QBCore.Functions.GetPlayer(src)
        id = Player.PlayerData.citizenid
        fname = tostring(Player.PlayerData.charinfo.firstname..' '..Player.PlayerData.charinfo.lastname)
    end
    MySQL.Async.fetchAll('SELECT * FROM angelicxs_gangterritorylist WHERE identifier = @identifier', {
    ['@identifier'] = id,
    }, function (result)
        local gangMember = false
        for k,v in pairs(result) do
            gangMember = v.gang
        end
        if gangMember then 
            TriggerClientEvent('angelicxs-gangTerritory:Notify', src, Config.Lang['one_gang_only_member'], Config.Lang['error'])
            return
        else
            if Config.UseESX  then
                if Player.getMoney() >= Config.CostToJoin then
                    Player.removeMoney(Config.CostToJoin)
                    paid = true
                end
            elseif Config.UseQBCore then
                local cash = Player.PlayerData.money['cash']
                if cash >= Config.CostToJoin then
                    Player.Functions.RemoveMoney('cash', Config.CostToJoin, "gang-purchase")
                    paid = true
                end
            end
            if not paid then
                TriggerClientEvent('angelicxs-gangTerritory:Notify', src, Config.Lang['low_money_join']..tostring(Config.CostToJoin), Config.Lang['error'])
            elseif paid then
                MySQL.Async.execute('INSERT INTO angelicxs_gangterritorylist (gang, identifier, name) VALUES (@gang, @identifier, @name)', {
                    ['@gang'] 	    = name,
                    ['@identifier'] = id,
                    ['@name'] = fname,
                }, function(rowsChanged)   
                end)
                TriggerClientEvent('angelicxs-gangTerritory:Notify', src, Config.Lang['join_gang']..tostring(name), Config.Lang['success'])
            end
        end
    end)
end)

RegisterNetEvent('angelicxs-gangTerritory:server:LeaveGang', function(oldgang)
    local src = source
    local Player = nil
    local id = nil
    local paid = false
    if Config.UseESX  then
        Player = ESX.GetPlayerFromId(src)
        id = Player.identifier
    elseif Config.UseQBCore then
        Player = QBCore.Functions.GetPlayer(src)
        id = Player.PlayerData.citizenid
    end
    MySQL.Async.fetchAll('SELECT * FROM angelicxs_gangterritorylist WHERE identifier = @identifier', {
    ['@identifier'] = id,
    }, function (result)
        local gangMember = false
        for k,v in pairs(result) do
            gangMember = v.gang
        end
        if not gangMember then 
            TriggerClientEvent('angelicxs-gangTerritory:Notify', src, Config.Lang['not_in_gang'], Config.Lang['error'])
            return
        elseif gangMember ~= oldgang then
            TriggerClientEvent('angelicxs-gangTerritory:Notify', src, Config.Lang['not_in_this_gang'], Config.Lang['error'])
            return
        else
            if Config.UseESX  then
                if Player.getMoney() >= Config.CostToLeave then
                    Player.removeMoney(Config.CostToLeave)
                    paid = true
                end
            elseif Config.UseQBCore then
                local cash = Player.PlayerData.money['cash']
                if cash >= Config.CostToLeave then
                    Player.Functions.RemoveMoney('cash', Config.CostToLeave, "gang-purchase")
                    paid = true
                end
            end
            if not paid then
                TriggerClientEvent('angelicxs-gangTerritory:Notify', src, Config.Lang['low_money_leave']..tostring(Config.CostToLeave), Config.Lang['error'])
            elseif paid then
                MySQL.Async.execute('DELETE FROM angelicxs_gangterritorylist WHERE identifier = @identifier',{
                    ['@identifier'] = id,
                }, function (rowsChanged)
                end)
                TriggerClientEvent('angelicxs-gangTerritory:Notify', src, Config.Lang['leave_gang'], Config.Lang['success'])
            end
        end
    end)
end)

RegisterNetEvent('angelicxs-gangTerritory:server:RemoveGangMember', function(id)
    local src = source
    local Player = nil
    local bossID = nil
    local paid = false
    if Config.UseESX  then
        Player = ESX.GetPlayerFromId(src)
        boss = Player.identifier
    elseif Config.UseQBCore then
        Player = QBCore.Functions.GetPlayer(src)
        bossID = Player.PlayerData.citizenid
    end
    MySQL.Async.fetchAll('SELECT * FROM angelicxs_gangterritorylist WHERE identifier = @identifier', {
    ['@identifier'] = bossID,
    }, function (result)
        local boss = false
        for k,v in pairs(result) do
            boss = v.boss
        end
        if not boss then 
            TriggerClientEvent('angelicxs-gangTerritory:Notify', src, Config.Lang['not_boss'], Config.Lang['error'])
            return
        else
            MySQL.Async.execute('DELETE FROM angelicxs_gangterritorylist WHERE identifier = @identifier',{
                ['@identifier'] = id,
            }, function (rowsChanged)
            end)
            TriggerClientEvent('angelicxs-gangTerritory:Notify', src, Config.Lang['member_removed'], Config.Lang['success'])
        end
    end)
end)

if Config.UseESX then
    ESX.RegisterServerCallback('angelicxs-gangTerritory:GangCheck:ESX', function(source, cb)
        if Config.UseAddOnGang then
            local Player = ESX.GetPlayerFromId(source)
            MySQL.Async.fetchAll('SELECT * FROM angelicxs_gangterritorylist where identifier = @identifier', {
                ['@identifier'] = Player.identifier,
                }, function (result)
                    local name = nil
                    local boss = nil
                    for k,v in pairs(result) do
                        name = v.gang
                        boss = v.boss
                        break
                    end
                cb(result, name, boss)
            end)
        else
            MySQL.Async.fetchAll('SELECT * FROM angelicxs_gangterritory', {
                }, function (result)
                cb(result)
            end)
        end
    end)
    ESX.RegisterServerCallback('angelicxs-gangTerritory:GangGrab:ESX', function(source, cb)
        Wait(3000)
        cb(marker)
    end)
    ESX.RegisterServerCallback('angelicxs-gangTerritory:GetGangMembers:ESX', function(source, cb, gang)
        MySQL.Async.fetchAll('SELECT * FROM angelicxs_gangterritorylist WHERE gang = @gang', {
            ['@gang'] = gang,
            }, function (result)
            cb(result)
        end)
    end)
    ESX.RegisterUsableItem(Config.TerritoryItemName, function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.removeInventoryItem(Config.TerritoryItemName, 1)
        TriggerClientEvent('angelicxs-gangTerritory:Notify',source, Config.Lang['used'], Config.LangType['success'])
        TriggerClientEvent('angelicxs-gangTerritory:PlaceMarker', source)
    end)
elseif Config.UseQBCore then
    QBCore.Functions.CreateCallback('angelicxs-gangTerritory:GangCheck:QBCore', function(source, cb)
        if Config.UseAddOnGang then
            local Player = QBCore.Functions.GetPlayer(source)
            MySQL.Async.fetchAll('SELECT * FROM angelicxs_gangterritorylist where identifier = @identifier', {
                ['@identifier'] = Player.PlayerData.citizenid,
                }, function (result)
                    local name = nil
                    local boss = nil
                    for k,v in pairs(result) do
                        name = v.gang
                        boss = v.boss
                        break
                    end
                cb(result, name, boss)
            end)
        else
            MySQL.Async.fetchAll('SELECT * FROM angelicxs_gangterritory', {
                }, function (result)
                cb(result)
            end)
        end
    end)
    QBCore.Functions.CreateCallback('angelicxs-gangTerritory:GangGrab:QBCore', function(source, cb)
        Wait(3000)
        cb(marker)
    end)
    QBCore.Functions.CreateCallback('angelicxs-gangTerritory:GetGangMembers:QBCore', function(source, cb, gang)
        MySQL.Async.fetchAll('SELECT * FROM angelicxs_gangterritorylist WHERE gang = @gang', {
            ['@gang'] = gang,
            }, function (result)
            cb(result)
        end)
    end)
    QBCore.Functions.CreateUseableItem(Config.TerritoryItemName, function(source, item)
        local Player = QBCore.Functions.GetPlayer(source)
        Player.Functions.RemoveItem(Config.TerritoryItemName, 1,item.slot)
        TriggerClientEvent('angelicxs-gangTerritory:Notify',source, Config.Lang['used'], Config.LangType['success'])
        TriggerClientEvent('angelicxs-gangTerritory:PlaceMarker', source)
    end)
end

AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() == resource then
        for k,v in pairs(marker)do
            if v['obj'] then
                if DoesEntityExist(v['obj']) then
                    DeleteEntity(v['obj'])
                end
            end
        end
    end
end)