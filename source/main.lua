import "particle"
import "spring"
import "fly"
import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/crank"
import "CoreLibs/sprites"
import "CoreLibs/animation"
import "CoreLibs/timer"

local gfx <const> = playdate.graphics
local font = gfx.font.new('font/Mini Sans 2X') -- DEMO
local sprites = {}

local gravity = playdate.geometry.vector2D.new(0,0.3)
local particles = {}
local springs = {}
local k = 0.8
local spacing = 5
local tongueParticle
local particleCount = 10
local movementForce = 2
local currentTarget = playdate.geometry.vector2D.new(460,200)
local pointsToHit = {}
local tongueActive = false
local pointTongueIndex = 1
local pointAddIndex = 0
local retractionTimeActive = false
local firstRetractionPos = playdate.geometry.vector2D.new(0,0)
local firstRetractionPosReached = false
local retractionSpeedIndex = 2
local mouthPosition = playdate.geometry.vector2D.new(308,188)
local circles = {}
local lickShotRadius = 30
local flies = {}
local score = 0
local gameTimer = playdate.timer.new(60000)
local targetMarkerImage = gfx.image.new("Images/targetMarker")
assert(targetMarkerImage)
local targetMarkers = {}
local targetRotation = 0
local gameState = "start"


--title animation

local frameTime = 32
local animationImagtetable = gfx.imagetable.new("title")
assert(animationImagtetable)
local titleAnimLoop = gfx.animation.loop.new(frameTime,animationImagtetable,true)


-- music loading

local fileplayer = playdate.sound.fileplayer.new()
fileplayer:load("Sounds/music")


local function loadImage(stringPath, active)
	local tempImg = gfx.image.new(stringPath)
	assert(tempImg)

	sprites[#sprites+1] = gfx.sprite.new(tempImg)
	
	if (active) then 
		sprites[#sprites]:add() 
	end
	sprites[#sprites]:moveTo(200,120)
end

local function loadGame()
	playdate.display.setRefreshRate(50) -- Sets framerate to 50 fps
	math.randomseed(playdate.getSecondsSinceEpoch()) -- seed for math.random
	gfx.setFont(font) -- DEMO



	local reticuleImage = gfx.image.new("Images/reticule")
	assert(reticuleImage)

	reticule_spr = gfx.sprite.new(reticuleImage)
	
	reticule_spr:moveTo(200,120)

	loadImage("Images/Chameleon1", false)
	loadImage("Images/Chameleon2", false)
	loadImage("Images/background", false)
	loadImage("Images/titleBackground", true)


	--some setup stuff to get all of our tongue particles ready
	for i = 1, particleCount, 1 do
		particles[i] = particle(288,173)
		if (i~=1) then
			local a = particles[i]
			local b = particles[i-1]
			springs[#springs+1] = spring(k, spacing, a, b)
		end
	end
	particles[1].label.unlocked = false
	tongueParticle = particles[#particles]
	tongueParticle.label.unlocked = false


	for i = 1, 8, 1 do
		flies[i] = fly(tongueParticle)
	end
end


local function controlReticule()
	local vec = playdate.geometry.vector2D.new(0,0)

	if (playdate.buttonIsPressed("down")) then
		vec.dy = 4
	end
	if (playdate.buttonIsPressed("up")) then
		vec.dy = -4
	end
	if (playdate.buttonIsPressed("left")) then
		vec.dx = -4
	end
	if (playdate.buttonIsPressed("right")) then
		vec.dx = 4
	end
	-- vec:scale(movementForce)
	-- tongueParticle:applyMovement(vec)
	reticule_spr:moveBy(vec.dx, vec.dy)
end

function crankSpringSpacing()
	spacing = spacing - 5
	if (spacing<0.01) then spacing = 0.01 end
	for i = 1, #springs, 1 do
		springs[i].data.restLength = spacing;
	end
end


local function updateGame()
	playdate.timer.updateTimers()


	--update flies
	for i = 1, #flies, 1 do
		flies[i]:update()
		if (flies[i].state == "onscreen") then
			print("checking fly closeness")
			if(flies[i].particle:isCloseTo(tongueParticle.label.position,lickShotRadius))then
				flies[i].state = "caught"
			end
		end
		
	end

	controlReticule()
	
	
	--Lining Up Shots
	if (not retractionTimeActive and not tongueActive and playdate.buttonJustPressed("b")) then
		local newTarget = playdate.geometry.vector2D.new(0,0)
		newTarget.dx = reticule_spr.x
		newTarget.dy = reticule_spr.y
		pointAddIndex = pointAddIndex + 1
		pointsToHit[pointAddIndex] = newTarget

		targetMarkers[pointAddIndex] = gfx.sprite.new(targetMarkerImage)
		assert(targetMarkers[pointAddIndex])
		targetMarkers[pointAddIndex]:add()
		targetMarkers[pointAddIndex]:moveTo(newTarget.dx,newTarget.dy)
		
		print("target added".. tostring(pointsToHit[pointAddIndex]))
	end

	--Setting Off the Shots
	if (not retractionTimeActive and not tongueActive and pointAddIndex > 0 and (playdate.buttonJustPressed("a") or pointAddIndex==3)) then
		tongueActive = true
		reticule_spr:remove()
		firstRetractionPos.dx = pointsToHit[#pointsToHit].dx
		print("first target retraction pos" .. tostring(firstRetractionPos))
		firstRetractionPos.dy = 220;
		print(" and again" .. tostring(firstRetractionPos))
		--probably should hide the reticuleImage While this happens
		print("let's go!")
	end

	if (tongueActive and pointAddIndex > 0) then
		--move the tongue particle towards the first pointsToHit point, 
		-- once it gets there move to the next in the lis
		if (not tongueParticle:isCloseTo(pointsToHit[pointTongueIndex], 8)) then 
			tongueParticle:MoveToPoint(pointsToHit[pointTongueIndex], 10)
		else 
			print("Target Hit!")	
			pointTongueIndex = pointTongueIndex +1
			if (pointTongueIndex > pointAddIndex) then
				pointTongueIndex = 1
				for i = 1, pointAddIndex, 1 do
					targetMarkers[i]:remove()
				end
				pointAddIndex = 0
				tongueActive = false
				retractionTimeActive = true
			end
		end
	end

	if (retractionTimeActive) then
		local crankTicks = playdate.getCrankTicks(6) == 1
		if (not firstRetractionPosReached) then
			if (not tongueParticle:isCloseTo(firstRetractionPos, 5)) then
				tongueParticle:MoveToPoint(firstRetractionPos,1)
			else 
				firstRetractionPosReached = true
			end
		else
			if (not tongueParticle:isCloseTo(mouthPosition, 8) and crankTicks) then
				crankSpringSpacing()
				retractionSpeedIndex = retractionSpeedIndex + 1
				tongueParticle:MoveToPoint(mouthPosition,retractionSpeedIndex)
			end
		end
		if ( tongueParticle:isCloseTo(mouthPosition, 4)) then
			retractionTimeActive = false
			retractionSpeedIndex = 1
			reticule_spr:add()
			spacing = 5
			local springLen = #springs
			for i = 1, springLen, 1 do
				springs[i].data.restLength = spacing;
			end
			local flyLen = #flies
			for i = 1, flyLen, 1 do
				if(flies[i].state == "caught") then
					score = score + 1
					flies[i]:shuffle()
					flies[i].state = "entering"
				end
			end
		end
	end
	
	local springLen = #springs
	for i = 1, springLen, 1 do
		springs[i]:update()
	end
	local particleLen = #particles
	for i = 1, particleLen, 1 do
		particles[i]:applyForce(gravity)
		particles[i]:update()
	end
end

local function drawGame()
	gfx.clear() -- Clears the screen PUT ABOVE OTHER STUFF
	gfx.sprite:update() -- this too apparently

	--draw a flies
	local flyLen = #flies
	for i = 1, flyLen, 1 do
		flies[i]:show()
	end



	gfx.drawText("Score:" .. tostring(score),30,10)
	local timeLeft = gameTimer.timeLeft/1000
	timeLeft = math.floor(timeLeft+0.5)
	--gfx.drawText("Time Remaining:" .. tostring(timeLeft),150,10)


	if (pointAddIndex>0 and #pointsToHit >0) then
		if (targetRotation<360)then
			targetRotation = targetRotation+1
		else
			targetRotation = 0
		end
		for i = 1, pointAddIndex, 1 do
			gfx.drawText(tostring(i), targetMarkers[i].x-30, targetMarkers[i].y-30)
			targetMarkers[i]:setRotation(targetRotation)
		end
	end

	if (tongueActive or retractionTimeActive) then
		sprites[1]:add()
		sprites[2]:remove()
		local springLen = #springs
		for i = 1, springLen, 1 do
			springs[i]:show()
		end
		local particleLen = #particles
		for i = 1, particleLen, 1 do
			particles[i]:show()
		end
	else
		sprites[1]:remove()
		sprites[2]:add()
	end
end

local function startScreen() 
	
end

loadGame()

function playdate.update()
	--gfx.setColor(gfx.kColorWhite)
	gfx.setBackgroundColor(gfx.kColorWhite)
	if (gameState == "start") then
		fileplayer:play(0)
		gfx.clear() -- Clears the screen PUT ABOVE OTHER STUFF
		gfx.sprite:update() -- this too apparently
		titleAnimLoop:draw(0,0)

		if (playdate.buttonJustPressed("a")) then
			for i = 1, 3, 1 do
				sprites[i]:add()
			end
			for i = 4, #sprites, 1 do
				sprites[i]:remove()
			end
			reticule_spr:add()
			gameState = "playing"
		end
		
	elseif(gameState == "playing") then
		updateGame()
		drawGame()
	elseif (gameState == "end") then

	end
	

	playdate.drawFPS(0,0) -- FPS widget
end

function playdate.debugDraw()
	gfx.setLineWidth(1)
	--bit of a debug draw 
	if (pointAddIndex>0 and #pointsToHit >0) then
		for i = 1, pointAddIndex, 1 do
			if (i>pointTongueIndex-1)then
				print("circle for point "..tostring(i))
				gfx.drawCircleAtPoint(pointsToHit[i], lickShotRadius)
			end
		end
	end

	local flyLen = #flies
	for i = 1, flyLen, 1 do
		flies[i]:debugShow()
	end
end