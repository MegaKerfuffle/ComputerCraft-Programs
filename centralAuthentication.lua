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
        - clearnace: string username
        Admin 
        - delete_user: string username, string authToken
        - set_clearance: string username, int newClearance, string authToken

    Auth Responses
        Public
        - ack: string details
        - success: string details
        - failure: string details
        - login_token: string authToken, user userData
        - clearance: string username, string clearance
]]

-- Settings
local intModemLocation = "top"
local extModemLocation = "back"
local listenChannel = 12460

-- Internal Vars
local database = {}
local tokens = {}
local intModem = peripheral.wrap(intModemLocation)
local extModem = peripheral.wrap(extModemLocation)
local commands = {
    -- Public commands; no auth required.
    ["register"] = function(message, returnChannel, modem)
        if (IsUser(message[2])) then
            modem.transmit(returnChannel, listenChannel, {"failure", "User already registered."})
            return
        end

        AddUser(message[2], message[3])
        modem.transmit(returnChannel, listenChannel, {"success", "Registered user ".. message[2]})
    end,
    ["unregister"] = function(message, returnChannel, modem)
        if (IsUser[message[2]] and VerifyAccess(message[2], message[3])[1]) then
            RemoveUser(message[2])
            print("Removed user ".. message[2])
            modem.transmit(returnChannel, listenChannel, {"success", "Unregistered user ".. message[2]})
        else
            print("Can't unregister user; sender is either not a user or not authed.")
            modem.transmit(returnChannel, listenChannel, {"failure", "Failed to unregister user."})
        end
    end,
    ["login"] = function(message, returnChannel, modem)
        if (IsUser(message[2])) then
            local auth = LoginUser(message[2], message[3])
            if (auth[1]) then
                local token = auth[2]
                local publicUser = GetUser(message[2])
                publicUser.password = nil
                print("Successfully logged user in.")
                modem.transmit(returnChannel, listenChannel, {"login_token", token, publicUser})
            else
                print("Can't login; invalid credentials.")
                modem.transmit(returnChannel, listenChannel, {"failure", "Invalid credentials."})
            end
        else
            print("Can't login; user doesn't exist.")
            modem.transmit(returnChannel, listenChannel, {"failure", "User doesn't exist."})
        end
    end,
    ["clearance"] = function(message, returnChannel, modem)
        if (IsUser(message[2])) then
            local user = GetUser(message[2])
            print("Retrieved clearance for a user.")
            modem.transmit(returnChannel, listenChannel, {"clearance", user.name, user.clearance})
        else
            print("Couldn't retrieve clearance; user doesn't exist.")
            modem.transmit(returnChannel, listenChannel, {"failure", "Invalid user."})
        end
    end,
}

-- Load our custom APIs
os.loadAPI("persistence.lua")
os.loadAPI("user.lua")


-- Persistently save the database.
function SaveDatabase()
    persistence.save("cas-data", database)
end

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
    SaveDatabase()
    print("Added a user.")
    return {true, "Successfully added user."}
end


-- Remove a user from the database.
function RemoveUser(username)
    for key, value in pairs(database) do
        if value.name == username then
            table.remove(database, key)
            SaveDatabase()
            return {true, "Successfully removed user."}
        end
    end
    return {false, "User not in database."}
end


-- Attempt to login a user. Returns a login token if successful.
function LoginUser(username, password)
    if (VerifyAccess(username, password)[1]) then
        local user = GetUser(username)
        if (user == nil) then
            return {false, nil}
        end
    
        local userToken = GenerateToken()
        -- FIXME: Tokens need to be replaced on multiple logins.
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
        local verified = user.password == password
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
        if (value.name == username) then
            return true
        end
    end
    return false
end


-- Retrieve the user with a given username.
function GetUser(username)
    for index, value in pairs(database) do
        if (value.name == username) then
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
    intModem.open(listenChannel)
    extModem.open(listenChannel)
    print("Opened listener on channel ".. listenChannel)
    while true do
        local event, modemSide, senderChannel, replyChannel,
        message = os.pullEvent("modem_message")

        -- Find which modem we gotta use to reply.
        local modem
        if (modemSide == intModemLocation) then
            modem = intModem
        elseif (modemSide == extModemLocation) then
            modem = extModem
        else
            print("Could not determine modem; aborting...")
            return
        end

        local command = commands[message[1]]
        if (command) then
            command(message, replyChannel, modem)
        else
            print("Invalid command received.")
            modem.transmit(replyChannel, listenChannel, {"ack", "Invalid command."})
        end
    end
end


-- Management stuff

function Manager_RegisterUser()
    print("User Registration")
    print("Username: ")
    local username = read()
    print("Password: ")
    local password = read("*")
    AddUser(username, password)
    print("Done!")
    os.sleep(2)
    term.clear()
    term.setCursorPos(1,1)
end

function Manager_DeleteUser()
    print("User Deletion")
    print("Enter username: ")
    local username = read()
    print("Are you sure? (Y/N)")
    local inp = read()
    while true do
        if (inp == "N") then
            return
        elseif (inp == "Y") then
            RemoveUser(username)
            print("Done!")
            os.sleep(2)
            term.clear()
            term.setCursorPos(1,1)
            return
        else
            print("Are you sure? (Y/N)")
        end
    end
end 

function Manager_SetClearance()
    print("User Clearance")
    print("Enter username: ")
    local username = read()
    print("Enter clearance level: ")
    local clearance = read()
    local user = GetUser(username)
    print("got user" .. user.name)
    user.clearance = clearance
    SaveDatabase()
    print("Done!")
    os.sleep(2)
    term.clear()
    term.setCursorPos(1,1)
end

function Manager_ListEntries()
    print("Users")
    for index, value in pairs(database) do
        print(index .." - ".. value.name .." (C"..value.clearance..")")
    end
    print("Done!")
    os.sleep(2)
    term.clear()
    term.setCursorPos(1,1)
end

function ManagerMain()
    while true do
        print("What would you like to do? (".. #database .. " database entries)")
        print("1) Register a user")
        print("2) Delete a user")
        print("3) Set user clearance")
        print("4) List users")
        local inp = read()
        if (inp == "1") then
            Manager_RegisterUser()
        elseif (inp == "2") then
            Manager_DeleteUser()
        elseif (inp == "3") then
            Manager_SetClearance()
        elseif (inp == "4") then
            Manager_ListEntries()
        else
            print("Invalid input.")
        end
    end
end

-- Run the program.
parallel.waitForAll(Main, ManagerMain)