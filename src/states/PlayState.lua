--[[
    GD50
    Match-3 Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    State in which we can actually play, moving around a grid cursor that
    can swap two tiles; when two tiles make a legal swap (a swap that results
    in a valid match), perform the swap and destroy all matched tiles, adding
    their values to the player's point score. The player can continue playing
    until they exceed the number of points needed to get to the next level
    or until the time runs out, at which point they are brought back to the
    main menu or the score entry menu if they made the top 10.
]]

PlayState = Class{__includes = BaseState}

function PlayState:init()
    
    -- start our transition alpha at full, so we fade in
    self.transitionAlpha = 1

    -- position in the grid which we're highlighting
    self.boardHighlightX = 0
    self.boardHighlightY = 0

    -- timer used to switch the highlight rect's color
    self.rectHighlighted = false

    -- flag to show whether we're able to process input (not swapping or clearing)
    self.canInput = true

    -- tile we're currently highlighting (preparing to swap)
    self.highlightedTile = nil

    self.score = 0
    self.timer = 60

    -- set our Timer class to turn cursor highlight on and off
    Timer.every(0.5, function()
        self.rectHighlighted = not self.rectHighlighted
    end)

    -- subtract 1 from timer every second
    Timer.every(1, function()
        self.timer = self.timer - 1

        -- play warning sound on timer if we get low
        if self.timer <= 5 then
            gSounds['clock']:play()
        end
    end)

    -- particle system 
    self.psystem = love.graphics.newParticleSystem(gTextures['particle'], 10000)
    
    -- lasts between 0.5-1 seconds seconds
    self.psystem:setParticleLifetime(0.1, 0.2)
    
    -- give it an acceleration of anywhere between X1,Y1 and X2,Y2 (0, 0) and (80, 80) here
    -- gives generally downward 
    self.psystem:setLinearAcceleration(-1, 0, 1, 1)
    
    -- spread of particles; normal looks more natural than uniform
    self.psystem:setEmissionArea('normal', 5, 5)
    self.psystem:setColors(1,1,1,1,1,1,0,1)
    
end

function PlayState:enter(params)
    
    
    -- grab level # from the params we're passed
    self.level = params.level
    
    -- spawn a board and place it toward the right
    self.board = params.board or Board(VIRTUAL_WIDTH - 272, 16, self.level)
    
    -- grab score from params if it was passed
    self.score = params.score or 0
    
    -- score we have to reach to get to the next level
    self.scoreGoal = self.level * 1.25 * 1000

    self.shinyBlocks = {}

    PlayState(self.board)
    
end

function PlayState:initShinyTiles(board)
    -- Initialize a table to store the positions of shiny blocks
    local shinyBlocks = {}
    self.board = board
    
    -- Iterate through your 2D grid of tiles
    for tileY = 1, 8 do
        for tileX = 1, 8 do
            if self.board.tiles[tileX][tileY].shine then
                -- If the tile is shiny, add its position to the shinyBlocks table
                local x = self.board.tiles[tileX][tileY].x
                local y = self.board.tiles[tileX][tileY].y
                table.insert(shinyBlocks, {x = x, y = y})
            end
        end
    end
    return shinyBlocks
end

function PlayState:update(dt)


    if next(self.shinyBlocks) == nil then
        self.shinyBlocks = PlayState:initShinyTiles(self.board)
    end
    
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
    
    -- go back to start if time runs out
    if self.timer <= 0 then
        
        -- clear timers from prior PlayStates
        Timer.clear()
        
        gSounds['game-over']:play()
        
        gStateMachine:change('game-over', {
            score = self.score
        })
    end
    
    -- go to next level if we surpass score goal
    if self.score >= self.scoreGoal then
        
        -- clear timers from prior PlayStates
        -- always clear before you change state, else next state's timers
            -- will also clear!
            Timer.clear()
            
            gSounds['next-level']:play()
            
            -- change to begin game state with new level (incremented)
            gStateMachine:change('begin-game', {
                level = self.level + 1,
                score = self.score
            })
    end
    
    if self.canInput then
        -- move cursor around based on bounds of grid, playing sounds
        if love.keyboard.wasPressed('up') then
            self.boardHighlightY = math.max(0, self.boardHighlightY - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('down') then
            self.boardHighlightY = math.min(7, self.boardHighlightY + 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('left') then
            self.boardHighlightX = math.max(0, self.boardHighlightX - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('right') then
            self.boardHighlightX = math.min(7, self.boardHighlightX + 1)
            gSounds['select']:play()
        end
        self.shinyBlocks = PlayState:initShinyTiles(self.board) --update particles
        
        -- if we've pressed enter, to select or deselect a tile...
         if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
            
            -- if same tile as currently highlighted, deselect
            local x = self.boardHighlightX + 1
            local y = self.boardHighlightY + 1
            
            -- if nothing is highlighted, highlight current tile
            if not self.highlightedTile then
                self.highlightedTile = self.board.tiles[y][x]

            -- if we select the position already highlighted, remove highlight
            elseif self.highlightedTile == self.board.tiles[y][x] then
                self.highlightedTile = nil

            -- if the difference between X and Y combined of this highlighted tile
            -- vs the previous is not equal to 1, also remove highlight
            elseif math.abs(self.highlightedTile.gridX - x) + math.abs(self.highlightedTile.gridY - y) > 1 then
                gSounds['error']:play()
                self.highlightedTile = nil
            else
                
                -- swap grid positions of tiles
                local tempX = self.highlightedTile.gridX
                local tempY = self.highlightedTile.gridY
                
                local newTile = self.board.tiles[y][x]
                
                self.highlightedTile.gridX = newTile.gridX
                self.highlightedTile.gridY = newTile.gridY
                newTile.gridX = tempX
                newTile.gridY = tempY
                
                -- swap tiles in the tiles table
                self.board.tiles[self.highlightedTile.gridY][self.highlightedTile.gridX] =
                    self.highlightedTile
                
                self.board.tiles[newTile.gridY][newTile.gridX] = newTile
                
                local varietyInMatches, isShiny = self.board:calculateMatches()
                print("varietyInMatches: ", varietyInMatches)
                print("shine: ", isShiny)
                if varietyInMatches == false then
                    gSounds['error']:play()
                    print("ERROR")
                    print("############ No MATCH #################")

                    -- Swap tiles in the tiles table back to their original positions

                    -- Remember the original positions before swapping
                    local originalGridX = self.highlightedTile.gridX
                    local originalGridY = self.highlightedTile.gridY

                    -- Swap grid positions back to the original positions
                    self.highlightedTile.gridX = newTile.gridX
                    self.highlightedTile.gridY = newTile.gridY
                    newTile.gridX = originalGridX
                    newTile.gridY = originalGridY

                    -- Swap tiles in the tiles table back to their original positions
                    self.board.tiles[self.highlightedTile.gridY][self.highlightedTile.gridX] = self.highlightedTile
                    self.board.tiles[newTile.gridY][newTile.gridX] = newTile

                    self.highlightedTile = nil
                else
                    -- tween coordinates between the two so they swap
                    Timer.tween(0.1, {
                        [self.highlightedTile] = {x = newTile.x, y = newTile.y},
                        [newTile] = {x = self.highlightedTile.x, y = self.highlightedTile.y}
                    })
                    
                    -- once the swap is finished, we can tween falling blocks as needed
                    :finish(function()
                        self:calculateMatches()
                    end)
                end
            end
        end
    end
    
    -- _______________ Spec.3 add shiny blocks ______________________
    -- shiny blocks (particle system)
    -- if block is shiney then emit particles
    --print("size of table", #self.shinyBlocks)
    for _, block in pairs(self.shinyBlocks) do
        --print("Block: ", _)
        --print("particle emitted at x and y: ", block.x," ", block.y)
        self.psystem:setPosition(block.x + VIRTUAL_WIDTH - 272 + 16, block.y + 16 + 16)
        self.psystem:emit(1)
    end
    --print(self.shinyBlocks[1])
    -- for rendering particle systems
    self.psystem:update(dt)
    
    Timer.update(dt)
end

--------------------------
function PlayState:ShinyTiles()
    for tileY = 1, 8 do
        for tileX = 1, 8 do
            if self.board.tiles[tileX][tileY].shine then
                -- get positions of tiles relative to the board and find center (half width and height of tile)
                self.psystem:setPosition(self.board.tiles[tileX][tileY].x + VIRTUAL_WIDTH - 272 + 16, self.board.tiles[tileX][tileY].y + 16 + 16) -- Set the particle system's position to (0, 0) initially
                self.psystem:emit(1)
            end
        end
    end
end


--[[
    Calculates whether any matches were found on the board and tweens the needed
    tiles to their new destinations if so. Also removes tiles from the board that
    have matched and replaces them with new randomized tiles, deferring most of this
    to the Board class.
    ]]
    function PlayState:calculateMatches()
        self.highlightedTile = nil
        
        -- if we have any matches, remove them and tween the falling blocks that result
        -- local matches = self.board:calculateMatches()
        local varietyInMatches, isShiny = self.board:calculateMatches()
        self.isShiny = isShiny
        
        if varietyInMatches then
            gSounds['match']:stop()
            gSounds['match']:play()
            
            
            -- add score for each match
            for k, varietyInMatches in pairs(varietyInMatches) do
            if self.isShiny == true then
                self.score = self.score + 8 * 50 -- for whole row
                self.timer = self.timer + 8
            else
                self.score = self.score + #varietyInMatches * 50
                self.timer = self.timer + #varietyInMatches -- add time to timer for a match
            end
            -- print("\nk: ",k)
            -- print("matches: ", #varietyInMatches)
            print("base score: ", self.score)
            for i, variety in pairs(varietyInMatches) do
                -- print("i: ",i)
                -- print("tile: ", tile)
                print("Tile bonus: " , 10 * variety - 10)
                self.score = self.score + 10 * variety - 10 -- add additional score for higher ranking tiles
            end
        end
        
        -- remove any tiles that matched from the board, making empty spaces
        print("is shiny -> play: ", self.isShiny)
        self.board:removeMatches(self.isShiny)
        
        -- gets a table with tween values for tiles that should now fall
        local tilesToFall = self.board:getFallingTiles()
        
        -- tween new tiles that spawn from the ceiling over 0.25s to fill in
        -- the new upper gaps that exist
        Timer.tween(0.25, tilesToFall):finish(function()
            
            -- recursively call function in case new matches have been created
            -- as a result of falling blocks once new blocks have finished falling
            self:calculateMatches()
        end)
        
        --self:MatchPossibility()
        
    else
        self.canInput = true
    end
end

-- similar to calculate matches above however for resetting board if no matches possible after a match
function PlayState:MatchPossibility()
    self.highlightedTile = nil

    if self.board:MatchPossibility(self.board) then
        print(true)
    else 
        print(false)
    end

    self.canInput = true
end

function PlayState:render()
    -- render board of tiles
    self.board:render()

    -- render shiny bricks
    --self.psystem:render()
    love.graphics.draw(self.psystem)

    -- render highlighted tile if it exists
    if self.highlightedTile then
        
        -- multiply so drawing white rect makes it brighter
        love.graphics.setBlendMode('add')

        love.graphics.setColor(1, 1, 1, 96/255)
        love.graphics.rectangle('fill', (self.highlightedTile.gridX - 1) * 32 + (VIRTUAL_WIDTH - 272),
            (self.highlightedTile.gridY - 1) * 32 + 16, 32, 32, 4)

        -- back to alpha
        love.graphics.setBlendMode('alpha')
    end

    -- render highlight rect color based on timer
    if self.rectHighlighted then
        love.graphics.setColor(217/255, 87/255, 99/255, 1)
    else
        love.graphics.setColor(172/255, 50/255, 50/255, 1)
    end

    -- draw actual cursor rect
    love.graphics.setLineWidth(4)
    love.graphics.rectangle('line', self.boardHighlightX * 32 + (VIRTUAL_WIDTH - 272),
        self.boardHighlightY * 32 + 16, 32, 32, 4)

    -- GUI text
    love.graphics.setColor(56/255, 56/255, 56/255, 234/255)
    love.graphics.rectangle('fill', 16, 16, 186, 116, 4)

    love.graphics.setColor(99/255, 155/255, 1, 1)
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf('Level: ' .. tostring(self.level), 20, 24, 182, 'center')
    love.graphics.printf('Score: ' .. tostring(self.score), 20, 52, 182, 'center')
    love.graphics.printf('Goal : ' .. tostring(self.scoreGoal), 20, 80, 182, 'center')
    love.graphics.printf('Timer: ' .. tostring(self.timer), 20, 108, 182, 'center')
end