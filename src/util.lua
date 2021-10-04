return {
	hex = function (str)
		str = str:gsub ("#","")
		return ("0x"..str:sub(1,2))/255.0, ("0x"..str:sub(3,4))/255.0, ("0x"..str:sub(5,6))/255.0
	end,
	pick = function (arr)
		if #arr>0 then
			return arr[math.random (#arr)]
		else
			local values = {}
			for k,v in pairs (arr) do
				values[#values+1] = v
			end
			return values[math.random (#values)]
		end
	end,
	inrange = function (a, b, c)
		return a < b and b < c
	end,
	shuffle = function (tbl)
		for i = #tbl, 2, -1 do
			local j = math.random(i)
			tbl[i], tbl[j] = tbl[j], tbl[i]
		end
		return tbl
	end

}
