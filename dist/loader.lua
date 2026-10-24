-- [[ 1. กำหนดค่าพื้นฐาน ]]
getgenv().ScriptKey = getgenv().ScriptKey or ""
local KeyFileName = "FyrelithHub_Key.txt"
local baseUrl = "https://raw.githubusercontent.com/tobedicided/FyrelithHub/dist/dist/%s.lua"

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ป้องกันการรันซ้ำ
if getgenv().FyrelithHubLoaded then
    warn("[Fyrelith Hub] สคริปต์กำลังทำงานอยู่แล้ว")
    return
end
getgenv().FyrelithHubLoaded = true

-- [[ 2. โหลด PandaAuth PUSL-V4 ]]
local fetchLibSuccess, PUSL = pcall(function()
    return loadstring(game:HttpGet("https://secure.pandauth.com/pv4/lib"))()
end)

if not fetchLibSuccess or not PUSL or type(PUSL.configure) ~= "function" then
    getgenv().FyrelithHubLoaded = false
    LocalPlayer:Kick("\n\n[Fyrelith Hub]\nไม่สามารถโหลด Library ตรวจสอบคีย์ได้\nกรุณาลองใหม่อีกครั้งในภายหลัง")
    return
end

-- ตั้งค่า Service ตาม Dashboard
PUSL.configure({
    serviceId = "fyrelithhub",
})

-- [[ 3. ฟังก์ชันอ่านและบันทึกคีย์ลงเครื่อง ]]
local function GetSavedKey()
    if isfile and isfile(KeyFileName) then
        local content = readfile(KeyFileName)
        if content and #content > 0 then
            return content:gsub("%s+", "")
        end
    end
    return ""
end

local function SaveKey(key)
    if writefile and key and key ~= "" then
        writefile(KeyFileName, key)
    end
end

-- [[ 4. ฟังก์ชันเริ่มรันสคริปต์ตามแมพ ]]
local function LaunchHub()
    local placeId = game.PlaceId
    local targetUrl = string.format(baseUrl, tostring(placeId))

    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Fyrelith Hub",
        Text = "ยืนยันคีย์สำเร็จ! กำลังโหลดแมพ...",
        Duration = 5
    })

    -- ดึงโค้ดตาม PlaceId
    local fetchSuccess, scriptContent = pcall(function()
        return game:HttpGet(targetUrl)
    end)

    if fetchSuccess and scriptContent and not scriptContent:find("404: Not Found") then
        local runSuccess, runError = pcall(function()
            loadstring(scriptContent)()
        end)
        if not runSuccess then
            warn("[Fyrelith Hub] Error ขณะรันโค้ดแมพ:", runError)
        end
    else
        -- ถ้าไม่มีแมพเฉพาะ ให้ดึงตัว universal
        local fallbackUrl = string.format(baseUrl, "universal")
        local fallbackSuccess, fallbackContent = pcall(function()
            return game:HttpGet(fallbackUrl)
        end)
        if fallbackSuccess and fallbackContent and not fallbackContent:find("404: Not Found") then
            loadstring(fallbackContent)()
        else
            warn("[Fyrelith Hub] ไม่พบสคริปต์สำหรับ PlaceId นี้ และไม่พบ universal.lua")
        end
    end
end

-- [[ 5. ตรวจสอบคีย์ ]]
local currentKey = (getgenv().ScriptKey ~= "" and getgenv().ScriptKey) or GetSavedKey()

if currentKey == "" then
    getgenv().FyrelithHubLoaded = false
    LocalPlayer:Kick("\n\n[Fyrelith Hub]\nไม่พบคีย์การใช้งาน\nกรุณาใส่คีย์ใน getgenv().ScriptKey ก่อนสั่งรัน")
    return
end

-- ตรวจสอบคีย์ผ่าน PUSL.validate
local validateSuccess, result = pcall(function()
    return PUSL.validate(currentKey)
end)

if validateSuccess and result and result.success then
    SaveKey(currentKey) -- เซฟคีย์ลงเครื่องเมื่อผ่าน
    LaunchHub()
else
    getgenv().FyrelithHubLoaded = false
    LocalPlayer:Kick("\n\n[Fyrelith Hub]\nคีย์ไม่ถูกต้อง หรือหมดอายุการใช้งานแล้ว\nกรุณาติดต่อร้านค้าเพื่อต่ออายุคีย์")
    return
end
