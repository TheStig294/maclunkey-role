CreateConVar("ttt_maclunkey_gun_damage", "1000", nil, "Sets the damage dealt by the Maclunkey Gun", 0, 2000)
local highlightsCvar = CreateConVar("ttt_maclunkey_jester_highlights", "1", FCVAR_REPLICATED, "0 - Maclunkey's appearance works like a traitor, 1 - Maclunkey's appearance works like a jester until shooting the Maclunkey gun", 0, 2)
-- local highlightsCvar = CreateConVar("ttt_maclunkey_jester_highlights", "1", FCVAR_REPLICATED, "0 - Maclunkey's appearance works like a traitor, 1 - Maclunkey's appearance works like a jester until shooting the Maclunkey gun, 2 - Maclunkey's appearance works like a jester until shooting the Maclunkey gun, but appears as a traitor to fellow traitors", 0, 2)
local HIGHLIGHTS_TRAITOR = 0
local HIGHLIGHTS_JESTER = 1
-- local HIGHLIGHTS_MIXED = 2
local ROLE = {}
ROLE.nameraw = "maclunkey"
ROLE.name = "Maclunkey"
ROLE.nameplural = "Maclunkies"
ROLE.nameext = "a Maclunkey"
ROLE.nameshort = "mak"
ROLE.desc = [[You are {role}! {comrades}
You're immune to environmental damage and cannot damage others
...until you shoot your "{role} Gun"!

Pretend to be {ajester}, then surprise everyone!]]
ROLE.team = ROLE_TEAM_TRAITOR

ROLE.shop = {"item_armor", "item_radar", "item_disg"}

ROLE.loadout = {"ttt_maclunkey_role_weapon"}

ROLE.startingcredits = nil
ROLE.startinghealth = nil
ROLE.maxhealth = nil
ROLE.selectionpredicate = nil
ROLE.shortdesc = "Pretends to be a jester. Immune to environmental damage and cannot damage others until shooting their special gun"
ROLE.convars = {}

table.insert(ROLE.convars, {
    cvar = "ttt_maclunkey_gun_damage",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

table.insert(ROLE.convars, {
    cvar = "ttt_maclunkey_jester_highlights",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

if highlightsCvar:GetInt() == HIGHLIGHTS_JESTER or highlightsCvar:GetInt() == HIGHLIGHTS_MIXED then
    -- Helper functions that handle all of the maclunkies' jester logic, if jester halos are enabled.
    ROLE.isactive = function(ply) return ply:GetNWBool("RevealedMaclunkey", false) end
    ROLE.shouldactlikejester = function(ply) return not ply:IsRoleActive() end
else
    ROLE.isactive = nil
    ROLE.shouldactlikejester = nil
end

ROLE.translations = {}
ROLE.shoulddelayshop = true

ROLE.moverolestate = function(source, target, keepOnSource)
    if source:IsRoleActive() then
        target:SetNWBool("RevealedMaclunkey", true)

        if target:HasWeapon("ttt_maclunkey_role_weapon") then
            target:StripWeapon("ttt_maclunkey_role_weapon")
            target:PrintMessage(HUD_PRINTCENTER, "Their " .. ROLE_STRINGS[ROLE_MACLUNKEY] .. " Gun was used!")
        end
    end

    if not keepOnSource then
        source:SetNWBool("RevealedMaclunkey", false)
    end
end

RegisterRole(ROLE)
RunConsoleCommand("ttt_maclunkey_shop_active_only", "0")
RunConsoleCommand("ttt_maclunkey_shop_delay", "1")

if SERVER then
    AddCSLuaFile()

    if highlightsCvar:GetInt() == HIGHLIGHTS_TRAITOR then
        -- Makes the maclunkey gun handle the jester damage, so the jester halos for the Maclunkey can be removed
        hook.Add("EntityTakeDamage", "MaclunkeyAlteredDamage", function(target, dmginfo)
            local attacker = dmginfo:GetAttacker()
            local classname = "ttt_maclunkey_role_weapon"

            -- If someone is holding the maclunkey gun but not using it, negate the damage they deal
            -- If someone is holding the maclunkey gun, they are immune to the same types of damage the jester is
            if attacker and attacker:IsPlayer() and attacker:HasWeapon(classname) and attacker:GetActiveWeapon():GetClass() ~= classname then
                return true
            elseif target and target:IsPlayer() and target:HasWeapon(classname) and (dmginfo:GetDamageType() == DMG_GENERIC or dmginfo:GetDamageType() == DMG_CRUSH or dmginfo:GetDamageType() == DMG_BURN or dmginfo:GetDamageType() == DMG_FALL or dmginfo:GetDamageType() == DMG_BLAST) then
                return true
            end
        end)
    end

    -- Prints a message to all jesters at the start of a round, telling them there is a maclunkey
    hook.Add("TTTBeginRound", "MaclunkeyAlertMessage", function()
        timer.Simple(1, function()
            local isMaclunkey = false

            for i, ply in ipairs(player.GetAll()) do
                if ply:IsMaclunkey() then
                    isMaclunkey = true
                    break
                end
            end

            if isMaclunkey then
                for i, ply in ipairs(player.GetAll()) do
                    if ply:IsJesterTeam() then
                        ply:PrintMessage(HUD_PRINTCENTER, "There is a Maclunkey")
                    end
                end
            end
        end)
    end)

    hook.Add("TTTPrepareRound", "MaclunkeyRoleReset", function()
        for i, ply in ipairs(player.GetAll()) do
            ply:SetNWBool("RevealedMaclunkey", false)
        end
    end)
end

if CLIENT then
    hook.Add("TTTTutorialRoleText", "MaclunkeyTutorialRoleText", function(role, titleLabel, roleIcon)
        if role == ROLE_MACLUNKEY then
            local roleColor = ROLE_COLORS[ROLE_TRAITOR]
            local jesterRoleColor = ROLE_COLORS[ROLE_JESTER]
            local teamName = GetRoleTeamName(ROLE_TRAITOR)
            local jesterTeamName = GetRoleTeamName(ROLE_TEAM_JESTER)

            return "<p>The " .. ROLE_STRINGS[ROLE_MACLUNKEY] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. teamName .. " team</span> who pretends to be a <span style='color: rgb(" .. jesterRoleColor.r .. ", " .. jesterRoleColor.g .. ", " .. jesterRoleColor.b .. ")'>" .. jesterTeamName .. "</span>. <br>They are immune to environmental damage and cannot damage others, until they shoot their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. ROLE_STRINGS[ROLE_MACLUNKEY] .. " gun</span>.<br><br>- Appears as a " .. jesterTeamName .. " to those that can see a " .. jesterTeamName .. ", until their " .. ROLE_STRINGS[ROLE_MACLUNKEY] .. " gun is shot (including their fellow " .. teamName .. "(s)!)<br><br>- Possible to also have a " .. jesterTeamName .. " in the round</p>"
        end
    end)
    -- local function GetGlitchedRole(target)
    --     local glitchMode = GetConVar("ttt_glitch_mode"):GetInt()
    --     -- Use the player's role if they are a traitor, otherwise this is a glitch and we should use their fake role
    --     local role = target:IsTraitorTeam() and target:GetRole() or target:GetNWInt("GlitchBluff", ROLE_TRAITOR)
    --     -- Only hide vanilla traitors
    --     if glitchMode == GLITCH_SHOW_AS_TRAITOR then
    --         if role == ROLE_TRAITOR then return ROLE_NONE, ROLE_TRAITOR end
    --         -- Hide all traitors, but show whether they are special or not based on the color
    --         return role, nil
    --     elseif glitchMode == GLITCH_SHOW_AS_SPECIAL_TRAITOR then
    --         return ROLE_NONE, role
    --     end
    --     -- Hide all traitors, period
    --     return ROLE_NONE, ROLE_TRAITOR
    -- end
    -- if highlightsCvar:GetInt() == HIGHLIGHTS_MIXED then
    --     hook.Add("TTTTargetIDPlayerRoleIcon", "MaclunkeyRoleIcon", function(target, client, role, noZ, colorRole, hideBeggar, showJester, hideBodysnatcher)
    --         if not target:IsMaclunkey() or not client:IsTraitorTeam() then return end
    --         if GetGlobalBool("ttt_glitch_round", false) then
    --             role, colorRole = GetGlitchedRole(target)
    --             return role, noZ, colorRole
    --         else
    --             return ROLE_MACLUNKEY, noZ, ROLE_TRAITOR
    --         end
    --     end)
    --     hook.Add("TTTTargetIDPlayerRing", "MaclunkeyRoleIcon", function(target, client, ringVisible)
    --         if not target:IsMaclunkey() or not client:IsTraitorTeam() then return end
    --         if GetGlobalBool("ttt_glitch_round", false) then
    --             role, colorRole = GetGlitchedRole(target)
    --             return ringVisible, ROLE_COLORS[colorRole]
    --         else
    --             return ringVisible, ROLE_COLORS[ROLE_TRAITOR]
    --         end
    --     end)
    --     hook.Add("TTTScoreboardPlayerRole", "MaclunkeyRoleIcon", function(target, client, color, roleFileName)
    --         if not target:IsMaclunkey() or not client:IsTraitorTeam() then return end
    --         if GetGlobalBool("ttt_glitch_round", false) then
    --             role, colorRole = GetGlitchedRole(target)
    --             return ROLE_COLORS_SCOREBOARD[colorRole], ROLE_STRINGS_SHORT[role]
    --         else
    --             return ROLE_COLORS_SCOREBOARD[ROLE_TRAITOR], ROLE_STRINGS_SHORT[ROLE_MACLUNKEY]
    --         end
    --     end)
    --     local client
    --     hook.Add("PreDrawHalos", "MaclunkeyHighlights", function()
    --         if not IsValid(client) then
    --             client = LocalPlayer()
    --             return
    --         end
    --         local allies = {}
    --         -- -- Start with the list of traitors
    --         -- local allies = GetTeamRoles(TRAITOR_ROLES)
    --         -- -- And add the glitch
    --         -- table.insert(allies, ROLE_GLITCH)
    --         -- And add the maclunkey
    --         table.insert(allies, ROLE_MACLUNKEY)
    --         OnPlayerHighlightEnabled(client, allies, jesters_visible_to_traitors, true, true)
    --     end)
    -- end
end