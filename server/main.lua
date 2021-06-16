QBCore = nil
TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)

local processing = {}

QBCore.Functions.CreateCallback('cui_wardrobe:saveOutfit', function(source, cb, data)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    local identifier = xPlayer.PlayerData.citizenid
    local slot = tonumber(data['slot'])

    if slot > Config.SlotsNumber then
        cb(false)
        return
    end

    -- Safeguard from trying to do this too fast on one slot
    if not processing[identifier] then
        processing[identifier] = {}
    end

    if not processing[identifier][slot] then
        processing[identifier][slot] = true
        Citizen.CreateThread(function()
            local name = data['name']
            local clothes = data['clothes']

            -- TODO: Validate data (name?)
            exports.ghmattimysql:scalar('SELECT 1 FROM player_outfits WHERE owner = @identifier AND slot = @slot', {['@identifier'] = identifier,['@slot'] = slot}, function(exists)
                -- TODO: Maybe split new (insert into) and edit (update) ?
                if exists then
                    exports.ghmattimysql:execute("UPDATE `player_outfits` SET `name` = '"..name.."', `clothes` = '"..json.encode(clothes).."' WHERE citizenid = '"..xPlayer.PlayerData.citizenid.."' AND `slot` = '"..slot.."'", function(rowsChanged)
                        if rowsChanged then
                            cb(true)
                        else
                            cb(false)
                        end
                        processing[identifier][slot] = nil
                    end)
                else
                    exports.ghmattimysql:execute("INSERT INTO `player_outfits` (`owner`, `slot`, `name`, `clothes`) VALUES ('"..xPlayer.PlayerData.citizenid.."', '"..slot.."', '"..name.."', '"..json.encode(clothes).."')", function(rowsChanged)
                        if rowsChanged then
                            cb(true)
                        else
                            cb(false)
                        end
                        processing[identifier][slot] = nil
                    end)
                end
            end)
        end)
    else
        -- Save request already pending, do nothing/fail
        cb(false)
        return
    end
end)

QBCore.Functions.CreateCallback('cui_wardrobe:deleteOutfit', function(source, cb, slot)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    local identifier = xPlayer.PlayerData.citizenid

    if slot > Config.SlotsNumber then
        cb(false)
        return
    end

    -- Safeguard from trying to do this too fast on one slot
    if not processing[identifier] then
        processing[identifier] = {}
    end

    if not processing[identifier][slot] then
        processing[identifier][slot] = true
        Citizen.CreateThread(function()
            exports.ghmattimysql:execute("SELECT * FROM `player_outfits` WHERE `owner` = '"..xPlayer.PlayerData.citizenid.."' AND `slot` = '"..slot.."'", function(exists)
                if exists then
                    exports.ghmattimysql:execute("DELETE FROM `player_outfits` WHERE `owner` = '"..xPlayer.PlayerData.citizenid.."' AND `slot` = '"..slot.."'", function(rowsChanged)
                        if rowsChanged then
                            cb(true)
                        else
                            cb(false)
                        end
                        processing[identifier][slot] = nil
                    end)
                else
                    cb(false)
                    processing[identifier][slot] = nil
                end
            end)
        end)
    else
        -- Delete request already pending, do nothing/fail
        cb(false)
        return
    end
end)

QBCore.Functions.CreateCallback('cui_wardrobe:getPlayerOutfits', function(source, cb)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    exports.ghmattimysql:execute("SELECT * FROM `player_outfits` WHERE `owner` = '"..xPlayer.PlayerData.citizenid.."'", function(result)
        local player_outfits = {}
        if result ~= nil then
            for k, v in pairs(result) do
                player_outfits[v.slot] = { name = v.name, data = json.decode(v.clothes) }
            end
        end

        cb(player_outfits)
    end)
end)

QBCore.Functions.CreateCallback('cui_wardrobe:getOutfitInSlot', function(source, cb, slot)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    exports.ghmattimysql:execute("SELECT name, clothes FROM `player_outfits` WHERE `owner` = '"..xPlayer.PlayerData.citizenid.."' AND `slot` = '"..slot.."'", function(result)
        local outfit = {}

        if result[1] ~= nil then
            outfit = { name = result[1]['name'], data = json.decode(result[1]['clothes']) }
        end

        cb(outfit)
    end)
end)
