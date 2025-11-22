
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
local timeLimit = 60
local timeLeft  = timeLimit

local moveSpeed = 220

-- Helpers
local function resetPuzzle()
  gameState = "playing"
  timeLeft  = timeLimit

  -- player starts near bottom-left, with a gap to the walls
  player:setPosition(120, 510)
  player:setLinearVelocity(0, 0)
  player:setType("dynamic")

  -- crate starts near top-right, with a gap to the walls
  crate:setPosition(700, 90)
  crate:setLinearVelocity(0, 0)
  crate:setType("dynamic")
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

  -- 2D initialization: Breezefield physics world (top-down, no gravity)
  world = bf.newWorld(0, 0, true)

  -- NOTE: in this version, world:newCollider("Rectangle", {x, y, w, h})
  -- treats x,y as the *center* of the rectangle.
  -- Place player bottom-left, crate top-right, both clearly inside the walls.
  player = world:newCollider("Rectangle", {120, 510, 40, 40})
  crate  = world:newCollider("Rectangle", {700, 90, 40, 40})

  -- make sure these are dynamic bodies
  player:setType("dynamic")
  crate:setType("dynamic")

  player:setLinearDamping(4)
  crate:setLinearDamping(4)

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

-- Input
function love.keypressed(key)
  if key == "r" then
    resetPuzzle()
  end
end

-- Update logic
local function updatePlayerMovement(dt)
  local vx, vy = 0, 0

  if love.keyboard.isDown("a") or love.keyboard.isDown("left")  then
    vx = vx - moveSpeed
  end
  if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
    vx = vx + moveSpeed
  end
  if love.keyboard.isDown("w") or love.keyboard.isDown("up")    then
    vy = vy - moveSpeed
  end
  if love.keyboard.isDown("s") or love.keyboard.isDown("down")  then
    vy = vy + moveSpeed
  end

  -- Directly set the velocity of the dynamic body
  player:setLinearVelocity(vx, vy)
end

local function checkWinCondition()
  if gameState ~= "playing" then return end

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
  if gameState == "playing" then
    updatePlayerMovement(dt)
    world:update(dt)

    timeLeft = timeLeft - dt
    if timeLeft <= 0 then
      timeLeft = 0
      if gameState ~= "success" then
        gameState = "fail"
      end
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
    -- place the ball in front of the camera and rotate slowly
    local transform = ballSprite:getSpriteTransform(0, 0.5, -3.0, t * 0.6, 0.9, 0.9)
    dream:draw(ballSprite, transform)
  end

  dream:present()

  -- 2) 2D physics + HUD
  love.graphics.origin()
  love.graphics.setColor(1, 1, 1, 1)

  -- Goal area
  love.graphics.setColor(0.2, 0.8, 0.3, 0.4)
  love.graphics.rectangle(
    "fill",
    goal.x - goal.w / 2,
    goal.y - goal.h / 2,
    goal.w,
    goal.h
  )

  -- Breezefield debug drawing for all colliders
  love.graphics.setColor(1, 1, 1, 1)
  world:draw()

  -- HUD 
  local y = 20
  local function line(text)
    love.graphics.print(text, 20, y)
    y = y + 18
  end

  line("Controls: WASD / Arrow keys to move. R to restart.")
  line(string.format("Time left: %.1f seconds", timeLeft))

  if gameState == "success" then
    line("")
    line("SUCCESS! The crate reached the goal. Press R to play again.")
  elseif gameState == "fail" then
    line("")
    line("FAILED! Time ran out. Press R to retry.")
  end
end

function love.resize()
  dream:resize()
end