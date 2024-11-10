local _, rm = ...
local L = rm.L

local _, currentCharacterClass = UnitClass("player") -- Always in English and upper case
local rankOrder = {
    Apprentice = 1, 
    Journeyman = 2, 
    Expert = 3, 
    Artisan = 4
}

local function isRecipeForCurrentClass(recipe)
    if not recipe.classes then
        return true
    else
        return rm.tableContains(recipe.classes, currentCharacterClass)
    end
end

local function isRecipeForCurrentSpecialization(recipe)
    local professionID = rm.getProfessionID(rm.displayedProfession)
    local currentSpecialization = rm.getSavedSpecializationByID(professionID)
    return (
        not recipe.specialization 
        or not currentSpecialization 
        or currentSpecialization == recipe.specialization
    )
end

function rm.isRecipeAvailableForCharacter(recipe)
    return (
        isRecipeForCurrentClass(recipe) 
        and isRecipeForCurrentSpecialization(recipe)
    )
end

function rm.isRankupRecipe(recipe)
    return type(recipe.teachesSpell) == "string"
end

local function isSkillLearnedByCharacter(characterSkills, recipe)
    return (
        rm.tableContains(characterSkills, recipe.teachesItem)
        or rm.tableContains(characterSkills, recipe.teachesSpell)
    )
end

function rm.getAllCharactersRecipeStatus(recipe, professionID)
    local otherCharactersInfo = rm.getProfessionSkillsForOtherCharacters(professionID)
    local charactersMissingRecipeSkill = {}
    local charactersWithRecipeSkill = {}
    for character in pairs(otherCharactersInfo) do
        local characterSkills = otherCharactersInfo[character][professionID]
        if characterSkills then
            if not isSkillLearnedByCharacter(characterSkills, recipe) then
                table.insert(charactersMissingRecipeSkill, character)
            else
                table.insert(charactersWithRecipeSkill, character)
            end
        end
    end
    return charactersMissingRecipeSkill, charactersWithRecipeSkill
end

-- Identifies all rankup recipes that teach a rank equal to or lower than the current profession rank
local function isLearnedRankupRecipe(recipe, professionRank)
    if rm.isRankupRecipe(recipe) then
        return rankOrder[recipe.teachesSpell] <= rankOrder[professionRank]
    end
    return false
end

function rm.isLearnedRecipe(recipe)
    local learnedSkills = rm.getSavedSkillsByProfessionName(rm.displayedProfession)
    local professionRank = rm.getSavedProfessionRank(rm.displayedProfession)
    local isLearnedRecipe = isSkillLearnedByCharacter(learnedSkills, recipe)
    return isLearnedRecipe or isLearnedRankupRecipe(recipe, professionRank)
end

function rm.isMissingRecipeOfCurrentFaction(recipe)
    return not recipe.faction or (recipe.faction == rm.currentFaction)
end

local function isCapitalized(string)
    return string:sub(1, 1):upper() == string:sub(1, 1)
end

local function capitalizeName(string)
    if not isCapitalized(string) then
        return string:gsub("^%l", string.upper)
    end
end

local function removeRecipePrefix(recipeName)
    for _, prefix in pairs(L.recipePrefixes) do
        if recipeName:sub(1, #prefix) == prefix then
            local strippedName = recipeName:sub(#prefix + 1)
            return capitalizeName(strippedName) or strippedName
        end
    end
    return recipeName
end

local function getInitialRecipeData(ID)
    local name, link, quality, _, _, _, _, _, _, texture = C_Item.GetItemInfo(ID)
    name = removeRecipePrefix(name)
    return name, link, quality, texture
end

local function getInitialSpellData(ID, professionID)
    local name = GetSpellInfo(ID)
    local link = "|cff71d5ff|Hspell:"..ID.."|h["..name.."]|h|r"
    local quality = select(3, C_Item.GetItemInfo(ID))
    if not quality then
        quality = 1
    end
    local texture = rm.recipeDB[professionID][ID].icon or GetSpellTexture(ID)
    return name, link, quality, texture
end

local function getRecipeData(recipeID, recipeData, professionID, initialDataFunction)
    local rName, rLink, rQuality, rTexture = initialDataFunction(recipeID, professionID)
    return {
        classes = recipeData["classes"], 
        faction = recipeData["faction"], 
        link = rLink,
        name = rName, 
        quality = rQuality, 
        repFaction = recipeData["repFaction"], 
        repLevel = recipeData["repLevel"], 
        season = recipeData["season"], 
        sources = rm.sourceDB[professionID][recipeID],
        skill = recipeData["skill"], 
        specialization = recipeData["specialization"], 
        teachesItem = recipeData["teachesItem"], 
        teachesSpell = recipeData["teachesSpell"], 
        texture = rTexture
    }
end

-- Called in Cacher.cacheAndStoreAllRecipes
function rm.storeRecipeData(recipeID, recipeData, professionID)
    local recipe = getRecipeData(recipeID, recipeData, professionID, getInitialRecipeData)
    rm.cachedRecipes[professionID][recipeID] = recipe
end

function rm.storeSpellData(spellID, spellData, professionID)
    local spell = getRecipeData(spellID, spellData, professionID, getInitialSpellData)
    rm.cachedRecipes[professionID][spellID] = spell
end

-- Retrieves all cached recipe data for the currently displayed profession
function rm.getProfessionRecipes(getSkillInfoFunction)
    local displayedProfessionID = rm.getProfessionID(rm.displayedProfession)
    return rm.cachedRecipes[displayedProfessionID]
end
