include("shared.lua")

ENT.Category = "Weapon Spawners"
ENT.PrintName = "Weapons Table"
ENT.Author = "Andrei15193"
ENT.Contact = "https://github.com/Andrei15193"
ENT.Purpose = "Place and configure weapon spawners for fun."
ENT.Instructions = "Spawn random weapons on a table. To configure the entity press the use key on it and a modal will pop-up with different options. Double click on a weapon to toggle its spawn state."

function ENT:Initialize()
    local copy = self;
    net.Receive("Andrei15193_Weapons_Table_Show", function()
        local compressedStateLength = net.ReadInt(32)
        local compressedState = net.ReadData(compressedStateLength)
        local state = util.JSONToTable(util.Decompress(compressedState))

        copy:OpenEditor(state)
    end)
end

function ENT:Draw()
    self:DrawModel()
end

function ENT:OpenEditor(state)
    local frameTitleHeight = 24
    local frameContentMargin = 10
    local inputMargin = 3
    local labelWidth = 130

    local weaponsConfigList = {}
    for weaponConfigKey, weaponConfig in pairs(state.weaponsConfig) do
        table.insert(weaponsConfigList, {
            printName = weaponConfig.printName,
            className = weaponConfig.className,
            spawn = weaponConfig.spawn
        })
    end

    local frame = vgui.Create("DFrame")
    frame:SetDeleteOnClose(true)
    frame:SetTitle("Weapons Table [" .. state.entityIndex .. "]")
    frame:SetSize(500, math.max(500, ScrH() - 200))

    local frameWidth, frameHeight = frame:GetSize()

    local isEnabledCheckboxLabel = vgui.Create("DLabel", frame, "isEnabledCheckboxLabel")
    local isEnabledCheckboxLabelWidth, isEnabledCheckboxLabelHeight = isEnabledCheckboxLabel:GetSize()
    isEnabledCheckboxLabel:SetText("Is Enabled:")
    isEnabledCheckboxLabel:SetWidth(labelWidth)
    isEnabledCheckboxLabel:SetPos(frameContentMargin, frameTitleHeight + frameContentMargin)
    local isEnabledCheckbox = vgui.Create("DCheckBox", frame, "isEnabledCheckbox")
    isEnabledCheckbox:SetChecked(state.isEnabled)
    isEnabledCheckbox:SetPos(frameContentMargin + labelWidth + inputMargin, frameTitleHeight + frameContentMargin)

    local timerDelayInputLabel = vgui.Create("DLabel", frame, "timerDelayInputLabel")
    local timerDelayInputLabelWidth, timerDelayInputLabelHeight = timerDelayInputLabel:GetSize()
    timerDelayInputLabel:SetText("Respawn Delay (Seconds):")
    timerDelayInputLabel:SetWidth(labelWidth)
    timerDelayInputLabel:SetPos(frameContentMargin, frameTitleHeight + frameContentMargin + isEnabledCheckboxLabelHeight + inputMargin)
    local timerDelayInput = vgui.Create("DNumberWang", frame, "timerDelayInput")
    timerDelayInput:SetDecimals(0)
    timerDelayInput:SetInterval(1)
    timerDelayInput:SetMinMax(1, 600)
    timerDelayInput:SetValue(state.timerDelayInSeconds)
    timerDelayInput:SetPos(frameContentMargin + labelWidth + inputMargin, frameTitleHeight + frameContentMargin + isEnabledCheckboxLabelHeight + inputMargin)

    local saveButton = vgui.Create("DButton", frame, "saveButton")
    local saveButtonWidth, saveButtonHeight = saveButton:GetSize()
    saveButton:SetText("Save")
    saveButton:SetPos(frameContentMargin, frameHeight - frameContentMargin - saveButtonHeight)
    function saveButton:DoClick()
        local updatedWeaponsConfig = {}
        for weaponConfigIndex, weaponConfig in pairs(weaponsConfigList) do
            updatedWeaponsConfig[weaponConfig.className] = {
                printName = weaponConfig.printName,
                className = weaponConfig.className,
                spawn = weaponConfig.spawn
            }
        end

        local updatedState = {
            isEnabled = isEnabledCheckbox:GetChecked(),
            timerDelayInSeconds = math.min(500, math.max(1, timerDelayInput:GetValue())),
            weaponsConfig = updatedWeaponsConfig
        }

        local compressedUpdatedState = util.Compress(util.TableToJSON(updatedState))
        local compressedUpdatedStateLength = #compressedUpdatedState

        net.Start("Andrei15193_Weapons_Table_Update")
        net.WriteInt(compressedUpdatedStateLength, 32)
        net.WriteData(compressedUpdatedState, compressedUpdatedStateLength)
        net.SendToServer()

        frame:Close()
    end

    local cancelButton = vgui.Create("DButton", frame, "cancelButton")
    local cancelButtonWidth, cancelButtonHeight = saveButton:GetSize()
    cancelButton:SetText("Cancel")
    cancelButton:SetPos(frameContentMargin + saveButtonWidth + frameContentMargin, frameHeight - frameContentMargin - cancelButtonHeight)
    function cancelButton:DoClick()
        frame:Close()
    end

    local weaponsConfigListView = vgui.Create("DListView", frame, "weaponsConfigListView")
    weaponsConfigListView:SetMultiSelect(false)
    weaponsConfigListView:AddColumn("Weapon")
    weaponsConfigListView:AddColumn("Spawn? (double click)")
    weaponsConfigListView:SetSize(frameWidth - 2 * frameContentMargin, frameHeight - frameTitleHeight - isEnabledCheckboxLabelHeight - timerDelayInputLabelHeight - inputMargin - saveButtonHeight - 4 * frameContentMargin)
    for weaponConfigIndex, weaponConfig in pairs(weaponsConfigList) do
        weaponsConfigListView:AddLine(language.GetPhrase(weaponConfig.printName), weaponConfig.spawn and 'Yes' or 'No')
    end
    weaponsConfigListView:SortByColumn(1)
    weaponsConfigListView:SetPos(frameContentMargin, frameTitleHeight + frameContentMargin + isEnabledCheckboxLabelHeight + inputMargin + timerDelayInputLabelHeight + frameContentMargin)
    function weaponsConfigListView:DoDoubleClick(lineID, line)
        local weaponConfig = weaponsConfigList[lineID]
        weaponConfig.spawn = !weaponConfig.spawn
        line:SetColumnText(2, weaponConfig.spawn and 'Yes' or 'No')
    end

    frame:SetVisible(true)
    frame:Center()
    frame:MakePopup()
end