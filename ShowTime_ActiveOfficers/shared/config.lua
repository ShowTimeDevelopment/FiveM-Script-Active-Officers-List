Config = {}

Config.Framework = "qbox" -- auto, qb-core, qbox
Config.UseDatabase = true
Config.VoiceSystem = "auto" -- auto, pma-voice

Config.UpdateInterval = 5000
Config.RequireItem = true
Config.ItemName = "emergencytablet"
Config.DefaultCallsign = "N/A"
Config.EnablePanicButton = true
Config.ShowOfficerRank = true
Config.AllowHzSuffix = true
Config.AllowRadioJoining = true

Config.Theme = "Dark"

Config.Themes = {
    ["Dark"] = {
        MainBackground = "10, 11, 16",
        HeaderBackground = "rgba(18, 19, 26, 1.0)",
        RowBackground = "rgba(255, 255, 255, 0.02)",
        SubheaderBackground = "rgba(22, 23, 30, 0.95)",
        BorderColor = "rgba(255, 255, 255, 0.08)",
        TextColor = "#ffffff",
        TextSecondary = "#a1a1aa",
        PrimaryColor = "#2673eb"
    },
    ["Neutral"] = {
        MainBackground = "45, 48, 62",
        HeaderBackground = "rgba(55, 58, 75, 1.0)",
        RowBackground = "rgba(255, 255, 255, 0.1)",
        SubheaderBackground = "rgba(75, 80, 100, 0.9)",
        BorderColor = "rgba(255, 255, 255, 0.2)",
        TextColor = "#ffffff",
        TextSecondary = "#e2e2e7",
        PrimaryColor = "#2673eb"
    }
}

Config.UI = {
    TalkingColor = "#d23416",
    joinBtnColor = "",
}

Config.RadioOffset = 0 

Config.DepartmentRadioChannels = {
    ["police"] = {
        ["1"]  = { label = "MAIN", color = "#b8b8b8", icon = "fa-volume-high" },
        ["2"]  = { label = "PATROL", color = "#009cff", icon = "fa-volume-high" },
        ["3"]  = { label = "SWAT", color = "#000000", icon = "fa-volume-high" },
        ["4"]  = { label = "DETECTIVE", color = "#ff9c00", icon = "fa-volume-high" },
        ["5"]  = { label = "TROOPERS", color = "#005aff", icon = "fa-volume-high" },
        ["6"]  = { label = "RED COMMAND", color = "#d23416", icon = "fa-volume-high" },
        ["7"]  = { label = "FLEECA BANK", color = "#2dd4bf", icon = "fa-vault" },
        ["8"]  = { label = "PALETO HEIST", color = "#2dd4bf", icon = "fa-vault" },
        ["9"]  = { label = "PACIFIC BANK", color = "#2dd4bf", icon = "fa-vault" },
        ["10"] = { label = "TAC-1", color = "#94a3b8", icon = "fa-shield-halved" },
        ["11"] = { label = "TAC-2", color = "#64748b", icon = "fa-shield-halved" },
        ["12"] = { label = "TRAINING", color = "#45c574", icon = "fa-book" },
        ["13"] = { label = "AIR UNIT", color = "#38bdf8", icon = "fa-helicopter" },
        ["14"] = { label = "K9 UNIT", color = "#facc15", icon = "fa-dog" }
    },
    ["ambulance"] = {
        ["1.1"] = { label = "MAIN", color = "#b8b8b8", icon = "fa-volume-high" },
        ["15"]  = { label = "PATROL", color = "#009cff", icon = "fa-volume-high" },
        ["16"]  = { label = "RED COMMAND", color = "#d23416", icon = "fa-volume-high" },
        ["17"]  = { label = "SURGERY", color = "#32d34cff", icon = "fa-briefcase-medical" }
    }
}

Config.Departments = {
    ["police"] = {
        label = "Police Department",
        color = "#60a5fa",
        icon = "fas fa-shield-alt",
        joinBtnColor = "",
        jobs = {"police", "sheriff", "ranger", "lspd", "bcso", "sast", "sasp", "dispatch", "k9", "highway", "hc"}
    },
    ["ambulance"] = {
        label = "Emergency Medical Services",
        color = "#f87171",
        icon = "fas fa-ambulance",
        joinBtnColor = "",
        jobs = {"ambulance", "ems", "medic", "doctor", "fire"}
    }
}

Config.DepartmentCallsignColors = {
    ["police"] = {
        {min = 200, max = 209, color = "#d23416"},
        {min = 210, max = 299, color = "#009cff"},
        {min = 300, max = 350, color = "#000000"},
        {min = 400, max = 450, color = "#da971f"},
        {min = 500, max = 550, color = "#2c39bc"},
        {min = 600, max = 660, color = "#2aac30"}
    },
    ["ambulance"] = {
        {min = 200, max = 209, color = "#d23416"},
        {min = 210, max = 299, color = "#009cff"},
    }
}

Config.Text = {
    title = "ACTIVE OFFICERS",
    units = "Active",
    no_units = "None",
    join_btn = "JOIN CHANNEL",
    settings_title = "OFFICER TERMINAL",
    tablet_status = "SYSTEM ACTIVE",
    tablet_footer = "", 
    input_placeholder = "CALLSIGN"
}
