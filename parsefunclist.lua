local parsefunclist = {
	configtest=function(tab)
		local result = {}
		for k,v in pairs(tab) do
			local tt = {}
			for tp,num in string.gmatch(v.cardinfo,"(%d+)-(%d+)") do
				tt[tonumber(tp)] = tonumber(num)
			end
			v.cardinfo = tt
			result[v.id] = v
		end
		return result
	end,
}
return parsefunclist