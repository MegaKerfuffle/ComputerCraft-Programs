--[[
    Sup this is designed to allow a user to easily save or retrieve persistent data 
    from the local computer. 
]]

-- Create the data directory if it doesn't already exist.
if not fs.exists("/.data") then
    fs.makeDir("/.data")
end

-- Save a value with a certain key
function save(key, value)
    local filePath = fs.combine("/.data", key)
    if (value == nil) then
        print("No value was given for persistent saving; things will break!")
        return fs.delete(filePath)
    end
    local dataFile = fs.open(filePath, "w")
    dataFile.write(textutils.serializeJSON(value))
    dataFile.close()
end


-- Load a value using a given key
function load(key)
    local filePath = fs.combine("/.data", key)
    if fs.exists(filePath) then
        local dataFile = fs.open(filePath, "r")
        local value = dataFile.readAll()
        dataFile.close()
        return textutils.unserializeJSON(value)
    else
        return nil
    end
end


-- Delete the value at a given key
function delete(key)
    local filePath = fs.combine("/.data", key)
    return fs.delete(filePath)
end