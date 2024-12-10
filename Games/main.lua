local love = require "love"
local anim8 = require "libraries/anim8"

function love.load()
    -- Set window title and icon
    love.window.setTitle("Galactic Invasion")
    local icon = love.image.newImageData('backgrounds/titleSpace.png')  -- Using title background as icon
    love.window.setIcon(icon)

    -- Screen dimensions
    screenWidth = love.graphics.getWidth()
    screenHeight = love.graphics.getHeight()

    -- Colors
    paddleColor = {0.6, 0.8, 1}  -- Soft blue
    ballColor = {1, 0.7, 0.3}    -- Warm orange
    scoreColor = {1, 1, 1}

    -- Fonts
    gameFont = love.graphics.newFont('font/PressStart2P.ttf', 30)
    scoreFont = love.graphics.newFont('font/PressStart2P.ttf', 50)
    titleFont = love.graphics.newFont('font/PressStart2P.ttf', 80)
    controlFont = love.graphics.newFont('font/PressStart2P.ttf', 20)

    -- Background Animation Setup
    titleBackground = love.graphics.newImage('backgrounds/titleSpace.png')
    gameBackground = love.graphics.newImage('backgrounds/Space.png')
    winBackground = love.graphics.newImage('backgrounds/Space.png')  -- Added win screen background
    local g1 = anim8.newGrid(64, 64, titleBackground:getWidth(), titleBackground:getHeight())
    local g2 = anim8.newGrid(64, 64, gameBackground:getWidth(), gameBackground:getHeight())
    titleBackgroundAnimation = anim8.newAnimation(g1('1-4', 1), 0.2)
    gameBackgroundAnimation = anim8.newAnimation(g2('1-4', 1), 0.2)

    -- Background scaling (fixed to prevent manual scaling)
    backgroundScale = 13.0

    -- Sound settings
    masterVolume = 1.0
    musicVolume = 0.7
    sfxVolume = 1.0

    -- Sounds
    paddleHitSound = love.audio.newSource('Music/pong-sound.wav', 'static')
    scoreSound = love.audio.newSource('Music/ScoreP2.wav', 'static')
    backgroundMusic = love.audio.newSource('backgroundMusic/Space.mp3', 'stream')
    backgroundMusic:setLooping(true)
    backgroundMusic:setVolume(musicVolume * masterVolume)
    backgroundMusic:play()

    -- Paddle dimensions
    paddleWidth = 15
    paddleHeight = 100
    paddleSpeed = 600

    -- Ball dimensions
    ballSize = 15
    ballSpeed = 300
    ballSpeedIncreaseRate = 1.3
    ballHitsBeforeSpeedIncrease = 3

    -- Player paddles
    player1 = {x = 50, y = screenHeight/2 - paddleHeight/2}
    player2 = {x = screenWidth - 50 - paddleWidth, y = screenHeight/2 - paddleHeight/2}

    -- Ball
    ball = {
        x = screenWidth/2 - ballSize/2, 
        y = screenHeight/2 - ballSize/2,
        dx = ballSpeed * (love.math.random() > 0.5 and 1 or -1),  -- Randomize initial direction
        dy = ballSpeed * (love.math.random() > 0.5 and 1 or -1),
        hitCount = 0
    }

    -- Scores
    player1Score = 0
    player2Score = 0

    maxScore = 5
    winningPlayer = nil

    -- Game state
    gameState = "title"
end

function love.update(dt)
    -- Only update game elements when in active game state
    if gameState ~= "game" then return end

    -- Background animation
    gameBackgroundAnimation:update(dt)

    -- Player 1 controls (W/S)
    if love.keyboard.isDown('w') then
        player1.y = math.max(0, player1.y - paddleSpeed * dt)
    end
    if love.keyboard.isDown('s') then
        player1.y = math.min(screenHeight - paddleHeight, player1.y + paddleSpeed * dt)
    end

    -- Player 2 controls (Up/Down arrows)
    if love.keyboard.isDown('up') then
        player2.y = math.max(0, player2.y - paddleSpeed * dt)
    end
    if love.keyboard.isDown('down') then
        player2.y = math.min(screenHeight - paddleHeight, player2.y + paddleSpeed * dt)
    end

    -- Ball movement
    ball.x = ball.x + ball.dx * dt
    ball.y = ball.y + ball.dy * dt

    -- Ball collision with top and bottom
    if ball.y <= 0 or ball.y >= screenHeight - ballSize then
        ball.dy = -ball.dy
    end

    -- Ball collision with paddles
    local hitPaddle1 = ball.x <= player1.x + paddleWidth and 
                       ball.x + ballSize >= player1.x and
                       ball.y + ballSize >= player1.y and 
                       ball.y <= player1.y + paddleHeight

    local hitPaddle2 = ball.x + ballSize >= player2.x and 
                       ball.x <= player2.x + paddleWidth and
                       ball.y + ballSize >= player2.y and 
                       ball.y <= player2.y + paddleHeight

    if hitPaddle1 then
        ball.x = player1.x + paddleWidth
        
        ball.hitCount = ball.hitCount + 1
        if ball.hitCount % ballHitsBeforeSpeedIncrease == 0 then
            ball.dx = ball.dx * ballSpeedIncreaseRate
            ball.dy = ball.dy * ballSpeedIncreaseRate
        end
        
        local relativeIntersectY = (player1.y + (paddleHeight/2)) - (ball.y + (ballSize/2))
        local normalizedRelativeIntersectionY = relativeIntersectY / (paddleHeight/2)
        local bounceAngle = normalizedRelativeIntersectionY * (5 * math.pi/12)
        
        local speed = math.sqrt(ball.dx^2 + ball.dy^2)
        ball.dx = speed * math.cos(bounceAngle)
        ball.dy = speed * -math.sin(bounceAngle)
        
        paddleHitSound:setVolume(sfxVolume * masterVolume)
        paddleHitSound:play()
    end

    if hitPaddle2 then
        ball.x = player2.x - ballSize
        
        ball.hitCount = ball.hitCount + 1
        if ball.hitCount % ballHitsBeforeSpeedIncrease == 0 then
            ball.dx = ball.dx * ballSpeedIncreaseRate
            ball.dy = ball.dy * ballSpeedIncreaseRate
        end
        
        local relativeIntersectY = (player2.y + (paddleHeight/2)) - (ball.y + (ballSize/2))
        local normalizedRelativeIntersectionY = relativeIntersectY / (paddleHeight/2)
        local bounceAngle = normalizedRelativeIntersectionY * (5 * math.pi/12)
        
        local speed = math.sqrt(ball.dx^2 + ball.dy^2)
        ball.dx = speed * -math.cos(bounceAngle)
        ball.dy = speed * -math.sin(bounceAngle)
        
        paddleHitSound:setVolume(sfxVolume * masterVolume)
        paddleHitSound:play()
    end

    -- Scoring
    if ball.x <= 0 then
        player2Score = player2Score + 1
        scoreSound:setVolume(sfxVolume * masterVolume)
        scoreSound:play()
        resetBall()
    end

    if ball.x >= screenWidth - ballSize then
        player1Score = player1Score + 1
        scoreSound:setVolume(sfxVolume * masterVolume)
        scoreSound:play()
        resetBall()
    end

    -- Win condition
    if player1Score >= maxScore then
        winningPlayer = "Player 1"
        gameState = "win"
    elseif player2Score >= maxScore then
        winningPlayer = "Player 2"
        gameState = "win"
    end
end

function resetBall()
    ball.x = screenWidth/2 - ballSize/2
    ball.y = screenHeight/2 - ballSize/2
    ball.dx = ballSpeed * (love.math.random() > 0.5 and 1 or -1)
    ball.dy = ballSpeed * (love.math.random() > 0.5 and 1 or -1)
    ball.hitCount = 0
end

function love.draw()
    -- Animated Background
    love.graphics.setColor(1, 1, 1)
    if gameState == "title" or gameState == "controls" then
        titleBackgroundAnimation:draw(
            titleBackground,
            0,  -- Fixed X offset
            0,  -- Fixed Y offset
            0,
            backgroundScale,
            backgroundScale
        )
    elseif gameState == "game" then
        gameBackgroundAnimation:draw(
            gameBackground, 
            0,  -- Fixed X offset
            0,  -- Fixed Y offset
            0,
            backgroundScale,
            backgroundScale
        )
    elseif gameState == "win" then
        -- Draw win screen background
        love.graphics.draw(
            winBackground,
            0,  -- Fixed X offset
            0,  -- Fixed Y offset
            0,
            backgroundScale,
            backgroundScale
        )
    end
    
    if gameState == "title" then
        -- Draw title
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(titleFont)
        love.graphics.printf("Galactic Invasion", 0, screenHeight/3, screenWidth, 'center')
        
        love.graphics.setFont(gameFont)
        love.graphics.printf("Press SPACE to start", 0, screenHeight/2 + 100, screenWidth, 'center')
        love.graphics.printf("Press C for Controls", 0, screenHeight/2 + 150, screenWidth, 'center')
        love.graphics.printf("Press M to toggle Music", 0, screenHeight/2 + 200, screenWidth, 'center')

        -- Your name only on title screen
        love.graphics.setFont(controlFont)
        love.graphics.printf("Created by S-W-4reel", 0, screenHeight - 30, screenWidth, 'center')
    
    elseif gameState == "controls" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(gameFont)
        love.graphics.printf("CONTROLS", 0, 100, screenWidth, 'center')
        
        love.graphics.setFont(controlFont)
        love.graphics.printf("Player 1 (Left Side):\nW - Move Up\nS - Move Down", 0, 250, screenWidth, 'center')
        love.graphics.printf("Player 2 (Right Side):\nUp Arrow - Move Up\nDown Arrow - Move Down", 0, 350, screenWidth, 'center')
        
        love.graphics.printf("Press SPACE to return to Title", 0, screenHeight - 100, screenWidth, 'center')
    
    elseif gameState == "game" then
        -- Draw game name in top right
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(controlFont)

        -- Dashed center line
        love.graphics.setColor(1, 1, 1, 0.2)
        for i = 0, screenHeight, 40 do
            love.graphics.rectangle('fill', screenWidth/2 - 2, i, 4, 20)
        end

        -- Set colors (softer blue for paddles)
        love.graphics.setColor(paddleColor)

        -- Draw paddles with rounded corners
        local cornerRadius = 5
        love.graphics.rectangle('fill', player1.x, player1.y, paddleWidth, paddleHeight, cornerRadius)
        love.graphics.rectangle('fill', player2.x, player2.y, paddleWidth, paddleHeight, cornerRadius)

        -- Draw ball (orange with slight rounding)
        love.graphics.setColor(ballColor)
        love.graphics.rectangle('fill', ball.x, ball.y, ballSize, ballSize, 3)

        -- Draw scores
        love.graphics.setColor(scoreColor)
        love.graphics.setFont(scoreFont)
        love.graphics.print(player1Score, screenWidth/4, 50)
        love.graphics.print(player2Score, 3*screenWidth/4, 50)
    end

    if gameState == "win" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(titleFont)
        love.graphics.printf(winningPlayer .. " Wins!", 0, screenHeight/3, screenWidth, 'center')
        
        love.graphics.setFont(gameFont)
        love.graphics.printf("Press SPACE to return to Title", 0, screenHeight/2 + 100, screenWidth, 'center')
    end
end

function love.keypressed(key)
    if gameState == "title" then
        if key == 'escape' then
            love.event.quit()
        elseif key == 'space' then
            -- Reset scores and ball when starting a new game
            player1Score = 0
            player2Score = 0
            resetBall()
            gameState = "game"
        elseif key == 'c' then
            gameState = "controls"
        elseif key == 'm' then
            -- Toggle music volume
            if masterVolume > 0 then
                masterVolume = 0
            else
                masterVolume = 1.0
            end
            backgroundMusic:setVolume(musicVolume * masterVolume)
        end
    
    elseif gameState == "controls" then
        if key == 'space' then
            gameState = "title"
        end
    
    elseif gameState == "game" then
        if key == 'escape' then
            gameState = "title"
        end
        
        if key == 'm' then
            -- Toggle music volume
            if masterVolume > 0 then
                masterVolume = 0
            else
                masterVolume = 1.0
            end
            backgroundMusic:setVolume(musicVolume * masterVolume)
        end
    end

    if gameState == "win" then
        if key == 'space' then
            -- Reset game
            player1Score = 0
            player2Score = 0
            winningPlayer = nil
            resetBall()
            gameState = "title"
        end
    end
end