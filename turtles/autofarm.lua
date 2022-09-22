-- turtle should be placed below the bottom-left corner of the field,
-- with *one* block of vertical seperation between the dirt and the
-- turtle
local args = { ... }
-- args:
--  [1] - field x size
--  [2] - field y size

local fieldSizeX = tonumber(args[1])
local fieldSizeY = tonumber(args[2])
local completedColumns = 0
local lastRot = "null" -- can be "left" or "right"

-- Till and seed a column of distance length
function WorkColumn(distance)
    local progress = 0
    while (progress < distance) do
        if (not turtle.forward()) then
            print("Turtle can't move forward; aborting...")
            return
        end
        -- this is the bit that really requires a hoe being equipped
        turtle.digDown()
        turtle.placeDown() -- NOTE: SEEDS NEED TO BE SELECTED
    end
end


-- Rotate the turtle left twice
function RotateLeft()
    for i = 0, 2 do
        turtle.turnLeft()
    end
end


-- Rotate the turtle right twice
function RotateRight()
    for i = 0, 2 do
        turtle.turnRight()
    end
end

-- NOTE: we should be doing a tool check here to verify a hoe is equipped.

-- Main program func
function Main()
    print("Beginning autofarm on area (x: " .. fieldSizeX .. ", y: " .. fieldSizeY .. ")")
    -- NOTE: Verify tool equipped and seeds selected

    -- Main program loop
    while (completedColumns < fieldSizeX) do
        print("Starting work on column ".. completedColumns)
        WorkColumn(fieldSizeY)
        if (lastRot == "null" or lastRot == "left") then
            RotateRight()
            lastRot = "right"
        elseif (lastRot == "right") then
            RotateLeft()
            lastRot = "left"
        end
        completedColumns = completedColumns + 1
    end
    print("Completed auto farming")
end

Main()