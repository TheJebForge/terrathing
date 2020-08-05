os.loadAPI("aes.lua")
local json = require("json")
local ecc = require("ecc")

local config = {}

local function loadServerConfig()
    local file = fs.open("config.json", "r")
    
    local conf = file:readAll()
    config = json.decode(conf)    
end

loadServerConfig()

local modem = peripheral.wrap(config.modemSide)
modem.open(config.modemChannel)

local function checkArg(what, whatType)
    if not type(what) == whatType then
        return false
    end

    return true
end

local function checkTable(t, ...)
    local args = { ... }
    
    for i = 1, #args, 2 do
        if not type(t[args[i]]) == args[i+1] then
            return false, args[i].." property: expected "..args[i+1]..", got "..type(t[args[i]])
        end
    end

    return true
end

local function parseMessage(msg)
    local ok, rtn = pcall(function() return json.decode(msg) end)

    if ok then
        return rtn
    end
end

local sessions = {}

math.randomseed(os.time() * 10000)
local randomseed = math.random(1, 22222222)
local prv, pub = ecc.keypair(randomseed)

while true do
    local event, side, sender, reply, message, distance = os.pullEvent()

    if event == "modem_message" then
        if type(message) == "table" then
            if message.type then
                -- unencrypted message
                if message.type == "auth" then
                    local ok, err = checkTable(message, "pub", "string", "computerid", "number")

                    if ok then
                        sessions[message.computerid] = ecc.exchange(prv, message.pub)
                        print("Connection made with computer "..message.computerid)
                        modem.transmit(reply, config.modemChannel, {
                            pub = pub,
                            response = "acceptedAuth"
                        })
                    else
                        modem.transmit(reply, config.modemChannel, {
                            error = err
                        })
                    end
                end
            else
                -- encrypted shit
                if message.test then
                    local ok, err = checkTable(message, "computerid", "number")

                    if ok then
                        print("Transmitting hoi test message to "..message.computerid)
                        modem.transmit(reply, config.modemChannel, {
                            response = "hoi",
                            message = ecc.encrypt("hoi this message is not readable without a proper key", sessions[message.computerid])
                        })
                    end
                end
            end
        end
    end

end