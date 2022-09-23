--[[
    what does this need:
        1) ability to register controllers and their data
        2) constant player detector scanning of controller coords
        3) if player in range, verify their clearance in CAS
        4) send door instructions 

    Notes
        - This may need two modems; one for CAS auth, one for door listening

    Controller Config
        A table consisting of the following keys:
        - "identifier" - string; the unique ID for this door
        - "detectPos1" - vector; position 1 for the detection box
        - "detectPos2" - vector; position 2 for the detection box
        - "clearance" - string; minimum clearance for the door
        - "defaultState" - bool; is the door open by default
        - "outputSide" - string; side to use for redstone output
]]

-- Load APIs
os.loadAPI("persistence.lua")
os.loadAPI("user.lua")
os.loadAPI("authentication.lua")

-- Settings

local modemLocation = "back"
local detectorLocation = "left"
local sendChannel = 12458
local receiveChannel = 12459

-- Internal
local modem = peripheral.wrap(modemLocation)
local detector = peripheral.wrap(detectorLocation)
local linkedControllers = {}

function ProxDetection()
    while true do
        if (#linkedControllers == 0) then
            print("No linked controllers.")
            os.sleep(2)
            return
        end

        for index, value in pairs(linkedControllers) do
            local players = detector.getPlayersInCoords(value["detectPos1"], value["detectPos2"])
            if (#players > 0) then
                local open = VerifyPlayers(players, value["clearance"])
                local instruction = {value["identifier"]}
                if (open) then table.insert(instruction, "openDoor")
                else table.insert(instruction, "closeDoor") end
                modem.transmit(sendChannel, receiveChannel, instruction)
            else os.sleep(0.5)
            end
        end
     end
end


function VerifyPlayers(players, reqClearance)
    for index, value in pairs(players) do
        local playerClearance = authentication.GetClearance(value)
        if (playerClearance == "X") then
            return false
        elseif (reqClearance ~= nil) then
            if (tonumber(playerClearance) < tonumber(reqClearance)) then
                return false
            end
        end
    end
    return true
end


-- Listens for controllers trying to register themselves.
function Listener()
    modem.open(receiveChannel)
    print("Initiated listener on channel "..receiveChannel)
    while true do
        local event, modemSide, senderChannel, replyChanel,
        message = os.pullEvent("modem_message")
        
        if (message[1] == "register") then
            table.insert(linkedControllers, message[2])
        end
    end
end

parallel.waitForAll(Listener, ProxDetection)