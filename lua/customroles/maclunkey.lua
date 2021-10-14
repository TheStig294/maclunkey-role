CreateConVar("ttt_maclunkey_gun_damage", "1000", {FCVAR_NOTIFY}, "Sets the damage dealt by the Maclunkey Gun", 0, 2000)

CreateConVar("ttt_maclunkey_jester_highlights", "1", {FCVAR_NOTIFY}, "Can the Maclunkey be seen as a jester?", 0, 1)

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
ROLE.convars = {}

table.insert(ROLE.convars, {
    cvar = "ttt_maclunkey_gun_damage",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})

table.insert(ROLE.convars, {
    cvar = "ttt_maclunkey_jester_highlights",
    type = ROLE_CONVAR_TYPE_BOOL
})

if GetConVar("ttt_maclunkey_jester_highlights"):GetBool() then
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

    if GetConVar("ttt_maclunkey_jester_highlights"):GetBool() == false then
        -- Makes the maclunkey gun handle the jester damage, so the jester halos for the Maclunkey can be removed
        hook.Add("EntityTakeDamage", "MaclunkeyAlteredDamage", function(target, dmginfo)
            local attacker = dmginfo:GetAttacker()
            local classname = "ttt_maclunkey_role_weapon"

            if attacker and attacker:IsPlayer() and attacker:HasWeapon(classname) and attacker:GetActiveWeapon():GetClass() ~= classname then
                -- If someone is holding the maclunkey gun but not using it, negate the damage they deal
                return true
            elseif target and target:IsPlayer() and target:HasWeapon(classname) and (dmginfo:GetDamageType() == DMG_GENERIC or dmginfo:GetDamageType() == DMG_CRUSH or dmginfo:GetDamageType() == DMG_BURN or dmginfo:GetDamageType() == DMG_FALL or dmginfo:GetDamageType() == DMG_BLAST) then
                -- If someone is holding the maclunkey gun, they are immune to the same types of damage the jester is
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
    hook.Add("TTTTutorialRoleText", "SummonerTutorialRoleText", function(role, titleLabel, roleIcon)
        if role == ROLE_MACLUNKEY then
            local roleColor = ROLE_COLORS[ROLE_TRAITOR]
            local jesterRoleColor = ROLE_COLORS[ROLE_JESTER]
            local teamName = GetRoleTeamName(ROLE_TRAITOR)
            local jesterTeamName = GetRoleTeamName(ROLE_TEAM_JESTER)

            return "<p>The " .. ROLE_STRINGS[ROLE_MACLUNKEY] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. teamName .. " team</span> who pretends to be a <span style='color: rgb(" .. jesterRoleColor.r .. ", " .. jesterRoleColor.g .. ", " .. jesterRoleColor.b .. ")'>" .. jesterTeamName .. "</span>. <br>They are immune to environmental damage and cannot damage others, until they shoot their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. ROLE_STRINGS[ROLE_MACLUNKEY] .. " gun</span>.<br><br>- Appears as a " .. jesterTeamName .. " to those that can see a " .. jesterTeamName .. ", until their " .. ROLE_STRINGS[ROLE_MACLUNKEY] .. " gun is shot (including their fellow " .. teamName .. "(s)!)<br><br>- Possible to also have a " .. jesterTeamName .. " in the round</p>"
        end
    end)
end