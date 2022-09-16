local args = { ... }
-- args:
--  [1] - x coord
--  [2] - y coord
--  [3] - z coord

local targetPos = vector.new(tonumber(args[1]), tonumber(args[2]), tonumber(args[3]))
local startPos
local currentPos
local cachedOrientation

-- Match the turtle's height with the target height
function MatchHeight()
    
    while (not currentPos.y == targetPos.y) do
        if (currentPos.y < targetPos.y) then
            if (not turtle.up()) then return false end 
            currentPos.y = currentPos.y + 1   
        elseif (currentPos.y > targetPos.y) then
            if (not turtle.down()) then return false end
            currentPos.y = currentPos.y - 1
        end
    end
    return true
end


function MatchX()

end


function MatchZ()

end


function Main()
    -- Init with getting our location and setting some vars
    startPos = vector.new(gps.locate(2))
    currentPos = startPos
    if not startPos.x then
        print("Failed to find current location; aborting moveto...")
        return
    end

    -- Begin movement
    if (not currentPos.y == targetPos.y) then
        if (not MatchHeight()) then
            print("Unable to match height; aborting moveto...")
            return    
        end
    end
    if (not currentPos.x == targetPos.x) then

    end
end 


-- Get the turtle's current orientation. Non-destructive;
-- will not attempt to break blocks.
--[[
Returns orientation as follows:
-x = 1
-z = 2
+x = 3
+z = 4
--]]
function GetOrientation()
    pos1 = vector.new(gps.locate(2))
    for i=0,3 do
        if (turtle.forward()) then
            break
        else
            print("Failed to move forward; rotating and trying again.")
            turtle.turnRight()
        end
    end
    pos2 = vector.new(gps.locate(2))
    heading = pos2 - pos1
    return ((heading.x + math.abs(heading.x) * 2) + (heading.z +math.abs(heading.z) * 3))
end 