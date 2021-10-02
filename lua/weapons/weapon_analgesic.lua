if SERVER then
    AddCSLuaFile()
end

if CLIENT then
    SWEP.PrintName       = "Analgesic Bullet"
    SWEP.Author			= "Squid Matty"
    SWEP.Contact			= "https://steamcommunity.com/id/mattyp92/";
    SWEP.Instructions	= "Shoot the drunk to sober them up"
    SWEP.Slot = 0
    SWEP.SlotPos = 1
    SWEP.IconLetter		= "M"
end

SWEP.Base = "weapon_tttbase"
SWEP.InLoadoutFor = nil
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = false
SWEP.LimitedStock = true

SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.AdminOnly = false
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.HoldType		= "pistol"
SWEP.UseHands = true
SWEP.ViewModel  = "models/weapons/v_pist_deagle.mdl"
SWEP.WorldModel = "models/weapons/w_pist_deagle.mdl"
SWEP.Kind = WEAPON_EQUIP1
SWEP.CanBuy = { ROLE_DETECTIVE, ROLE_TRAITOR }
SWEP.AutoSpawnable = false

SWEP.Primary.ClipSize		= 1
SWEP.Primary.DefaultClip	= 1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo		= "Analgesic"

SWEP.Weight					= 7

local randomChance = CreateConVar( "ttt_analgesic_random_team", 0.50 , {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The chance the drunk joins the user's team" )
local nonDrunk = CreateConVar( "ttt_analgesic_not_drunk", 1 , {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "How it should handle being used on non-drunks" )
local jesterUse = CreateConVar( "ttt_analgesic_jester_use", 0 , {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Can Jester's use it?" )


function SWEP:SecondaryAttack()
    if not self.IronSightsPos then return end
    if self:GetNextSecondaryFire() > CurTime() then return end

    local bIronsights = not self:GetIronsights()

    self:SetIronsights( bIronsights )

    self:SetZoom( bIronsights )

    self:SetNextSecondaryFire( CurTime() + 0.3 )
end

function SWEP:PrimaryAttack()
    local p = self.Owner
    if self:Clip1() <= 0 or not CR_VERSION or not CRVersion("1.2.7") then return end

    self:SendWeaponAnim(self.PrimaryAnim)
    self.Owner:MuzzleFlash()
    self.Owner:SetAnimation( PLAYER_ATTACK1 )

    local Bullet = {}

    Bullet.Dmgtype = "DMG_GENERIC"
    Bullet.Num = num
    Bullet.Spread = Vector( cone, cone, 0 )
    Bullet.Tracer = 0
    Bullet.Force = 0
    Bullet.Damage = 0
    Bullet.Src = p:GetShootPos()
    Bullet.Dir = p:GetAimVector()
    Bullet.TracerName = "TRACER_NONE"

    Bullet.Callback = function(atk, tr, dmg)
        local tgt = tr.Entity
        if SERVER then
            if not IsPlayer(tgt) or tgt:IsSpec() or not tgt:Alive() then return end
            if tgt:IsDrunk() then
                local team = p:GetRoleTeam(true)
                if team ~= ROLE_TEAM_JESTER then
                    if math.random() <= randomChance then
                        tgt:SoberDrunk(team)
                    else
                        tgt:SoberDrunk()
                    end
                elseif jesterUse then
                    tgt:SoberDrunk()
                end
            elseif nonDrunk == 1 then
                tgt:Kill()
            elseif nonDrunk == 2 then
                p:Kill()
            elseif nonDrunk == 3 then
                tgt:SetHealth(tgt:GetMaxHealth())
            end
        end
    end
    self:TakePrimaryAmmo( 1 )
    p:FireBullets( Bullet )
end

function SWEP:Holster()
    self:SetIronsights(false)
    self:SetZoom(false)
    return true
end

function SWEP:PreDrop()
    self:SetZoom(false)
    self:SetIronsights(false)
    return self.BaseClass.PreDrop(self)
end

function SWEP:Reload()
    self.Weapon:DefaultReload( ACT_VM_RELOAD );
    self:SetIronsights( false )
    self:SetZoom(false)
end

function SWEP:WasBought(buyer)
    if IsValid(buyer) then -- probably already self.Owner
        buyer:GiveAmmo( 1, "Analgesic", true )
    end
end