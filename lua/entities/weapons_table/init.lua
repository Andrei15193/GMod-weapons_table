AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

util.AddNetworkString("Andrei15193_Weapons_Table_Show")
util.AddNetworkString("Andrei15193_Weapons_Table_Update")

function ENT:Initialize()
    self.timerId = "Andrei15193_Weapons_Table_Timer_" .. self:EntIndex()
    self.hookId = "Andrei15193_Weapons_Table_EquipOrRemove_Hook_" .. self:EntIndex()

    self.state = {
        entityIndex = self:EntIndex(),
        isEnabled = false,
        timerDelayInSeconds = 2,
        weaponsConfig = {}
    }
    self.selectedWeaponsCache = {}
    self.weapon = nil

    self:AddPredefinedWeapons()
    self:AddScriptedWeapons()

    self:SetModel("models/props_c17/FurnitureTable002a.mdl")
    self:SetUseType(SIMPLE_USE)

    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:PhysicsInit(SOLID_VPHYSICS)

    self:PhysWake()

    local copy = self;
    hook.Add("WeaponEquip", self.hookId, function(weapon)
        copy:OnWeaponEquipedOrRemoved(weapon)
    end)
    hook.Add("EntityRemoved", self.hookId, function(entity)
        copy:OnWeaponEquipedOrRemoved(entity)
    end)
    net.Receive("Andrei15193_Weapons_Table_Update", function()
        copy:HandleUpdateNetMessage()
    end)
end

function ENT:Use(activator, caller)
    local compressedState = util.Compress(util.TableToJSON(self.state))
    local compressedStateLength = #compressedState

    net.Start("Andrei15193_Weapons_Table_Show")
    net.WriteInt(compressedStateLength, 32)
    net.WriteData(compressedState, compressedStateLength)
    net.Send(activator)
end

function ENT:HandleUpdateNetMessage()
    local compressedUpdatedStateLength = net.ReadInt(32)
    local compressedUpdatedState = net.ReadData(compressedUpdatedStateLength)
    local updatedState = util.JSONToTable(util.Decompress(compressedUpdatedState))

    local oldIsEnabled = self.state.isEnabled
    local newIsEnabled = updatedState.isEnabled

    self.state.timerDelayInSeconds = updatedState.timerDelayInSeconds
    self.state.weaponsConfig = updatedState.weaponsConfig
    
    self.selectedWeaponsCache = {}
    for weaponConfigKey, weaponConfig in pairs(self.state.weaponsConfig) do
        if weaponConfig.spawn then
            table.insert(self.selectedWeaponsCache, weaponConfig.className)
        end
    end

    if oldIsEnabled != newIsEnabled then
        self.state.isEnabled = newIsEnabled
        if newIsEnabled then
            self:SpawnWeapon()
        else
            timer.Remove(self.timerId)
        end
    end
end

function ENT:SpawnWeapon()
    if self.state.isEnabled then
        weapon = self:CreateWeapon()
        if weapon != nil then
            weapon:Spawn()
            self:RotateToFitTable(weapon)
            self:PositionOnTable(weapon)
            self.weapon = weapon
        end
    end
end

function ENT:CreateWeapon()
    if #self.selectedWeaponsCache == 0 then
        return nil
    end

    return ents.Create(self.selectedWeaponsCache[math.random(#self.selectedWeaponsCache)])
end

function ENT:OnWeaponEquipedOrRemoved(weapon)
    if self.weapon == weapon then
        self.weapon = nil
        local copy = self
        timer.Create(self.timerId, self.state.timerDelayInSeconds, 1, function()
            copy:SpawnWeapon()
        end)
    end
end

function ENT:RotateToFitTable(weapon)
    local tablePosition = self:GetPos()
    local tableAngle = self:GetAngles()

    local weaponMinimumModelBounds, weaponMaximumModelBounds = weapon:GetModelBounds()
    local weaponBoundLengths = (weaponMaximumModelBounds - weaponMinimumModelBounds)
    local weaponXOffset, weaponYOffset, weaponZOffset = weaponMinimumModelBounds:Unpack()

    local weaponAngle = self:GetAngles()
    local weaponXAxis = weaponAngle:Right()
    local weaponYAxis = weaponAngle:Forward()
    local weaponZAxis = weaponAngle:Up()

    if weaponBoundLengths.x > weaponBoundLengths.y and weaponBoundLengths.x > weaponBoundLengths.z then
        weaponAngle:RotateAroundAxis(weaponZAxis, 90)
        weaponBoundLengths:SetUnpacked(weaponBoundLengths.y, weaponBoundLengths.x, weaponBoundLengths.z)

        local temporary = weaponXAxis
        weaponXAxis = weaponYAxis
        weaponYAxis = temporary
    end

    if weaponBoundLengths.z > weaponBoundLengths.x then
        weaponAngle:RotateAroundAxis(weaponYAxis, 90)
        weaponBoundLengths:SetUnpacked(weaponBoundLengths.z, weaponBoundLengths.y, weaponBoundLengths.x)
    end

    weapon:SetAngles(weaponAngle)
end

function ENT:PositionOnTable(weapon)
    local tablePosition = self:GetPos()
    local tableAngle = self:GetAngles()
    local _, tableMaximumModelBounds = self:GetModelBounds()
    local tableTopOffset = tableMaximumModelBounds.z

    local weaponMinimumModelBounds, weaponMaximumModelBounds = weapon:GetModelBounds()
    local weaponPositionOffset = Vector(0, 0, tableTopOffset - weaponMinimumModelBounds.z + 1)
    weaponPositionOffset:Rotate(tableAngle)

    local weaponBoundsCenter = (weaponMinimumModelBounds + weaponMaximumModelBounds) / 2
    weaponBoundsCenter:Rotate(weapon:GetAngles())
    weaponBoundsCenter:SetUnpacked(weaponBoundsCenter.x, weaponBoundsCenter.y, 0)

    local weaponPosition = tablePosition + weaponPositionOffset - weaponBoundsCenter
    weapon:SetPos(weaponPosition)
end

function ENT:AddPredefinedWeapons()
    self.state.weaponsConfig["gmod_tool"] = {
        printName = "#GMOD_ToolGun",
        className = "gmod_tool",
        spawn = false
    }
    self.state.weaponsConfig["gmod_camera"] = {
        printName = "#GMOD_Camera",
        className = "gmod_camera",
        spawn = false
    }
    self.state.weaponsConfig["weapon_physgun"] = {
        printName = "#GMOD_Physgun",
        className = "weapon_physgun",
        spawn = false
    }
    self.state.weaponsConfig["weapon_357"] = {
        printName = "#HL2_357Handgun",
        className = "weapon_357",
        spawn = false
    }
    self.state.weaponsConfig["weapon_pistol"] = {
        printName = "#HL2_Pistol",
        className = "weapon_pistol",
        spawn = false
    }
    self.state.weaponsConfig["weapon_bugbait"] = {
        printName = "#HL2_Bugbait",
        className = "weapon_bugbait",
        spawn = false
    }
    self.state.weaponsConfig["weapon_crossbow"] = {
        printName = "#HL2_Crossbow",
        className = "weapon_crossbow",
        spawn = false
    }
    self.state.weaponsConfig["weapon_crowbar"] = {
        printName = "#HL2_Crowbar",
        className = "weapon_crowbar",
        spawn = false
    }
    self.state.weaponsConfig["weapon_frag"] = {
        printName = "#HL2_Grenade",
        className = "weapon_frag",
        spawn = false
    }
    self.state.weaponsConfig["weapon_physcannon"] = {
        printName = "#HL2_GravityGun",
        className = "weapon_physcannon",
        spawn = false
    }
    self.state.weaponsConfig["weapon_ar2"] = {
        printName = "#HL2_Pulse_Rifle",
        className = "weapon_ar2",
        spawn = false
    }
    self.state.weaponsConfig["weapon_rpg"] = {
        printName = "#HL2_RPG",
        className = "weapon_rpg",
        spawn = false
    }
    self.state.weaponsConfig["weapon_slam"] = {
        printName = "#HL2_SLAM",
        className = "weapon_slam",
        spawn = false
    }
    self.state.weaponsConfig["weapon_shotgun"] = {
        printName = "#HL2_Shotgun",
        className = "weapon_shotgun",
        spawn = false
    }
    self.state.weaponsConfig["weapon_smg1"] = {
        printName = "#HL2_SMG1",
        className = "weapon_smg1",
        spawn = false
    }
    self.state.weaponsConfig["weapon_stunstick"] = {
        printName = "#HL2_StunBaton",
        className = "weapon_stunstick",
        spawn = false
    }
    self.state.weaponsConfig["manhack_welder"] = {
        printName = "#GMOD_ManhackGun",
        className = "manhack_welder",
        spawn = false
    }
    self.state.weaponsConfig["weapon_medkit"] = {
        printName = "#GMOD_MedKit",
        className = "weapon_medkit",
        spawn = false
    }
end

function ENT:AddScriptedWeapons()
    for weaponKey, weapon in pairs(weapons.GetList()) do
        if weapon.Spawnable and !weapon.AdminOnly and weapon.WorldModel != nil and weapon.WorldModel != '' and self.state.weaponsConfig[weapon.ClassName] == nil then
            self.state.weaponsConfig[weapon.ClassName] = {
                printName = (weapon.PrintName or weapon.ClassName),
                className = weapon.ClassName,
                spawn = false
            }
        end
    end
end