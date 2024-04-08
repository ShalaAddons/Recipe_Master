local _, rm = ...

function rm.getSavedSpecializationByID(professionID)
    return rm.getCharacterSavedVariables()[professionID]["specialization"]
end

function rm.getSavedSpecializationByName(profession)
    return rm.getCharacterSavedVariables()[rm.getProfessionID(profession)]["specialization"]
end

function rm.getSpecializationName(specializationID)
    local specializationName = GetSpellInfo(specializationID)
    return specializationName
end

local specializationIDs = {
    [164] = {9788, 17041, 17040, 17039, 9787},
    [202] = {20219, 20222},
    [165] = {10657, 10658, 10660}
}

local function storeCurrentSpecializations(currentSpecializations, spellID)
    for professionID, specs in pairs(specializationIDs) do
        if rm.tableContains(specs, spellID) then
            currentSpecializations[professionID] = spellID
        end
    end
end

function rm.getAllProfessionsSpecialization()
    local currentSpecializations = {}
    local numSpellTabs = GetNumSpellTabs()
    for i = 1, numSpellTabs do
        local offset, numSlots = select(3, GetSpellTabInfo(i))
        for j = offset + 1, offset + numSlots do
            local _, _, spellID = GetSpellBookItemName(j, BOOKTYPE_SPELL)
            storeCurrentSpecializations(currentSpecializations, spellID)
        end
    end
    return currentSpecializations
end

-- Saves all current professions' specializations if any
function rm.saveProfessionsSpecializations(currentSpecializations)
    for professionID, specializationID in pairs(currentSpecializations) do
        if not rm.getSavedSpecializationByID(professionID) then
            rm.getSavedProfessionByID(professionID)["specialization"] = specializationID
        end
    end
end

local function isSpecializationAbandoned(currentSpecializations, professionID)
    return not currentSpecializations[professionID] and rm.getSavedSpecializationByID(professionID)
end

function rm.removeAbandonedSpecialization(currentSpecializations, professionID)
    if isSpecializationAbandoned(currentSpecializations, professionID) then
        rm.getSavedProfessionByID(professionID)["specialization"] = nil
    end
end
