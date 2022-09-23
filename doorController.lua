--[[
    Door Controller

    Author 
        Rob, Discord @MegaKerfuffle#9278
    
    Summary
        An automated door controller, allowing the user to setup an endpoint for
        the door manager. 

    Components
        1) First-start configuration; collects required door information and
        saves it for future use.
        2) Network listener; used to listen for and to follow door instructions.
    
    Config
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

-- Settings
local modemLocation = "bottom"
local managerChannel = 12458
local listenChannel = 12459

-- Internal
local modem = peripheral.wrap(modemLocation)
local currentOutput = false
local config = persistence.load("door-config")
if (config == nil) then
    ConfigDoor()
end

-- Used to register this door with the Door Manager.
function RegisterSelf()
    local configMsg = {
        "register",
        config
    }
    modem.transmit(managerChannel, listenChannel, configMsg)
    Listen()
end


-- Listen for door instructions.
function Listen()
    while true do
        local event, modemSide, senderChannel, replyChannel,
        message = os.pullEventRaw("modem_message")
        if (message[1] == config["identifier"]) then
            if (message[2] == "openDoor") then
                print("Opening door if able.")
                if (currentOutput and config["defaultState"]) then
                    SetOutput(false)
                elseif (not currentOutput and not config["defaultState"]) then
                    SetOutput(true)
                end
            elseif (message[2] == "closeDoor") then
                print("Closing door if able.")
                if (not currentOutput and config["defaultState"]) then
                    SetOutput(true)
                elseif (currentOutput and not config["defaultState"]) then
                    SetOutput(false)
                end
            end
        end
    end
end


-- Set the door's output. This doesn't care about the door's default state.
function SetOutput(bool)
    currentOutput = bool
    redstone.setOutput(config["outputSide"], bool)
end


-- Run a configuration prompt for the door.
function ConfigDoor()
    print("=== DOOR CONFIGURATION ===")
    print("Provide a door ID: ")
    local doorId = read()
    print("We'll now set up the door's detection area.")
    print("This area is a box defined by two corner coordinates.")
    os.sleep(1)
    print("Enter the coords of the first corner (format = 'x y z'): ")
    local pos1 = GetVectorFromString(read())
    print("Enter the coords of the second corner (format = 'x y z'):")
    local pos2 = GetVectorFromString(read())
    print("Enter the minimum clearance for this door:")
    local clearance = read()
    print("Ensure the door has no redstone input.")
    os.sleep(1)
    local defaultState = false -- true = open, false = closed
    while true do
        print("Is the door currently open? (Y/N)")
        local inp = read()
        if (inp == "Y") then defaultState = true break
        elseif (inp == "N") then defaultState = false break
        end
    end
    print("Where should the redstone output for this door be?")
    print("Options are: front, back, left, right, top, bottom")
    local outputSide = read()
    print("This door is now configured.")
    config = {
        ["identifier"] = doorId,
        ["detectPos1"] = pos1,
        ["detectPos2"] = pos2,
        ["clearance"] = clearance,
        ["defaultState"] = defaultState,
        ["outputSide"] = outputSide
    }
    persistence.save("door-config", config)
end


-- Helper func to get a vector out of a string, 
-- assuming the string is formatted "x y z"
function GetVectorFromString(string)
    local chunks = {}
    for substring in string:gmatch("%S+") do
        table.insert(chunks, substring)
    end
    return vector.new(chunks[1], chunks[2], chunks[3]) 
end


-- Run the registration and listener.
-- NOTE: Tempted to add a local control interface that allows a user
-- to login to CAS and control the door if they have clearance.
RegisterSelf()