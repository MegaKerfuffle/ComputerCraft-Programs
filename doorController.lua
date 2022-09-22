--[[
    ok what do we need?

        1) setup process in which the controller registers with the
        manager and provides coordinates and minimum clearance level
        2) save system to save the setup process details
        3) ability to receive instructions from the door manager
]]

-- Settings
local modemLocation = "bottom"
local managerChannel = 12458
local listenChannel = 12459

local doorDefaultState = false
local doorId = "example01"
local doorMinClearance = "2"
local doorWhitelist = {}
local detectorCoords1 = vector.new(0,0,0)
local detectorCoords2 = vector.new(1,1,1)

-- Internal
local modem = peripheral.wrap(modemLocation)

-- Load APIs
os.loadAPI("persistence.lua")


function RegisterSelf()
    local doorConfig = {
        "register",
        detectorCoords1,
        detectorCoords2,
        doorId,
        doorMinClearance,
        doorWhitelist
    }
    modem.transmit(managerChannel, listenChannel, doorConfig)
end


function Listen()
    while true do
        local event, modemSide, senderChannel, replyChannel,
        message = os.pullEvent("modem_message")

        if (message[1] == "doorDelta") then
            -- do something
        end
    end
end