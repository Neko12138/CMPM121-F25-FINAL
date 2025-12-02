-- Third-party libraries
local dream = require("libs.3DreamEngine.3DreamEngine")
local bf    = require("libs.breezefield")

-- 3D rendering objects
local sun
local ballTexture
local ballQuad
local ballSprite

-- 2D physics world
local world
local player
local crate
local walls = {}

-- Goal area screen-space rectangle for the Main Room
local mainGoal = { x = 540, y = 500, w = 80, h = 80 }

-- Yellow Zones for Rooms 1, 2, 3
local yellowZones = {
    room1 = { x = 700, y = 100, w = 40, h = 40, hasKey = false },
    room2 = { x = 100, y = 100, w = 40, h = 40, hasKey = true }, -- The real key is here
    room3 = { x = 700, y = 500, w = 40, h = 40, hasKey = false }
}

-- Gameplay state
local gameState = "playing"
local timeLimit = 120
local timeLeft  = timeLimit
local moveSpeed = 220

-- Interaction & Inventory State
local hasKey = false
local isCrateLocked = true
local message = ""
local messageTimer = 0

-- Pulling state
local pulling = false
local pullOffsetX = 0
local pullOffsetY = 0
local pullDistance = 60 

-- Language Settings
local langs = {"en", "zh", "ar"} -- English, Chinese, Arabic
local currentLangIndex = 1

-- Font Variables
local font_zh = nil -- (Noto Sans SC)
local font_ar = nil -- (Noto Sans Arabic)

-- Translation Dictionary
local txt = {
    en = {
        ctrl = "Controls: WASD Move. SPACE Interact/Pull. R Restart. L Language.",
        time = "Time left: %.1f seconds",
        inv = "INVENTORY:",
        empty = "Empty",
        key = "[ KEY ]",
        msg_unlock = "UNLOCKED! You can now move the crate.",
        msg_lock = "LOCKED! You need to find a key in the maze rooms.",
        msg_found = "YOU FOUND THE KEY!",
        msg_have = "You already have the key.",
        msg_no = "There is no key here.",
        win = "SUCCESS! The crate reached the goal. Press R.",
        fail = "FAILED! Time ran out. Press R.",
        zone = "ZONE"
    },
    zh = {
        ctrl = "操作: WASD 移动. 空格 互动. R 重置. L 切换语言.",
        time = "剩余时间: %.1f 秒",
        inv = "物品栏:",
        empty = "空",
        key = "[ 钥匙 ]",
        msg_unlock = "已解锁！现在可以移动箱子。",
        msg_lock = "已上锁！去迷宫房间找钥匙。",
        msg_found = "找到钥匙了！",
        msg_have = "你已经有钥匙了。",
        msg_no = "这里没有钥匙。",
        win = "成功！箱子已到位。按 R 重来。",
        fail = "失败！时间耗尽。按 R 重来。",
        zone = "区域"
    },
    ar = {
        ctrl = "تحكم: WASD تحرك. مسافة تفاعل. R إعادة. L لغة.", 
        time = "الوقت: %.1f ثانية",
        inv = ":المخزون",
        empty = "فارغ",
        key = "[ مفتاح ]",
        msg_unlock = "مفتوح! حرك الصندوق الآن.",
        msg_lock = "مغلق! ابحث عن المفتاح.",
        msg_found = "وجدت المفتاح!",
        msg_have = "لديك المفتاح بالفعل.",
        msg_no = "لا يوجد مفتاح هنا.",
        win = "نجاح! اضغط R.",
        fail = "فشل! اضغط R.",
        zone = "منطقة"
    }
}

-- Helpers
local function createWall(x, y, w, h)
    local wall = world:newCollider("Rectangle", {x, y, w, h})
    wall:setType("static")
    table.insert(walls, wall)
end

-- Modified setupWorld to handle different rooms
local function setupWorld(roomName)
  -- SAFELY destroy the old world if it exists
  if world and world.destroy then
      world:destroy()
  end
  
  walls = {} -- Clear old walls
  world = bf.newWorld(0, 0, true) -- Create new physics world

  -- Create Player
  -- Default spawn point
  local px, py = 120, 510 
  
  -- Use different spawn points for different rooms if needed
  if roomName == "room2" then px, py = 700, 500 end
  if roomName == "room3" then px, py = 120, 120 end

  player = world:newCollider("Rectangle", {px, py, 40, 40})
  player:setType("dynamic")
  player:setFixedRotation(true)
  player:setLinearDamping(4)

  -- Setup Specific Room Physics
  if roomName == "main" then
      -- == MAIN ROOM
      crate = world:newCollider("Rectangle", {400, 300, 40, 40})
      crate:setFixedRotation(true)
      crate:setLinearDamping(4)
      
      -- Lock logic
      if isCrateLocked then
          crate:setType("static")
      else
          crate:setType("dynamic")
      end

      -- Original Walls
      createWall(400, 50, 760, 20)   -- top
      createWall(400, 550, 760, 20)  -- bottom
      createWall(50, 300, 20, 500)   -- left
      createWall(750, 300, 20, 500)  -- right

  elseif roomName == "room1" then
      -- == ROOM 1
      createWall(400, 25, 800, 50) -- Top
      createWall(400, 575, 800, 50)-- Bottom
      createWall(25, 300, 50, 600) -- Left
      createWall(775, 300, 50, 600)-- Right
      
      -- Maze walls
      createWall(300, 200, 400, 20)
      createWall(500, 400, 400, 20)

  elseif roomName == "room2" then
      -- == ROOM 2
      createWall(400, 25, 800, 50)
      createWall(400, 575, 800, 50)
      createWall(25, 300, 50, 600)
      createWall(775, 300, 50, 600)
      
      -- Maze walls
      createWall(250, 300, 20, 400)
      createWall(550, 300, 20, 400)

  elseif roomName == "room3" then
      -- == ROOM 3
      createWall(400, 25, 800, 50)
      createWall(400, 575, 800, 50)
      createWall(25, 300, 50, 600)
      createWall(775, 300, 50, 600)
      
      -- Maze walls
      createWall(400, 300, 200, 200)
  end

  gameState = "playing"
  pulling = false
end


--Room Setting
local rooms = { "main", "room1", "room2", "room3" }
local currentRoom = "main"

local buttonY = 560
local buttonW = 80
local buttonH = 30
local buttonXStart = 20

-- Room Change Handlers
-- REFACTORED: Now all rooms call setupWorld with their name
local roomHandlers = {
    main = function()
        setupWorld("main")
        print("Entered Main Room")
    end,
    room1 = function()
        setupWorld("room1")
        print("Entered Room 1")
    end,
    room2 = function()
        setupWorld("room2")
        print("Entered Room 2")
    end,
    room3 = function()
        setupWorld("room3")
        print("Entered Room 3")
    end,
}

local function enterRoom(name)
    currentRoom = name
    if roomHandlers[name] then
        roomHandlers[name]()
    end
end

-- LOVE callbacks
function love.load()
  love.window.setTitle("F2 Adventure - Maze & Inventory")

  -- 3D initialization
  dream:init()
  sun = dream:newLight("sun")
  sun:setPosition(2, 4, 2)
  
  -- [[ NEW: Load BOTH Fonts ]]
  if love.filesystem.getInfo("font.ttf") then
      font_zh = love.graphics.newFont("font.ttf", 16)
  else
      font_zh = love.graphics.newFont(14)
  end

  if love.filesystem.getInfo("font_ar.ttf") then
      font_ar = love.graphics.newFont("font_ar.ttf", 16)
  else
      print("Warning: font_ar.ttf not found! Arabic will not show.")
      font_ar = font_zh
  end
  
  love.graphics.setFont(font_zh)

  -- Texture setup
  ballTexture = love.graphics.newCanvas(64, 64)
  love.graphics.push("all")
  love.graphics.setCanvas(ballTexture)
  love.graphics.clear(0, 0, 0, 0)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.circle("fill", 32, 32, 28)
  love.graphics.setCanvas()
  love.graphics.pop()
  love.graphics.setColor(1, 1, 1, 1)

  ballQuad   = love.graphics.newQuad(0, 0, 64, 64, 64, 64)
  ballSprite = dream:newSprite(ballTexture, ballTexture, false, ballQuad)

  enterRoom("main")
end

-- Input
function love.keypressed(key)
    -- [[ Switch Language Logic ]]
    if key == "l" then
        currentLangIndex = currentLangIndex + 1
        if currentLangIndex > #langs then 
            currentLangIndex = 1 
        end
    end

    if key == "r" then
        isCrateLocked = true
        timeLeft = timeLimit
        hasKey = false
        currentRoom = "main"
        if world then
            setupWorld(currentRoom)
        end
        pulling = false
    
    elseif key == "space" then
        if world then
            local px, py = player:getPosition()
            
            -- == INTERACTION LOGIC ==
            
            if currentRoom == "main" then
                -- CRATE INTERACTION
                local cx, cy = crate:getPosition()
                local dist = math.sqrt((cx-px)^2 + (cy-py)^2)
                
                if dist <= pullDistance then
                    if isCrateLocked then
                        if hasKey then
                            isCrateLocked = false
                            crate:setType("dynamic")
                            message = "msg_unlock"
                        else
                            message = "msg_lock"
                        end
                        messageTimer = 3
                    else
                        -- Start Pulling
                        pulling = true
                        pullOffsetX = cx - px
                        pullOffsetY = cy - py
                        crate:setLinearVelocity(0, 0)
                    end
                end
                
            else
                -- YELLOW ZONE INTERACTION (Rooms 1, 2, 3)
                local zone = yellowZones[currentRoom]
                if zone then
                    -- Calculate distance to center of yellow zone
                    local zCenterX = zone.x + zone.w/2
                    local zCenterY = zone.y + zone.h/2
                    local dist = math.sqrt((zCenterX-px)^2 + (zCenterY-py)^2)
                    
                    if dist <= 60 then
                        if zone.hasKey then
                            if not hasKey then
                                hasKey = true
                                message = "msg_found"
                            else
                                message = "msg_have"
                            end
                        else
                            message = "msg_no"
                        end
                        messageTimer = 3
                    end
                end
            end
        end
    end
end

-- release space to stop pulling
function love.keyreleased(key)
    if key == "space" then
        pulling = false
        if world and crate and not isCrateLocked then 
            crate:setLinearVelocity(0, 0) 
        end
    end
end

-- Update logic
local function updatePlayerMovement(dt)
  if not world then return end
  local vx, vy = 0, 0
  if love.keyboard.isDown("a") or love.keyboard.isDown("left")  then vx = vx - moveSpeed end
  if love.keyboard.isDown("d") or love.keyboard.isDown("right") then vx = vx + moveSpeed end
  if love.keyboard.isDown("w") or love.keyboard.isDown("up")    then vy = vy - moveSpeed end
  if love.keyboard.isDown("s") or love.keyboard.isDown("down")  then vy = vy + moveSpeed end
  player:setLinearVelocity(vx, vy)
end

local function updatePulling(dt)
    if pulling and world and not isCrateLocked then
        local px, py = player:getPosition()
        crate:setPosition(px + pullOffsetX, py + pullOffsetY)
        crate:setLinearVelocity(0, 0)
    end
end

local function checkWinCondition()
  if not world or gameState ~= "playing" or currentRoom ~= "main" then return end
  local cx, cy = crate:getPosition()
  local left   = mainGoal.x - mainGoal.w / 2
  local right  = mainGoal.x + mainGoal.w / 2
  local top    = mainGoal.y - mainGoal.h / 2
  local bottom = mainGoal.y + mainGoal.h / 2
  if cx >= left and cx <= right and cy >= top and cy <= bottom then
    gameState = "success"
  end
end

function love.update(dt)
  if world and gameState == "playing" then
    updatePlayerMovement(dt)
    updatePulling(dt)
    world:update(dt)

    timeLeft = math.max(timeLeft - dt, 0)
    if timeLeft <= 0 and gameState ~= "success" then
      gameState = "fail"
    end

    checkWinCondition()
  end
  
  if messageTimer > 0 then
      messageTimer = messageTimer - dt
      if messageTimer <= 0 then message = "" end
  end

  dream:update()
end


-- Drawing
function love.draw()
  -- 1) 3D background
  dream:prepare()
  dream:addLight(sun)
  if ballSprite then
    local t = love.timer.getTime()
    local transform = ballSprite:getSpriteTransform(2, 2.5, -3.0, t * 0.6, 0.9, 0.9)
    dream:draw(ballSprite, transform)
  end
  dream:present()

  -- 2) 2D physics + HUD
  love.graphics.origin()
  love.graphics.setColor(1, 1, 1, 1)

  -- [[ NEW: Get current dictionary & SET FONT ]]
  local langCode = langs[currentLangIndex]
  local curTxt = txt[langCode]
  
  -- Dynamically Switch Font
  if langCode == "ar" then
      love.graphics.setFont(font_ar)
  else
      love.graphics.setFont(font_zh)
  end

  if world then
    -- Draw Room Specific Floor/Targets
    if currentRoom == "main" then
        -- Draw Green Goal
        love.graphics.setColor(0.2, 0.8, 0.3, 0.4)
        love.graphics.rectangle("fill", mainGoal.x - mainGoal.w/2, mainGoal.y - mainGoal.h/2, mainGoal.w, mainGoal.h)
        
        -- Draw Crate manually
        local cx, cy = crate:getPosition()
        if isCrateLocked then
            love.graphics.setColor(1, 0, 0, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        love.graphics.rectangle("fill", cx-20, cy-20, 40, 40)
    
    else
        -- Draw Yellow Interaction Zones (Rooms 1, 2, 3)
        local zone = yellowZones[currentRoom]
        if zone then
            love.graphics.setColor(1, 1, 0, 0.6) -- Yellow
            love.graphics.rectangle("fill", zone.x, zone.y, zone.w, zone.h)
            love.graphics.setColor(1, 1, 1, 1)
            
            -- [[ UPDATED: Use variable text ]]
            love.graphics.print(curTxt.zone, zone.x, zone.y - 15)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
    -- Draw physics world
    world:draw()
  end

  -- HUD & UI
  local y = 20
  local function line(text)
    love.graphics.print(text, 20, y)
    y = y + 18
  end

  -- INVENTORY DISPLAY
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle("fill", 650, 10, 140, 60)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.rectangle("line", 650, 10, 140, 60)
  
  -- [[ UPDATED: Use variable text ]]
  love.graphics.print(curTxt.inv, 660, 20)
  if hasKey then
      love.graphics.setColor(1, 1, 0, 1)
      love.graphics.print(curTxt.key, 660, 40)
  else
      love.graphics.setColor(0.6, 0.6, 0.6, 1)
      love.graphics.print(curTxt.empty, 660, 40)
  end
  love.graphics.setColor(1, 1, 1, 1)


  if world then
    -- [[ UPDATED: Use variable text ]]
    line(curTxt.ctrl)
    line(string.format(curTxt.time, timeLeft))
    
    -- Status Messages
    if message ~= "" then
        love.graphics.setColor(1, 0.5, 0, 1)
        
        -- [[ UPDATED: Lookup message key ]]
        local str = curTxt[message] or message
        love.graphics.print(str, 300, 50)
        
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- [[ UPDATED: Win/Fail text ]]
    if gameState == "success" then line("") line(curTxt.win) 
    elseif gameState == "fail" then line("") line(curTxt.fail) end
  end

  -- Draw Room Buttons
  local x = buttonXStart
  for i, room in ipairs(rooms) do
    local label = (room == "main") and "Main" or room:sub(5)
    if currentRoom == room then label = "["..label.."]" end
    love.graphics.setColor(0.2,0.2,0.2,0.8)
    love.graphics.rectangle("fill", x, buttonY, buttonW, buttonH)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf(label, x, buttonY + 6, buttonW, "center")
    x = x + buttonW + 10
  end
end

function love.mousepressed(mx, my, button)
    if button ~= 1 then return end
    
    -- Room switching buttons
    local x = buttonXStart
    for i, room in ipairs(rooms) do
        if mx >= x and mx <= x + buttonW and my >= buttonY and my <= buttonY + buttonH then
            enterRoom(room)
        end
        x = x + buttonW + 10
    end
end

function love.resize()
  dream:resize()
end