AddCSLuaFile()
local ShootSound = Sound("weapons/maclunkey_shoot.wav")
local DrawSound = Sound("weapons/maclunkey_draw.wav")

if CLIENT then
    SWEP.PrintName = "Maclunkey Gun"
    SWEP.Slot = 8
    SWEP.Icon = "VGUI/ttt/roles/mak/ttt_maclunkey_role_weapon.png"
    SWEP.ViewModelFOV = 75

    SWEP.EquipMenuData = {
        type = "Weapon",
        desc = "Takes a second to draw, then shoots a deadly laser shot!"
    }
end

SWEP.Author = "Faaafv"
SWEP.Instructions = " "
SWEP.Category = WEAPON_CATEGORY_ROLE
SWEP.IconLetter = "w"
SWEP.UseHands = true
SWEP.Base = "weapon_tttbase"
SWEP.HoldType = "pistol"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.DrawCrosshair = true
SWEP.WeaponDeploySpeed = 0.5
SWEP.ViewModel = "models/weapons/maclunkey/c_maclunkey.mdl"
SWEP.WorldModel = "models/weapons/maclunkey/w_maclunkey.mdl"
SWEP.ViewModelFlip = false
SWEP.Weight = 1
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.AutoSpawnable = false
SWEP.Primary.Recoil = .9
SWEP.Primary.Damage = 1000
SWEP.Primary.NumShots = 1
SWEP.Primary.Cone = 0
SWEP.Primary.ClipSize = 1
SWEP.Primary.Delay = 2.0
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Primary.Tracer = "effect_sw_laser_red"
SWEP.Kind = WEAPON_ROLE
SWEP.AllowDrop = false
SWEP.NoSights = true

function SWEP:Initialize()
    self:SetDeploySpeed(self.WeaponDeploySpeed)

    if ConVarExists("ttt_maclunkey_gun_damage") then
        self.Primary.Damage = GetConVar("ttt_maclunkey_gun_damage"):GetInt()
    end

    if CLIENT then
        self.PrintName = ROLE_STRINGS[ROLE_MACLUNKEY] .. " Gun"
    end
end

function SWEP:Deploy()
    if SERVER and self:GetOwner():Alive() and not self:GetOwner():IsSpec() then
        -- Plays the sound twice... so it's louder
        for i = 1, 2 do
            self:GetOwner():EmitSound(DrawSound, 85, 100, 1, CHAN_AUTO)
        end
    end

    self.Primary.Cone = self.HipCone

    return true
end

function SWEP:Holster()
    return true
end

function SWEP:OnDrop()
    if SERVER then
        self:Remove()
    end
end

function SWEP:ShouldDropOnDie()
    return false
end

function SWEP:PrimaryAttack()
    if (not self:CanPrimaryAttack()) then return end
    self:GetOwner():SetNWBool("RevealedMaclunkey", true)
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self:Shoot()
    self:TakePrimaryAmmo(1)

    timer.Simple(0.1, function()
        if SERVER then
            self:GetOwner():GiveDelayedShopItems()
            self:Remove()
        end
    end)
end

function SWEP:Shoot()
    local cone = self.Primary.Cone
    local bullet = {}
    bullet.Num = 1
    bullet.Src = self:GetOwner():GetShootPos()
    bullet.Dir = self:GetOwner():GetAimVector()
    bullet.Spread = Vector(cone, cone, 0)
    bullet.Tracer = 1
    bullet.Force = 2
    bullet.Damage = self.Primary.Damage
    bullet.TracerName = self.Primary.Tracer
    bullet.Callback = maclunkey_bullet
    self:GetOwner():FireBullets(bullet)
    self:GetOwner():EmitSound(ShootSound, 75, 100, 1, CHAN_AUTO)
end