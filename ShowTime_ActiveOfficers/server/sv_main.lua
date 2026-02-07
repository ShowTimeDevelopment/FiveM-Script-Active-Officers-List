Bridge.Init()

local store = {}
local cov = {}

local function getIdType()
    return 'citizenid'
end

local function calcColor(c, did)
    local n = tonumber(tostring(c):match("%d+"))
    if not n or not did then return "#64748b" end
    local r = Config.DepartmentCallsignColors[did]
    if not r then return "#64748b" end
    for _, v in ipairs(r) do
        if n >= v.min and n <= v.max then return v.color end
    end
    return "#64748b"
end

local function findDept(j)
    for id, d in pairs(Config.Departments) do
        for _, aj in ipairs(d.jobs) do
            if j == aj then return id end
        end
    end
    return nil
end

if Config.UseDatabase and GetResourceState('oxmysql') == 'started' then
    MySQL.ready(function()
        local idf = getIdType()
        local q = {
            string.format("CREATE TABLE IF NOT EXISTS `officer_settings` (`%s` varchar(60) NOT NULL, `callsign` varchar(10) DEFAULT 'N/A', `pos_x` float DEFAULT NULL, `pos_y` float DEFAULT NULL, `is_visible` tinyint(1) DEFAULT 0, `opacity` float DEFAULT 1.0, `scale` float DEFAULT 1.0, PRIMARY KEY (`%s`))", idf, idf),
            "ALTER TABLE `officer_settings` ADD COLUMN IF NOT EXISTS `scale` FLOAT DEFAULT 1.0",
            "ALTER TABLE `officer_settings` ADD COLUMN IF NOT EXISTS `opacity` FLOAT DEFAULT 1.0"
        }
        for _, v in ipairs(q) do MySQL.query(v) end

        MySQL.query('SELECT * FROM officer_settings', {}, function(res)
            if res then
                for _, v in ipairs(res) do
                    local id = v[idf]
                    if id then
                        store[id] = {
                            callsign = v.callsign or "N/A",
                            pos = {x = v.pos_x, y = v.pos_y},
                            visible = (v.is_visible == 1),
                            opacity = v.opacity or 1.0,
                            scale = v.scale or 1.0
                        }
                    end
                end
            end
        end)
    end)
end

local function commit(id, k, v, src)
    if not store[id] then 
        store[id] = {callsign = "N/A", pos = nil, visible = false, opacity = 1.0, scale = 1.0}
    end
    store[id][k] = v
    if k == "callsign" and src then
        local pd = Bridge.GetPlayerData(src)
        if pd and pd.metadata then
            if Bridge.FrameworkObject then
                local pObj = Bridge.FrameworkObject.Functions.GetPlayer(src)
                if pObj then pObj.Functions.SetMetaData("callsign", v) end
            end
        end
    end
    
    if Config.UseDatabase and GetResourceState('oxmysql') == 'started' then
        local s = store[id]
        local idf = getIdType()
        MySQL.insert(string.format('INSERT INTO officer_settings (%s, callsign, pos_x, pos_y, is_visible, opacity, scale) VALUES (?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE callsign = ?, pos_x = ?, pos_y = ?, is_visible = ?, opacity = ?, scale = ?', idf), 
            {id, s.callsign, s.pos and s.pos.x, s.pos and s.pos.y, s.visible, s.opacity, s.scale, s.callsign, s.pos and s.pos.x, s.pos and s.pos.y, s.visible, s.opacity, s.scale})
    end
end

local function build()
    local res = {}
    for id, _ in pairs(Config.Departments) do
        res[id] = { grouped = {}, total = 0 }
    end
    
    local srcs = GetPlayers()
    if #srcs == 0 then return res end

    local any = false
    for _, src in ipairs(srcs) do
        local pd = Bridge.GetPlayerData(src)
        
        if pd and pd.onDuty then
            any = true
            local did = findDept(pd.job)
            
            if did then
                local cid = cov[src] or tonumber(Player(src).state.radioChannel) or 0
                local t = (Player(src).state.talking == true) or (Player(src).state.radioActive == true)
                local pan = Player(src).state.isPanic or false
                local cls = store[pd.identifier] and store[pd.identifier].callsign or pd.metadata["callsign"] or Config.DefaultCallsign
                local cNum = tostring(cls):gsub('[^%d]', '')
                
                -- Get channel info from config
                local cc = (Config.DepartmentRadioChannels[did] and Config.DepartmentRadioChannels[did][tostring(cid)])
                -- Local pill shows numerical frequency (e.g., 11 Hz)
                local rLabel = (cid > 0) and (cid .. (Config.AllowHzSuffix and " Hz" or "")) or "Off"
                
                local uData = {
                    source = src,
                    name = pd.name,
                    rank = pd.jobGradeName or "Officer",
                    callsign = cls,
                    callsignNum = tonumber(cNum) or 999,
                    callsignColor = calcColor(cls, did),
                    radioLabel = rLabel,
                    talking = t,
                    isPanic = pan
                }

                local function ins(target)
                    local d = res[target]
                    if not d.grouped[cid] then 
                        local groupCc = (Config.DepartmentRadioChannels[target] and Config.DepartmentRadioChannels[target][tostring(cid)]) 
                        -- Group label shows descriptive name (e.g., TAC-2)
                        local gLabel = (cid > 0) and (groupCc and groupCc.label or (cid .. (Config.AllowHzSuffix and " Hz" or ""))) or "Off"
                        local gColor = groupCc and groupCc.color or "#a1a1aa"
                        local gIcon = groupCc and groupCc.icon or "fa-walkie-talkie"
                        
                        d.grouped[cid] = { id = cid, label = gLabel, color = gColor, icon = gIcon, units = {} }
                    end
                    table.insert(d.grouped[cid].units, uData)
                    d.total = d.total + 1
                end

                if res[did] then ins(did) end

                if pan then
                    for target, _ in pairs(Config.Departments) do
                        if target ~= did then ins(target) end
                    end
                end
            end
        end
    end

    if not any then return res end

    local final = {}
    for id, data in pairs(res) do
        local sorted = {}
        for _, g in pairs(data.grouped) do
            table.sort(g.units, function(a, b) return a.callsignNum < b.callsignNum end)
            table.insert(sorted, g)
        end
        table.sort(sorted, function(a, b) return a.id < b.id end)
        final[id] = { units = sorted, total = data.total }
    end
    
    return final
end

local function sync()
    local srcs = GetPlayers()
    if #srcs == 0 then return end

    local data = build()
    
    for _, src in ipairs(srcs) do
        local pd = Bridge.GetPlayerData(src)
        if pd then
            local did = findDept(pd.job)
            if did and data[did] then
                TriggerClientEvent('ShowTime_ActiveOfficers:SyncList', src, data[did].units, data[did].total, did)
            end
        end
    end
end

local lock = false
local function throttle()
    if lock then return end
    lock = true
    SetTimeout(150, function()
        lock = false
        sync()
    end)
end

AddStateBagChangeHandler('radioChannel', nil, function(b, _, v)
    local n = tonumber((b:gsub('player:', '')))
    if n then cov[n] = tonumber(v) or 0 end
end)

AddStateBagChangeHandler('talking', nil, function(b, _, v)
    local s = tonumber((b:gsub('player:', '')))
    if s then TriggerClientEvent('ShowTime_ActiveOfficers:SetTalking', -1, s, (v == true)) end
end)

AddStateBagChangeHandler('radioActive', nil, function(b, _, v)
    local s = tonumber((b:gsub('player:', '')))
    if s then TriggerClientEvent('ShowTime_ActiveOfficers:SetTalking', -1, s, (v == true)) end
end)

RegisterNetEvent('ShowTime_ActiveOfficers:RequestUpdate', function()
    local src = source
    local pd = Bridge.GetPlayerData(src)
    if not pd then return end
    local did = findDept(pd.job)
    if not did then return end
    local full = build()
    if full[did] then
        TriggerClientEvent('ShowTime_ActiveOfficers:SyncList', src, full[did].units, full[did].total, did)
    end
end)

RegisterNetEvent('ShowTime_ActiveOfficers:JoinRadio', function(ch)
    local src = source
    local idx = tonumber(ch) or 0
    
    local pd = Bridge.GetPlayerData(src)
    if pd and idx > 0 then
        local did = findDept(pd.job)
        if did and Config.DepartmentRadioChannels[did] then
            -- Optional logic here if needed
        end
    end

    local finalIdx = idx > 0 and (idx + (Config.RadioOffset or 0)) or 0
    Bridge.SetPlayerRadio(src, finalIdx)
    TriggerClientEvent('ShowTime_ActiveOfficers:ClientJoinRadio', src, finalIdx)
    sync()
end)

RegisterNetEvent('ShowTime_ActiveOfficers:SavePosition', function(pos)
    local pd = Bridge.GetPlayerData(source)
    if pd then commit(pd.identifier, "pos", pos, source) end
end)

CreateThread(function()
    while true do
        Wait(Config.UpdateInterval or 5000)
        sync()
    end
end)

RegisterNetEvent('ShowTime_ActiveOfficers:SaveCallsign', function(c)
    local src = source
    if not c or #tostring(c) > 10 then return end
    
    local pd = Bridge.GetPlayerData(src)
    if pd then 
        if not store[pd.identifier] then 
            store[pd.identifier] = {callsign = "N/A", pos = nil, visible = false, opacity = 1.0, scale = 1.0}
        end
        store[pd.identifier].callsign = c
        commit(pd.identifier, "callsign", c, src) 
        sync()
    end
end)

RegisterNetEvent('ShowTime_ActiveOfficers:SaveOpacity', function(v)
    local pd = Bridge.GetPlayerData(source)
    if pd then commit(pd.identifier, "opacity", v, source) end
end)

RegisterNetEvent('ShowTime_ActiveOfficers:SaveScale', function(v)
    local pd = Bridge.GetPlayerData(source)
    if pd then commit(pd.identifier, "scale", v, source) end
end)

RegisterNetEvent('ShowTime_ActiveOfficers:ToggleVisibility', function(v)
    local pd = Bridge.GetPlayerData(source)
    if pd then commit(pd.identifier, "visible", v, source) end
end)

RegisterNetEvent('ShowTime_ActiveOfficers:ToggleDuty', function()
    local src = source
    local pd = Bridge.GetPlayerData(src)
    if not pd then return end
    local on = not pd.onDuty
    Bridge.SetPlayerDuty(src, on)
    sync()
end)

Bridge.CreateCallback('ShowTime_ActiveOfficers:GetMySettings', function(src, cb)
    local pd = Bridge.GetPlayerData(src)
    if pd then
        local s = store[pd.identifier] or {callsign = "N/A", pos = nil, visible = false, opacity = 1.0, scale = 1.0}
        cb(s)
    else cb(nil) end
end)

Bridge.CreateCallback('ShowTime_ActiveOfficers:GetOfficerCoords', function(_, cb, t)
    local ped = GetPlayerPed(t)
    if ped ~= 0 then cb(GetEntityCoords(ped)) else cb(nil) end
end)

if Bridge.FrameworkObject then
    Bridge.FrameworkObject.Functions.CreateUseableItem(Config.ItemName, function(src)
        TriggerClientEvent('ShowTime_ActiveOfficers:OpenTerminal', src)
    end)
end

AddEventHandler('playerJoining', function() SetTimeout(2000, function() throttle() end) end)
AddEventHandler('playerDropped', function() throttle() end)
AddStateBagChangeHandler('radioChannel', nil, function(b, _, v)
    local n = tonumber((b:gsub('player:', '')))
    if n then cov[n] = tonumber(v) or 0 throttle() end
end)
RegisterNetEvent('QBCore:Server:OnJobUpdate', function() throttle() end)

if Config.EnablePanicButton then
    RegisterCommand('panic', function(src)
        local pd = Bridge.GetPlayerData(src)
        if not pd or not pd.onDuty then return end
        if Player(src).state.isPanic then return end
        
        Player(src).state:set('isPanic', true, true)
        TriggerClientEvent('ShowTime_ActiveOfficers:PanicAlert', -1, src)
        sync()
        
        SetTimeout(7000, function()
            Player(src).state:set('isPanic', false, true)
            sync()
        end)
    end)
end
