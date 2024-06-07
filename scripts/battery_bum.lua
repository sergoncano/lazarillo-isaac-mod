
local despawningBeggars = {}

local beingrobbedBeggars = {}

local chargeQueue = {}

local hitChance = 7
local angelChance = 0.05

local game = Game()
local lazaroType = Isaac.GetPlayerTypeByName("Lazaro", false)

local function removeByValue(list, value)
    local newList = {}
    for k,v in pairs(list) do
        if  value ~= v then
            table.insert(newList, v) 
        end
    end
    return newList
end

function LazarilloMod:stealFromBatteryBum(entityBeggar, collider) 
    local beggarSprite = entityBeggar:GetSprite()
    local player = collider:ToPlayer()
    if math.floor(math.random(0, hitChance)) == 0 then
        table.insert(despawningBeggars, entityBeggar)
        beggarSprite:Load("gfx/beggars/battery_bum/battery_bum.anm2", true) 
        beggarSprite:Play("Shake", true)
        if game:GetLevel():GetAbsoluteStage() > 6 then
            player:TakeDamage(2, 0, EntityRef(entityBeggar), 0)
        else
            player:TakeDamage(1, 0, EntityRef(entityBeggar), 0)
        end
        
        game:GetLevel():SetStateFlag(LevelStateFlag.STATE_REDHEART_DAMAGED, true)
        return {
            Collide = true,
            SkipCollisionEffects = true
        }
    else
        table.insert(beingrobbedBeggars, entityBeggar)
        table.insert(chargeQueue, player)
        SFXManager():Play(SoundEffect.SOUND_SCAMPER)
        beggarSprite:Load("gfx/beggars/battery_bum/battery_bum.anm2", true) 
        beggarSprite:Play("GetStolen", false)
    end
    return {
        Collide = true,
        SkipCollisionEffects = true
    }
end

function LazarilloMod:triggerStealFromBatteryBum(entityBeggar, collider, low)	 
    if collider.Type ~= EntityType.ENTITY_PLAYER then
        return
    end
    local beggarSprite = entityBeggar:GetSprite()
    if (beggarSprite:GetAnimation() == "GetStolen") then
        return { Collide = true, SkipCollisionEffects = true}
    end
    if (not (beggarSprite:IsPlaying("PayPrize") or beggarSprite:IsPlaying("Prize") or beggarSprite:IsPlaying("PayNothing"))) then
        local playerType = collider:ToPlayer():GetPlayerType()
        if playerType == lazaroType then
            local player = collider:ToPlayer()
            if player:GetActiveItem() ~= 0 then
                if player:GetActiveCharge() < Isaac.GetItemConfig():GetCollectible(player:GetActiveItem()).MaxCharges then
                    local notTeleporting = ((not beggarSprite:IsPlaying("Teleport")) and (not beggarSprite:IsPlaying("Shake")) and ( not beggarSprite:IsFinished("Shake")) and (not beggarSprite:IsFinished("Teleport")))
                    if ((not beggarSprite:IsPlaying("GetStolen")) and notTeleporting)  then
                        return LazarilloMod:stealFromBatteryBum(entityBeggar, collider)           
                    elseif beggarSprite:IsPlaying("Teleport") then
                        return { Collide = false, SkipCollisionEffects = true}
                    end
                end
            end
            return {
                Collide = true,
                SkipCollisionEffects = true
            }
        end
    end
end


LazarilloMod:AddCallback(ModCallbacks.MC_PRE_SLOT_COLLISION, LazarilloMod.triggerStealFromBatteryBum, SlotVariant.BATTERY_BUM) 

function LazarilloMod:updateBatteryBumSprite()
    for _, entityBeggar in ipairs(beingrobbedBeggars) do
        local beggarSprite = entityBeggar:GetSprite()        
        beggarSprite.PlaybackSpeed = 1
        if beggarSprite:IsFinished("GetStolen") then
            LazarilloMod:raiseAngelChance(angelChance)
            local player = chargeQueue[1]
            SFXManager():Play(SoundEffect.SOUND_BATTERYCHARGE)
            player:SetActiveCharge(player:GetActiveCharge()+1) 
            table.remove(chargeQueue, 1)
            beggarSprite:Play("Idle", true) 
            
            beingrobbedBeggars = removeByValue(beingrobbedBeggars, entityBeggar)
        end
    end
    for _, entityBeggar in ipairs(despawningBeggars) do
        local beggarSprite = entityBeggar:GetSprite()        
        if beggarSprite:IsFinished("Teleport") then
            beggarSprite.PlaybackSpeed = 4
            entityBeggar:Remove()
            despawningBeggars = removeByValue(despawningBeggars, entityBeggar)             
        end
        if beggarSprite:IsFinished("Shake") then
            SFXManager():Play(SoundEffect.SOUND_SUMMON_POOF, 4)
            beggarSprite.PlaybackSpeed = 1
            beggarSprite:Load("gfx/beggars/battery_bum/battery_bum.anm2", true) 
            beggarSprite:Play("Teleport", true)
        end
    end
end


LazarilloMod:AddCallback(ModCallbacks.MC_POST_RENDER , LazarilloMod.updateBatteryBumSprite) 


function LazarilloMod:clearBatteryBumData() 
    beingrobbedBeggars = {}
    despawningBeggars = {}
end

LazarilloMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, LazarilloMod.clearBatteryBumData) 

