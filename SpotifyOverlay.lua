name = "Spotify Overlay"
description = "Spotify Overlay"


---@diagnostic disable: undefined-field
---@diagnostic disable: param-type-mismatch


importLib("anetwork")
anetwork.Initialise(1)

positionX = 0
positionY = 0
sizeX = 150
sizeY = 75
scale = 1


CACHEPATH = "SpotifyOverlay/tokencache.json"
REFRESHPATH = "SpotifyOverlay/refreshcache.txt"
LOGPATH = "SpotifyOverlay/apiLogs.txt"

SPOTIFY_LOGO_LINK = "https://storage.googleapis.com/pr-newsroom-wp/1/2023/05/Spotify_Primary_Logo_RGB_Green.png"
CLIDAS = "&client_id=0cf442a705504a94acaeed65f98b6417&client_secret=8237b2069cd04618bbb12a8c07237538"

TRACK_DATA = {
    track_id = "",
    track_name = "No Song Playing or Spotify is closed",
    artist = "No Artist",
    album_name = "No Album",
    track_progress = 0,
    track_duration = 0,
    album_art_link = SPOTIFY_LOGO_LINK,
    album_art = gfx2.loadImageFromUrl(SPOTIFY_LOGO_LINK),
    album_art_blurred = gfx2.loadImageFromUrl(SPOTIFY_LOGO_LINK)
}



-- function clearLogs()
--     fs.delete(LOGPATH)
-- end

function resetSettings()
    mainTextColor = {255, 255, 255, 255}
    durationTextColor = {255, 255, 255, 255}
    prgbarOutlineColor = {255, 255, 255, 255}
    prgbarColor = {255, 255, 255, 255}
    mainOutlineColor = {255, 255, 255, 255}
    albumArtOutlineColor = {255, 255, 255, 255}
    marqueeText = true
    bgBlur = true
    updateInterval = 5
    -- logsEnabled = false
end


client.settings.addAir(10)
client.settings.addCategory("Color Settings")
mainTextColor = client.settings.addNamelessColor("Main Text Color", {255, 225, 255, 255})
durationTextColor = client.settings.addNamelessColor("Duration Text Color", {255, 225, 255, 255})
prgbarOutlineColor = client.settings.addNamelessColor("Progressbar Outline Color", {255, 225, 255, 255})
prgbarColor = client.settings.addNamelessColor("Progressbar Color", {255, 225, 255, 255})
mainOutlineColor = client.settings.addNamelessColor("Main Outline Color", {255, 225, 255, 255})
albumArtOutlineColor = client.settings.addNamelessColor("Album Art Outline Color", {255, 225, 255, 255})
client.settings.stopCategory()

client.settings.addAir(10)
client.settings.addCategory("Visual Settings")
marqueeText = true
client.settings.addBool("Marquee Text", "marqueeText")
client.settings.addInfo("Turns on or off the marquee text (scrolling text).\nMarquee text is only enabled if the text does not fully fit in the overlay.\nWARNING: Can cause (slight) performance issues on lower-end computers.")
bgBlur = true
client.settings.addBool("Background Blur", "bgBlur")
client.settings.addInfo("WARNING: Can cause (moderate) performance issues on lower-end computers.")
client.settings.stopCategory()

client.settings.addAir(10)
client.settings.addCategory("Miscellaneous Settings")
updateInterval = 5
client.settings.addInt("API Update Interval (seconds)", "updateInterval", 1, 20)
client.settings.addInfo("Specifies the amount of time before another API request is sent.\nWARNING: Setting this too low can result in rate limiting.")
-- logsEnabled = false
-- client.settings.addBool("Enable API logs", "logsEnabled")
-- client.settings.addInfo("Useful for debugging.\nWARNING: This setting logs every API request sent, which can take hoard storage if left turned on.")
-- client.settings.addFunction("Clear API Logs", "clearLogs", "Clear")
-- client.settings.addInfo("Deletes the API log file.")
client.settings.addFunction("Reset Settings to Default", "resetSettings", "Reset")
client.settings.stopCategory()



registerCommand("spotify", function(args)
    local argsTable = {}
    for i in args:gmatch("%S+") do
        table.insert(argsTable, i)
    end
    if argsTable[1] == "help" then
        print("...")
        print("§lSpotifyOverlay Commands List:§r")
        print("§l.spotify setup§r - Setup the Spotify Overlay Script.")
        print("§l.spotify auth§r - Get the Spotify Auth Token.")
        print("§l.spotify refreshtoken§r - Get the Spotify Refresh Token.")
        print("§l.spotify printdata§r - Print the current Spotify track info.")
        print("§l.spotify copydata§r - Copy the current Spotify track info.")
        print("§l.spotify cleardata§r - Purge the Spotify Overlay cache.")
        print("...")
    elseif argsTable[1] == "cleardata" then
        fs.delete("SpotifyOverlay")
    fs.mkdir("SpotifyOverlay")
    elseif argsTable[1] == "setup" then
        print("...")
        print("Welcome to the Spotify Overlay Script!")
        print("To get started, run the <§l.spotify auth§r> command.")
        print("This will copy a URL to your clipboard, which you have to paste in a browser.")
        print("After doing that, copy the URL you were redirected to you and use it in the <§l.spotify refreshtoken§r> command.")
        print("Then you should be good to go!")
        print("...")
    elseif argsTable[1] == "printdata" then
        print("...")
        print(get_track_info_str(TRACK_DATA))
        print("...")
    elseif argsTable[1] == "copydata" then
        setClipboard(get_track_info_str(TRACK_DATA))
        print("Copied current spotify track info!")
    elseif argsTable[1] == "auth" then
        local reqUrl = "https://accounts.spotify.com/authorize?"
            .."response_type=code"
            ..CLIDAS
            .."&scope=user-read-currently-playing"
            .."&redirect_uri=https%3A%2F%2Flocalhost%3A7777%2Fcallback"
        setClipboard(reqUrl)
        client.notification("Spotify Auth URL copied to clipboard.")
    elseif argsTable[1] == "refreshtoken" then
        if argsTable[2] then
            if argsTable[2]:sub(1, 31) == 'https://localhost:7777/callback' then
                anetwork.post(
                    "https://accounts.spotify.com/api/token",
                    "grant_type=authorization_code&redirect_uri=https%3A%2F%2Flocalhost%3A7777%2Fcallback&code="..argsTable[2]:sub(38, -1)..CLIDAS,
                    {},
                    function(resp,err)
                        if resp then
                            io.open(REFRESHPATH, 'w+'):write(jsonToTable(resp.body).refresh_token)
                            client.notification("Spotify API Refresh Token created.")
                        end
                    end,
                    "POST"
                )
                -- if logsEnabled then io.open(LOGPATH, 'a+'):write("["..os.time().."] Sent POST request to /api/token\n") end
            end
        else
            client.notification("Invalid callback URL.")
        end
    end
end)



function onEnable()
    if not fs.exist("SpotifyOverlay") then
        fs.mkdir("SpotifyOverlay")
    end
    if not fs.exist(REFRESHPATH) then
        -- print("§l[§2Spotify§fOverlayScript]§r Run .spotifysetup to get started.")
        client.notification("Run .spotify setup to get started.")
    end
end

-- function onDisable()
--     if fs.exist(CACHEPATH) then
--         fs.delete(CACHEPATH)
--     end
-- end

song_end = nil
function postInit()
    get_token()
    song_end = os.clock() + TRACK_DATA.track_duration/1000 - TRACK_DATA.track_progress/1000
end



function get_track_info_str(trackData)
    return "Track Name: "..trackData.track_name.."\n"..
           "Artist: "..trackData.artist.."\n"..
           "Album: "..trackData.album_name.."\n"..
           "Track Progress: "..math.floor(trackData.track_progress/1000//60)..":"..string.format("%0.2i", math.floor(trackData.track_progress/1000 - math.floor(trackData.track_progress/1000//60)*60)).."\n"..
           "Track Duration: "..math.floor(trackData.track_duration/1000//60) ..":"..string.format("%0.2i", math.floor(trackData.track_duration/1000 - math.floor(trackData.track_duration/1000//60)*60)).."\n"..
           "Track ID: "..trackData.track_id
end


function reduce_len(str, len)
    if str:len() >= len+3 then
        return str:sub(1, len):match( "^%s*(.-)%s*$" ).."..."
    else
        return str
    end
end


RENDER_BG_ALB_ART = false
BLUR_ALB_ART = true
STOP_PRGBAR = true
function update_text(resp, err)
    if not resp then return end
    local r = jsonToTable(resp.body)
    if r and r.item then
        TRACK_DATA.track_id = r.item.id
        TRACK_DATA.track_name = r.item.name
        TRACK_DATA.artist = r.item.artists[1].name
        TRACK_DATA.album_name = r.item.album.name
        TRACK_DATA.track_progress = r.progress_ms
        TRACK_DATA.track_duration = r.item.duration_ms
        local albUrl300px = r.item.album.images[2].url
        if TRACK_DATA.album_art_link ~= albUrl300px then
            RENDER_BG_ALB_ART = false
            TRACK_DATA.album_art = gfx2.loadImageFromUrl(albUrl300px)
            TRACK_DATA.album_art_blurred = gfx2.loadImageFromUrl(albUrl300px)
            TRACK_DATA.album_art_link = albUrl300px
            BLUR_ALB_ART = true
        end
        temp_track_progress = TRACK_DATA.track_progress
        STOP_PRGBAR = false
    else
        TRACK_DATA.track_id = nil
        TRACK_DATA.track_name = "No Song Playing or Spotify is closed"
        TRACK_DATA.artist = "No Artist"
        TRACK_DATA.album_name = "No Album"
        TRACK_DATA.album_art_link = SPOTIFY_LOGO_LINK
        TRACK_DATA.track_duration = 1
        TRACK_DATA.album_art = gfx2.loadImageFromUrl(SPOTIFY_LOGO_LINK)
        TRACK_DATA.album_art_blurred = gfx2.loadImageFromUrl(SPOTIFY_LOGO_LINK)
        TRACK_DATA.track_progress = 0
        STOP_PRGBAR = true
    end
end


last_token_req = nil
function get_token()
    if not fs.exist(REFRESHPATH) then return end
    local action = ''
    local refresh_cache = io.open(REFRESHPATH,'r'):read("*a")
    if fs.exist(CACHEPATH) then
        local token_cache = io.open(CACHEPATH,'r'):read("*a")
        if token_cache and (os.time() - fs.stats(CACHEPATH).writetime < 3600)  then
            if token_cache:len()>0 then
                get_song(jsonToTable(token_cache), "UNREFRESHED")
            else
                action = 'refresh'
            end
        else
            action = 'refresh'
        end
    else
        action = 'refresh'
    end
    if action == 'refresh' then
        local data = "grant_type=refresh_token&refresh_token="..refresh_cache..CLIDAS
        anetwork.post("https://accounts.spotify.com/api/token", data, {}, get_song, "POST")
        -- if logsEnabled then io.open(LOGPATH, 'a+'):write("["..os.time().."] Sent POST request to /api/token\n") end
    end
end


function get_song(resp, err)
    local token = ''
    if err == "UNREFRESHED" then
        token = resp.access_token
    else
        token = jsonToTable(resp.body).access_token
        io.open(CACHEPATH, 'w+'):write(resp.body)
    end
    if not token then return end
    anetwork.get("https://api.spotify.com/v1/me/player/currently-playing", {Authorization = "Bearer "..token}, update_text)
    -- if logsEnabled then io.open(LOGPATH, 'a+'):write("["..os.time().."] Sent GET request to /v1/me/player/currently-playing\n") end
end



updt = 0
temp_track_progress = TRACK_DATA.track_progress
last_track_id = ""
function update(dt)
    if TRACK_DATA.track_id ~= last_track_id then
        xOffsetTrack = 0
        xOffsetArtist = 0
        xOffsetAlbum = 0
        last_track_id = TRACK_DATA.track_id
    end
    if not STOP_PRGBAR then
        temp_track_progress = temp_track_progress + dt*1000
    else
        temp_track_progress = 0
    end
    if bgBlur and BLUR_ALB_ART then
        if TRACK_DATA.album_art_blurred.width > 0 then
            TRACK_DATA.album_art_blurred:blur(5)
            TRACK_DATA.album_art_blurred:unload()
            BLUR_ALB_ART = false
            RENDER_BG_ALB_ART = true
        end
    end
    updt = updt + dt
    anetwork.Tick()
    local current = os.clock()
    if song_end then
        if (current >= song_end) then
            get_token()
            song_end = current + TRACK_DATA.track_duration/1000 - TRACK_DATA.track_progress/1000
            updt = 0
        elseif updt >= updateInterval then
            get_token()
            updt = 0
        end
    end
end



xOffsetTrack = 0
xOffsetArtist = 0
xOffsetAlbum = 0
function render2(dt)

    local fw2, fh2 = gfx2.textSize("A", 2)
    local fw1p5, fh1p5 = gfx2.textSize("A", 1.5)

    gfx2.bindRenderTarget(nil)

    gfx2.pushUndocumentedClipArea(0, 0, 150, 75, 10)
    gfx2.color(120, 120, 120, 240)
    gfx2.fillRoundRect(0, 0, 150, 75, 10)
    if bgBlur then
        if TRACK_DATA.album_art_blurred and RENDER_BG_ALB_ART then
            gfx2.drawImage(0,-50,150,150,TRACK_DATA.album_art_blurred)
        end
    else
        if TRACK_DATA.album_art then
            gfx2.drawImage(0,-50,150,150,TRACK_DATA.album_art)
        end
    end
    for i = 1, 255 do
        gfx2.color(0, 0, 0, 255 - i)
        gfx2.fillRect(i - 1, 0, 1, 150)
    end
    gfx2.color(mainOutlineColor)
    gfx2.drawRoundRect(0, 0, 150 ,75, 10, 1)
    gfx2.popUndocumentedClipArea(1)

    gfx2.color(mainTextColor)

    gfx2.pushClipArea(14, 11, fw2*13, fh2)
    if marqueeText then
        if gfx2.textSize(TRACK_DATA.track_name, 2) > fw2*13 then
            xOffsetTrack = xOffsetTrack + fw2/100
            gfx2.text(14 - xOffsetTrack, 11, TRACK_DATA.track_name.."  ", 2)
            if xOffsetTrack >= gfx2.textSize(TRACK_DATA.track_name.."  ", 2) then
                xOffsetTrack = -fw2*13
            end
        else
            gfx2.text(14, 11, TRACK_DATA.track_name, 2)
        end
    else
        gfx2.text(14, 11, reduce_len(TRACK_DATA.track_name, 13), 2)
    end
    gfx2.popClipArea(1)

    gfx2.pushClipArea(14, 11 + fh2, fw1p5*17, fh1p5*2)
    if marqueeText then
        if gfx2.textSize(TRACK_DATA.artist, 2) > fw2*13 then
            xOffsetArtist = xOffsetArtist + fw2/100
            gfx2.text(14 - xOffsetArtist, 11 + fh2, TRACK_DATA.artist.."  ", 1.5)
            if xOffsetArtist >= gfx2.textSize(TRACK_DATA.artist.."  ", 1.5) then
                xOffsetArtist = -fw2*13
            end
        else
            gfx2.text(14, 11 + fh2, TRACK_DATA.artist, 1.5)
        end
        if gfx2.textSize(TRACK_DATA.album_name,2) > fw2*13 then
            xOffsetAlbum = xOffsetAlbum + fw2/100
            gfx2.text(14 - xOffsetAlbum, 11 + fh2 + fh1p5, TRACK_DATA.album_name.."  ", 1.5)
            if xOffsetAlbum >= gfx2.textSize(TRACK_DATA.album_name.."  ", 1.5) then
                xOffsetAlbum = -fw2*13
            end
        else
            gfx2.text(14, 11 + fh2 + fh1p5, TRACK_DATA.album_name, 1.5)
        end
    else
        gfx2.text(14, 11 + fh2, reduce_len(TRACK_DATA.artist, 17), 1.5)
        gfx2.text(14, 11 + fh2 + fh1p5, reduce_len(TRACK_DATA.album_name, 17), 1.5)
    end
    gfx2.popClipArea(1)

    gfx2.color(durationTextColor)
    gfx2.text(14, 11 + fh2*2 + fh1p5*1.5, math.floor(temp_track_progress/1000//60)..":"..string.format("%0.2i", math.floor(temp_track_progress/1000 - math.floor(temp_track_progress/1000//60)*60)), 1)
    gfx2.text(124, 11 + fh2*2 + fh1p5*1.5, math.floor(TRACK_DATA.track_duration/1000//60) ..":"..string.format("%0.2i", math.floor(TRACK_DATA.track_duration/1000 - math.floor(TRACK_DATA.track_duration/1000//60)*60)), 1)

    gfx2.color(prgbarOutlineColor)
    gfx2.drawRoundRect(30,13 + fh2*2 + fh1p5*1.5,90,3,1,1)
    gfx2.color(prgbarColor)
    if temp_track_progress < TRACK_DATA.track_duration then
        gfx2.fillRoundRect(30, 13.5 + fh2*2 + fh1p5*1.5, 90*temp_track_progress/TRACK_DATA.track_duration, 2, 2)
    else
        gfx2.fillRoundRect(30, 13.5 + fh2*2 + fh1p5*1.5, 90, 2, 2)
    end

    if TRACK_DATA.track_id:len()>0 then
        gfx2.pushUndocumentedClipArea(110, 10, 30, 30, 5)
        if TRACK_DATA.album_art then gfx2.drawImage(110, 10, 30, 30, TRACK_DATA.album_art) end
        gfx2.color(albumArtOutlineColor)
        gfx2.drawRoundRect(110, 10, 30, 30, 5, 1)
        gfx2.popUndocumentedClipArea(1)
    end
end

