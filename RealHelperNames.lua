-- ============================================================
-- FS25_RealHelperNames.lua
-- by Marcus (Cobra Modding)
-- 
--
-- Version 1.0.0.0
--
--
-- Keine Änderung am Skript ohne meine Erlaubnis
-- ============================================================

RealHelperNames = {}

RealHelperNames.crew = {
    A = {title = "Niklas",    gender = "male",   age = "young"},
    B = {title = "Kevin",     gender = "male",   age = "young"},
    C = {title = "Robin",     gender = "male",   age = "young"},
    D = {title = "Adolf",     gender = "male",   age = "old"},
    E = {title = "Harald",    gender = "male",   age = "old"},
    F = {title = "Sophie",    gender = "female", age = "young"},
    G = {title = "Angelique", gender = "female", age = "young"},
    H = {title = "Mariam",    gender = "female", age = "young", darkerComplexion = true},
    I = {title = "Anna",      gender = "female", age = "old"},
    J = {title = "Tina",      gender = "female", age = "old"}
}

RealHelperNames.crewOrder = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J"}
RealHelperNames.stylePools = {male = {}, female = {}, unknown = {}, bySource = {}}

RealHelperNames.avatarSources = {
    A = "A", B = "A", C = "A", D = "E", E = "E",
    F = "B", G = "D", H = "F", I = "J", J = "H"
}

function RealHelperNames.getStyleLuminance(style)
    local color = style ~= nil and style.faceNeutralDiffuseColor or nil
    if color == nil then
        return 1
    end

    local r = color[1] or color.r or 1
    local g = color[2] or color.g or 1
    local b = color[3] or color.b or 1
    return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

function RealHelperNames.getSkinToneIndex(style)
    local face = style ~= nil and style.configs ~= nil and style.configs.face or nil
    if face == nil then
        return 0
    end
    return face.selectedColorIndex or 0
end

function RealHelperNames.captureBaseStyles(manager)
    if manager == nil or manager.helpers == nil then
        return
    end

    RealHelperNames.stylePools = {male = {}, female = {}, unknown = {}, bySource = {}}

    for index = 1, manager.numHelpers do
        local helper = manager.indexToHelper[index]
        if helper ~= nil and helper.playerStyle ~= nil then
            local style = helper.playerStyle
            local filename = string.lower(style.xmlFilename or style.filename or "")
            local gender = "unknown"
            if string.find(filename, "playerf", 1, true) ~= nil then
                gender = "female"
            elseif string.find(filename, "playerm", 1, true) ~= nil then
                gender = "male"
            end

            local entry = {
                style = style,
                sourceName = helper.name,
                luminance = RealHelperNames.getStyleLuminance(style),
                skinTone = RealHelperNames.getSkinToneIndex(style)
            }
            table.insert(RealHelperNames.stylePools[gender], entry)
            RealHelperNames.stylePools.bySource[tostring(helper.name)] = entry

        end
    end

end

function RealHelperNames.getSourceStyle(sourceName)
    return RealHelperNames.stylePools.bySource[tostring(sourceName)]
end

function RealHelperNames.patchGermanHelperLabels()
    if g_i18n == nil or g_i18n.texts == nil then
        return
    end

    for key, value in pairs(g_i18n.texts) do
        if type(value) == "string" then
            local newValue, count = string.gsub(value, "KI%-Helfer %%s", "%%s")
            if count == 0 then
                newValue, count = string.gsub(value, "KI%-HELFER %%s", "%%s")
            end
            if count > 0 then
                g_i18n.texts[key] = newValue
            end
        end
    end
end

function RealHelperNames.applyCrew(manager)
    if manager == nil or manager.helpers == nil then
        Logging.warning("[RealHelperNames] HelperManager is not ready")
        return
    end

    for _, helperKey in ipairs(RealHelperNames.crewOrder) do
        local person = RealHelperNames.crew[helperKey]
        local helper = manager.helpers[helperKey]
        if helper ~= nil then
            helper.title = person.title

            helper.name = person.title

            local selected = RealHelperNames.getSourceStyle(RealHelperNames.avatarSources[helperKey])

            if selected ~= nil then
                helper.playerStyle = RealHelperNames.getRuntimeStyle(helperKey) or selected.style
            else
                Logging.warning("[RealHelperNames] No %s base avatar for %s; keeping map style", person.gender, person.title)
            end

        end
    end
end

function RealHelperNames.onDefaultHelpersLoaded(manager, missionInfo, baseDirectory)
    RealHelperNames.captureBaseStyles(manager)
end

function RealHelperNames.onAllHelpersLoaded(manager, xmlFile, missionInfo, baseDirectory)
    RealHelperNames.patchGermanHelperLabels()
    RealHelperNames.applyCrew(manager)
end

function RealHelperNames.showNotification(job, superFunc, aiMessage)
    local helper = g_helperManager ~= nil and g_helperManager:getHelperByIndex(job.helperIndex) or nil

    if helper ~= nil then
        local playerFarmId = nil
        if g_currentMission ~= nil and g_localPlayer ~= nil then
            playerFarmId = g_localPlayer.farmId
        end

        if aiMessage ~= nil and job.startedFarmId == playerFarmId then
            local text = RealHelperNames.stripTextPrefix(aiMessage:getMessage(job))
            local errorType = aiMessage:getType()
            local notificationType = FSBaseMission.INGAME_NOTIFICATION_CRITICAL

            if errorType == AIMessageType.OK then
                notificationType = FSBaseMission.INGAME_NOTIFICATION_OK
            elseif errorType == AIMessageType.INFO then
                notificationType = FSBaseMission.INGAME_NOTIFICATION_INFO
            end

            g_currentMission:addIngameNotification(notificationType, text)
        end
    end
end

function RealHelperNames.stripHelperPrefix(mission, superFunc, notificationType, message, ...)
    if type(message) == "string" then
        message = string.gsub(message, "^KI%-Helfer%s+", "")
        message = string.gsub(message, "^AI%s+[Ww]orker%s+", "")
    end
    return superFunc(mission, notificationType, message, ...)
end

function RealHelperNames.stripTextPrefix(text)
    if type(text) ~= "string" then
        return text
    end
    text = string.gsub(text, "^KI%-Helfer%s+", "")
    text = string.gsub(text, "^AI%s+[Ww]orker%s+", "")
    text = string.gsub(text, "%s*%(KI%-Helfer%s+", " (")
    text = string.gsub(text, "%s*%(KI%-HELFER%s+", " (")
    return text
end

function RealHelperNames.stripAIMessage(messageObject, superFunc, ...)
    return RealHelperNames.stripTextPrefix(superFunc(messageObject, ...))
end

function RealHelperNames.stripVehicleFullName(vehicle, superFunc, ...)
    return RealHelperNames.stripTextPrefix(superFunc(vehicle, ...))
end

function RealHelperNames.stripTopNotification(notification, superFunc, title, text, info, iconFilename, duration, ...)
    return superFunc(
        notification,
        RealHelperNames.stripTextPrefix(title),
        RealHelperNames.stripTextPrefix(text),
        RealHelperNames.stripTextPrefix(info),
        iconFilename,
        duration,
        ...
    )
end

function RealHelperNames.forceHelperVehicleStyle(vehicle, superFunc, helper, ...)
    if helper ~= nil then
        local helperKey = nil
        for key, person in pairs(RealHelperNames.crew) do
            if helper == g_helperManager.helpers[key] or helper.title == person.title then
                helperKey = key
                break
            end
        end

        local sourceKey = helperKey ~= nil and RealHelperNames.avatarSources[helperKey] or nil
        local selected = sourceKey ~= nil and RealHelperNames.getSourceStyle(sourceKey) or nil
        if selected ~= nil then
            helper.playerStyle = selected.style
        end
    end

    return superFunc(vehicle, helper, ...)
end

function RealHelperNames.getRuntimeStyle(helperKey)
    local sourceKey = RealHelperNames.avatarSources[helperKey]
    local selected = sourceKey ~= nil and RealHelperNames.getSourceStyle(sourceKey) or nil
    if selected == nil then
        return nil
    end

    local runtimeStyle = PlayerStyle.new()
    runtimeStyle:copyFrom(selected.style)

    if helperKey == "H" then
        runtimeStyle.configs.face:setSelectedItemName("head01")
        runtimeStyle.configs.face:setSelectedColorIndex(1)
        runtimeStyle.configs.hairStyle:setSelectedItemName("hair16")
        runtimeStyle.configs.hairStyle:setSelectedColorIndex(20)
    elseif helperKey == "A" then
        runtimeStyle.configs.bottom:setSelectedItemName("jeans")
        runtimeStyle.configs.top:setSelectedItemName("denimJacket")
        runtimeStyle.configs.headgear:setSelectedItemName("empty")
    elseif helperKey == "B" then
        runtimeStyle.configs.bottom:setSelectedItemName("jeans")
        runtimeStyle.configs.top:setSelectedItemName("topFarmJacketM")
        runtimeStyle.configs.headgear:setSelectedItemName("ballcap")
        runtimeStyle.configs.headgear:setSelectedColorIndex(9)
    elseif helperKey == "D" then
        runtimeStyle.configs.hairStyle:setSelectedItemName("hair04")
        runtimeStyle.configs.hairStyle:setSelectedColorIndex(4)
        runtimeStyle.configs.beard:setSelectedItemName("empty")
    elseif helperKey == "E" then
        runtimeStyle.configs.hairStyle:setSelectedItemName("hair12")
        runtimeStyle.configs.hairStyle:setSelectedColorIndex(5)
        runtimeStyle.configs.beard:setSelectedItemName("goatee01_head02")
        runtimeStyle.configs.beard:setSelectedColorIndex(5)
    end

    return runtimeStyle
end

function RealHelperNames.onAIJobStarted(vehicle, superFunc, job, helperIndex, startedFarmId, ...)
    local result = superFunc(vehicle, job, helperIndex, startedFarmId, ...)
    local helper = g_helperManager ~= nil and g_helperManager:getHelperByIndex(helperIndex) or nil
    if helper ~= nil and vehicle.setVehicleCharacter ~= nil then
        local helperKey = nil
        for key, person in pairs(RealHelperNames.crew) do
            if helper == g_helperManager.helpers[key] or helper.title == person.title then
                helperKey = key
                break
            end
        end

        local style = helperKey ~= nil and RealHelperNames.getRuntimeStyle(helperKey) or nil
        if style ~= nil then
            helper.playerStyle = style
            vehicle:setVehicleCharacter(style)
        end
    end
    return result
end

function RealHelperNames.blockedByObjectMessage(messageObject, superFunc, job)
    local template = g_i18n:getText("ai_messageErrorBlockedByObject")
    template = RealHelperNames.stripTextPrefix(template)
    local helperName = job ~= nil and job:getHelperName() or "Unknown"
    return string.format(template, helperName)
end

HelperManager.loadDefaultTypes = Utils.appendedFunction(
    HelperManager.loadDefaultTypes,
    RealHelperNames.onDefaultHelpersLoaded
)

HelperManager.loadMapData = Utils.appendedFunction(
    HelperManager.loadMapData,
    RealHelperNames.onAllHelpersLoaded
)

AIJob.showNotification = Utils.overwrittenFunction(
    AIJob.showNotification,
    RealHelperNames.showNotification
)

if AIMessage ~= nil and AIMessage.getMessage ~= nil then
    AIMessage.getMessage = Utils.overwrittenFunction(
        AIMessage.getMessage,
        RealHelperNames.stripAIMessage
    )
end

FSBaseMission.addIngameNotification = Utils.overwrittenFunction(
    FSBaseMission.addIngameNotification,
    RealHelperNames.stripHelperPrefix
)

local messageClasses = {
    AIMessageErrorCouldNotPrepare,
    AIMessageErrorFieldNotOwned,
    AIMessageErrorFieldNotReady,
    AIMessageErrorGraintankIsFull,
    AIMessageErrorImplementWrongWay,
    AIMessageErrorNoFieldFound,
    AIMessageErrorNotReachable,
    AIMessageErrorOutOfFill,
    AIMessageErrorOutOfFuel,
    AIMessageErrorOutOfMoney,
    AIMessageErrorVehicleBroken,
    AIMessageSuccessFinishedJob,
    AIMessageSuccessSiloEmpty,
    AIMessageSuccessStoppedByUser
}

for _, messageClass in ipairs(messageClasses) do
    if messageClass ~= nil and messageClass.getMessage ~= nil then
        messageClass.getMessage = Utils.overwrittenFunction(
            messageClass.getMessage,
            RealHelperNames.stripAIMessage
        )
    end
end

if AIJobVehicle ~= nil and AIJobVehicle.getFullName ~= nil then
    AIJobVehicle.getFullName = Utils.overwrittenFunction(
        AIJobVehicle.getFullName,
        RealHelperNames.stripVehicleFullName
    )
end


if TopNotification ~= nil and TopNotification.setNotification ~= nil then
    TopNotification.setNotification = Utils.overwrittenFunction(
        TopNotification.setNotification,
        RealHelperNames.stripTopNotification
    )
end


if Enterable ~= nil and Enterable.setRandomVehicleCharacter ~= nil then
    Enterable.setRandomVehicleCharacter = Utils.overwrittenFunction(
        Enterable.setRandomVehicleCharacter,
        RealHelperNames.forceHelperVehicleStyle
    )
end


if AIJobVehicle ~= nil and AIJobVehicle.aiJobStarted ~= nil then
    AIJobVehicle.aiJobStarted = Utils.overwrittenFunction(
        AIJobVehicle.aiJobStarted,
        RealHelperNames.onAIJobStarted
    )
end


if AIMessageErrorBlockedByObject ~= nil
    and AIMessageErrorBlockedByObject.getMessage ~= nil then

    AIMessageErrorBlockedByObject.getMessage = Utils.overwrittenFunction(
        AIMessageErrorBlockedByObject.getMessage,
        RealHelperNames.blockedByObjectMessage
    )
end
