ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.Spawnable = true

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "Enabled", { KeyName = "enabled", Edit = { title = "Enabled", type = "Boolean", order = 0 } })
    self:NetworkVar("Float", 0, "TimerDelayInSeconds", { KeyName = "timerDelayInSeconds", Edit = { title = "Timer Delay (seconds)", type = "Float", order = 1, min = 1, max = 3600 } })

    local boolNetworkVariableSlot = 1
    local order = 2
    local availableWeaponClassNames = {}

    for weaponIndex, weapon in pairs(weapons.GetList()) do
        if weapon.PrintName != nil and !table.HasValue(availableWeaponClassNames, weapon.ClassName) then
            table.insert(availableWeaponClassNames, string.lower(weapon.ClassName))

            self:NetworkVar("Bool", boolNetworkVariableSlot, "spawn_weapon_" .. boolNetworkVariableSlot, { KeyName = "spawn_weapon" .. weapon.ClassName, Edit = { title = weapon.PrintName .. " (" .. weapon.ClassName .. ")", category = "Spawn List", type = "Boolean", order = order } });
            boolNetworkVariableSlot = boolNetworkVariableSlot + 1
            order = order + 1
        end
    end

    if SERVER then
        self:SetTimerDelayInSeconds(2)
        self:NetworkVarNotify("Enabled", self.EnabledChanged)
    end
end