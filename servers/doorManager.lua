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
        - "currentState" - bool; is the door open right now
        - "outputSide" - string; side to use for redstone output
]]

-- Load APIs
os.loadAPI("persistence.lua")
os.loadAPI("user.lua")
os.loadAPI("authentication.lua")

-- Settings

local modemLocation = "top"
local detectorLocation = "right"
local sendChannel = 12458
local listenChannel = 12459

-- Internal
local modem = peripheral.wrap(modemLocation)
local detector = peripheral.wrap(detectorLocation)
local linkedControllers = {}
local openDoors = {}

function ProxDetection()
    while true do
        if (#linkedControllers == 0) then
            print("No linked controllers.")
            os.sleep(1)
        else
            for index, value in pairs(linkedControllers) do
                local players = detector.getPlayersInCoords(value["detectPos1"], value["detectPos2"])
                if (#players > 0) then
                    -- TEMP
                    print("Got players at door " .. value["identifier"])
                    local verified = VerifyPlayers(players, value["clearance"])
                    print("Players verified: ".. tostring(verified))
                    local instruction = {value["identifier"]}
                    if (verified) then table.insert(instruction, "openDoor")
                    else table.insert(instruction, "closeDoor") end

                    if (value["currentState"] and verified) then
                        print("Changing state for door ".. value["identifier"])
                        value["currentState"] = not verified
                        modem.transmit(sendChannel, listenChannel, instruction)
                    end
                else
                    if (not value["currentState"]) then
                        modem.transmit(sendChannel, listenChannel, {value["identifier"], "closeDoor"})
                        value["currentState"] = true
                    end
                    os.sleep(0.25)
                end
            end
        end
     end
end


function VerifyPlayers(players, reqClearance)
    for index, value in pairs(players) do
        local playerClearance = authentication.GetClearance(value)
        if (playerClearance == nil or playerClearance == "X") then
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
    modem = peripheral.wrap(modemLocation)
    modem.open(listenChannel)
    print("Initiated listener on channel "..listenChannel)
    while true do
        local event, modemSide, senderChannel, replyChanel,
        message = os.pullEvent("modem_message")
        print("Received modem message.")

        if (message[1] == "register") then
            message[2]["currentState"] = true
            table.insert(linkedControllers, message[2])
            print("Registered a door.")
        end
    end
end

authentication.SetModemSide(modemLocation)
parallel.waitForAll(Listener, ProxDetection)