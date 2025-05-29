local component = require("component")
local term = require("term")
local event = require("event")
local unicode = require("unicode")
 
local me = component.me_interface or component.me_controller
local gpu = component.gpu
 
local screenW, screenH = gpu.getResolution()
local barWidth = screenW - 4
local rowsPerPage = screenH - 5
 
-- Data & state
local allData = {}
local currentPage = 1
local filters = {fluids = true, gases = true, essentia = true, energy = true}
 
-- Colors
local function generateColor(str)
  local hash = 0
  for i = 1, #str do
    hash = (hash * 31 + str:byte(i)) % 0xFFFFFF
  end
  if (hash & 0xFF) < 60 and (hash >> 8 & 0xFF) < 60 and (hash >> 16 & 0xFF) < 60 then
    hash = hash | 0x303030
  end
  return hash
end
 
local function formatNumber(val)
  local suffixes = {"", "k", "M", "G", "T"}
  local i = 1
  while val >= 1000 and i < #suffixes do
    val = val / 1000
    i = i + 1
  end
  return string.format("%.1f%s", val, suffixes[i])
end
 
local function drawBar(y, name, amount, capacity, color)
  local percent = (capacity > 0) and (amount / capacity) or 0
  local filled = math.floor(percent * barWidth)
 
  gpu.setBackground(color)
  gpu.setForeground(0x000000)
  gpu.fill(2, y, filled, 1, " ")
 
  name = unicode.sub(name, 1, 18)
  gpu.set(2, y, name)
 
  local valStr = formatNumber(amount) .. "/" .. formatNumber(capacity)
  local percentStr = string.format("%.1f%%", percent * 100)
 
  gpu.set(screenW - #valStr - 8, y, valStr)
  gpu.set(screenW - #percentStr, y, percentStr)
 
  gpu.setBackground(0x000000)
end
 
local function drawButton(x, label, active)
  local bg = active and 0x00AA00 or 0x333333
  local fg = active and 0xFFFFFF or 0xAAAAAA
  gpu.setBackground(bg)
  gpu.setForeground(fg)
  gpu.set(x, screenH - 1, label)
end
 
local function getFilteredData()
  local items = {}
    
 if filters.energy and component.isAvailable("induction_matrix") then
   local matrix = component.induction_matrix
   local stored = matrix.getEnergy()
   local max = matrix.getMaxEnergy()
   table.insert(items, {type = "header", label = "== Energy =="})
   table.insert(items, {type = "entry", name = "Energy", amount = stored, capacity = max})
 end
 
  if filters.fluids and me.getFluidsInNetwork then
    local fluids = me.getFluidsInNetwork() or {}
    if #fluids > 0 then
      table.insert(items, {type = "header", label = "== Fluids =="})
      for _, f in ipairs(fluids) do
        table.insert(items, {
          type = "entry",
          name = f.label or f.name,
          amount = f.amount or 0,
          capacity = f.capacity or f.amount
        })
      end
    end
  end
 
  if filters.gases and me.getGasesInNetwork then
    local gases = me.getGasesInNetwork() or {}
    if #gases > 0 then
      table.insert(items, {type = "header", label = "== Gases =="})
      for _, g in ipairs(gases) do
        table.insert(items, {
          type = "entry",
          name = g.label or g.name,
          amount = g.amount or 0,
          capacity = g.capacity or g.amount
        })
      end
    end
  end
 
  if filters.essentia and me.getEssentiaInNetwork then
    local essentia = me.getEssentiaInNetwork() or {}
    if #essentia > 0 then
      table.insert(items, {type = "header", label = "== Essentia =="})
      for _, e in ipairs(essentia) do
        table.insert(items, {
          type = "entry",
          name = e.label or e.name,
          amount = e.amount or 0,
          capacity = 3000
        })
      end
    end
  end
 
  return items
end
 
local function drawUI()
  term.clear()
  local y = 1
  local i = 1
  local shown = 0
 
  while shown < rowsPerPage and i <= #allData do
    local item = allData[i + (currentPage - 1) * rowsPerPage]
    if not item then break end
    if item.type == "header" then
      gpu.setForeground(0xFFFFFF)
      gpu.setBackground(0x000000)
      gpu.set((screenW - #item.label) // 2, y, item.label)
    else
      local color = generateColor(item.name)
      drawBar(y, item.name, item.amount, item.capacity, color)
    end
    y = y + 1
    shown = shown + 1
    i = i + 1
  end
 
  -- Buttons
  drawButton(2, "[◀ Prev]", false)
  drawButton(13, "[Next ▶]", false)
  drawButton(24, "[Fluids]", filters.fluids)
  drawButton(35, "[Gases]", filters.gases)
  drawButton(45, "[Essentia]", filters.essentia)
  drawButton(55, "[Energy]", filters.energy)
  drawButton(screenW - 10, "[Refresh]", false)
end
 
local function inBounds(x, y, bx, by, w)
  return y == by and x >= bx and x < (bx + w)
end
 
local function handleTouch(x, y)
  if inBounds(x, y, 2, screenH - 1, 9) then
    currentPage = math.max(1, currentPage - 1)
  elseif inBounds(x, y, 13, screenH - 1, 10) then
    currentPage = currentPage + 1
  elseif inBounds(x, y, 24, screenH - 1, 9) then
    filters.fluids = not filters.fluids
    currentPage = 1
  elseif inBounds(x, y, 35, screenH - 1, 8) then
    filters.gases = not filters.gases
    currentPage = 1
  elseif inBounds(x, y, 45, screenH - 1, 11) then
    filters.essentia = not filters.essentia
    currentPage = 1
  elseif inBounds(x, y, 55, screenH - 1, 9) then
    filters.energy = not filters.energy
    currentPage = 1
  elseif inBounds(x, y, screenW - 10, screenH - 1, 9) then
    -- Refresh
  else
    return
  end
  allData = getFilteredData()
  drawUI()
end
 
-- Initial load
allData = getFilteredData()
drawUI()
 
while true do
  local _, _, x, y = event.pull("touch")
  handleTouch(x, y)
end
 
