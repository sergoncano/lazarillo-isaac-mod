
local lazaroType = Isaac.GetPlayerTypeByName("Lazaro", false)
local hairCostume = Isaac.GetCostumeIdByPath("gfx/characters/lazaro_hair.anm2")
local lazaroSpeed = 0.3
local lazaroLuck = -1
local lazaroDamage = 0.4


function LazarilloMod:EvalCache(player, cacheFlag)
    if player:GetPlayerType() == lazaroType then
        if cacheFlag == CacheFlag.CACHE_SPEED then
            player.MoveSpeed = player.MoveSpeed + lazaroSpeed
        end        
        if cacheFlag == CacheFlag.CACHE_LUCK then
            player.Luck = player.Luck + lazaroLuck
        end
        if cacheFlag == CacheFlag.CACHE_DAMAGE then
            player.Damage = player.Damage + lazaroDamage
        end
    end
    
end

LazarilloMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, LazarilloMod.EvalCache)