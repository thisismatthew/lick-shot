import "CoreLibs/graphics"
import "CoreLibs/object"

local gfx <const> = playdate.graphics

class("spring").extends()

function spring:init(k, restLength,a, b)
    self.data = {
		k = k,
		restLength = restLength,
		a = a,
		b = b,
	}
end

function spring:update()
	data = self.data
	force = data.b.label.position - data.a.label.position
	x = force:magnitude() - data.restLength
	force:normalize()
	force:scale(data.k * x)
	data.a:applyForce(force)
	force:scale(-1)
	data.b:applyForce(force)
end

function spring:show()
	a = self.data.a
	b = self.data.b
	gfx.setLineWidth(10)
	gfx.drawLine(a.label.position.dx,a.label.position.dy,b.label.position.dx,b.label.position.dy)
end


