import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/sprites"
import "CoreLibs/animation"

math.randomseed(playdate.getSecondsSinceEpoch())
local gfx <const> = playdate.graphics
--Fly animation stuff
local frameTime = math.random(180,200)
local animationImagtetable = gfx.imagetable.new("fly")
assert(animationImagtetable)
local flyAnimLoop = gfx.animation.loop.new(frameTime,animationImagtetable,true)
local drawPoint
local checkPosition = playdate.geometry.vector2D.new(0,0)
local width,height = flyAnimLoop:image():getSize()
local spawnMin = playdate.geometry.point.new(40,40)
local leftSpawn = playdate.geometry.point.new(200,150)
local spawnMax = playdate.geometry.point.new(300,100)
class("fly").extends()

function fly:init(tongueParticle)
    
    self.tongueParticle = tongueParticle
    self.state = "entering"
    self.startPoint = playdate.geometry.point.new(0,0)
    self.endPoint = playdate.geometry.point.new(0,0) 
    self:shuffle()
    self.particle = particle(self.startPoint.x, self.startPoint.y)
    drawPoint = playdate.geometry.point.new(0, 0)
end

function fly:shuffle()
    self.endPoint = self:getEndPoint()
    self.startPoint = self:getStartPoint()
    self.particle = particle(self.startPoint.x, self.startPoint.y)
end

function fly:getEndPoint()
    --TODO - make it so they spawn into the bottom left corner too rather than just the top part of the screen
    local x = math.random(spawnMin.x,spawnMax.x)
    local y = 0
    if (x > leftSpawn.x) then
        y = math.random(spawnMin.y,spawnMax.y)
    else
        y = math.random(spawnMin.y,leftSpawn.y)
    end
    return playdate.geometry.point.new(x,y)
end

function fly:getStartPoint()
    local x = math.random(0, 400)
    local y = math.random(-200, -50)
    return playdate.geometry.point.new(x,y)
end

function fly:show()
    assert(self.particle)
    drawPoint.x = self.particle.label.position.dx - width/2
    drawPoint.y = self.particle.label.position.dy - height/2
    flyAnimLoop:draw(drawPoint)
end

function fly:debugShow()
    gfx.drawRect(spawnMin.x, spawnMin.y, spawnMax.x, spawnMax.y)
    gfx.drawRect(spawnMin.x, spawnMin.y, leftSpawn.x, leftSpawn.y)
end



function fly:update()
    if (self.state == "entering") then
        checkPosition.dx = self.endPoint.x
        checkPosition.dy = self.endPoint.y
        if(not self.particle:isCloseTo(checkPosition, 4)) then
            self.particle:MoveToPoint(checkPosition, 2)
        else 
            print("reached postion!")
            self.state = "onscreen"
        end
    elseif (self.state == "onscreen") then
        
        --stay put?
        --maybe move to a random point nearby 
        -- position + randomised 1,1 vector
    elseif (self.state == "caught") then
        --move to be stuck to the tongueParticle
        self.particle.label.position = self.tongueParticle.label.position
    end
    self.particle:update()
end