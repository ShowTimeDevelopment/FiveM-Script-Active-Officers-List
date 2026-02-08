Bridge.Init()

local ui = false
local talk = false
local dat = {
    callsign = "N/A", opacity = 1.0, scale = 1.0, visible = false, pos = {x = 20, y = 400},
    panelOpen = false
}

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(0) end
    Wait(500)
    ShutdownLoadingScreen()
    BusyspinnerOff()
end)

local vst = {}
local auth = false
local chk = 0

local function isActive()
    return dat.visible or dat.panelOpen
end

local function hasAuth()
    local t = GetGameTimer()
    if t - chk < 5000 then 
        return auth
    end
    
    local p = Bridge.GetPlayerData()
    if not p or not p.job then 
        auth = false
        chk = t
        return false 
    end
    
    for _, d in pairs(Config.Departments) do
        for _, j in ipairs(d.jobs) do
            if p.job.name == j then 
                auth = true
                chk = t
                return true 
            end
        end
    end
    
    auth = false
    chk = t
    return false
end

local function getDept()
    local p = Bridge.GetPlayerData()
    if not p or not p.job then return nil end
    for id, d in pairs(Config.Departments) do
        for _, j in ipairs(d.jobs) do
            if p.job.name == j then return id end
        end
    end
    return nil
end

local function openTerm()
    if not hasAuth() then return end

    dat.panelOpen = true
    ExecuteCommand("e tablet2")
    SetNuiFocus(true, true)
    TriggerServerEvent('ShowTime_ActiveOfficers:RequestUpdate')
    local p = Bridge.GetPlayerData()
    SendNUIMessage({
        action = "openSettings",
        onDuty = p.job and p.job.onduty,
        currentCallsign = dat.callsign or "N/A",
        currentOpacity = dat.opacity or 1.0,
        currentScale = dat.scale or 1.0,
        config = Config,
        deptId = getDept(),
        localSource = GetPlayerServerId(PlayerId())
    })
end

if Config.RequireItem then
    RegisterNetEvent('ShowTime_ActiveOfficers:OpenTerminal', function()
        if not Bridge.HasItem(Config.ItemName) then
            Bridge.Notify("You need an emergency tablet!", "error")
            return
        end
        openTerm()
    end)
else
    RegisterNetEvent('ShowTime_ActiveOfficers:OpenTerminal', function()
        openTerm()
    end)
    
    RegisterCommand('activeofficers', function()
        openTerm()
    end, false)

    RegisterKeyMapping('activeofficers', 'Open Emergency Terminal', 'keyboard', 'EQUALS')
end

RegisterNetEvent('ShowTime_ActiveOfficers:SyncList', function(u, t, did)
    local p = Bridge.GetPlayerData()
    local a = hasAuth()
    
    if did then dat.visible = dat.visible end 

    SendNUIMessage({
        action = a and "updateList" or "hideList",
        onDuty = p.job and p.job.onduty,
        units = a and u or {},
        totalUnits = a and t or 0,
        deptId = did,
        config = Config,
        visible = a and dat.visible or false,
        opacity = dat.opacity,
        scale = dat.scale,
        pos = dat.pos,
        localSource = GetPlayerServerId(PlayerId()),
        localChannel = tonumber(LocalPlayer.state.radioChannel) or 0
    })
end)

local function setVoice(src, val)
    if src == GetPlayerServerId(PlayerId()) then talk = (val == true) end
    
    if vst[src] == val then return end
    vst[src] = val

    if isActive() then
        SendNUIMessage({ action = "setTalking", source = src, talking = (val == true) })
    end
end

RegisterNetEvent('ShowTime_ActiveOfficers:SetTalking', function(src, t)
    setVoice(src, t)
end)

AddStateBagChangeHandler('talking', nil, function(b, _, v)
    local s = tonumber((b:gsub('player:', '')))
    if s then setVoice(s, v) end
end)

RegisterNetEvent('ShowTime_ActiveOfficers:PanicAlert', function(sid)
    if hasAuth() then
        PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
        PlaySoundFrontend(-1, "OOB_Start", "GTAO_FM_Events_Soundset", 1)
        
        if sid and sid ~= 9999 and sid > 0 then
            Bridge.TriggerCallback('ShowTime_ActiveOfficers:GetOfficerCoords', function(c)
                if c then 
                    SetNewWaypoint(c.x, c.y) 
                    Bridge.Notify("PANIC BUTTON ACTIVATED!", "error")
                end
            end, sid)
        else
            Bridge.Notify("PANIC BUTTON ACTIVATED!", "error")
        end
    end
end)

AddStateBagChangeHandler('radioActive', nil, function(b, _, v)
    local s = tonumber((b:gsub('player:', '')))
    if s then setVoice(s, v) end
end)

AddStateBagChangeHandler('radioChannel', 'player:' .. GetPlayerServerId(PlayerId()), function(_, _, v)
    SendNUIMessage({ action = "updateLocalChannel", channel = tonumber(v) or 0 })
end)

RegisterNetEvent('ShowTime_ActiveOfficers:ClientJoinRadio', function(ch)
    local idx = tonumber(ch) or 0
    if talk then Bridge.Notify("Cannot switch radio while talking!", "error") return end
    
    SendNUIMessage({ action = "updateLocalChannel", channel = idx })
    
    PlaySoundFrontend(-1, "NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
    if idx > 0 then Bridge.Notify("Joined Radio: " .. idx, "success")
    else Bridge.Notify("Disconnected from Radio", "primary") end
end)

local function loadPlayerSettings()
    Bridge.TriggerCallback('ShowTime_ActiveOfficers:GetMySettings', function(s)
        if s then
            dat = s
        else
            dat = {
                callsign = "N/A", opacity = 1.0, scale = 1.0, visible = false, pos = {x = 20, y = 400},
                panelOpen = false
            }
        end
        dat.visible = false
        SendNUIMessage({
            action = "updateList", config = Config, visible = false,
            opacity = dat.opacity, scale = dat.scale, pos = dat.pos,
            localSource = GetPlayerServerId(PlayerId()),
            localChannel = tonumber(LocalPlayer.state.radioChannel) or 0
        })
        if Bridge.GetVoiceSystem() == 'pma-voice' then
            Bridge.SetVoiceMicClicks(true)
        end
        
        ShutdownLoadingScreen()
        BusyspinnerOff()
    end)
end

Bridge.OnPlayerLoaded(function()
    loadPlayerSettings()
end)

CreateThread(function()
    Wait(1000)
    local p = Bridge.GetPlayerData()
    if p and p.job then
        loadPlayerSettings()
    end
end)

Bridge.OnJobUpdate(function()
    if not hasAuth() then
        ExecuteCommand("e c")
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "hideList" })
        SendNUIMessage({ action = "closeSettings" })
        dat.visible = false
        dat.panelOpen = false
    end
end)

RegisterNUICallback('closeUI', function(_, cb) 
    dat.panelOpen = false
    SetNuiFocus(false, false) 
    ExecuteCommand("e c")
    cb('ok') 
end)

RegisterNUICallback('savePosition', function(d, cb)
    dat.pos = {x = d.x, y = d.y}
    TriggerServerEvent('ShowTime_ActiveOfficers:SavePosition', dat.pos)
    cb('ok')
end)

RegisterNUICallback('saveCallsign', function(d, cb)
    dat.callsign = d.callsign
    TriggerServerEvent('ShowTime_ActiveOfficers:SaveCallsign', d.callsign)
    cb('ok')
end)

RegisterNUICallback('toggleList', function(d, cb)
    dat.visible = d.visible
    TriggerServerEvent('ShowTime_ActiveOfficers:ToggleVisibility', d.visible)
    cb('ok')
end)

RegisterNUICallback('updateOpacity', function(d, cb)
    dat.opacity = tonumber(d.opacity) or 1.0
    TriggerServerEvent('ShowTime_ActiveOfficers:SaveOpacity', dat.opacity)
    cb('ok')
end)

RegisterNUICallback('updateScale', function(d, cb)
    dat.scale = tonumber(d.scale) or 1.0
    TriggerServerEvent('ShowTime_ActiveOfficers:SaveScale', dat.scale)
    cb('ok')
end)

RegisterNUICallback('joinRadio', function(d, cb)
    if d.channel then TriggerServerEvent('ShowTime_ActiveOfficers:JoinRadio', tonumber(d.channel)) end
    cb('ok')
end)

RegisterNUICallback('setWaypoint', function(d, cb)
    if not d.source then cb('error') return end
    Bridge.TriggerCallback('ShowTime_ActiveOfficers:GetOfficerCoords', function(c)
        if c then SetNewWaypoint(c.x, c.y) Bridge.Notify("GPS Waypoint set.", "success")
        else Bridge.Notify("Could not get location.", "error") end
    end, d.source)
    cb('ok')
end)

RegisterNUICallback('openActiveOfficersSettings', function(_, cb)
    openTerm()
    cb('ok')
end)

RegisterNUICallback('toggleDuty', function(_, cb)
    TriggerServerEvent('ShowTime_ActiveOfficers:ToggleDuty')
    cb('ok')
end)

RegisterNUICallback('triggerPanic', function(_, cb)
    ExecuteCommand("panic")
    cb('ok')
end)
