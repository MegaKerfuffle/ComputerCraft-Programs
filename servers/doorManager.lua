--[[
    what does this need:
        1) ability to register controllers and their data
        2) constant player detector scanning of controller coords
        3) if player in range, verify their clearance in CAS
        4) send door instructions 
]]

-- Settings
local detectorLocation = "left"
local sendChannel = 12458
local casChannel = 12460

-- Internal
local linkedControllers = {}

-- Load APIs
os.loadAPI("persistence.lua")
os.loadAPI("user.lua")



function ControllerListener()
    while true do
        local event, modemSide, senderChannel, replyChanel,
        message = os.pullEvent("modem_message")
        
        if (message[1] == "register") then
            local controllerData = {
                
            }
        end
        -- Register controller here from message.
    end
end