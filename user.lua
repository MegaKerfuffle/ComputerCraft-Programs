--[[
    A representation of a user, mainly used by the central
    authentication service.

    Clearances:
        X - blacklisted
        0 - no clearance
        1 to 5 - higher is more secure
]]

-- Can add a bunch of methods in here if need be.
local user = {
    check_password = function(self, passwordInput)
        return self.password == passwordInput
    end,
    tostring = function(self)
        return self.name
    end,
    equals = function(self, other)
        return self.name == other.name
    end
}

local umetatable = {
    __index = user,
    __checkpw = user.check_password,
    __tostring = user.tostring,
    __eq == user.equals,
}

function new(username, password)
    return setmetatable({
        uid = 0,
        name = username,
        password = password,
        balance = 25.0,
        clearance = "0", -- a string
    }, umetatable)
end