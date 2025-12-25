--// =========================
--// SERVICES
--// =========================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local TextService = game:GetService("TextService")

--// =========================
--// CONFIG / TEMPLATE
--// =========================
getgenv().Settings = {
    PLAYERS = {
        VICTIM = "371623432",
        HELPER = "2905247264",
        HELPERS_INGAME_NAME = "Nera Zeshi",
    },

    VISUAL = {
        oldGuildName = "",
        newGuildName = "",
        DisplayName = "zzz",
        GUILD_ROLE = "Leader",
        BADGE_TOGGLES = {
            Bronze = false,
            DarkGoldRed = false,
            Deep = true,
            Gold = false,
            IronVow = false,
            Red = false,
            Silver = false,
        },

        DETAILS = {
            ["Leader"] = "Matty",
            ["Old_Name"] = "",
            ["Lieutenants"] = "1",
            ["Officers"] = "7",
            ["Overall Score"] = "746",
            ["PvE Score"] = "826",
            ["PvP Score"] = "-80",
            ["Rooms"] = "9",
        },
    },

    SERVER = {
        SERVER_AGE = "", -- leave empty to keep current value
        SERVER_NAME = "Quick Jade Gremor ", -- leave empty to keep current value
        SERVER_REGION = "", -- leave empty to keep current value
        CHARACTER_SLOT = "2601791150:A|1 [Lv.1]", -- leave empty to keep current value
    }
}

--// =========================
--// RESOLVE NAMES
--// =========================
local TARGET_INITIAL_TEXT
local HOVER_TEXT
if getgenv().Settings.PLAYERS.HELPERS_INGAME_NAME then
    TARGET_INITIAL_TEXT = getgenv().Settings.PLAYERS.HELPERS_INGAME_NAME
end
if getgenv().Settings.PLAYERS.VICTIM then
    local success, name = pcall(function()
        return Players:GetNameFromUserIdAsync(tonumber(getgenv().Settings.PLAYERS.VICTIM))
    end)
    if success then HOVER_TEXT = name end
end

--// =========================
--// LEADERBOARD HOVER SPOOF
--// =========================
local scrollingFrame = PlayerGui:FindFirstChild("LeaderboardGui") and PlayerGui.LeaderboardGui.MainFrame:FindFirstChild("ScrollingFrame")
if scrollingFrame then
    local function setupHover(frame)
        if not (frame:IsA("Frame") and frame.Name == "PlayerFrame") then return end
        local label = frame:FindFirstChild("Player")
        if not (label and label:IsA("TextLabel")) then return end
        if type(label.Text) ~= "string" then return end
        if TARGET_INITIAL_TEXT and label.Text ~= TARGET_INITIAL_TEXT then return end

        local originalText = label.Text
        local hovering = false

        frame.MouseEnter:Connect(function()
            if label and type(HOVER_TEXT) == "string" then
                hovering = true
                label.Text = HOVER_TEXT
            end
        end)

        frame.MouseLeave:Connect(function()
            if label and type(originalText) == "string" then
                hovering = false
                label.Text = originalText
            end
        end)

        label:GetPropertyChangedSignal("Text"):Connect(function()
            if hovering and type(label.Text) == "string" and label.Text ~= HOVER_TEXT then
                label.Text = HOVER_TEXT
            end
        end)
    end

    for _, child in ipairs(scrollingFrame:GetChildren()) do
        setupHover(child)
    end
    scrollingFrame.ChildAdded:Connect(setupHover)
end

--// =========================
--// GUILD TEXT SPOOFER
--// =========================
local function isGuildLabel(obj)
    return obj:IsA("TextLabel") and obj.Name == "Guild"
end

local function fixGuildText(label)
    if typeof(label.Text) == "string" and getgenv().Settings.VISUAL.oldGuildName and getgenv().Settings.VISUAL.newGuildName then
        label.Text = label.Text:gsub(getgenv().Settings.VISUAL.oldGuildName, getgenv().Settings.VISUAL.newGuildName)
    end
end

local function monitorLabel(label)
    fixGuildText(label)
    label:GetPropertyChangedSignal("Text"):Connect(function()
        fixGuildText(label)
    end)
end

for _, obj in ipairs(game:GetDescendants()) do
    if isGuildLabel(obj) then monitorLabel(obj) end
end
game.DescendantAdded:Connect(function(obj)
    if isGuildLabel(obj) then monitorLabel(obj) end
end)

--// =========================
--// HELPER / VICTIM VISUAL SPOOF
--// =========================
if getgenv().Settings.PLAYERS.HELPER then
    local success, helperName = pcall(function()
        return Players:GetNameFromUserIdAsync(tonumber(getgenv().Settings.PLAYERS.HELPER))
    end)
    if success then
        local helper = Players:FindFirstChild(helperName)
        if helper then
            local victimName = getgenv().Settings.PLAYERS.VICTIM and Players:GetNameFromUserIdAsync(tonumber(getgenv().Settings.PLAYERS.VICTIM)) or helper.Name
            local chosenName = getgenv().Settings.VISUAL.DisplayName ~= "" and getgenv().Settings.VISUAL.DisplayName or helper.DisplayName

            helper.Name = victimName or helper.Name
            helper.DisplayName = chosenName or helper.DisplayName
            if helper.Character and helper.Character:FindFirstChild("Humanoid") then
                helper.Character.Humanoid.NameDisplayDistance = 0
                helper.Character.Humanoid.DisplayName = chosenName or helper.Character.Humanoid.DisplayName
            end

            helper.CharacterAdded:Connect(function(char)
                local hum = char:WaitForChild("Humanoid")
                if hum then hum.DisplayName = chosenName or hum.DisplayName end
            end)
        end
    end
end

--// =========================
--// GUILD INFO SPOOF
--// =========================
local LeaderboardUI = PlayerGui:FindFirstChild("LeaderboardGui")
local guildInfoFrame = LeaderboardUI and LeaderboardUI.MainFrame:FindFirstChild("GuildInfo")
if guildInfoFrame then
    guildInfoFrame:GetPropertyChangedSignal("Visible"):Connect(function()
        if not guildInfoFrame.Visible then return end
        if getgenv().Settings.VISUAL.GUILD_ROLE then
            guildInfoFrame.Title.Text = getgenv().Settings.VISUAL.GUILD_ROLE
        end

        if getgenv().Settings.VISUAL.DETAILS then
            local details = {}
            for name, value in pairs(getgenv().Settings.VISUAL.DETAILS) do
                details[#details + 1] = string.format("<b>%s</b>: %s", name, value)
            end
            table.sort(details)
            guildInfoFrame.DescSheet.Desc.RichText = true
            guildInfoFrame.DescSheet.Desc.Text = table.concat(details, "\n")
        end
    end)
end

--// =========================
--// BADGE INJECTION
--// =========================
local BadgeSource = PlayerGui:FindFirstChild("LeaderboardGui") and PlayerGui.LeaderboardGui:FindFirstChild("LeaderboardClient")

local function getEnabledBadge()
    if not getgenv().Settings.VISUAL.BADGE_TOGGLES or not BadgeSource then return end
    for name, enabled in pairs(getgenv().Settings.VISUAL.BADGE_TOGGLES) do
        if enabled then
            return BadgeSource:FindFirstChild(name)
        end
    end
end

local function cloneBadgeIntoPlayer(label)
    if not (label and label:IsA("TextLabel")) then return end
    if label:FindFirstChild("InjectedBadge") then return end
    local badgeTemplate = getEnabledBadge()
    if not badgeTemplate then return end
    local badge = badgeTemplate:Clone()
    badge.Name = "InjectedBadge"
    badge.Parent = label
end

if scrollingFrame then
    for _, child in ipairs(scrollingFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name == "PlayerFrame" then
            local label = child:FindFirstChild("Player")
            if label and (not TARGET_INITIAL_TEXT or label.Text == TARGET_INITIAL_TEXT) then
                cloneBadgeIntoPlayer(label)
            end
        end
    end
    scrollingFrame.ChildAdded:Connect(function(child)
        if child:IsA("Frame") and child.Name == "PlayerFrame" then
            local label = child:FindFirstChild("Player")
            if label and (not TARGET_INITIAL_TEXT or label.Text == TARGET_INITIAL_TEXT) then
                cloneBadgeIntoPlayer(label)
            end
        end
    end)
end

--// =========================
--// WORLDUI / SERVER INFO SPOOF
--// =========================
local WorldUI = PlayerGui:FindFirstChild("TopbarGui") and PlayerGui.TopbarGui:FindFirstChild("Container")
if WorldUI then
    local function refreshRegion()
        local Title1 = WorldUI.InfoFrame.ServerInfo:FindFirstChild("ServerTitle")
        local Title2 = WorldUI.InfoFrame.ServerInfo:FindFirstChild("ServerRegion")
        local PingIcon = Title2 and Title2:FindFirstChild("PingIcon")

        if Title1 and Title2 then
            local titleSize1 = TextService:GetTextSize(Title1.Text, Title1.TextSize, Title1.Font, Vector2.new(1000,18))
            local titleSize2 = TextService:GetTextSize(Title2.Text, Title2.TextSize, Title2.Font, Vector2.new(1000,18))
            local max = math.max(titleSize1.X, titleSize2.X)

            Title1.Size = UDim2.new(0, titleSize1.X + 5, 0, 18)
            Title2.Size = UDim2.new(0, titleSize2.X + 3, 0, 18)
            WorldUI.InfoFrame.ServerInfo.Size = UDim2.new(0, max + 40, 0, 18)

            if PingIcon then
                PingIcon.Position = UDim2.new(0, Title2.Position.X.Offset + Title2.Size.X.Offset + 5, PingIcon.Position.Y.Scale, PingIcon.Position.Y.Offset)
            end
        end
    end

    -- Server Age
    if getgenv().Settings.SERVER.SERVER_AGE and getgenv().Settings.SERVER.SERVER_AGE ~= "" then
        WorldUI.InfoFrame.ServerInfo.ServerAge.Text = getgenv().Settings.SERVER.SERVER_AGE
        WorldUI.InfoFrame.ServerInfo.ServerAge:GetPropertyChangedSignal("Text"):Connect(function()
            if WorldUI.InfoFrame.ServerInfo.ServerAge.Text ~= getgenv().Settings.SERVER.SERVER_AGE then
                WorldUI.InfoFrame.ServerInfo.ServerAge.Text = getgenv().Settings.SERVER.SERVER_AGE
            end
        end)
    end

    -- Server Name
    if getgenv().Settings.SERVER.SERVER_NAME and getgenv().Settings.SERVER.SERVER_NAME ~= "" then
        local Title = WorldUI.InfoFrame.ServerInfo:FindFirstChild("ServerTitle")
        if Title then
            Title.Text = getgenv().Settings.SERVER.SERVER_NAME
            refreshRegion()
            Title:GetPropertyChangedSignal("Text"):Connect(function()
                if Title.Text ~= getgenv().Settings.SERVER.SERVER_NAME then
                    Title.Text = getgenv().Settings.SERVER.SERVER_NAME
                end
                refreshRegion()
            end)
        end
    end

    -- Server Region
    if getgenv().Settings.SERVER.SERVER_REGION and getgenv().Settings.SERVER.SERVER_REGION ~= "" then
        local Title = WorldUI.InfoFrame.ServerInfo:FindFirstChild("ServerRegion")
        if Title then
            Title.Text = getgenv().Settings.SERVER.SERVER_REGION
            refreshRegion()
            Title:GetPropertyChangedSignal("Text"):Connect(function()
                if Title.Text ~= getgenv().Settings.SERVER.SERVER_REGION then
                    Title.Text = getgenv().Settings.SERVER.SERVER_REGION
                end
                refreshRegion()
            end)
        end
    end

    -- Character Slot
    if getgenv().Settings.SERVER.CHARACTER_SLOT and getgenv().Settings.SERVER.CHARACTER_SLOT ~= "" then
        local SlotLabel = WorldUI.InfoFrame:FindFirstChild("CharacterInfo") and WorldUI.InfoFrame.CharacterInfo:FindFirstChild("Slot")
        if SlotLabel then
            SlotLabel.Text = getgenv().Settings.SERVER.CHARACTER_SLOT
        end
    end
end
