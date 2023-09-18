--[[
    GD50
    Match-3 Remake

    -- Board Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The Board is our arrangement of Tiles with which we must try to find matching
    sets of three horizontally or vertically.
]]

Board = Class{}

function Board:init(x, y, level)
    self.x = x
    self.y = y
    self.matches = {}
    self.level = level

    self.varieties = 5
    self.currentTiles = {} -- to give score according to tiles

    self:initializeTiles()
    self.isShiny = true


end

function Board:initializeTiles()
    self.tiles = {}
    
    if self.level < 7 then 
        for tileY = 1, 8 do
            
            -- empty table that will serve as a new row
            table.insert(self.tiles, {})

            for tileX = 1, 8 do
                -- chance of shiny block
                shine_prob = math.random(8) -- 1/8 chance for a shiny block   
                -- create a new tile at X,Y with a random color and variety
                if shine_prob > 1 then
                    table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(12), math.random(self.level), false))
                else 
                    table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(12), math.random(self.level), true))
                end
            end
        end
    else 
        for tileY = 1, 8 do
            
            -- empty table that will serve as a new row
            table.insert(self.tiles, {})

            for tileX = 1, 8 do
                
                shine_prob = math.random(8) -- greater than 1 then no shiny block added   
                -- create a new tile at X,Y with a random color and variety
                if shine_prob > 1 then
                    table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(12), math.random(self.level), false))
                else 
                    table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(12), math.random(self.level), true))
                end
            end
        end
    end

    while self:calculateMatches() do
        
        -- recursively initialize if matches were returned so we always have
        -- a matchless board on start

        while not self:MatchPossibility() do
            -- recursively init board if no possible matches
            self:initializeTiles()
        end
    end
    
end

function Board:MatchPossibility(params)
    -- iterate over all possible swaps to get a match. if no match then re-init tiles
    
    -- originalBoard prior to swapping
    local originalTiles = {} or params.board()

    if not originalTiles == params.board() then
        for tileY = 1, 8 do
            originalTiles[tileY] = {}
            for tileX = 1, 8 do
                originalTiles[tileY][tileX] = self.tiles[tileY][tileX]:clone()
            end
        end

    end
    
    
    -- for all y rows
    for tileY = 1, 8 do --8th row 1 less swap
        for tileX = 1, 8 do
            if tileX < 8 and tileY < 8 then
                -- print("tileX: ", tileX, " tileY: ", tileY)
                
                -- swap tiles adjacent / horizontally
                local tempTile = self.tiles[tileY][tileX]
                self.tiles[tileY][tileX] = self.tiles[tileY][tileX + 1]
                self.tiles[tileY][tileX + 1] = tempTile

                local varietyInMatches, isShiny = self:calculateMatches()

                -- Reset the board to original tiles
                self.tiles = originalTiles
                
                -- check if swap causes a match
                if varietyInMatches then
                    print("---------------- Possible Match Found ----------------")
                    return true 
                end

                -- swap tiles adjacent / veritcally 
                local tempTile = self.tiles[tileY][tileX]
                self.tiles[tileY][tileX] = self.tiles[tileY + 1][tileX]
                self.tiles[tileY + 1][tileX] = tempTile

                local varietyInMatches, isShiny = self:calculateMatches()

                -- Reset the board to original tiles
                self.tiles = originalTiles
                
                -- check if swap causes a match
                if varietyInMatches then
                    print("---------------- Possible Match Found ----------------")
                    return true 
                end

            elseif tileX == 8 and tileY < 8 then
                --print("tileX: ", tileX, " tileY: ", tileY)
                
                -- for last column cannot flip horizontally only vertically
            
                -- swap tiles adjacent / veritcally 
                local tempTile = self.tiles[tileY][tileX]
                self.tiles[tileY][tileX] = self.tiles[tileY + 1][tileX]
                self.tiles[tileY + 1][tileX] = tempTile

                local varietyInMatches, isShiny = self:calculateMatches()

                -- Reset the board to original tiles
                self.tiles = originalTiles
                
                -- check if swap causes a match
                if varietyInMatches then
                    print("---------------- Possible Match Found ----------------")
                    return true 
                end

            elseif tileX < 8 and tileY == 8 then
                -- for last row cannot flip vertically only horizontally
            
                -- swap tiles adjacent / veritcally 
                local tempTile = self.tiles[tileY][tileX]
                self.tiles[tileY][tileX] = self.tiles[tileY][tileX + 1]
                self.tiles[tileY][tileX + 1] = tempTile

                local varietyInMatches, isShiny = self:calculateMatches()

                -- Reset the board to original tiles
                self.tiles = originalTiles
                
                -- check if swap causes a match
                if varietyInMatches then
                    print("---------------- Possible Match Found ----------------")
                    return true 
                end

            elseif tileX == 8 and tileY == 8 then
                break -- final tile all possible swaps completed
            end
        end
    end

    return true

end
--[[
    Goes left to right, top to bottom in the board, calculating matches by counting consecutive
    tiles of the same color. Doesn't need to check the last tile in every row or column if the 
    last two haven't been a match.
]]


function Board:calculateMatches(def)
    local board = def.board or self.board
    local matches = {}
    local varietyInMatches = {} -- table keeping track of variety within a match e.g {1,2,2} variety
    self.isShiny = false
    hasShine_h = false
    hasShine_v = false
    ShineTable_h = {}
    ShineTable_v = {}
    -- how many of the same color blocks in a row we've found
    local matchNum = 1
 
    if not board == nil then -- if board input exists
        -- horizontal matches first
        for y = 1, 8 do
            local colorToMatch = board.tiles[y][1].color

            matchNum = 1

            -- every horizontal tile
            for x = 2, 8 do

                -- if this is the same color as the one we're trying to match...
                if board.tiles[y][x].color == colorToMatch then
                    matchNum = matchNum + 1
                else
                    
                    -- set this as the new color we want to watch for
                    colorToMatch = board.tiles[y][x].color

                    -- if we have a match of 3 or more up to now, add it to our matches table
                    if matchNum >= 3 then
                        local match = {}
                        local varietyMatch = {}

                        -- go backwards from here by matchNum
                        for x2 = x - 1, x - matchNum, -1 do
                            
                            -- add each tile to the match that's in that match
                            table.insert(match, board.tiles[y][x2])
                            table.insert(varietyMatch, board.tiles[y][x2].variety)
                        end
                        
                        local matchHasShiny_h = false
                        for _, tile in ipairs(match) do
                            if tile.shine == true then
                                matchHasShiny_h = true
                                break
                            end
                        end
                        if matchHasShiny_h then
                            hasShine_h = true
                        end
                        -- add this match to our total matches table
                        table.insert(matches, match)
                        table.insert(varietyInMatches, varietyMatch)
                    end

                    matchNum = 1

                    -- don't need to check last two if they won't be in a match
                    if x >= 7 then
                        break
                    end
                end
            end

            -- account for the last row ending with a match
            if matchNum >= 3 then
                local match = {}
                local varietyMatch = {}
                
                -- go backwards from end of last row by matchNum
                for x = 8, 8 - matchNum + 1, -1 do
                    table.insert(match, board.tiles[y][x])
                    table.insert(varietyMatch, board.tiles[y][x].variety)
                end

                local matchHasShiny_h = false
                for _, tile in ipairs(match) do
                    if tile.shine == true then
                        matchHasShiny_h = true
                        break
                    end
                end

                if matchHasShiny_h then
                    hasShine_h = true
                end

                table.insert(matches, match)
                table.insert(varietyInMatches, varietyMatch)
            
            else
                --hasShine_h = false
            end
        end

    
        -- vertical matches
        for x = 1, 8 do
            local colorToMatch = board.tiles[1][x].color
            matchNum = 1
            
            -- every vertical tile
            for y = 2, 8 do
                
                if board.tiles[y][x].color == colorToMatch then
                    matchNum = matchNum + 1
                else
                    colorToMatch = board.tiles[y][x].color
                    
                    if matchNum >= 3 then
                        local match = {}
                        local varietyMatch = {}
                        
                        for y2 = y - 1, y - matchNum, -1 do
                            table.insert(match, board.tiles[y2][x])
                            table.insert(varietyMatch, board.tiles[y2][x].variety)
                        end
                        
                        local matchHasShiny_v = false
                        for _, tile in ipairs(match) do
                            if tile.shine == true then
                                matchHasShiny_v = true
                                break
                            end
                        end
                        if matchHasShiny_v then
                            hasShine_v = true
                        end
                            
                        table.insert(matches, match)
                        table.insert(varietyInMatches, varietyMatch)
                    end

                    matchNum = 1
                
                    -- don't need to check last two if they won't be in a match
                    if y >= 7 then
                        break
                    end
                end
            end
            
            -- account for the last column ending with a match
            if matchNum >= 3 then
                local match = {}
                local varietyMatch = {}
                
                -- go backwards from end of last row by matchNum
                for y = 8, 8 - matchNum + 1, -1 do
                    table.insert(match, board.tiles[y][x])
                    table.insert(varietyMatch, board.tiles[y][x].variety)
                end
                
                local matchHasShiny_v = false

                for _, tile in ipairs(match) do
                    if tile.shine == true then
                        matchHasShiny_v = true
                        break
                    end
                end

                if matchHasShiny_v then
                    hasShine_v = true
                end
                
                table.insert(matches, match)
                table.insert(varietyInMatches, variety)
                
            end
        end
            
        return (#varietyInMatches > 0 and varietyInMatches or false), self.isShiny

    elseif board == nil then
        print("no parameter board given")
        -- horizontal matches first
        for y = 1, 8 do
            local colorToMatch = self.tiles[y][1].color

            matchNum = 1
            
            -- every horizontal tile
            for x = 2, 8 do
                
                -- if this is the same color as the one we're trying to match...
                if self.tiles[y][x].color == colorToMatch then
                    matchNum = matchNum + 1
                else
                    
                -- set this as the new color we want to watch for
                colorToMatch = self.tiles[y][x].color

                -- if we have a match of 3 or more up to now, add it to our matches table
                if matchNum >= 3 then
                    local match = {}
                    local varietyMatch = {}
                    
                    -- go backwards from here by matchNum
                    for x2 = x - 1, x - matchNum, -1 do
                        
                        -- add each tile to the match that's in that match
                        table.insert(match, self.tiles[y][x2])
                        table.insert(varietyMatch, self.tiles[y][x2].variety)
                    end
                    
                    local matchHasShiny_h = false
                    for _, tile in ipairs(match) do
                        if tile.shine == true then
                            matchHasShiny_h = true
                            break
                        end
                    end
                    if matchHasShiny_h then
                        hasShine_h = true
                    end
                    -- add this match to our total matches table
                    table.insert(matches, match)
                    table.insert(varietyInMatches, varietyMatch)
                end

                matchNum = 1
                
                -- don't need to check last two if they won't be in a match
                if x >= 7 then
                    break
                end
            end
        end

        -- account for the last row ending with a match
        if matchNum >= 3 then
            local match = {}
            local varietyMatch = {}
            
            -- go backwards from end of last row by matchNum
            for x = 8, 8 - matchNum + 1, -1 do
                table.insert(match, self.tiles[y][x])
                table.insert(varietyMatch, self.tiles[y][x].variety)
            end
            
            local matchHasShiny_h = false
            for _, tile in ipairs(match) do
                if tile.shine == true then
                    matchHasShiny_h = true
                    break
                end
            end
            
            if matchHasShiny_h then
                hasShine_h = true
            end
            
            table.insert(matches, match)
            table.insert(varietyInMatches, varietyMatch)
            
        else
            --hasShine_h = false
        end
    end
    
    
    -- vertical matches
    for x = 1, 8 do
        local colorToMatch = self.tiles[1][x].color
        matchNum = 1
        
        -- every vertical tile
        for y = 2, 8 do
            
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                colorToMatch = self.tiles[y][x].color
                
                if matchNum >= 3 then
                    local match = {}
                    local varietyMatch = {}
                    
                    for y2 = y - 1, y - matchNum, -1 do
                        table.insert(match, self.tiles[y2][x])
                        table.insert(varietyMatch, self.tiles[y2][x].variety)
                    end
                    
                    local matchHasShiny_v = false
                    for _, tile in ipairs(match) do
                        if tile.shine == true then
                            matchHasShiny_v = true
                            break
                        end
                    end
                    if matchHasShiny_v then
                        hasShine_v = true
                    end
                        
                    table.insert(matches, match)
                    table.insert(varietyInMatches, varietyMatch)
                end

                matchNum = 1
            
                -- don't need to check last two if they won't be in a match
                if y >= 7 then
                    break
                end
            end
        end
        
        -- account for the last column ending with a match
        if matchNum >= 3 then
            local match = {}
            local varietyMatch = {}
            
            -- go backwards from end of last row by matchNum
            for y = 8, 8 - matchNum + 1, -1 do
                table.insert(match, self.tiles[y][x])
                table.insert(varietyMatch, self.tiles[y][x].variety)
            end
            
            local matchHasShiny_v = false
            
            for _, tile in ipairs(match) do
                if tile.shine == true then
                    matchHasShiny_v = true
                    break
                end
            end
            
            if matchHasShiny_v then
                hasShine_v = true
            end
            
            table.insert(matches, match)
            table.insert(varietyInMatches, variety)
            
        end
    end
    
    -- store matches for later reference
    self.matches = matches
    self.varietyInMatches = varietyInMatches
    
    
    if hasShine_v and hasShine_h then
        self.isShiny = true
    elseif hasShine_h then
        self.isShiny = true
    elseif hasShine_v then
        self.isShiny = true
    elseif hasShine_h == false and hasShine_v == false then
        self.isShiny = false
    end
    
    -- If there's a shiny block within the match, set self.isShiny to true
    if hasShine_h then
        --print("self.isshiny set to true")
        self.isShiny = true
    end
    
    -- return matches table if > 0, else just return false
    --return #self.matches > 0 and self.matches or false
    --print("#matches: ", #self.matches)
    --print("#variety matches: ", #self.varietyInMatches)
    --print("is shiny block: ", self.isShiny)
    return (#self.varietyInMatches > 0 and self.varietyInMatches or false), self.isShiny
    end
end

--[[
    Remove the matches from the Board by just setting the Tile slots within
    them to nil, then setting self.matches to nil.
]]
function Board:removeMatches(shine)
    if shine == false then
        for k, match in pairs(self.matches) do
            for k, tile in pairs(match) do
                self.tiles[tile.gridY][tile.gridX] = nil
            end
        end
    else  -- remove all in row or column
        local elim_column = true
        local no_row, no_column

        for k, match in pairs(self.matches) do
            for k, tile in pairs(match) do
                if tile.gridY == match[1].gridY then
                    elim_column = false -- to eliminate column or row
                    no_row = tile.gridY
                else 
                    elim_column = true
                    no_column = tile.gridX
                end
            end
        end
        
        
        if elim_column == true then
            --print("elimating a column")
            -- To eliminate tiles in a given column
            for y = 1, #self.tiles do
                if self.tiles[y][no_column] then
                    self.tiles[y][no_column] = nil
                end
            end
        else
            -- To eliminate tiles in a given row
            for x = 1, #self.tiles[no_row] do
                if self.tiles[no_row][x] then
                    self.tiles[no_row][x] = nil
                end
            end
        end

    end
    self.matches = nil
end

--[[
    Shifts down all of the tiles that now have spaces below them, then returns a table that
    contains tweening information for these new tiles.
]]
function Board:getFallingTiles()
    -- tween table, with tiles as keys and their x and y as the to values
    local tweens = {}

    -- for each column, go up tile by tile till we hit a space
    for x = 1, 8 do
        local space = false
        local spaceY = 0

        local y = 8
        while y >= 1 do
            
            -- if our last tile was a space...
            local tile = self.tiles[y][x]
            
            if space then
                
                -- if the current tile is *not* a space, bring this down to the lowest space
                if tile then
                    
                    -- put the tile in the correct spot in the board and fix its grid positions
                    self.tiles[spaceY][x] = tile
                    tile.gridY = spaceY
                    
                    -- set its prior position to nil
                    self.tiles[y][x] = nil
                    
                    -- tween the Y position to 32 x its grid position
                    tweens[tile] = {
                        y = (tile.gridY - 1) * 32
                    }
                    
                    -- set Y to spaceY so we start back from here again
                    space = false
                    y = spaceY
                    
                    -- set this back to 0 so we know we don't have an active space
                    spaceY = 0
                end
            elseif tile == nil then
                space = true
                
                -- if we haven't assigned a space yet, set this to it
                if spaceY == 0 then
                    spaceY = y
                end
            end
            
            y = y - 1
        end
    end
    
    if self.level < 7 then 
        -- create replacement tiles at the top of the screen
        for x = 1, 8 do
            for y = 8, 1, -1 do
                local tile = self.tiles[y][x]
                
                -- if the tile is nil, we need to add a new one
                if not tile then
                    
                    shine_prob = math.random(8) -- greater than 1 then no shiny block added 

                    -- new tile with random color and variety
                    local tile = Tile(x, y, math.random(12), math.random(self.level), false)
                    if shine_prob > 1 then
                        tile = Tile(x, y, math.random(12), math.random(self.level), false)
                    else
                        tile = Tile(x, y, math.random(12), math.random(self.level), true)
                    end
                    tile.y = -32
                    self.tiles[y][x] = tile

                    -- create a new tween to return for this tile to fall down
                    tweens[tile] = {
                        y = (tile.gridY - 1) * 32
                    }
                end
            end
        end
    else
                -- create replacement tiles at the top of the screen
                for x = 1, 8 do
                    for y = 8, 1, -1 do
                        local tile = self.tiles[y][x]
        
                        -- if the tile is nil, we need to add a new one
                        if not tile then
        
                            shine_prob = math.random(8) -- greater than 1 then no shiny block added 

                                -- new tile with random color and variety
                                local tile = Tile(x, y, math.random(12), math.random(self.level), false)
                                if shine_prob > 1 then
                                    tile = Tile(x, y, math.random(12), math.random(self.level), false)
                                else
                                    tile = Tile(x, y, math.random(12), math.random(self.level), true)
                                end
                            tile.y = -32
                            self.tiles[y][x] = tile
        
                            -- create a new tween to return for this tile to fall down
                            tweens[tile] = {
                                y = (tile.gridY - 1) * 32
                            }
                        end
                    end
                end
    end
    return tweens
end

function Board:render()
    for y = 1, #self.tiles do
        for x = 1, #self.tiles[1] do
            self.tiles[y][x]:render(self.x, self.y)
        end
    end
end
