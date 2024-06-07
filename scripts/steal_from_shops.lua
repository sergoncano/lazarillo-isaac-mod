local game = Game()
local lazaroType = Isaac.GetPlayerTypeByName("Lazaro", false)
local stealFrameNumber = 80

local function getShopItems(entities)
    local shopItems = {}
    for index, value in pairs(entities) do
        if value:ToPickup():IsShopItem() then
            table.insert(shopItems, value)
        end
    end
    return shopItems
end

function LazarilloMod:despawnShopItems()
    local shopItems = getShopItems(Isaac.FindByType(5))
    SFXManager():Play(SoundEffect.SOUND_SUMMON_POOF, 4)
    for _, item in ipairs(shopItems) do
        item:Remove()
        item:GetSprite():Update()
    end
end
----------------------------------------------------
local stealingFrames = {}

local function getPlayers()
    local players = {}
    for i = 1, game:GetNumPlayers(), 1 do
        table.insert(players, game:GetPlayer(i))
    end
    return players
end

local lazarillos = {}

function LazarilloMod:updateCounter()
    for key, pair in pairs(stealingFrames) do
        local lazarillo = pair[1]
        local frames = pair[2]
        if frames > 0 and frames < stealFrameNumber then
            frames = frames + 1
        end
        if frames >= stealFrameNumber then
            frames = 0
        end
        local sprite = lazarillo:GetSprite()
        local isPickingUp = sprite:IsPlaying("Pickup") or sprite:IsPlaying("PickupWalkUp") or sprite:IsPlaying("PickupWalkDown") or sprite:IsPlaying("PickupWalkRight") or sprite:IsPlaying("PickupWalkLeft") or sprite:IsPlaying("HideItem") or sprite:IsPlaying("LiftItem") or sprite:IsPlaying("UseItem")
        if isPickingUp and frames == 0 then
            frames = 1
        end
        pair[2] = frames
    end
end

LazarilloMod:AddCallback(ModCallbacks.MC_POST_RENDER, LazarilloMod.updateCounter)

function LazarilloMod:createCounter()
    for key, player in pairs(getPlayers()) do
        if player:GetPlayerType() == lazaroType then
            table.insert(lazarillos, player)
            stealingFrames = {}
        end
    end
    for key, lazarillo in pairs(lazarillos) do
        table.insert(stealingFrames, {lazarillo, 0})
    end
end

LazarilloMod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, LazarilloMod.createCounter , 0) 

local function getFramesByLazarillo(lazarilloToTest)
    local returnedFrames = nil
    for key, pair in pairs(stealingFrames) do
        local lazarillo = pair[1]
        local frames = pair[2] 
        if GetPtrHash(lazarillo) == GetPtrHash(lazarilloToTest) then
            returnedFrames = frames
        end
    end
    return returnedFrames
end

local restockWorking = true
local scheduledForDeletion = false
local framePassed = false
function LazarilloMod:stealFromShop(entity, collider)
    if collider.Type ~= EntityType.ENTITY_PLAYER then
        return
    end
    local player = collider:ToPlayer()
    if player:GetPlayerType() == lazaroType then
        local pickup = entity:ToPickup()
        if pickup:IsShopItem() then
            if player:GetNumCoins() < pickup.Price then
                local sprite = player:GetSprite()
                local isPickingUp = sprite:IsPlaying("Pickup") or sprite:IsPlaying("PickupWalkUp") or sprite:IsPlaying("PickupWalkDown") or sprite:IsPlaying("PickupWalkRight") or sprite:IsPlaying("PickupWalkLeft") or sprite:IsPlaying("HideItem") or sprite:IsPlaying("LiftItem") or sprite:IsPlaying("UseItem")
                if not isPickingUp then
                    if getFramesByLazarillo(player) == 0 then
                        player:AddCoins(pickup.Price)
                        if not (player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and math.floor(math.random(0,1)) == 0) then
                            scheduledForDeletion = true
                            game:AddDevilRoomDeal()
                            restockWorking = false
                        end
                    end
                end
            end
        end
    end
end

LazarilloMod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, LazarilloMod.stealFromShop)

function LazarilloMod:DeleteInSchedule()
    if scheduledForDeletion then
        if framePassed then
            LazarilloMod:despawnShopItems()
            framePassed = false
            scheduledForDeletion = false
        else
            framePassed = true
        end
    end
end

LazarilloMod:AddCallback(ModCallbacks.MC_POST_RENDER, LazarilloMod.DeleteInSchedule)

function LazarilloMod:cancelRestock( ... )
    return restockWorking
end

LazarilloMod:AddCallback(ModCallbacks.MC_PRE_RESTOCK_SHOP, LazarilloMod.cancelRestock)

function LazarilloMod:clearRestockData()
    restockWorking = true
end

LazarilloMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, LazarilloMod.clearRestockData)

function LazarilloMod:removeDevilDeals(entity, collider)
    local roomType = game:GetRoom():GetType()
    if roomType == RoomType.ROOM_DEVIL or roomType == RoomType.ROOM_BLACK_MARKET then
        if collider.Type ~= EntityType.ENTITY_PLAYER then
            return
        end
        local player = collider:ToPlayer()
        if player:GetPlayerType() == lazaroType then
            local pickup = entity:ToPickup()
            if pickup:IsShopItem() then
                
                LazarilloMod:despawnShopItems()
            end
        end
    end
end

LazarilloMod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, LazarilloMod.removeDevilDeals)
