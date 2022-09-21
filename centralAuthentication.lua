--[[
    Central Authentication Service

    Author
        Rob, Discord @MegaKerfuffle#9278

    Summary
        The Central Authentication Service (CAS) handles the storing, management,
        and verification of user data and credentials. This program specifically is
        meant to act as a server, and has no way of receiving user input on the local
        computer.

    Notes
        - CAS listens for requests on channel 12460 by default.
        - CAS responds to requests with responses, as soon as the requested operation
        is complete.
        - WARNING: User data/credentials are sent over the network (to the CAS) in
        plaintext. This is a security vulnerability, as any other users on the same
        network with the channel number can eavesdrop and collect user data in transit.

    Auth Requests
        Public
        - register: string username, string password
        - login: string username, string password
        - unregister: string username, string password
        Admin 
        - delete_user: string username, string authToken
        - set_clearance: string username, int newClearance, string authToken

    Auth Responses
        Public
        - ack: string details
        - success: string details
        - failure: string details
        - login_token: string authToken
]]

-- Settings
local modemLocation = "top"
local listenChannel = 12460

-- Internal data
local database = {}
local tokens = {}
local modem = peripheral.wrap(modemLocation)
local commands = {
    -- Public commands; no auth required.
    ["register"] = function(message, returnChannel)
        if (IsUser(message[2])) then
            modem.transmit(returnChannel, listenChannel, {"failure", "User already registered."})
            return
        end

        AddUser(message[2], message[3])
        modem.transmit(returnChannel, listenChannel, {"success", "Registered user ".. message[2]})
    end,
    ["unregister"] = function(message, returnChannel)
        if (IsUser[message[2]] and VerifyAccess(message[2], message[3])[1]) then
            RemoveUser(message[2])
            print("Removed user ".. message[2])
            modem.transmit(returnChannel, listenChannel, {"success", "Unregistered user ".. message[2]})
        else
            print("Can't unregister user; sender is either not a user or not authed.")
            modem.transmit(returnChannel, listenChannel, {"failure", "Failed to unregister user."})
        end
    end,
    ["login"] = function(message, returnChannel)
        if (IsUser(message[2])) then
            if (VerifyAccess(message[2], message[3])) then
                local token = LoginUser(message[2], message[3])[2]
                print("Successfully logged user ".. message[2] " in.")
                modem.transmit(returnChannel, listenChannel, {"login_token", token})
            else
                print("Can't login; invalid credentials.")
                modem.transmit(returnChannel, listenChannel, {"failure", "Invalid credentials."})
            end
        else
            print("Can't login; user doesn't exist.")
            modem.transmit(returnChannel, listenChannel, {"failure", "User doesn't exist."})
        end
    end,
}

-- Load our custom APIs
os.loadAPI("persistence.lua")
os.loadAPI("user.lua")


-- Generates a unique login token.
function GenerateToken()
    local template = "xxxxx-4xxx-yxxx"
    return string.gsub(template, '[xy]', function(c)
        math.randomseed(os.time())
        local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format("%x", v)
    end)
end


-- Validate the uniqueness of a UID.
function ValidateUID(uid)
    for key, value in pairs(database) do
        if (value.uid == uid) then
            return false
        end
    end
    return true
end


-- Adds a new user to the database.
function AddUser(username, password)
    -- Check if given username is already used.
    if #database > 0 then
        for key, value in pairs(database) do
            if value.name == username then
                return {false, "User already exists; aborting..."}
            end
        end
    end
    
    local newUser = user.new(username, password)
    math.randomseed(os.time())
    local userId = math.random(0, 999)
    -- Ensure userID is unique.
    while true do
        if (ValidateUID(userId)) then break
        else userId = math.random(0,999) end
    end
    newUser.uid = userId
    table.insert(database, newUser)
    persistence.save("cas-data", database)
    return {true, "Successfully added user."}
end


-- Remove a user from the database.
function RemoveUser(username)
    for key, value in pairs(database) do
        if value.name == username then
            table.remove(database, index)
            persistence.save("cas-data", database)
            return {true, "Successfully removed user."}
        end
    end
    return {false, "User not in database."}
end


-- Attempt to login a user. Returns a login token if successful.
function LoginUser(username, password)
    if (VerifyAccess(username, password)) then
        local user = GetUser(username)
        if (user == nil) then
            return
        end
    
        local userToken = GenerateToken()
        table.insert(tokens, {[user.uid] = userToken})
        return {true, userToken}
    else
        return {false, nil}
    end
end


-- Retrieve the clearance level of a user.
function GetClearance(username)
    for index, value in ipairs(database) do
        if value.name == username then
            return value.clearance
        end
    end
    print("User not in database.")
    return nil
end


-- Attempt to verify a user using a password.
function VerifyAccess(username, password)
    local user = GetUser(username)
    if (user == nil) then
        return { false, "User not in database."}
    else
        local verified = user.check_password(password)
        local outcome
        if verified then
            outcome = "Access granted."
        else
            outcome = "Access denied."
        end
        return { verified, outcome}
    end
end


-- Attempt to load existing authentication data.
function TryLoadData()
    local data = persistence.load("cas-data")
    if data == nil then
        return false
    else
        -- NOTE: There's a chance that I'll need to iterate
        -- through data to append it's elements to database.
        database = data
        return true
    end
end


-- Check if a user exists in the database.
function IsUser(username)
    for index, value in pairs(database) do
        if (value.username == username) then
            return true
        end
    end
    return false
end


-- Retrieve the user with a given username.
function GetUser(username)
    for index, value in pairs(database) do
        if (value.username == username) then
            return value
        end
    end
    return nil
end


-- Main program function.
function Main()
    if (TryLoadData()) then
        print("Loaded saved authentication data.")
    end

    -- Open our listener channel.
    modem.open(12460)
    print("Opened listener...")
    while true do
        local event, modemSide, senderChannel, replyChannel,
        message = os.pullEvent("modem_message")
        local command = commands[message[1]]
        if (command) then
            command(message, replyChannel)
        else
            print("Invalid command received.")
            modem.transmit(replyChannel, listenChannel, {"ack", "Invalid command."})
        end
    end
end

-- Run the program.
Main()