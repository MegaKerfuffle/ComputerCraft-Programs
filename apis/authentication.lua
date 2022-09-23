--[[
    Authentication API

    Author
        Rob, Discord @MegaKerfuffle#9278

    Summary
        The authentication API works on a client device and is used to
        authenticate the current user with the Central Authentication
        Service.
    
    Notes
        - N/A
]]

-- Settings
local modemLocation = "back"
local sendChannel = 12460
local returnChRange = {4000,6000}

-- Internal Vars
local loginToken
local modem = peripheral.wrap(modemLocation)
local returnChannel

-- Load custom APIs
--os.loadAPI("persistence.lua")
os.loadAPI("user.lua")

-- Helper function to override the default modem side.
function SetModemSide(side)
    modemLocation = side
    modem = peripheral.wrap(modemLocation)
end


-- Attempts to register a new user on CAS
function RegisterUser(username, password)
    if (username == nil or password == nil) then
        print("Error: Missing credentials. Did you provide a username and password?")
        return false
    end

    returnChannel = GetReturnChannel()
    modem.transmit(sendChannel, returnChannel, {"register", username, password})
    local result = AwaitModemMessage(returnChannel)
    local message = result[3]
    if (message[1] == "success") then
        print(message[2])
        return true
    else
        print(message[2])
        return false
    end
end


-- Attempt to login to CAS. Returns whether the attempt was successful.
function TryLogin(username, password)
    if (username == nil or password == nil) then
        print("Error: Missing credentials. Did you provide a username and password?")
        return false
    end

    returnChannel = GetReturnChannel()
    modem.transmit(sendChannel, returnChannel, {"login", username, password})
    local result = AwaitModemMessage(returnChannel)
    local message = result[3]
    print(message[1])
    if (message[1] == "login_token") then
        loginToken = message[2]
        print("Successfully logged in.")
        return {true, message[3]}
    elseif (message[1] == "failure") then
        print(message[2])
        return {false}
    end
end


-- Logout (clears saved tokens)
function Logout()
    if (loginToken ~= nil) then
        loginToken = nil
    end
end


-- Check if the stored login token is still valid on CAS.
function VerifyLoginToken()
    if (loginToken == nil) then
        print("Error: Can't verify login token; no token stored.")
        return false
    end

    returnChannel = GetReturnChannel()
    modem.transmit(sendChannel, returnChannel, {"check_token", loginToken})
    local result = AwaitModemMessage(returnChannel)
    local message = result[3]
    if (message[1] == "verify_token") then
        if (not message[2]) then
            print(message[3])
        end
        return message[2]
    end
end


function GetClearance(username)
    returnChannel = GetReturnChannel()
    modem.transmit(sendChannel, returnChannel, {"clearance", username})
    local result = AwaitModemMessage(returnChannel)
    local message = result[3]
    if (message[1] == "clearance") then
        print("Got clearance for user ".. message[2].. ", C"..message[3])
        return message[3]
    end
end


-- Get a random return channel to make message interception
-- more difficult.
function GetReturnChannel()
    math.randomseed(os.time())
    return math.random(returnChRange[1], returnChRange[2])
end


-- Waits for a modem message to arrive. Returns the 
-- sender channel [1], reply channel [2], and message [3].
function AwaitModemMessage(listenChannel)
    modem.open(listenChannel)
    local event, modemSide, senderChannel, replyChannel,
    message = os.pullEvent("modem_message")
    modem.close(listenChannel)
    return {senderChannel, replyChannel, message}
end