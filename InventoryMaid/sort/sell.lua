sell = {}

function sell.sell(InventoryMaid)
    local ts = Game.GetTransactionSystem()
    baseSort = require ("sort/baseSort.lua")
    baseSort.generateSellList(InventoryMaid)

    Game.AddToInventory("Items.money", sell.calculateMoney())
    for _, v in ipairs(baseSort.finalSellList) do
        ts:RemoveItem(Game.GetPlayer(), v:GetID(), 1)
    end  

    removeJunk = require ("sort/removeJunk.lua")
    removeJunk.sellJunk(InventoryMaid)  

    grenades = require("sort/grenades")
    grenades.sellGrenades(InventoryMaid)
end 

function sell.disassemble(InventoryMaid)
    baseSort = require ("sort/baseSort.lua")
    baseSort.generateSellList(InventoryMaid)

    for _, v in ipairs(baseSort.finalSellList) do
        local craftingSystem = Game.GetScriptableSystemsContainer():Get(CName.new('CraftingSystem'))
        craftingSystem:DisassembleItem(Game.GetPlayer(), v:GetID(), 1)
    end  

    removeJunk = require ("sort/removeJunk.lua")
    removeJunk.dissasembleJunk(InventoryMaid) 

    grenades = require("sort/grenades")
    grenades.disassembleGrenades(InventoryMaid)
end

function sell.calculateMoney()
    sellPrice = 0
    local ssc = Game.GetScriptableSystemsContainer()
    local espd = ssc:Get("EquipmentSystem"):GetPlayerData(Game.GetPlayer())
    local imgr = espd:GetInventoryManager()
    for _, v in ipairs(baseSort.finalSellList) do
        sellPrice = sellPrice + imgr:GetSellPrice(Game.GetPlayer(), v:GetID())
    end
    return sellPrice
end

function sell.preview(InventoryMaid)
    local money = 0
    local nItems = 0
    local nItemsAfter = 0

    local wT = 0
    local wS = 0
    local wM = 0
    local jT = 0
    local jS = 0
    local jM = 0
    local gT = 0
    local gS = 0
    local gM = 0

    removeJunk = require ("sort/removeJunk.lua")
    baseSort = require ("sort/baseSort.lua")
    grenades = require("sort/grenades")
    tableFunctions = require ("utility/tableFunctions.lua")
    baseSort.generateSellList(InventoryMaid)
    nItems = baseSort.nItems
    wT = baseSort.nItems
    nItemsAfter = nItems - tableFunctions.getLength(baseSort.finalSellList)
    wS = #baseSort.finalSellList
    money = sell.calculateMoney()
    wM = money

    local junkInfo = removeJunk.preview(InventoryMaid)
    money = money + junkInfo.money
    jM = junkInfo.money
    nItems = nItems + junkInfo.count
    jT = junkInfo.count
    nItemsAfter = nItemsAfter + junkInfo.afterCount
    jS = jT - junkInfo.afterCount

    local grenadesInfo = grenades.preview(InventoryMaid)
    money = money + grenadesInfo.money
    gM = grenadesInfo.money
    nItems = nItems + grenadesInfo.count
    gT = grenadesInfo.count
    nItemsAfter = nItemsAfter + grenadesInfo.afterCount
    gS = gT - grenadesInfo.afterCount

--    return string.format("Items currently: %d, After: %d, \nMoney gained: %d",nItems, nItemsAfter, money)
    output = "Wpn & Amr: ".. wS.. "/".. wT.. ": $".. wM.. "\nJunk items: ".. jS.. "/".. jT.. ": $".. jM.. "\nGrenades: ".. gS.. "/".. gT.. ": $".. gM
    print(output)
    return string.format(output)
end

return sell