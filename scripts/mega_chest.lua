local lazaroType = Isaac.GetPlayerTypeByName("Lazaro", false)

local chestsWithKeysIn = {}

local function removeByValue(list, value)
    local newList = {}
    for k,v in pairs(list) do
        if  value ~= v then
            table.insert(newList, v) 
        end
    end
    return newList
end

function LazarilloMod:triggerGetKeyBack(player, collider)
    if player:GetPlayerType() ~= lazaroType then
        return
    end

    local colliderIsMegaChest = (collider.Type == EntityType.ENTITY_PICKUP and collider.Variant == 57)
    if colliderIsMegaChest then
        local sprite = collider:GetSprite()
        if sprite:IsPlaying("UseKey") or sprite:IsPlaying("UseCoin") then
            table.insert(chestsWithKeysIn, {collider, player})
        end
    end

end

LazarilloMod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, LazarilloMod.triggerGetKeyBack)

function LazarilloMod:getKeyBack()
    for key, pair in pairs(chestsWithKeysIn) do
        local chest = pair[1]
        local player = pair[2]
        local sprite = chest:GetSprite()
        if sprite:IsFinished("UseKey") then
            player:AddKeys(1)
            sprite:Play("Idle")
            removeByValue(chestsWithKeysIn, {chest, player})
        end
        if sprite:IsFinished("UseCoin") then
            player:AddCoins(1)
            sprite:Play("Idle")
            removeByValue(chestsWithKeysIn, {chest, player})
        end
    end
end

LazarilloMod:AddCallback(ModCallbacks.MC_POST_RENDER, LazarilloMod.getKeyBack)