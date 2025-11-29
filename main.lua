-- Third-party libraries

local dream = require("libs.3DreamEngine.3DreamEngine")
local bf    = require("libs.breezefield")

-- 3D rendering objects
local sun
local ballTexture
local ballQuad
local ballSprite

-- 2D physics world (Breezefield)
local world
local player
local crate
local walls = {}

-- Goal area (screen-space rectangle)
local goal = { x = 540, y = 500, w = 80, h = 80 }

-- Gameplay state
local gameState = "playing"
local timeLimit = 120
local timeLeft  = timeLimit

local moveSpeed = 220

-- Pulling state (move these near top so they're clearly defined)
local pulling = false      -- Player pull state
local pullOffsetX = 0
local pullOffsetY = 0
local pullDistance = 50    -- Pull trigger distance

-- Helpers
local function resetPuzzle()
  gameState = "playing"
  timeLeft  = timeLimit

  -- cancel pulling if active
  pulling = false

  -- player starts near bottom-left, with a gap to the walls
  player:setPosition(120, 510)
  player:setLinearVelocity(0, 0)
  player:setType("dynamic")

  -- crate starts near top-right, with a gap to the walls
  crate:setPosition(700, 90)
  crate:setLinearVelocity(0, 0)
  crate:setType("dynamic")
end


local function setupWorld()
  world = bf.newWorld(0, 0, true)

  -- player & crate
  player = world:newCollider("Rectangle", {120, 510, 40, 40})
  crate  = world:newCollider("Rectangle", {700, 90, 40, 40})
  player:setType("dynamic")
  crate:setType("dynamic")
  player:setLinearDamping(4)
  crate:setLinearDamping(4)
  player:setFixedRotation(true)
  crate:setFixedRotation(true)

  -- Static boundary walls
  walls = {
    world:newCollider("Rectangle", {400, 50, 760, 20}),   -- top
    world:newCollider("Rectangle", {400, 550, 760, 20}),  -- bottom
    world:newCollider("Rectangle", {50, 300, 20, 500}),   -- left
    world:newCollider("Rectangle", {750, 300, 20, 500}),  -- right
  }
  for _, w in ipairs(walls) do
    w:setType("static")
  end

  resetPuzzle()
end


--Room Setting
local rooms = { "main", "room1", "room2", "room3" }
local currentRoom = "main"

local buttonY = 560
local buttonW = 80
local buttonH = 30
local buttonXStart = 20

-- room change
local roomHandlers = {
    main = function()
        setupWorld()
        print("Entered Main Room")
    end,
    room1 = function()
        world = nil
        print("Entered Room 1 (empty)")
    end,
    room2 = function()
        world = nil
        print("Entered Room 2 (empty)")
    end,
    room3 = function()
        world = nil
        print("Entered Room 3 (empty)")
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
  love.window.setTitle("F1 Physics Puzzle - Push the Crate")

  -- 3D initialization: 3DreamEngine with a simple billboard ball
  dream:init()

  sun = dream:newLight("sun")
  sun:setPosition(2, 4, 2)

  -- Use a Canvas to draw a white circle as the billboard texture
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
    if key == "r" then
        if world then
            resetPuzzle()
        end
        pulling = false
    elseif key == "space" then
        if world then
            local px, py = player:getPosition()
            local cx, cy = crate:getPosition()
            local dx, dy = cx - px, cy - py
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist <= pullDistance then
                pulling = true
                pullOffsetX = dx
                pullOffsetY = dy
                crate:setLinearVelocity(0, 0)
            end
        end
    end
end

-- release space to stop pulling
function love.keyreleased(key)
    if key == "space" then
        pulling = false
        if world then crate:setLinearVelocity(0, 0) end
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

-- This is the pulling updater
local function updatePulling(dt)
    if pulling and world then
        local px, py = player:getPosition()
        crate:setPosition(px + pullOffsetX, py + pullOffsetY)
        crate:setLinearVelocity(0, 0)
    end
end

local function checkWinCondition()
  if not world or gameState ~= "playing" then return end
  local cx, cy = crate:getPosition()
  local left   = goal.x - goal.w / 2
  local right  = goal.x + goal.w / 2
  local top    = goal.y - goal.h / 2
  local bottom = goal.y + goal.h / 2
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

  dream:update()
end


-- Drawing
function love.draw()
  -- 1) 3D background: rotating billboard ball (3DreamEngine)
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

  if world then
    -- Goal area
    love.graphics.setColor(0.2, 0.8, 0.3, 0.4)
    love.graphics.rectangle("fill", goal.x - goal.w/2, goal.y - goal.h/2, goal.w, goal.h)
    love.graphics.setColor(1, 1, 1, 1)
    world:draw()
  end

  -- HUD
  local y = 20
  local function line(text)
    love.graphics.print(text, 20, y)
    y = y + 18
  end

  if world then
    line("Controls: WASD / Arrow keys to move. R to restart.")
    line(string.format("Time left: %.1f seconds", timeLeft))
    if gameState == "success" then line("") line("SUCCESS! The crate reached the goal. Press R.") 
    elseif gameState == "fail" then line("") line("FAILED! Time ran out. Press R.") end
  else
    line("Empty room. Use buttons to return to Main Room.")
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
