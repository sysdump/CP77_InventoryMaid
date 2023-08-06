grenades = {}

grenades.ts = Game.GetTransactionSystem()
grenades.ps = Game.GetPlayerSystem()	
grenades.player = grenades.ps:GetLocalPlayerMainGameObject()
grenades.ssc = Game.GetScriptableSystemsContainer();
grenades.ss = Game.GetStatsSystem()
grenades.equipmentSystem = grenades.ssc:Get("EquipmentSystem");
grenades.espd = grenades.equipmentSystem:GetPlayerData(grenades.player);
grenades.imgr = grenades.espd:GetInventoryManager();
grenades.grenadesList = {["frag"] = {},
                        ["emp"] = {},
                        ["incendiary_grenade"] = {},
                        ["flash"] = {},
                        ["biohazard"] = {},
                        ["recon"] = {},
                        ["cutting"] = {}}


function grenades.handleGrenadeType(InventoryMaid, action)
    print("handleGrenadeType")
    local sellAny = false
    for _,t in ipairs(InventoryMaid.settings.grenadeSettings.typeOptions) do
        if t.sellType == true then
            sellAny = true
            break
        end
    end
    if not sellAny then
        do return 0, 0, 0 end
    end

    grenades.grenadesList = {["frag"] = {},
                        ["emp"] = {},
                        ["incendiary_grenade"] = {},
                        ["flash"] = {},
                        ["biohazard"] = {},
                        ["recon"] = {},
                        ["cutting"] = {}} -- Reset the list

    local moneyGained = 0  
    local itemsBefore = 0
    local itemsAfter = 0

    local _, items = grenades.ts:GetItemListByTag(grenades.player, "Grenade")
    
    for _, stack in ipairs(items) do -- Get all grenade stacks in the inventory and insert them into grenadesList, sorted by type, removing unwanted qualitys
        local itemRecord = Game['gameRPGManager::GetItemRecord;ItemID'](stack:GetID())
        local statObj = stack:GetStatsObjectID()
	    local quality = grenades.ss:GetStatValue(statObj, gamedataStatType.Quality)
        if ((InventoryMaid.settings.grenadeSettings.sellQualitys.common and quality == 0) or (InventoryMaid.settings.grenadeSettings.sellQualitys.uncommon and quality == 1) or (InventoryMaid.settings.grenadeSettings.sellQualitys.rare and quality == 2) or (InventoryMaid.settings.grenadeSettings.sellQualitys.epic and quality == 3)) then
            table.insert(grenades.grenadesList[itemRecord:FriendlyName()], stack) 
        end
        itemsBefore = itemsBefore + grenades.ts:GetItemQuantity(grenades.player, stack:GetID())
    end
    
    for _, nadeType in pairs(grenades.grenadesList) do -- Sort the type lists by type qualitys, to sell the grenades with lower quality first
        table.sort(nadeType, grenades.sortFilter)  
    end

    itemsAfter = itemsBefore

    for key, singleTypeStacks in pairs(grenades.grenadesList) do
        local totalToProcessPerType = 0

        for _, stack in pairs(singleTypeStacks) do -- Get the total number of grenades per category that shoud get sold
            totalToProcessPerType = totalToProcessPerType + grenades.ts:GetItemQuantity(grenades.player, stack:GetID()) * (grenades.getTypeSettings(InventoryMaid, stack).filterValuePercent / 100)
        end

        totalToProcessPerType = math.floor(totalToProcessPerType)
        
        for _, stack in pairs(singleTypeStacks) do
            local toProcessPerStack = 0
            if grenades.getTypeSettings(InventoryMaid, stack).sellType then -- Only do stuff if the type is allowed to get sold
                local sellPrice = grenades.imgr:GetSellPrice(grenades.player, stack:GetID())
                local countPerStack = grenades.ts:GetItemQuantity(grenades.player, stack:GetID())

                if countPerStack > totalToProcessPerType then
                    toProcessPerStack = totalToProcessPerType
                end

                if grenades.getTypeSettings(InventoryMaid, stack).sellAll then
                    toProcessPerStack = countPerStack
                end

                --statObj = v:GetStatsObjectID()
                --local currentQuality = grenades.ss:GetStatValue(statObj, 'Quality')
                --print(key, itemQuantity, currentQuality, grenades.getTypeSettings(InventoryMaid, v).typeName, grenades.getTypeSettings(InventoryMaid, v).sellType)
                moneyGained = moneyGained + sellPrice * toProcessPerStack
                totalToProcessPerType = totalToProcessPerType - toProcessPerStack

                if action == "sell" then
                    grenades.ts:RemoveItem(grenades.player, stack:GetID(), toProcessPerStack) 
                elseif action == "disassemble" then
                    local craftingSystem = Game.GetScriptableSystemsContainer():Get(CName.new('CraftingSystem'))
                    craftingSystem:DisassembleItem(grenades.player, stack:GetID(), toProcessPerStack)
                elseif action == "preview" then
                    itemsAfter = itemsAfter - toProcessPerStack
                end
            end
        end
    end

    if action == "sell" then
        Game.AddToInventory("Items.money", tostring(moneyGained))
    end

    return moneyGained, itemsBefore, itemsAfter
end

function grenades.getTypeSettings(InventoryMaid, type)
	typeID = type:GetID()	
	itemRecord = Game['gameRPGManager::GetItemRecord;ItemID'](typeID)
	t = itemRecord:FriendlyName()
    for _, x in ipairs(InventoryMaid.settings.grenadeSettings.typeOptions) do
        if t == x.typeName then
            return x
        end
    end
end

function grenades.sortFilter(left, right)
    statL = left:GetStatsObjectID()
    statR = right:GetStatsObjectID()

    return grenades.ss:GetStatValue(statL, gamedataStatType.Quality) < grenades.ss:GetStatValue(statR, gamedataStatType.Quality)
end

function grenades.preview(InventoryMaid)
    local info = {count = 0, money = 0, afterCount = 0}
    money, before, after = grenades.handleGrenadeType(InventoryMaid, "preview")
    info.count = before
    info.money = money
    info.afterCount = after
    return info
end

function grenades.sellGrenades(InventoryMaid)
    grenades.handleGrenadeType(InventoryMaid, "sell")
end

function grenades.disassembleGrenades(InventoryMaid)
    grenades.handleGrenadeType(InventoryMaid, "disassemble")
end

return grenades