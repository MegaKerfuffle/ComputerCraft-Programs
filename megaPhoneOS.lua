--[[
    MegaPhone OS

    Author 
        Rob, Discord @MegaKerfuffle#9278

    Summary
        MegaPhone OS is responsible for running the MegaPhone
        personally computing and communication device.

    Notes
        - N/A
]]
local args = { ... }

-- Load APIs
os.loadAPI("user.lua")
os.loadAPI("authentication.lua")

-- Internal vars
local currentUser = nil

function PressAnyKey()
    print("PRESS ANY KEY TO CONTINUE")
    local event, key = os.pullEvent("key")
end

function CenterCursorForText(text)
    local w,h = term.getSize()
    local x,y = term.getCursorPos()
    term.setCursorPos(math.floor(w/2 - #text / 2 + 0.5), y)
end


function DrawTopBar()
    local template = {
        "MegaPhoneOS® v0.1.0",
        "%s | BAL: M$ %d",
        "USER: %s/C%s",
        "--------------------------"
    }
    -- Format the template with needed data.
    local time = textutils.formatTime(os.time())
    local balance = 0.0 -- grab it from server eventually
    local userName = "GUEST"
    local clearance = "0"
    if (currentUser ~= nil) then
        balance = currentUser.balance
        userName = currentUser.name
        clearance = currentUser.clearance
    end
    template[2] = string.format(template[2], time, balance)
    template[3] = string.format(template[3], userName, clearance)

    -- Prep for display and display it.
    local x,y = term.getCursorPos()
    term.setCursorPos(1,1)
    for index, value in pairs(template) do
        print(value)
    end

    -- Reset cursor pos
    term.setCursorPos(x,y)
end


-- Initialize the OS
function Initialize()
    local template = {
        "    MegaPhone®\n\n",
        "      Powered by MegaCorp®\n\n\n\n"
    }
    local initTxt = "Initializing..."
    term.clear()
    term.setCursorPos(1,5)
    
    for key, value in pairs(template) do
        CenterCursorForText(value)
        textutils.slowPrint(value, 25)
    end
    CenterCursorForText(initTxt)
    print(initTxt)
    os.sleep(1)
    Main()
end


-- TODO: split up MUI into logged in and not logged in options
function Main()
    while true do
        term.clear()
        term.setCursorPos(1,5)
        DrawTopBar()
        print("Main Menu")
        print("  1) Login\n  2) Logout")
        local inp = read()
        if (inp == "1") then
            Login()
        elseif (inp == "2") then
            Logout()
        end
    end
end

function Login()
    print("Username: ")
    local username = read()
    print("Password: ")
    local password = read()
    local auth = authentication.TryLogin(username, password)
    if (auth[1]) then
        currentUser = auth[2]
    end
    PressAnyKey()
end

function Logout()
    while true do
        print("Are you sure? (Y/N)")
        local inp = read()
        if (inp == "Y") then
            authentication.Logout()
            currentUser = nil
            print("Logged out.\n")
            PressAnyKey()
            return
        elseif (inp == "N") then
            PressAnyKey()
            return
        else
            print("Are you sure? (Y/N)")
        end
    end
end

-- Start MegaPhoneOS
if (args[1] == "true") then
    Main()
else
    Initialize()
end