local lastdata = nil
ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function DiscordRequest(method, endpoint, jsondata)
    local data = nil
    PerformHttpRequest("https://discordapp.com/api/" .. endpoint,
                       function(errorCode, resultData, resultHeaders)
        data = {data = resultData, code = errorCode, headers = resultHeaders}
    end, method, #jsondata > 0 and json.encode(jsondata) or "", {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bot " .. Config.token
    })

    while data == nil do Citizen.Wait(0) end

    return data
end



function string.starts(String, Start)
    return string.sub(String, 1, string.len(Start)) == Start
end

function mysplit(inputstr, sep)
    if sep == nil then sep = "%s" end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

function GetRealPlayerName(playerId)
        local xPlayer = ESX.GetPlayerFromId(playerId)
        return xPlayer.getName()
    end

function ExecuteCOMM(command)
    if string.starts(command, Config.Prefix) then

    if string.starts(command, Config.Prefix .. "kick") and Config.kick then

            local t = mysplit(command, " ")

            if t[2] ~= nil and GetPlayerName(t[2]) ~= nil then
                sendToDiscord("Kick System",
                              "Wyrzucony pomyślnie " .. GetPlayerName(t[2]),
                              16711680)
                DropPlayer(t[2], "[ServerMenager_Bot] Wyrzucony Przez Bota Discord")

            else

                sendToDiscord("Kick System",
                              "Nie można znaleźć identyfikatora. Upewnij się, że wprowadziłeś prawidłowy identyfikator",
                              16711680)

            end

        elseif string.starts(command, Config.Prefix .. "revive") and Config.revive then
                local t = mysplit(command, " ")
                if t[2] ~= nil and GetPlayerName(t[2]) ~= nil then
                    TriggerClientEvent("esx_ambulancejob:revive", t[2])
                    sendToDiscord("Revive System",
                                  "Pomyślnie ożywiony " .. GetPlayerName(t[2]),
                                  16711680)

                else

                    sendToDiscord("Revive System",
                                  "Nie można znaleźć identyfikatora. Upewnij się, że wprowadziłeś prawidłowy identyfikator",
                                  16711680)

                end

        elseif string.starts(command, Config.Prefix .. "setjob") and Config.setjob then
                local t = mysplit(command, " ")
                if t[2] ~= nil and GetPlayerName(t[2]) ~= nil then
                    local xPlayer = ESX.GetPlayerFromId(t[2])
                    if xPlayer then

                        if t[3] and t[4] then
                            xPlayer.setJob(tostring(t[3]),t[4])
                            sendToDiscord("Job System",
                                          "Pomyślnie zmieniłeś prace " ..
                                              xPlayer.getName() .. ' na ' .. tostring(t[3]),
                                          16711680)
                        else
                            sendToDiscord("Job System",
                                          "Nazwa JOB LUB Stanowisko było nieprawidłowe. Upewnij się, że wpisujesz w ten sposób:\nsetjob <id> <job_name> <grade_number>",
                                          16711680)
                        end

                    end

                else

                    sendToDiscord("Job System",
                                  "Nie można znaleźć identyfikatora. Upewnij się, że wprowadziłeś prawidłowy identyfikator",
                                  16711680)

                end

        elseif string.starts(command, Config.Prefix .. "announce") and Config.announce then

            local safecom = command
            local t = mysplit(command, " ")
            if t[2] ~= nil then

                TriggerClientEvent("ServerMenager_Bot:announce", -1, string.gsub(safecom, Config.Prefix .. "announce", ""))

                sendToDiscord("Announce System",
                              "Wysłano pomyślnie: " ..
                                  string.gsub(safecom,
                                    Config.Prefix .. "announce", "") ..
                                  " | Do " .. GetNumPlayerIndices() ..
                                  " Graczy Na Wyspie", 16711680)

            else

                sendToDiscord("Announce System", "Nieprawidłowy Input", 16711680)
            end

            -- Command Not Found
        else

            sendToDiscord("ServerMenager_Bot",
                          "Nie znaleziono polecenia. Upewnij się, że wprowadzasz prawidłowe polecenie",
                          16711680)

        end
    end

end

Citizen.CreateThread(function()

    PerformHttpRequest(Config.webhook, function(err, text, headers) end, 'POST',
                       json.encode({
        username = Config.Nazwa,
        content = "**[ServerMenager_Bot]** __Bot Discord Jest Online__",
        avatar_url = Config.AvatarURL
    }), {['Content-Type'] = 'application/json'})
    while true do

        local chanel =
            DiscordRequest("GET", "channels/" .. Config.id_kanalu, {})
        if chanel.data then
            local data = json.decode(chanel.data)
            local lst = data.last_message_id
            local lastmessage = DiscordRequest("GET", "channels/" ..
                                                   Config.id_kanalu ..
                                                   "/messages/" .. lst, {})
            if lastmessage.data then
                local lstdata = json.decode(lastmessage.data)
                if lastdata == nil then lastdata = lstdata.id end

                if lastdata ~= lstdata.id and lstdata.author.username ~=
                    Config.Nazwa then

                    ExecuteCOMM(lstdata.content)
                    lastdata = lstdata.id
                    --	sendToDiscord('New Message Recived',lstdata.content,16711680)

                end
            end
        end
        Citizen.Wait(Config.WaitEveryTick)
    end
end)

function sendToDiscord(name, message, color)
    local connect = {
        {
            ["color"] = color,
            ["title"] = "**" .. name .. "**",
            ["description"] = message,
            ["footer"] = {["text"] = "ServerMenager_Bot"}
        }
    }
    PerformHttpRequest(Config.webhook, function(err, text, headers) end, 'POST',
                       json.encode({
        username = Config.Nazwa,
        embeds = connect,
        avatar_url = Config.AvatarURL
    }), {['Content-Type'] = 'application/json'})
end
