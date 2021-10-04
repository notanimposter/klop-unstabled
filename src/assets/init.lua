local Images = {}
local Sounds = {}
return {
	Images = Images,
	Sounds = Sounds,
	load = function ()
		for i,filename in ipairs (love.filesystem.getDirectoryItems ("assets/")) do
			local name, ext = filename:match ("(.+)%.(...)")
			if ext == "png" then
				Images[name] = love.graphics.newImage ("assets/"..filename)
			elseif ext == "wav" then
				Sounds[name] = love.audio.newSource ("assets/"..filename, 'static')
			end
		end
	end
}
