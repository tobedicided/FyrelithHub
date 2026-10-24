-- [[ 1. กำหนดค่าพื้นฐาน ]]
-- หากผู้ใช้ต้องการใส่คีย์ตรงในสคริปต์ สามารถวางในเครื่องหมายคำพูดได้
getgenv().ScriptKey = getgenv().ScriptKey or ""

-- ใส่ชื่อ Service ให้ตรงกับที่ตั้งไว้บนหน้า Dashboard ของ Panda Development
local ServiceName = "ใส่ชื่อServiceของคุณที่นี่"
local KeyFileName = "FyrelithHub_Key.txt"

-- URL ไปยัง GitHub ของคุณ (Branch: dist / Folder: dist)
local baseUrl = "https://raw.githubusercontent.com/tobedicided/FyrelithHub/dist/dist/%s.lua"

-- [[ 2. ป้องกันการรันสคริปต์ซ้อนกัน ]]
if getgenv().FyrelithHubLoaded then
    warn("[Fyrelith Hub] สคริปต์กำลังทำงานอยู่แล้ว")
    return
end
getgenv().FyrelithHubLoaded = true

-- [[ 3. อ้างอิง Services และโหลดไลบรารี PandaAuth ]]
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local successLib, PandaAuth = pcall(function()
    return loadstring(game:HttpGet("https://pandadevelopment.net/service_api/PandaLib.lua"))()
end)

if not successLib or not PandaAuth then
    LocalPlayer:Kick("\n\n[Fyrelith Hub]\nไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ตรวจสอบคีย์ได้\nกรุณาลองใหม่อีกครั้งในภายหลัง")
    return
end

-- ฟังก์ชันอ่านคีย์ที่เคยเซฟไว้ในโฟลเดอร์ Workspace ของ Executor
local function GetSavedKey()
    if isfile and isfile(KeyFileName) then
        local content = readfile(KeyFileName)
        if content and #content > 0 then
            return content:gsub("%s+", "") -- ตัดช่องว่างออก
        end
    end
    return ""
end

-- ฟังก์ชันบันทึกคีย์ลงเครื่อง
local function SaveKey(key)
    if writefile and key and key ~= "" then
        writefile(KeyFileName, key)
    end
end

-- [[ 4. ฟังก์ชันหลักสำหรับดึงสคริปต์ตามแมพ ]]
local function LaunchHub()
    local placeId = game.PlaceId
    local targetUrl = string.format(baseUrl, tostring(placeId))

    -- แสดงการแจ้งเตือนในเกม
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Fyrelith Hub",
        Text = "ยืนยันคีย์สำเร็จ! กำลังโหลดสคริปต์...",
        Duration = 5
    })

    -- พยายามดาวน์โหลดสคริปต์ตาม PlaceId
    local fetchSuccess, scriptContent = pcall(function()
        return game:HttpGet(targetUrl)
    end)

    if fetchSuccess and scriptContent and not scriptContent:find("404: Not Found") then
        local runSuccess, runError = pcall(function()
            loadstring(scriptContent)()
        end)
        
        if not runSuccess then
            warn("[Fyrelith Hub] เกิดข้อผิดพลาดขณะรันสคริปต์แมพ:", runError)
        end
    else
        -- หากไม่มีไฟล์ของ PlaceId นั้น ให้โหลด universal.lua
        local fallbackUrl = string.format(baseUrl, "universal")
        local fallbackSuccess, fallbackContent = pcall(function()
            return game:HttpGet(fallbackUrl)
        end)

        if fallbackSuccess and fallbackContent and not fallbackContent:find("404: Not Found") then
            loadstring(fallbackContent)()
        else
            warn("[Fyrelith Hub] ไม่พบสคริปต์เฉพาะของแมพนี้ และไม่พบไฟล์ universal.lua")
        end
    end
end

-- [[ 5. ตรวจสอบคีย์และเริ่มการทำงาน ]]
local currentKey = (getgenv().ScriptKey ~= "" and getgenv().ScriptKey) or GetSavedKey()

-- กรณีที่ไม่มีคีย์เลย
if currentKey == "" then
    getgenv().FyrelithHubLoaded = false
    LocalPlayer:Kick("\n\n[Fyrelith Hub]\nไม่พบคีย์การใช้งาน\nกรุณาใส่คีย์ใน getgenv().ScriptKey ก่อนสั่งรันสคริปต์")
    return
end

-- ยืนยันความถูกต้องของคีย์กับเซิร์ฟเวอร์ PandaAuth
local isValid = false
local checkSuccess, checkResult = pcall(function()
    return PandaAuth:ValidateKey(ServiceName, currentKey)
end)

if checkSuccess and checkResult then
    isValid = true
end

if isValid then
    SaveKey(currentKey) -- เซฟคีย์ที่ถูกต้องไว้ในเครื่องเพื่อไม่ต้องกรอกใหม่ในรอบถัดไป
    LaunchHub()
else
    getgenv().FyrelithHubLoaded = false
    LocalPlayer:Kick("\n\n[Fyrelith Hub]\nคีย์ไม่ถูกต้อง หรือหมดอายุการใช้งานแล้ว\nกรุณาติดต่อร้านค้าเพื่อรับหรือต่ออายุคีย์")
    return
end
