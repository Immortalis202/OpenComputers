local component = require("component")
local computer = require("computer")
local event = require("event")
local term = require("term")
local gpu = component.gpu
local sides = require("sides")
local RS = require("redstone-control")
local cfg = require("config")
local clr = cfg.clr

-- Find LSC
for k, v in component.list("gt_machine") do
	if component.invoke(k, "getName") == "multimachine.supercapacitor" then
		msc = component.proxy(k)
	end
end

function getCells()
        local countCell_Draconic = 0
        local countCell_Thermal = 0
        local countCell_RfTools = 0
        
        local TE_Cell = component.list("energy_device")
        local DE_Cell = component.list("Draconic Storage")
        local RT_Cell = component.list("RfTools_cell")
        
        local cellsID = {}
        for address, name in pairs(DE_Cell) do
            countCell_Draconic = countCell_Draconic + 1
            if countCell_Draconic > 1 then 
                cellsID[address] = "Draconic Power Orb".." "..countCell_Draconic
            else 
                cellsID[address] = "Draconic Power Orb"
            end 
        
        for address, name in pairs(TE_Cell) do
            countCell_Thermal = countCell_Thermal + 1
            if countCell_Thermal > 1 then                     
                cellsID[address] = "Thermal Expansion Power Cell".." "..countCell_Thermal
            else
                cellsID[address] = "Thermal Expansion Power Cell"
            end 

        for address, name in pairs(RT_Cell) do
            countCell_RfTools = countCell_RfTools + 1    
            if countCell_RfTools > 1 then
                cellsID[address] = "RfTools Power Cell".." "..countCell_RfTools
            else
                cellsID[address] = "RfTools Power Cell"
            end
        end 
    return cellsID
end

function getTotal()
        local totalPower = 0
        local totalMaxPower = 0
        local cellid =getCells()
        for address, name in pairs(cellid) do 
            local cell = component.proxy(address)
            totalPower = totalPower + cell.getEnergyStored()
            totalMaxPower = totalMaxPower + cell.getMaxEnergyStored()
        end
        return totalPower, totalMaxPower
    end 


clearScreen()
gpu.set( 67, 1, "Power Monitor")
local cellsID = getCells()

while true do 
    local _,_,x,y = event.pull(1,"touch")
    local count = 0
    if x and y then goto quit end
    for address, name in pairs(cellsID) do
        local cell = component.proxy(address)
        count = count + 1
        local t = count * 4 
        progressBar(name, t, cell.getEnergyStored(), cell.getMaxEnergyStored(), 0x00bb00, true, "RF")
    end

    local totalPower,totalMaxPower = getTotal()
    progressBar("TotalPower", 48 - count, totalPower,totalMaxPower, 0x00bb00, true, "RF")
    
    os.sleep(0.25)
end 


::quit::
gpu.setResolution(oldW, oldH)
clearScreen()