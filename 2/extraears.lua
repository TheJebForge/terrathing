local modem = peripheral.wrap("back")
modem.open(55)
local ecc = require("ecc")

math.randomseed(os.time() * 10000)
local randomseed = math.random(1, 22222222)
local prv, pub = ecc.keypair(randomseed)

local serverShared = {}

while true do
    local event, side, sender, reply, message, distance = os.pullEvent("modem_message")

    if event == "modem_message" then
        if type(message) == "table" then
            if message.response == "acceptedAuth" then
                print("got public")
                serverShared = ecc.exchange(prv, message.pub)
            elseif message.response == "hoi" then
                print("got message")
                print("message:", ecc.decrypt(message.message, serverShared))
            end
        end
    end
end