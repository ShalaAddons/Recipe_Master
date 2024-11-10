local _, rm = ...
local L = rm.L
local F = rm.F

local localizedClassifications = {
    ["Boss"] = L.boss,
    ["Rare"] = L.rare,
    ["Elite"] = L.elite,
    ["Rare Elite"] = L.rareElite,
    ["Dungeon"] = L.dungeon
}

------------------------- Shared -------------------------
local function getFactionIcon(data)
    return "|T"..F.textures.factionIcons[data["faction"]]..":14.5:14.5:-1.5:-0.5:32:32:4:32:4:32|t"
end

local function shortenLongName(str, maxLength)
    if #str > maxLength + 3 then
        return string.sub(str, 1, maxLength).."..."
    end
    return str
end

local function getNPCName(npc)
    local fullName = npc["names"][rm.locale] or npc["names"]["enUS"]
    local displayName = ""
    if npc["faction"] then
        displayName = getFactionIcon(npc)
    end
    displayName = displayName..shortenLongName(fullName, F.sizes.sourcesCellTextLength["npc"])
    return displayName, fullName
end

local function getLocalizedClassification(data)
    local classification = data["classification"]
    return localizedClassifications[classification] or false
end

local function getZoneName(infoTable, subject)
    local fullName
    if not subject["zones"] then
        return L.unknown
    elseif #subject["zones"] == 1 then
        fullName = C_Map.GetAreaInfo(subject["zones"][1])
        return shortenLongName(fullName, F.sizes.sourcesCellTextLength["zone"]), fullName
    else
        local names = {}
        local fullNames = {}
        for _, zone in pairs(subject["zones"]) do
            fullName = C_Map.GetAreaInfo(zone)
            local shortName = shortenLongName(fullName, F.sizes.sourcesCellTextLength["zone"])
            table.insert(names, shortName)
            fullNames[shortName] = fullName
        end
        return names, fullNames
    end
end

local function storeCommonNPCInfo(infoTable, npc)
    infoTable[L.name], infoTable["fullName"] = getNPCName(npc)
    infoTable["classification"] = getLocalizedClassification(npc)
    infoTable[L.zone], infoTable["fullZoneName"] = getZoneName(infoTable, npc)
end

local function getClassificationColor(classification)
    local classificationColors = {
        ["Boss"] = F.colors.redHex,
        ["Rare"] = F.colors.cadetBlueHex,
        ["Elite"] = F.colors.orangeHex,
        ["Rare Elite"] = F.colors.lightPurpleHex,
        ["Dungeon"] =  F.colors.tanHex
    }
    return classificationColors[classification] or F.colors.whiteHex
end

local function getColoredLevelBasedOnClassification(data)
    local classification = data["classification"]
    local level = data["level"] or L.unknown
    local classificationColor = getClassificationColor(classification)
    return WrapTextInColorCode(level, classificationColor)
end

------------------------- Drop, Pickpocket -------------------------
function rm.getCreatureInfo(sourceID, sourceData)
    local npcInfo = {}
    local npc = rm.npcDB[sourceID]
    storeCommonNPCInfo(npcInfo, npc)
    npcInfo[L.level] = getColoredLevelBasedOnClassification(npc)
    npcInfo[L.chance] = sourceData
    return npcInfo
end

------------------------- Vendor -------------------------
local function getCost(cost, currencySuffix)
    return tonumber(cost:match("(%d+)"..currencySuffix)) or 0
end

local function getFormattedCost(cost)
    local goldAmount = getCost(cost, "gld")
    local silverAmount = getCost(cost, "svr")
    local copperAmount = getCost(cost, "cpr")
    local engineeringExchangeTicket = getCost(cost, "eet")
    local tarnishedUndermineReal = getCost(cost, "tur")
    local formattedCost = ""
    if goldAmount > 0 then
        formattedCost = formattedCost.." "..goldAmount..F.textures.goldCoin
    end
    if silverAmount > 0 then
        formattedCost = formattedCost.." "..silverAmount..F.textures.silverCoin
    end
    if copperAmount > 0 then
        formattedCost = formattedCost.." "..copperAmount..F.textures.copperCoin
    end
    if engineeringExchangeTicket > 0 then
        formattedCost = engineeringExchangeTicket..F.textures.exchangeTicket
    end
    if tarnishedUndermineReal > 0 then
        formattedCost = tarnishedUndermineReal..F.textures.tarnishedUndermineReal
    end
    return formattedCost
end

local function storeVendorSupply(sourceData, vendorInfo)
    local cost = sourceData["cost"]
    local stock = sourceData["stock"]
    if cost then
        vendorInfo[L.price] = getFormattedCost(cost)
    else
        vendorInfo[L.price] = L.unknown
    end
    if stock ~= nil then
        vendorInfo[L.stock] = stock
    else
        vendorInfo[L.stock] = L.unlimited
    end
end

function rm.getVendorInfo(sourceID, sourceData)
    local vendorInfo = {}
    local vendor = rm.npcDB[sourceID]
    storeCommonNPCInfo(vendorInfo, vendor)
    storeVendorSupply(sourceData, vendorInfo)
    return vendorInfo
end

------------------------- Quest -------------------------
local function getQuestName(sourceID, quest)
    local fullName = C_QuestLog.GetQuestInfo(sourceID)
    local displayName = ""
    if quest["faction"] then
        displayName = getFactionIcon(quest)
    end
    if fullName then
        displayName = displayName..shortenLongName(fullName, F.sizes.sourcesCellTextLength["quest"])
    else
        displayName = displayName..L.unknown
    end
    return displayName, fullName
end

local function getClassAndRaceColor(classes, races)
    if not classes and not races then
        return F.colors.whiteHex
    elseif classes and races then
        return F.colors.yellowHex
    elseif classes then
        return F.colors.skyBlueHex
    elseif races then
        return F.colors.emeraldHex
    end
end

local function colorQuestNameIfClassRaceOrCompleted(quest, classes, races)
    if quest["completed"] then
        quest[L.name] = WrapTextInColorCode(quest[L.name], F.colors.grayHex)
    else
        local classAndRaceColor = getClassAndRaceColor(classes, races)
        quest[L.name] = WrapTextInColorCode(quest[L.name], classAndRaceColor)
    end
end

local function getClassName(classNumber)
    return C_CreatureInfo.GetClassInfo(classNumber).className
end

local function getFormattedClassNames(classes)
    local formattedClasses = ""
    if classes then
        formattedClasses = L.classes
        for _, classNumber in pairs(classes) do
            formattedClasses = formattedClasses..", "..getClassName(classNumber)
        end
    end
    return formattedClasses
end

local function getRaceName(raceNumber)
    return C_CreatureInfo.GetRaceInfo(raceNumber).raceName
end

local function getFormattedRaceNames(races)
    local formattedRaces = ""
    if races then
        formattedRaces = L.races
        for _, raceNumber in pairs(races) do
            formattedRaces = formattedRaces..", "..getRaceName(raceNumber)
        end
    end
    return formattedRaces
end

local function getFormattedClassAndRaceInfo(classes, races)
    local formattedInfo = ""
    formattedInfo = formattedInfo..getFormattedClassNames(classes)
    if formattedInfo == "" then
        formattedInfo = formattedInfo..getFormattedRaceNames(races)
    else
        formattedInfo = formattedInfo.."\n"..getFormattedRaceNames(races)
    end
    return formattedInfo:gsub("%%s, ", "") -- Removes every "%s, " found in formattedInfo
end

function rm.getQuestInfo(sourceID)
    local questInfo = {}
    local quest = rm.questDB[sourceID]
    local classes = quest["classes"]
    local races = quest["races"]
    questInfo[L.name], questInfo["fullName"] = getQuestName(sourceID, quest)
    questInfo["completed"] = C_QuestLog.IsQuestFlaggedCompleted(sourceID)
    colorQuestNameIfClassRaceOrCompleted(questInfo, classes, races)
    questInfo[L.level] = getColoredLevelBasedOnClassification(quest)
    questInfo[L.minimum] = quest["reqLevel"]
    questInfo["classesAndRaces"] = getFormattedClassAndRaceInfo(classes, races)
    questInfo["classification"] = getLocalizedClassification(quest)
    return questInfo
end

------------------------- Unique Sources -------------------------
function rm.getUniqueInfo(sourceID)
    local uniqueInfo = {}
    local uniqueNPC = rm.uniqueDB[sourceID]
    if uniqueNPC then
        storeCommonNPCInfo(uniqueInfo, uniqueNPC)
        uniqueInfo[L.level] = getColoredLevelBasedOnClassification(uniqueNPC)
    else
        uniqueInfo[L.name] = ""
        uniqueInfo[L.level] = ""
        uniqueInfo[L.zone] = ""
    end
    uniqueInfo["instructions"] = L.uniqueSourceInstructions[sourceID][rm.locale] or L.uniqueSourceInstructions[sourceID]["enUS"]
    return uniqueInfo
end

------------------------- Object -------------------------
local function getObjectName(object)
    local fullName = object["names"][rm.locale] or object["names"]["enUS"]
    local displayName = shortenLongName(fullName, F.sizes.sourcesCellTextLength["object"])
    return displayName, fullName
end

function rm.getObjectInfo(sourceID, sourceData)
    local objectInfo = {}
    local object = rm.objectDB[sourceID]
    objectInfo[L.name], objectInfo["fullName"] = getObjectName(object)
    objectInfo[L.chance] = sourceData
    objectInfo[L.zone], objectInfo["fullZoneName"] = getZoneName(objectInfo, object)
    return objectInfo
end

------------------------- Trainer -------------------------
function rm.getTrainerInfo(sourceID)
    local trainerInfo = {}
    local trainer = rm.npcDB[sourceID]
    storeCommonNPCInfo(trainerInfo, trainer)
    return trainerInfo
end

------------------------- Fishing -------------------------
function rm.getFishingInfo(sourceID, sourceData)
    local info = {}
    local name = C_Map.GetAreaInfo(sourceID)
    info["fullName"] = name
    info[L.name] = shortenLongName(name, F.sizes.sourcesCellTextLength["firstOfTwoColumns"])
    info[L.chance] = sourceData
    return info
end

------------------------- Item -------------------------
function rm.getItemInfo(sourceID, sourceData)
    local info = {}
    local name = rm.cachedItemNames[sourceID]
    info["fullName"] = name
    info[L.name] = shortenLongName(name, F.sizes.sourcesCellTextLength["firstOfTwoColumns"])
    if sourceData ~= "" then
        info[L.chance] = sourceData
    else
        info[L.chance] = L.unknown
    end
    return info
end
