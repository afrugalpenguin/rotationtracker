local Addon = select(1, ...)

local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("SilentRotate")

function SilentRotate:CreateConfig()

	local function get(info)
		return SilentRotate.db.profile[info[#info]]
	end

	local function set(info, value)
		SilentRotate.db.profile[info[#info]] = value
        SilentRotate:applySettings()
	end

    local function refreshNames()
        for _, hunter in pairs(SilentRotate.hunterTable) do
            SilentRotate:setHunterName(hunter)
        end
    end

    local function refreshFrameColors()
        for _, hunter in pairs(SilentRotate.hunterTable) do
            SilentRotate:setHunterFrameColor(hunter)
        end
    end

    local function getColor(info)
        return SilentRotate.db.profile[info[#info]][1], SilentRotate.db.profile[info[#info]][2], SilentRotate.db.profile[info[#info]][3]
    end

    local function setColor(info, r, g, b, suffix)
        local colorName = info[#info]
        local suffixIndex = string.find(colorName, suffix)
        if suffixIndex > 0 then
            -- Exclude the trailing suffix string
            colorName = string.sub(colorName, 1, suffixIndex-1)
        end
        SilentRotate.colors[colorName] = CreateColor(r, g, b)
        set(info, {r,g,b})
    end

    local function setFgColor(info, r, g, b)
        setColor(info, r, g, b, "Color")
        refreshNames()
    end

    local function setBgColor(info, r, g, b)
        setColor(info, r, g, b, "BackgroundColor")
        refreshFrameColors()
    end

    local function setNameTag(...)
        set(...)
        refreshNames()
    end

	local options = {
		name = "SilentRotate",
		type = "group",
		get = get,
		set = set,
		icon = "",
		args = {
            general = {
                name = L['SETTING_GENERAL'],
                type = "group",
                order = 1,
                args = {
					descriptionText = {
						name = "SilentRotate " .. SilentRotate.version .. " by Vinny-Illidan, based on the TranqRotate code by Slivo-Sulfuron\n",
						type = "description",
						width = "full",
						order = 1,
					},
					repoLink = {
						name = L['SETTING_GENERAL_REPORT'] .. " https://github.com/ennvina/silentrotate\n",
						type = "description",
						width = "full",
						order = 2,
					},
                    -- @todo : find a way to space widget properly
					spacer3 = {
						name = ' ',
						type = "description",
						width = "full",
						order = 3,
					},
					baseVersion = {
						name = L['SETTING_GENERAL_DESC'],
						type = "description",
						width = "full",
						order = 4,
					},
                    -- @todo : find a way to space widget properly
					spacer4 = {
						name = ' ',
						type = "description",
						width = "full",
						order = 5,
					},
                    lock = {
                        name = L["LOCK_WINDOW"],
                        desc = L["LOCK_WINDOW_DESC"],
                        type = "toggle",
                        order = 6,
                        width = "double",
                    },
                    hideNotInRaid = {
                        name = L["HIDE_WINDOW_NOT_IN_RAID"],
                        desc = L["HIDE_WINDOW_NOT_IN_RAID_DESC"],
                        type = "toggle",
                        order = 7,
                        width = "double",
                    },
                    doNotShowWindowOnRaidJoin = {
                        name = L["DO_NOT_SHOW_WHEN_JOINING_RAID"],
                        desc = L["DO_NOT_SHOW_WHEN_JOINING_RAID_DESC"],
                        type = "toggle",
                        order = 8,
                        width = "full",
                    },
                    showWindowWhenTargetingBoss = {
                        name = L["SHOW_WHEN_TARGETING_BOSS"],
                        desc = L["SHOW_WHEN_TARGETING_BOSS_DESC"],
                        type = "toggle",
                        order = 9,
                        width = "full",
                    },
                    testHeader = {
                        name = L["TEST_MODE_HEADER"],
                        type = "header",
                        order = 10,
                    },
                    ToggleArcaneShotTestingDesc = {
                        name = L['ENABLE_ARCANE_SHOT_TESTING_DESC'],
                        type = "description",
                        width = "full",
                        order = 11,
                    },
                    spacer12 = {
                        name = ' ',
                        type = "description",
                        width = "full",
                        order = 12,
                    },
                    ToggleArcaneShotTesting = {
                        name = L["ENABLE_ARCANE_SHOT_TESTING"],
                        type = "execute",
                        order = 13,
                        func = function() SilentRotate.toggleArcaneShotTesting() end
                    }
                }
            },
            modes = {
                name = L['SETTING_MODES'],
                type = "group",
                order = 2,
                args = {
                    tranqModeHeader = {
                        type = "header",
                        order = 1,
                    },
                    tranqModeButton = {
                        name = L["TRANQ_MODE_FULL_NAME"],
                        desc = string.format(L["MODE_BUTTON_DESC"], L["TRANQ_MODE_FULL_NAME"]),
                        type = "toggle",
                        order = 2,
                        width = "full",
                    },
                    tranqModeText = {
                        name = L["MODE_LABEL"],
                        desc = string.format(L["MODE_LABEL_DESC"], L["TRANQ_MODE_FULL_NAME"]),
                        type = "input",
                        order = 3,
                        width = "half",
                        hidden = function() return not SilentRotate.db.profile.tranqModeButton end,
                    },
                    loathebModeHeader = {
                        type = "header",
                        order = 4,
                    },
                    loathebModeButton = {
                        name = L["LOATHEB_MODE_FULL_NAME"],
                        desc = string.format(L["MODE_BUTTON_DESC"], L["LOATHEB_MODE_FULL_NAME"]),
                        type = "toggle",
                        order = 5,
                        width = "full",
                    },
                    loathebModeText = {
                        name = L["MODE_LABEL"],
                        desc = string.format(L["MODE_LABEL_DESC"], L["LOATHEB_MODE_FULL_NAME"]),
                        type = "input",
                        order = 6,
                        width = "half",
                        hidden = function() return not SilentRotate.db.profile.loathebModeButton end,
                    },
                    distractModeHeader = {
                        type = "header",
                        order = 7,
                    },
                    distractModeButton = {
                        name = L["DISTRACT_MODE_FULL_NAME"],
                        desc = string.format(L["MODE_BUTTON_DESC"], L["DISTRACT_MODE_FULL_NAME"]),
                        type = "toggle",
                        order = 8,
                        width = "full",
                    },
                    distractModeText = {
                        name = L["MODE_LABEL"],
                        desc = string.format(L["MODE_LABEL_DESC"], L["DISTRACT_MODE_FULL_NAME"]),
                        type = "input",
                        order = 9,
                        width = "half",
                        hidden = function() return not SilentRotate.db.profile.distractModeButton end,
                    },
                    --[[ Do not allow Razuvious mode for now
                    razModeHeader = {
                        type = "header",
                        order = 10,
                    },
                    razModeButton = {
                        name = L["RAZ_MODE_FULL_NAME"],
                        desc = string.format(L["MODE_BUTTON_DESC"], L["RAZ_MODE_FULL_NAME"]),
                        type = "toggle",
                        order = 11,
                        width = "full",
                    },
                    razModeText = {
                        name = L["MODE_LABEL"],
                        desc = string.format(L["MODE_LABEL_DESC"], L["RAZ_MODE_FULL_NAME"]),
                        type = "input",
                        order = 12,
                        width = "half",
                        hidden = function() return not SilentRotate.db.profile.razModeButton end,
                    },
                    ]]
                }
            },
            announces = {
                name = L['SETTING_ANNOUNCES'],
                type = "group",
                order = 3,
                args = {
                    enableAnnounces = {
                        name = L["ENABLE_ANNOUNCES"],
                        desc = L["ENABLE_ANNOUNCES_DESC"],
                        type = "toggle",
                        order = 1,
                        width = "double",
                    },
                    announceHeader = {
                        name = L["ANNOUNCES_MESSAGE_HEADER"],
                        type = "header",
                        order = 20,
                    },
                    channelType = {
                        name = L["MESSAGE_CHANNEL_TYPE"],
                        desc = L["MESSAGE_CHANNEL_TYPE_DESC"],
                        type = "select",
                        order = 21,
                        values = {
                            ["RAID_WARNING"] = L["CHANNEL_RAID_WARNING"],
                            ["SAY"] = L["CHANNEL_SAY"],
                            ["YELL"] = L["CHANNEL_YELL"],
                            ["PARTY"] = L["CHANNEL_PARTY"],
                            ["RAID"] = L["CHANNEL_RAID"],
                            ["GUILD"] = L["CHANNEL_GUILD"]
                        },
                    },
                    spacer22 = {
                        name = ' ',
                        type = "description",
                        width = "normal",
                        order = 22,
                    },
                    announceSuccessMessage = {
                        name = L["SUCCESS_MESSAGE_LABEL"],
                        type = "input",
                        order = 23,
                        width = "double",
                    },
                    announceFailMessage = {
                        name = L["FAIL_MESSAGE_LABEL"],
                        type = "input",
                        order = 24,
                        width = "double",
                    },
                    whisperFailMessage = {
                        name = L["FAIL_WHISPER_LABEL"],
                        type = "input",
                        order = 25,
                        width = "double",
                    },
                    announceLoathebMessage = {
                        name = L["LOATHEB_MESSAGE_LABEL"],
                        type = "input",
                        order = 23,
                        width = "double",
                    },
                    setupBroadcastHeader = {
                        name = L["BROADCAST_MESSAGE_HEADER"],
                        type = "header",
                        order = 30,
                    },
                    rotationReportChannelType = {
                        name = L["MESSAGE_CHANNEL_TYPE"],
                        type = "select",
                        order = 31,
                        values = {
                            ["CHANNEL"] = L["CHANNEL_CHANNEL"],
                            ["RAID_WARNING"] = L["CHANNEL_RAID_WARNING"],
                            ["SAY"] = L["CHANNEL_SAY"],
                            ["YELL"] = L["CHANNEL_YELL"],
                            ["PARTY"] = L["CHANNEL_PARTY"],
                            ["RAID"] = L["CHANNEL_RAID"],
                            ["GUILD"] = L["CHANNEL_GUILD"]
                        },
                        set = function(info, value) set(info,value) LibStub("AceConfigRegistry-3.0", true):NotifyChange("SilentRotate") end
                    },
                    setupBroadcastTargetChannel = {
                        name = L["MESSAGE_CHANNEL_NAME"],
                        desc = L["MESSAGE_CHANNEL_NAME_DESC"],
                        type = "input",
                        order = 32,
                        hidden = function() return not (SilentRotate.db.profile.rotationReportChannelType == "CHANNEL") end,
                    },
                    useMultilineRotationReport = {
                        name = L["USE_MULTILINE_ROTATION_REPORT"],
                        desc = L["USE_MULTILINE_ROTATION_REPORT_DESC"],
                        type = "toggle",
                        order = 40,
                        width = "full",
                    },
                }
            },
            names = {
                name = L['SETTING_NAMES'],
                type = "group",
                order = 4,
                args = {
                    nameTagHeader = {
                        name = L["NAME_TAG_HEADER"],
                        type = "header",
                        order = 1,
                    },
                    useClassColor = {
                        name = L["USE_CLASS_COLOR"],
                        desc = L["USE_CLASS_COLOR_DESC"],
                        type = "toggle",
                        order = 2,
                        width = "full",
                        set = setNameTag,
                    },
                    useNameOutline = {
                        name = L["USE_NAME_OUTLINE"],
                        desc = L["USE_NAME_OUTLINE_DESC"],
                        type = "toggle",
                        order = 3,
                        width = "full",
                        set = setNameTag,
                    },
                    appendGroup = {
                        name = L["APPEND_GROUP"],
                        desc = L["APPEND_GROUP_DESC"],
                        type = "toggle",
                        order = 4,
                        width = "full",
                        set = setNameTag,
                    },
                    groupSuffix = {
                        name = L["GROUP_SUFFIX_LABEL"],
                        desc = L["GROUP_SUFFIX_LABEL_DESC"],
                        type = "input",
                        order = 5,
                        width = "half",
                        set = setNameTag,
                        hidden = function() return not SilentRotate.db.profile.appendGroup end,
                    },
                    groupSuffixColor = {
                        name = L["GROUP_SUFFIX_COLOR"],
                        desc = L["GROUP_SUFFIX_COLOR_DESC"],
                        type = "color",
                        order = 6,
                        get = getColor,
                        set = setFgColor,
                        hidden = function() return not SilentRotate.db.profile.appendGroup end,
                    },
                    backgroundHeader = {
                        name = L["BACKGROUND_HEADER"],
                        type = "header",
                        order = 7,
                    },
                    neutralBackgroundColor = {
                        name = L["NEUTRAL_BG"],
                        desc = L["NEUTRAL_BG_DESC"],
                        type = "color",
                        order = 8,
                        width = "full",
                        get = getColor,
                        set = setBgColor,
                    },
                    activeBackgroundColor = {
                        name = L["ACTIVE_BG"],
                        desc = L["ACTIVE_BG_DESC"],
                        type = "color",
                        order = 9,
                        width = "full",
                        get = getColor,
                        set = setBgColor,
                    },
                    deadBackgroundColor = {
                        name = L["DEAD_BG"],
                        desc = L["DEAD_BG_DESC"],
                        type = "color",
                        order = 10,
                        width = "full",
                        get = getColor,
                        set = setBgColor,
                    },
                    offlineBackgroundColor = {
                        name = L["OFFLINE_BG"],
                        desc = L["OFFLINE_BG_DESC"],
                        type = "color",
                        order = 11,
                        width = "full",
                        get = getColor,
                        set = setBgColor,
                    },
                }
            },
            sounds = {
                name = L['SETTING_SOUNDS'],
                type = "group",
                order = 5,
                args = {
                    enableNextToTranqSound = {
                        name = L["ENABLE_NEXT_TO_TRANQ_SOUND"],
                        desc = L["ENABLE_NEXT_TO_TRANQ_SOUND"],
                        type = "toggle",
                        order = 1,
                        width = "full",
                    },
                    enableTranqNowSound = {
                        name = L["ENABLE_TRANQ_NOW_SOUND"],
                        desc = L["ENABLE_TRANQ_NOW_SOUND"],
                        type = "toggle",
                        order = 2,
                        width = "full",
                    },
                    tranqNowSound = {
                        name = L["TRANQ_NOW_SOUND_CHOICE"],
                        desc = L["TRANQ_NOW_SOUND_CHOICE"],
                        type = "select",
                        style = "dropdown",
                        order = 3,
                        values = SilentRotate.constants.tranqNowSounds,
                        set = function(info, value)
                            set(info, value)
                            PlaySoundFile(SilentRotate.constants.sounds.alarms[value])
                        end
                    },
                    baseVersion = {
                        name = L['DBM_SOUND_WARNING'],
                        type = "description",
                        width = "full",
                        order = 4,
                    },
                }
            },
        }
	}

    AceConfigRegistry:RegisterOptionsTable(Addon, options, true)
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

    AceConfigDialog:AddToBlizOptions(Addon, nil, nil, "general")
    AceConfigDialog:AddToBlizOptions(Addon, L['SETTING_ANNOUNCES'], Addon, "announces")
    AceConfigDialog:AddToBlizOptions(Addon, L["SETTING_PROFILES"], Addon, "profile")

    AceConfigDialog:SetDefaultSize(Addon, 895, 570)

end

