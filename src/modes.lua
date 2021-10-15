local Addon = select(1, ...)
local SilentRotate = select(2, ...)
local L = LibStub("AceLocale-3.0"):GetLocale("SilentRotate")

-- Get the mode from a mode name
-- If modeName is nil, get the current mode
function SilentRotate:getMode(modeName)
    if not modeName then
        modeName = SilentRotate.db.profile.currentMode
    end

    if modeName and modeName:sub(-1) == 'z' then -- All old mode names end with 'z'
        modeName = SilentRotate.backwardCompatibilityModeMap[modeName] or modeName
    end

    -- return the mode object, or TranqShot as the default mode if no mode is set
    return SilentRotate.modes[modeName or SilentRotate.modes.tranqShot.modeName]
end

-- Activate the specific mode
function SilentRotate:activateMode(modeName)
    local currentMode = self:getMode()
    local paramMode = self:getMode(modeName)
    if currentMode.modeName == paramMode.modeName then return end

    oldFrame = SilentRotate.mainFrame.modeFrames[currentMode.modeName]
    if oldFrame then
        oldFrame.texture:SetColorTexture(SilentRotate.colors.darkBlue:GetRGB())
    end

    newFrame = SilentRotate.mainFrame.modeFrames[modeName]
    if newFrame then
        SilentRotate.db.profile.currentMode = modeName
        newFrame.texture:SetColorTexture(SilentRotate.colors.blue:GetRGB())
        SilentRotate:updateRaidStatus()
        local AceConfigDialog = LibStub("AceConfigDialog-3.0")
        AceConfigDialog:ConfigTableChanged("", Addon)
    end
end

-- Return true if the player is recommended for a specific mode
-- If className is nil, the class is fetched from the unit
-- If mode is nil, use the current mode instead
function SilentRotate:isPlayerWanted(unit, className, modeName)
    if className == nil then
        className = (select(2,UnitClass(unit)))
    end

    local mode = self:getMode(modeName)
    if mode and mode.wanted then
        if type(mode.wanted) == 'string' then
            return className == mode.wanted
        elseif type(mode.wanted) == 'table' then
            for _, c in pairs(mode.wanted) do
                if className == c then
                    return true
                end
            end
            return false
        elseif type(mode.wanted) == 'function' then
            local raceName = select(2,UnitRace(unit))
            return mode.wanted(mode, className, raceName)
        end
    end

    return nil
end

-- Return true if the spellId/spellName matches one of the spells of spellWanted
-- spellWanted can be either a spell id, a spell name, a list of ids and names, or a function(spellId, spellName)
function SilentRotate:isSpellInteresting(spellId, spellName, spellWanted)

    if type(spellWanted) == 'number' then -- Single spell ID
        return spellWanted == spellId

    elseif type(spellWanted) == 'string' then -- Single spell name
        return spellWanted == spellName

    elseif type(spellWanted) == 'table' then -- List of spell IDs and/or names
        for _, s in pairs(spellWanted) do
            if type(s) == 'number' and s == spellId
            or type(s) == 'string' and s == spellName then
                return true
            end
        end
        return false

    elseif type(spellWanted) == 'function' then -- Functor
        return spellWanted(spellId, spellName)
    end

    return false
end

-- Get the default duration known for a specific mode
-- If mode is nil, use the current mode instead
function SilentRotate:getModeCooldown(modeName)
    local mode = self:getMode(modeName)

    if mode and mode.cooldown then
        if type(mode.cooldown) == 'number' then
            return mode.cooldown
        elseif type(mode.cooldown) == 'function' then
            return mode.cooldown()
        end
    end

    return nil
end

-- Get the default duration known for an effect (e.g. buff) given by a specific mode
-- If mode is nil, use the current mode instead
-- If the mode provides no effect, the returned duration is zero
function SilentRotate:getModeEffectDuration(modeName)
    local mode = self:getMode(modeName)

    if mode and mode.effectDuration then
        if type(mode.effectDuration) == 'number' then
            return mode.effectDuration
        elseif type(mode.effectDuration) == 'function' then
            return mode.effectDuration()
        end
    end

    return nil
end

-- Each mode has a specific Broadcast text so that it does not conflict with other modes
function SilentRotate:getBroadcastHeaderText()
    local mode = self:getMode()

    if mode and type(mode.modeName) == 'string' then
        return string.format(L['BROADCAST_HEADER_TEXT'], L[mode.modeNameUpper.."_MODE_FULL_NAME"])
    end

    return ''
end


SilentRotate.modes = {
    tranqShot = {
        oldModeName = 'hunterz',
        project = true,
        default = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC,
        wanted = 'HUNTER',
        cooldown = 20,
        -- effectDuration = nil,
        canFail = true,
        spell = function(self, spellId, spellName)
            return spellName == GetSpellInfo(19801) -- 'Tranquilizing Shot'
                or spellName == GetSpellInfo(14287) and SilentRotate.testMode -- 'Arcane Shot'
        end,
        -- auraTest = nil,
        customCombatlogFunc = function(self, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, spellId, spellName)
            if event == "SPELL_AURA_APPLIED" and SilentRotate:isBossFrenzy(spellName, sourceGUID) and SilentRotate:isPlayerNextTranq() then
                SilentRotate:throwTranqAlert()
            elseif event == "UNIT_DIED" and SilentRotate:isTranqableBoss(destGUID) then
                SilentRotate:resetRotation()
            end
        end,
        targetGUID = function(self, sourceGUID, destGUID) return destGUID end,
        -- buffName = nil,
        -- buffCanReturn = nil,
        -- customTargetName = nil,
        announceArg = function(self, hunter, destName) return destName end,
    },

    loatheb = {
        oldModeName = 'healerz',
        project = true,
        default = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC,
        wanted = {'PRIEST', 'PALADIN', 'SHAMAN', 'DRUID'},
        cooldown = 60,
        -- effectDuration = nil,
        -- canFail = nil,
        -- spell = nil,
        auraTest = function(self, spellId, spellName)
            return SilentRotate.testMode and spellId == 11196 -- 11196 is the spell ID of "Recently Bandaged"
                or spellId == 29184 -- priest debuff
                or spellId == 29195 -- druid debuff
                or spellId == 29197 -- paladin debuff
                or spellId == 29199 -- shaman debuff
        end,
        -- customCombatlogFunc = nil,
        -- effectDuration = nil,
        -- targetGUID = nil,
        -- buffName = nil,
        -- buffCanReturn = nil,
        -- customTargetName = nil,
        announceArg = function(self, hunter, destName) return destName end,
    },

    distract = {
        oldModeName = 'roguez',
        project = true,
        default = false,
        wanted = 'ROGUE',
        cooldown = 30,
        effectDuration = 10,
        canFail = true,
        spell = GetSpellInfo(1725),
        -- auraTest = nil,
        -- customCombatlogFunc = nil,
        -- targetGUID = nil,
        -- buffName = nil,
        -- buffCanReturn = nil,
        -- customTargetName = nil,
        announceArg = function(self, hunter, destName) return destName end,
    },

    fearWard = {
        oldModeName = 'fearz',
        project = true,
        default = true,
        wanted = 'Priest',
        cooldown = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) and 30 or 180,
        effectDuration = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) and 600 or 180,
        canFail = false,
        spell = GetSpellInfo(6346),
        -- auraTest = nil,
        -- customCombatlogFunc = nil,
        targetGUID = function(self, sourceGUID, destGUID) return destGUID end,
        buffName = function(self, spellId, spellName) return spellName end,
        buffCanReturn = false,
        -- customTargetName = nil,
        announceArg = function(self, hunter, destName) return destName end,
    },

    aoeTaunt = {
        oldModeName = 'tauntz',
        project = true,
        default = false,
        wanted = {'WARRIOR', 'DRUID'},
        cooldown = 600,
        effectDuration = 6,
        canFail = true,
        spell = {
            GetSpellInfo(1161), -- warrior's Challenging Shout
            GetSpellInfo(5209), -- druid's Challenging Roar
        },
        -- auraTest = nil,
        -- customCombatlogFunc = nil,
        -- targetGUID = nil,
        -- buffName = nil,
        -- buffCanReturn = nil,
        -- customTargetName = nil,
        announceArg = function(self, hunter, destName) return destName end,
    },

    misdi = {
        oldModeName = 'misdiz',
        project = WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC,
        default = WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC,
        wanted = 'HUNTER',
        cooldown = 120,
        effectDuration = 30,
        canFail = false,
        spell = GetSpellInfo(34477),
        -- auraTest = nil,
        -- customCombatlogFunc = nil,
        targetGUID = function(self, sourceGUID, destGUID) return destGUID end,
        buffName = function(self, spellId, spellName) return spellName end,
        buffCanReturn = false,
        -- customTargetName = nil,
        announceArg = function(self, hunter, destName) return destName end,
    },

    bloodlust = {
        oldModeName = 'shamanz',
        project = WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC,
        default = WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC,
        wanted = 'SHAMAN',
        cooldown = 600,
        effectDuration = 40,
        canFail = false,
        spell = {
            GetSpellInfo(2825), -- Bloodlust
            GetSpellInfo(32182), -- Heroism
        },
        -- auraTest = nil,
        -- customCombatlogFunc = nil,
        targetGUID = function(self, sourceGUID, destGUID) return sourceGUID end, -- Target is the caster itself
        buffName = function(self, spellId, spellName) return spellName end,
        buffCanReturn = false,
        customTargetName = function(self, hunter, targetName) return string.format(SilentRotate.db.profile.groupSuffix, hunter.subgroup or 0) end,
        announceArg = function(self, hunter, destName) return hunter.subgroup or 0 end,
    },

    grounding = {
        project = true,
        default = false,
        wanted = 'SHAMAN',
        cooldown = 15,
        effectDuration = 45,
        canFail = false,
        spell = GetSpellInfo(8177),
        -- auraTest = nil,
        -- customCombatlogFunc = nil,
        targetGUID = function(self, sourceGUID, destGUID) return sourceGUID end, -- Target is the caster itself
        buffName = function(self, spellId, spellName) return self.metadata.groundingTotemEffectName end, -- Buff is the totem effect
        buffCanReturn = true,
        customTargetName = function(self, hunter, targetName) return string.format(SilentRotate.db.profile.groupSuffix, hunter.subgroup or 0) end,
        announceArg = function(self, hunter, destName) return hunter.subgroup or 0 end,
        metadata = { groundingTotemEffectName = GetSpellInfo(8178) }, -- The buff is the name from spellId+1, not from spellId
    },

    brez = {
        project = true,
        default = false,
        wanted = 'DRUID',
        cooldown = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) and 1800 or 1200,
        -- effectDuration = nil,
        canFail = false,
        spell = GetSpellInfo(20484), -- Rebirth Rank 1
        -- auraTest = nil,
        -- customCombatlogFunc = nil,
        targetGUID = function(self, sourceGUID, destGUID) return destGUID end,
        -- buffName = nil,
        -- buffCanReturn = nil,
        -- customTargetName = nil,
        announceArg = function(self, hunter, destName) return destName end,
    },

    innerv = {
        project = true,
        default = false,
        wanted = 'DRUID',
        cooldown = 360,
        effectDuration = 20,
        canFail = false,
        spell = GetSpellInfo(29166),
        -- auraTest = nil,
        -- customCombatlogFunc = nil,
        targetGUID = function(self, sourceGUID, destGUID) return destGUID end,
        buffName = function(self, spellId, spellName) return spellName end,
        buffCanReturn = false,
        -- customTargetName = nil,
        announceArg = function(self, hunter, destName) return destName end,
    },
}

-- Create a backward compatibility map between old mode names and new ones
-- And fill some attributes automatically
SilentRotate.backwardCompatibilityModeMap = {}
for modeName, mode in pairs(SilentRotate.modes) do
    mode.modeName = modeName
    mode.modeNameUpper = modeName:upper()
    mode.modeNameFirstUpper = modeName:gsub("^%l", string.upper)
    if type(mode.oldModeName) == 'string' then
        SilentRotate.backwardCompatibilityModeMap[mode.oldModeName] = modeName
    end
end
