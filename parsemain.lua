local g_funclist = require "parsefunclist"

function CopyTable(obj)
	if type(obj) ~= "table" then
		return nil
	end
	local new_table = {}
	for k,v in pairs(obj) do
		if type(v) == "table" then
			new_table[k] = CopyTable(v) 
		else
			new_table[k] = v
		end
	end
	return new_table
end

function PrintTable(obj)
	for k, v in pairs(obj) do
		if type(v) == "table" then
			print("\t",k," = {")
			PrintTable(v)
			print("\t","}")
		else
			print("\t",k, " = ", v, ",")
		end
	end
end
function LogTable(name, tab)
	name = name or "default"
	print(name, " =\n{")
	PrintTable(tab)
	print("}")
end

local temp = 0
local space = "\t"
local endline = "\n"
function WriteTableToFile(ret,file)
	local ttspace = space
	for i=1,temp do
		ttspace = ttspace .. space
	end
	if temp == 0 then
		file:write(endline.."{"..endline)
	else
		file:write(endline..ttspace.."{"..endline)
	end
	temp = temp + 1
	for k, v in pairs(ret) do
		if type(v) == "table" then
			if type(k) == "number" then
				file:write(ttspace.."["..k.."]=")
			else
				file:write(ttspace..tostring(k).."=")
			end
			WriteTableToFile(v,file)
		else
			if type(v) == "string" then
				if type(k) == "number" then
					file:write(ttspace.."["..k.."]='"..tostring(v).."',"..endline)
				else
					file:write(ttspace..tostring(k).."='"..tostring(v).."',"..endline)
				end
			else
				if type(k) == "number" then
					file:write(ttspace.."["..k.."]="..tostring(v)..","..endline)
				else
					file:write(ttspace..tostring(k).."="..tostring(v)..","..endline)
				end
			end
		end
	end
	temp = temp - 1
	if temp ==  0 then
		file:write(ttspace..endline.."}"..endline)
	else
		file:write(ttspace..endline..ttspace.."},"..endline)
	end
end

function SplitString(str,del)
	local ret = {}
	local pos = 0
	local index = 1
	while true do
		pos = string.find(str,del,pos)
		if pos == nil then
			local ss = string.sub(str,index,#str)
			table.insert(ret,ss)
			break
		end
		local ss = string.sub(str,index,pos-1)
		index = pos + 1
		pos = pos + 1
		table.insert(ret,ss)
	end
	return ret
end

function ParseCSVFile(filename)
	local file, msg = io.open(filename,"r")
	if not file then
		print("not exist the file,msg = ",msg)
		return nil
	end
	local index = 0
	local attrname = {}
	local attrtype = {}
	local data = {}
	for line in file:lines() do
		line = string.gsub(line,"\r\n",",")
		local rowData = SplitString(line,",")
		if index == 1 then
			attrname = CopyTable(rowData)
		end
		if index == 2 then
			attrtype = CopyTable(rowData)
		end
		if index >= 3 then
			data[#data+1] = rowData
		end
		index = index + 1
	end
	file:close()
	return data,attrname,attrtype
end

function ParseCSVFileToLuaTable(filename,targetpath)
	local tabname = string.sub(filename,1,string.find(filename,".csv")-1)
	local data,attrname,attrtype = ParseCSVFile(filename)
	if not data then
		return
	end
	targetpath =targetpath..tabname..".lua"
	local tempCfg = {}
	for i=1, #data do
		local tt = data[i]
		local one = {}
		for k,v in ipairs(tt) do
			if attrtype[k] == "String" then
				one[attrname[k]] = v
			elseif attrtype[k] == "Number" then
				if v ~= "" then
					one[attrname[k]] = tonumber(v)
				else
					one[attrname[k]] = 0
				end
			end
		end
		table.insert(tempCfg,one)
	end
	local parsefunc = g_funclist[tabname]
	local ret = nil
	if parsefunc then
		ret = parsefunc(tempCfg)
	end
	local file = io.open(targetpath..".lua","w")
	file:write("local "..tabname.."=")
	if ret then
		WriteTableToFile(ret,file)
	else
		WriteTableToFile(tempCfg,file)
	end
	file:write("return "..tabname)
	file:close()
end

function ParseAllCSVFile(filename, targetpath)
	local data,attrname,attrtype = ParseCSVFile(filename)
	for i=1, #data do
		local tabname = data[i][2]
		print("parse ["..tabname.."] begin...")
		ParseCSVFileToLuaTable(tabname,targetpath)
		print("parse ["..tabname.."] end...")
	end
end
local cmd = {...}
local filename = cmd[1] or "readme.csv"
local targetpath = cmd[2] or "Config/"
ParseAllCSVFile(filename, targetpath)