local detector = peripheral.find("playerDetector")
local allowedPlayers = { "MegaKerfuffle" }
local doorAuthed = false
   
if detector == nil then error("No player detector found.") end
 
function GetPlayers(range)
    local players = detector.getPlayersInRange(range)
    if #players > 0 then
        for k, v in pairs(players) do
            for indev, value in ipairs(allowedPlayers) do
                if v == value then
                    print("Authenticated user ".. v ..".")
                    doorAuthed = true
                else
                    print("Unauthenticated user entered prox. Closing.")
                    doorAuthed = false
                end
            end
           
        end
    else
        print("No players in range.")
        if doorAuthed then
            doorAuthed = false
        end 
    end
    redstone.setOutput("right", doorAuthed)
end
                
while true do
    GetPlayers(3.5)
    os.sleep(0.25)
end