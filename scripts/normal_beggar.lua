
local despawningBeggars = {}

local beingrobbedBeggars = {}

local hitChance = 15
local angelChance = 0.02

local game = Game()
local lazaroType = Isaac.GetPlayerTypeByName("Lazaro", false)

function LazarilloMod:raiseAngelChance(chance)
    if game:IsGreedMode() then
        return
    end
    local level = game:GetLevel()
    if level:GetStage() < 3 then
        return
    end
    level:AddAngelRoomChance(chance)
end

 local function removeByValue(list, value)
    local newList = {}
    for k,v in pairs(list) do
        if  value ~= v then
            table.insert(newList, v) 
        end
    end
    return newList
end

function LazarilloMod:stealFromBeggar(entityBeggar, collider)
    local beggarSprite = entityBeggar:GetSprite()
    local player = collider:ToPlayer()
    if math.floor(math.random(0,hitChance)) == 0 then
        table.insert(despawningBeggars, entityBeggar)
        beggarSprite:Load("gfx/beggars/beggar/beggar.anm2", true)
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
        SFXManager():Play(SoundEffect.SOUND_SCAMPER)
        beggarSprite:Load("gfx/beggars/beggar/beggar.anm2", true)
        beggarSprite:Play("GetStolen", false)
    end
    return {
        Collide = true,
        SkipCollisionEffects = true
    }
end

function LazarilloMod:triggerStealFromBeggar(entityBeggar, collider, low)	
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
            local notTeleporting = ((not beggarSprite:IsPlaying("Teleport")) and (not beggarSprite:IsPlaying("Shake")) and ( not beggarSprite:IsFinished("Shake")) and (not beggarSprite:IsFinished("Teleport")))
            if ((not beggarSprite:IsPlaying("GetStolen")) and notTeleporting)  then
                return LazarilloMod:stealFromBeggar(entityBeggar, collider)
            elseif beggarSprite:IsPlaying("Teleport") then
                return { Collide = false, SkipCollisionEffects = true}
            end
            return {
                Collide = true,
                SkipCollisionEffects = true
            }
        end
    end
end


LazarilloMod:AddCallback(ModCallbacks.MC_PRE_SLOT_COLLISION, LazarilloMod.triggerStealFromBeggar, SlotVariant.BEGGAR)

function LazarilloMod:updateBeggarSprite()
    for _, entityBeggar in ipairs(beingrobbedBeggars) do
        local beggarSprite = entityBeggar:GetSprite()        
        beggarSprite.PlaybackSpeed = 1
        if beggarSprite:IsFinished("GetStolen") then
            LazarilloMod:raiseAngelChance(angelChance)
            Isaac.GetPlayer():AddCoins(1)
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
            beggarSprite.PlaybackSpeed = 1
            SFXManager():Play(SoundEffect.SOUND_SUMMON_POOF, 4)
            beggarSprite:Load("gfx/beggars/beggar/beggar.anm2", true)
            beggarSprite:Play("Teleport", true)
        end
    end
end


LazarilloMod:AddCallback(ModCallbacks.MC_POST_RENDER , LazarilloMod.updateBeggarSprite)


function LazarilloMod:clearBeggarData()
    beingrobbedBeggars = {}
    despawningBeggars = {}
end

LazarilloMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, LazarilloMod.clearBeggarData)

