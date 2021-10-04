-- Imports
local lg = love.graphics
local lp = love.physics
local Assets = require 'assets'

local hex = (require 'util').hex
local pick = (require 'util').pick
local inrange = (require 'util').inrange
local shuffle = (require 'util').shuffle

-- Global spaghetti
DEBUG = false
function dprint (str) if DEBUG then print (str) end end

local WIDTH = 400
local HEIGHT = 400
local DPI_SCALE = 2
local GOAL = 2000
local LegKeys = {'k','l','o','p'}
local BarColors = {
	pwr = {hex 'f9c440'},
	grp = {hex '3a9104'},
	ket = {hex '0d52bf'},
	ivr = {hex 'c6262e'}
}
-- this could be so much better lol. shoulda made a class for this or something
local BarOrder = {"pwr", "grp", "ivr", "ket"}

local PHYSICS_WORLD, Objects, HorseLegs, Obstacles, Bars, START_TIME, CURRENT_TIME

function love.load ()
	love.window.updateMode (WIDTH*DPI_SCALE,HEIGHT*DPI_SCALE)
	math.randomseed(love.timer.getTime ())
	love.window.setTitle ("KLOP: Un-stabled")
	lg.setDefaultFilter ('nearest', 'nearest', 0)
	lg.setFont (love.graphics.newFont (12, 'normal'))
	Assets.load ()
	reset ()
end
-- every physics coefficient is completely arbitrary and was chosen
-- because it felt the right combination of janky and playable
function reset ()
	START_TIME = love.timer.getTime ()
	CURRENT_TIME = START_TIME
	Bars = {
		pwr = 0.5,
		grp = 0.5,
		ket = 0,
		ivr = 0
	}
	Objects = {}
	HorseLegs = {}
	Obstacles = {}

	PHYSICS_WORLD = lp.newWorld (0, 80)
	PHYSICS_WORLD:setSleepingAllowed (false)
	Objects.floor = lp.newBody (PHYSICS_WORLD, 0, HEIGHT-50, 'static')
	lp.newFixture (Objects.floor, lp.newEdgeShape (-100000,0, 100000, 0)):setFriction (1)
	Objects.horse = lp.newBody (PHYSICS_WORLD, 50, HEIGHT-50-40, 'dynamic')
	local f = lp.newFixture (Objects.horse, lp.newPolygonShape (18,-20, 30,-11, 30,-2, 20,18, -20,19, -35,10, 0, -5, -20,-10))
	f:setRestitution (0.8)
	f:setFriction (0.1)
	for x=160,100000,math.random (100,200) do
		local body = lp.newBody (PHYSICS_WORLD, x, HEIGHT-40)
		local fix = lp.newFixture (body, lp.newCircleShape(math.random(15,30)))
		Objects["obstacle_"..x] = body
		table.insert (Obstacles, body)
	end

	for i=1,4 do
		local body = lp.newBody (PHYSICS_WORLD, 22*i-10, HEIGHT-52, 'dynamic')
		local fix = lp.newFixture (body, lp.newCircleShape (4))
		fix:setDensity (200)
		fix:setCategory (2)
		fix:setMask (2) -- probably unnecessary now that the feet can't collide anyway
		local x,y = Objects.horse:getPosition ()
		x, y = x+10*(i-3), y+15
		local z,w = body:getPosition ()

		local ax, ay = z-x, w-y
		local d = math.sqrt (ax*ax+ay*ay)
		ax, ay = ax/d, ay/d
		local j = lp.newDistanceJoint (Objects.horse, body, x, y, z, w);
		j:setFrequency (3)
		table.insert (HorseLegs, j)
		lp.newPrismaticJoint (Objects.horse, body, x, y, ax, ay)

		Objects["horse_foot_"..i] = body
	end
end

function love.keypressed (key)
	if key == 'r' then
		reset ()
	elseif key == '-' and DPI_SCALE > 1 then
		DPI_SCALE = DPI_SCALE - 0.5
		love.window.updateMode (WIDTH*DPI_SCALE,HEIGHT*DPI_SCALE)
	elseif key == '=' and DPI_SCALE < 5 then
		DPI_SCALE =DPI_SCALE + 0.5
		love.window.updateMode (WIDTH*DPI_SCALE,HEIGHT*DPI_SCALE)
	end
end
function love.update (dt)
	for i,leg_joint in ipairs (HorseLegs) do
		if love.keyboard.isDown (LegKeys[i]) then
			leg_joint:setLength (math.min (50, leg_joint:getLength ()+2*math.pow (Bars.pwr+0.5, 3)))
			Objects["horse_foot_"..i]:getFixtures ()[1]:setFriction (Bars.grp)
		else
			Objects["horse_foot_"..i]:getFixtures ()[1]:setFriction (0.05)
			leg_joint:setLength (math.max (5, leg_joint:getLength ()-2))
		end
	end
	if love.keyboard.isDown (',') then
		if Bars.ivr > 0.06 then
			Bars.pwr = Bars.pwr + 0.03
			Bars.ivr = Bars.ivr - 0.06
		end
	else
		Bars.ivr = math.min (1, math.max (0, Bars.ivr + 0.006))
	end
	if love.keyboard.isDown ('.') then
		if Bars.ket > 0.06 then
			Bars.grp = Bars.grp + 0.03
			Bars.ket = Bars.ket - 0.06
		end
	else
		Bars.ket = math.min (1, math.max (0, Bars.ket + 0.006))
	end
	-- update pwr value
	Bars.pwr = math.min (1, math.max (0, Bars.pwr + 0.1*(math.random ()-0.5)))
	Bars.grp = math.min (1, math.max (0, Bars.grp + 0.1*(math.random ()-0.5)))

	PHYSICS_WORLD:update (dt)

	if Objects.horse:getX () < GOAL then
		CURRENT_TIME = love.timer.getTime ()
	end
end
function love.draw ()
	lg.push ()
		lg.scale (DPI_SCALE, DPI_SCALE)
		lg.clear (hex '64baff')
		-- draw the floor
		lg.setColor (hex '3a9104')
		lg.rectangle ('fill', 0, Objects.floor:getY (), WIDTH, 50)
		lg.push ()
			lg.translate (WIDTH/2-Objects.horse:getX (), 0)
			lg.print ("go right if you can", -130, HEIGHT-50-60)
			lg.print ("- & = for DPI scaling", -130, HEIGHT-50-40)
			lg.print (", & . to use drugs", -130, HEIGHT-50-20)
			-- draw the obstacles
			for i, obstacle in ipairs (Obstacles) do
				local x,y = obstacle:getPosition ()
				lg.circle ('fill', x, y, obstacle:getFixtures ()[1]:getShape ():getRadius ())
			end
			lg.setColor (hex 'ffffff')
			-- draw the barn
			lg.draw (Assets.Images.barn, 0, Objects.floor:getY () - Assets.Images.barn:getHeight ())
			-- draw the horse
			local hx, hy = Objects.horse:getPosition ()
			lg.draw (Assets.Images.horse, hx, hy, Objects.horse:getAngle (), 1, 1, 31, 20)
			lg.setLineWidth (5)
			for i, joint in ipairs (HorseLegs) do
				lg.setColor (hex '57392d')
				lg.line (joint:getAnchors ())
				local x,y = Objects["horse_foot_"..i]:getPosition ()
				lg.circle ('fill', x, y, 4)
				lg.setColor (hex 'fafafa')
				lg.print (LegKeys[i], x, y)
			end
			lg.setLineWidth (1)
			-- draw shape bounding boxes
			if DEBUG then
				lg.setColor (hex 'ffe16b')
				for i,body in ipairs (PHYSICS_WORLD:getBodies ()) do
					for j, fixture in ipairs (body:getFixtures ()) do
						local shape = fixture:getShape ()
						if shape:getType () == 'polygon' then
							lg.polygon ('line', body:getWorldPoints (shape:getPoints ()))
						else
							for k=1,shape:getChildCount () do
								local x,y = body:getPosition ()
								local x1,y1,x2,y2 = shape:computeAABB (0, 0, body:getAngle (), k)
								lg.rectangle ('line', x+x1, y+y1, x2-x1, y2-y1)
							end
						end
					end
				end
			end
		lg.pop ()
		-- draw bars
		lg.push ()
			for i,k in ipairs (BarOrder) do
				local val = Bars[k]
				lg.setColor (unpack (BarColors[k]))
				lg.rectangle ('fill', 20, 60, 10, -50*val)
				lg.setColor (hex '333333')
				lg.rectangle ('line', 20, 10, 10, 50)
				lg.print (k, 15, 65)
				lg.translate (30,0)
			end
		lg.pop ()

		local win_string = ""
		if Objects.horse:getX () > GOAL then
			win_string = " :) You win!!!"
		end
		lg.print (string.format ("%d/%d cubits traveled%s", Objects.horse:getX (), GOAL, win_string), #BarOrder*30+10, 20)
		lg.print (string.format ("%0.2f seconds elapsed", CURRENT_TIME - START_TIME), #BarOrder*30+10, 40)
	lg.pop ()
end
