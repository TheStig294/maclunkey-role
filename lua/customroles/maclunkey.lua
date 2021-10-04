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
ROLE.isactive = function(ply) return ply:GetNWBool("RevealedMaclunkey", false) end
ROLE.selectionpredicate = nil
ROLE.convars = {}
-- Helper function that handles all of the maclunkies' jester logic, e.g. appearing as a jester to other traitors
ROLE.shouldactlikejester = function(ply) return not ply:IsRoleActive() end
ROLE.translations = {}
ROLE.shoulddelayshop = true
RegisterRole(ROLE)
RunConsoleCommand("ttt_maclunkey_shop_active_only", "0")
RunConsoleCommand("ttt_maclunkey_shop_delay", "1")

if SERVER then
    AddCSLuaFile()

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