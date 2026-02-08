Bridge = {}
Bridge.Framework = nil
Bridge.FrameworkObject = nil
Bridge.VoiceSystem = nil

local function DetectFramework()
    if GetResourceState('qb-core') == 'started' then
        local success, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if success and core then
            Bridge.Framework = 'qbcore'
            Bridge.FrameworkObject = core
            return 'qbcore'
        end
    end
    
    local qboxResources = {'qbx_core', 'qbx-core', 'qbox-core'}
    for _, res in ipairs(qboxResources) do
        if GetResourceState(res) == 'started' then
            local success, core = pcall(function() return exports[res]:GetCoreObject() end)
            if success and core then
                Bridge.Framework = 'qbox'
                Bridge.FrameworkObject = core
                return 'qbox'
            end
        end
    end
    
    if not Bridge.FrameworkObject then
        local success, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if success and core then
            Bridge.Framework = 'qbcore'
            Bridge.FrameworkObject = core
            return 'qbcore'
        end
    end
    
    Bridge.Framework = nil
    Bridge.FrameworkObject = nil
    return nil
end

local function DetectVoiceSystem()
    if GetResourceState('pma-voice') == 'started' then
        Bridge.VoiceSystem = 'pma-voice'
        return 'pma-voice'
    elseif GetResourceState('saltychat') == 'started' then
        Bridge.VoiceSystem = 'saltychat'
        return 'saltychat'
    elseif GetResourceState('mumble-voip') == 'started' then
        Bridge.VoiceSystem = 'mumble-voip'
        return 'mumble-voip'
    else
        Bridge.VoiceSystem = 'none'
        return 'none'
    end
end

function Bridge.Init()
    local detectedFramework = DetectFramework()
    local detectedVoice = DetectVoiceSystem()
    
    if Config.Framework ~= "auto" then
        local framework = Config.Framework:lower()
        if framework == "qb-core" then framework = "qbcore" end
        Bridge.Framework = framework
    end
    
    if Config.VoiceSystem ~= "auto" then
        Bridge.VoiceSystem = Config.VoiceSystem:lower()
    end
    
    if not Bridge.FrameworkObject then
        print("^1[ShowTime_ActiveOfficers] WARNING: No framework object detected. Ensure you are using a supported framework (QBCore/QBox).^7")
    end

    return Bridge.Framework, Bridge.VoiceSystem
end

function Bridge.GetFramework()
    return Bridge.Framework or 'unknown'
end

function Bridge.GetVoiceSystem()
    return Bridge.VoiceSystem or 'none'
end

if IsDuplicityVersion() then
    
    function Bridge.GetPlayerData(source)
        if not Bridge.FrameworkObject then return nil end
        
        local Player = Bridge.FrameworkObject.Functions.GetPlayer(source)
        if not Player then return nil end
        
        return {
            source = source,
            identifier = Player.PlayerData.citizenid,
            name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
            job = Player.PlayerData.job.name,
            jobLabel = Player.PlayerData.job.label,
            jobGrade = Player.PlayerData.job.grade.level,
            jobGradeName = Player.PlayerData.job.grade.name,
            onDuty = Player.PlayerData.job.onduty or false,
            metadata = Player.PlayerData.metadata or {}
        }
    end
    
    function Bridge.IsPlayerOnDuty(source)
        local playerData = Bridge.GetPlayerData(source)
        return playerData and playerData.onDuty or false
    end
    
    function Bridge.SetPlayerDuty(source, onDuty)
        if not Bridge.FrameworkObject then return false end
        
        local Player = Bridge.FrameworkObject.Functions.GetPlayer(source)
        if Player then
            Player.Functions.SetJobDuty(onDuty)
            return true
        end
        return false
    end
    
    function Bridge.Notify(source, message, type)
        if Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
            TriggerClientEvent('QBCore:Notify', source, message, type)
        end
    end
    
    function Bridge.CreateCallback(name, cb)
        if Bridge.FrameworkObject then
            Bridge.FrameworkObject.Functions.CreateCallback(name, cb)
        end
    end
    
    function Bridge.SetPlayerRadio(source, channel)
        if Bridge.VoiceSystem == 'pma-voice' then
            Player(source).state:set('radioChannel', channel, true)
            if GetResourceState('pma-voice') == 'started' then
                pcall(function() exports['pma-voice']:setPlayerRadio(source, channel) end)
            end
        elseif Bridge.VoiceSystem == 'saltychat' then
            exports['saltychat']:SetPlayerRadioChannel(source, tostring(channel), true)
        elseif Bridge.VoiceSystem == 'mumble-voip' then
            exports['mumble-voip']:SetPlayerRadioChannel(source, channel)
        end
    end
    
else
    
    function Bridge.GetPlayerData()
        if Bridge.FrameworkObject then
            return Bridge.FrameworkObject.Functions.GetPlayerData()
        end
        return nil
    end
    
    function Bridge.TriggerCallback(name, cb, ...)
        if Bridge.FrameworkObject then
            Bridge.FrameworkObject.Functions.TriggerCallback(name, cb, ...)
        end
    end
    
    function Bridge.Notify(message, type)
        if Bridge.FrameworkObject then
            Bridge.FrameworkObject.Functions.Notify(message, type)
        end
    end
    
    function Bridge.HasItem(itemName)
        if not itemName or itemName == "" then return true end
        if not Bridge.FrameworkObject then return false end

        local has = false
        if GetResourceState('ox_inventory') == 'started' then
            local count = exports.ox_inventory:Search('count', itemName)
            has = count > 0
        else
            local pData = Bridge.FrameworkObject.Functions.GetPlayerData()
            if pData and pData.items then
                for _, item in pairs(pData.items) do
                    if item.name == itemName and item.amount > 0 then 
                        has = true 
                        break
                    end
                end
            end
        end

        return has
    end

    function Bridge.OnPlayerLoaded(callback)
        if Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
            RegisterNetEvent('QBCore:Client:OnPlayerLoaded', callback)
        end
    end

    function Bridge.OnJobUpdate(callback)
        if Bridge.Framework == 'qbcore' or Bridge.Framework == 'qbox' then
            RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
                callback({
                    name = JobInfo.name,
                    label = JobInfo.label,
                    grade = JobInfo.grade.level,
                    gradeName = JobInfo.grade.name,
                    onduty = JobInfo.onduty
                })
            end)
        end
    end
    
    function Bridge.SetVoiceMicClicks(enabled)
        if Bridge.VoiceSystem == 'pma-voice' then
            exports['pma-voice']:setVoiceProperty('micClicks', enabled)
        end
    end
end

return Bridge
