--[[
    hey this is a basic central authentication service that contains information
    about users in a database of sorts

    yeah

    the CAS does not send any net requests by default; instead, requests are sent
    to it and it responds with whatever data is requested.

    CAS requests should be sent over channel 12460
]]

os.loadAPI("persistence.lua")
os.loadAPI("user.lua")
local database = {}

function AddUser(username, password)
    -- Check if given username is already used.
    if #database > 0 then
        for key, value in pairs(database) do
            if value.name == username then
                print("User already exists, aborting.")
                return
            end
        end
    end
    
    local newUser = user.new(username, password)
    math.randomseed(os.time())
    local userId = math.random(0, 999)
    -- NOTE: should check if userId is unique here
    newUser.uid = userId
    table.insert(database, newUser)
    persistence.save("cas-data", database)
    print("Added user and saved persistently (database count: " .. #database .. ")")
end


function RemoveUser(username)
    for key, value in pairs(database) do
        if value.name == username then
            table.remove(database, index)
            persistence.save("cas-data", database)
            print("Successfully removed user.")
            return
        end
    end
    print("User not in database.")
end


function GetClearance(username)
    for index, value in ipairs(database) do
        if value.name == username then
            return value.clearance
        end
    end
    print("User not in database.")
    return nil
end


function VerifyAccess(username, password)
    for key, value in pairs(database) do
        if value.name == username then
            return value.check_password(password)
        end
    end
    print("User not in database.")
    return false
end


-- Attempt to load existing CAS data
local temp = persistence.load("cas-data")
if not temp == nil then
    database = temp
end

local modem = peripheral.wrap("top")
modem.open(12460)
while true do
    local event, modemSide, senderChannel,
    replyChannel, message, senderDistance = os.pullEvent("modem_message")
    print("Received a message on channel " .. senderChannel)
    if message[1] == "addUser" then
        AddUser(message[2], message[3])
        modem.transmit(replyChannel, senderChannel, {"ack", "Added user."})
    elseif message[1] == "removeUser" then
        RemoveUser(message[2])
        modem.transmit(replyChannel, senderChannel, {"ack", "Removed user."})
    elseif message[1] == "getUser" then
        local temp = nil
        for key, value in pairs(database) do
            print(value.uid)
            if (value.name == message[2]) then
                temp = value
                modem.transmit(replyChannel, senderChannel, {"user", temp})
                break
            end
        end 
        modem.transmit(replyChannel, senderChannel, {"ack", "no mfing user by that name"})
    else
        print("No idea wtf that message is.")
    end
end