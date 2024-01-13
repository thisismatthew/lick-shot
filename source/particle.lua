import "CoreLibs/graphics"
import "CoreLibs/object"

local gfx <const> = playdate.graphics

class("particle").extends()

function particle:init(x,y)
    self.label = {
        acceleration = playdate.geometry.vector2D.new(0,0),
        velocity = playdate.geometry.vector2D.new(0,0),
        position = playdate.geometry.vector2D.new(x,y),
        unlocked = true
	}
end

function particle:applyForce(force)
    if (self.label.unlocked) then
        self.label.acceleration = self.label.acceleration + force
    end
end

function particle:applyMovement(force)
    self.label.acceleration = self.label.acceleration + force
end

function particle:MoveToPoint(point, speed)
    --get direction
    force = point - self.label.position
    force:normalize()
    force = force * speed

    self:applyMovement(force)
end

function particle:isCloseTo(point, threshold)
    distance = point - self.label.position
    return (point - self.label.position):magnitude() <= threshold
end

function particle:update()
    local label = self.label
    label.velocity = label.velocity * 0.8
    label.velocity = label.velocity + label.acceleration
    label.position = label.position + label.velocity
    label.acceleration.dx = 0
    label.acceleration.dy = 0
end

function particle:show()
    gfx.setLineWidth(5)
    gfx.drawCircleAtPoint(self.label.position.dx,self.label.position.dy,3)
end

