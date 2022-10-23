-- Lib of JustBenDev
-- V:0.3
print([[
 ____                 _      _ _      
|  _ \               | |    (_) |    
| |_) | ___ _ __  ___| |     _| |__  
|  _ < / _ \ '_ \/ __| |    | | '_ \ 
| |_) |  __/ | | \__ \ |____| | |_) |
|____/ \___|_| |_|___/______|_|_.__/  V:0.4
]])
Bens = {}

if SERVER then
	util.AddNetworkString("BensLib")

	local META = FindMetaTable("Player")
	function META:BPrint(...)
		net.Start("BensLib")
		net.WriteUInt(1,4)
		net.WriteTable({...})
		net.Send(self)
	end
	
	function META:BNotify(Txt,IType,Duration)
		print(Txt,IType,Duration)
		net.Start("BensLib")
		net.WriteUInt(2,4)
		net.WriteString(Txt)
		net.WriteUInt(IType,8)
		net.WriteUInt(Duration,8)
		net.Send(self)
	end
end

Bens.util = {}
Bens.util.IsValidSteamID64 = function(SteamID)
	if !isstring(SteamID) then return false end 	-- Type Check
	if SteamID:len() != 17 then return false end	-- Len Check
	return true
end

function Bens.Round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

-- Current Color mode
Bens.Color 			= {}
Bens.Color.White 	= Color(255,255,255) 		-- rgb(255,255,255)
Bens.Color.Black 	= Color(0,0,0) 				-- rgb(0,0,0)

Bens.Color.Green	= Color(45, 205, 115) 		-- rgb(45, 205, 115)
Bens.Color.Red		= Color(230, 75, 60) 		-- rgb(230, 75, 60)
Bens.Color.Orange	= Color(255,200,0)			-- rgb(255,200,0)
Bens.Color.Blue	= Color(3,169,244)			-- rgb(3,169,244)
-----------------------------------------------------------------------

Bens.Func = {}
Bens.Derma = {}
Bens.Net = {}

Bens.Net.ReadTable = function ()
	local DLen = net.ReadUInt(32)
	local Buffer = net.ReadData(DLen)
	Buffer = util.Decompress(Buffer)
	return util.JSONToTable(Buffer)
end

Bens.Net.WriteTable = function (TBL)
	local Buffer = util.TableToJSON(TBL or {})
	Buffer = util.Compress(Buffer)
	net.WriteUInt(#Buffer,32)
	net.WriteData(Buffer,#Buffer)
end

Bens.Func.Darker = function(COLOR,VAL)
	return Color(COLOR["r"]-VAL,COLOR["g"]-VAL,COLOR["b"]-VAL,COLOR["a"])
end

Bens.Func.LerpColor = function(Fraction, From, To)
	local r = math.ceil(Lerp(Fraction,From["r"],To["r"]))
	local g = math.ceil(Lerp(Fraction,From["g"],To["g"]))
	local b = math.ceil(Lerp(Fraction,From["b"],To["b"]))
	local a = math.ceil(Lerp(Fraction,From["a"],To["a"]))
	return Color(r,g,b,a)
end

Bens.Func.SameColor = function(CA, CB)
	if
		CA.r == CB.r and
		CA.g == CB.g and
		CA.b == CB.b and
		CA.a == CB.a
	then
		return true
	end
	return false
end

Bens.Func.Rainbox = function ()
	local Rainbox 	= {}
	Rainbox.state 	= 0
	Rainbox.a 		= 255
	Rainbox.r 		= 255
	Rainbox.g 		= 0
	Rainbox.b 		= 0
	Rainbox.func = function()
		local self = Rainbox
		if self.state == 0 then
			self.g = self.g + 1
			if self.g == 255 then
				self.state = 1
			end
		end
		if self.state == 1 then
			self.r = self.r - 1
			if self.r == 0 then
				self.state = 2
			end
		end
		if self.state == 2 then
			self.b = self.b + 1
			if self.b == 255 then
				self.state = 3
			end
		end
		if self.state == 3 then
			self.g = self.g - 1
			if self.g == 0 then
				self.state = 4
			end
		end
		if self.state == 4 then
			self.r = self.r + 1
			if self.r == 255 then
				self.state = 5
			end
		end
		if self.state == 5 then
			self.b = self.b - 1
			if self.b == 0 then
				self.state = 0
			end
		end
		return Color(self.r,self.g,self.b,self.a)
	end
	return Rainbox.func
end


if CLIENT then
	net.Receive( "BensLib", function( len )
		local cmd = net.ReadUInt(4)
		if cmd == 1 then
			chat.AddText(unpack(net.ReadTable()))
		elseif cmd == 2 then
			notification.AddLegacy(net.ReadString(),net.ReadUInt(8),net.ReadUInt(8))
		end
	end)

	Bens.Ratio 		= ScrW() / 1920

	local blur = Material("pp/blurscreen")
	function Bens.Derma.DrawBlur(panel, amount)
		local x, y = panel:LocalToScreen(0, 0)
		local scrW, scrH = ScrW(), ScrH()
		surface.SetDrawColor(255, 255, 255)
		surface.SetMaterial(blur)
		for i = 1, 3 do
			blur:SetFloat("$blur", (i / 3) * (amount or 6))
			blur:Recompute()
			render.UpdateScreenEffectTexture()
			surface.DrawTexturedRect(x * -1, y * -1, scrW, scrH)
		end
	end
	Bens.Derma.Btn = function(PARENT,TXT,FONT,DOCK,SIZE,ALIGN,TCOLOR)
		local L = vgui.Create("DButton", PARENT)
		L:SetTextColor(Bens.Color.White)
		if TCOLOR != nil then L:SetTextColor(TCOLOR) end
		if DOCK then L:Dock(DOCK) end
		if FONT then
			L:SetFont(FONT)
		else
			L:SetFont("Rajdhani-Thin-Big")
		end
		if ALIGN != nil then
			L:SetContentAlignment(ALIGN)
		end
		L:SetText(TXT)
		if SIZE == nil then
			L:SizeToContents()
		else
			L:SetSize(SIZE,SIZE)
		end
		return L
	end
	Bens.Derma.Img = function(PARENT,IMG,DOCK,SIZE,ICOLOR)
		local L = vgui.Create("DImage", PARENT)
		if DOCK then L:Dock(DOCK) end
		if SIZE == nil then
			L:SizeToContents()
		else
			L:SetSize(SIZE,SIZE)
		end
		if isstring(IMG) then
			L:SetImage(IMG)
		else 
			L:SetMaterial(IMG)
		end
		if ICOLOR != nil then
			L:SetImageColor(ICOLOR)
		end
		return L
	end
	Bens.Derma.BtnImg = function(PARENT,IMG,DOCK,SIZE)
		local L = vgui.Create("DImageButton", PARENT)
		if DOCK then L:Dock(DOCK) end
		if SIZE == nil then
			L:SizeToContents()
		else
			L:SetSize(SIZE,SIZE)
		end
		if isstring(IMG) then
			L:SetImage(IMG)
		else 
			print(IMG)
			L:SetMaterial(IMG)
		end
		return L
	end
	Bens.Derma.FLabel = function(PARENT,TXT,FONT,DOCK,SIZE,ALIGN,TCOLOR)
		local L = vgui.Create("DLabel", PARENT)
		L:SetTextColor(Bens.Color.White)
		if TCOLOR != nil then L:SetTextColor(TCOLOR) end
		if DOCK then L:Dock(DOCK) end
		if FONT then
			L:SetFont(FONT)
		else
			L:SetFont("Rajdhani-Thin-Big")
		end
		if ALIGN != nil then
			L:SetContentAlignment(ALIGN)
		end
		L:SetText(TXT)
		if SIZE == nil then
			L:SizeToContents()
		else
			L:SetSize(SIZE,SIZE)
		end
		return L
	end
	Bens.Derma.Underline = function(s,w,h,COLOR,ALIGN)
		surface.SetFont(s:GetFont())
		local linew,lineh = surface.GetTextSize(s:GetText())
		if ALIGN == 5 then
			draw.RoundedBox(0, w/2-linew/2, s:GetTall()/2+lineh/2-10, linew, 4, COLOR)
		elseif ALIGN == 4 then
			draw.RoundedBox(0, 0, s:GetTall()/2+lineh/2-10, linew, 4, COLOR)
		end
	end
	Bens.Derma.Container = function(PARENT,DOCK,SIZE)
		local C = vgui.Create("Panel", PARENT)
		if DOCK then C:Dock(DOCK) end
		C:SetSize(SIZE,SIZE)
		C:InvalidateParent(true)
		return C
	end

	Bens.Func.Money = function(MONEY)
		local buffer = ""
		local C = 0
		MONEYTBL = string.Explode("",tostring(MONEY))
		-- for i=1,#MONEYTBL do
		for i=#MONEYTBL,1,-1 do
			buffer = buffer..MONEYTBL[i]
			C = C + 1
			if C == 3 then
				buffer = buffer.." "
				C = 0
			end
		end
		local newbuffer = ""
		for i=#buffer,1,-1 do
			newbuffer = newbuffer..buffer[i]
		end
		return newbuffer
	end
end

if SERVER then
	Bens.ResourceDir = function (PATH,RECURSIVE)
		local files, directories = file.Find(PATH.."*", "THIRDPARTY")
		if files == nil then return end
		for k, v in pairs(files) do
			print("[JustBenDev Ressource Loader] : Resource "..PATH..v.." added.")
			resource.AddFile(PATH..v);
		end
	end
end

// Shared
Bens.LuaLoadDir = function (PATH,LuaState,RECURSIVE,Execute)
	if Execute == nil then Execute = true end
	local files, directories = file.Find(PATH.."*", "LUA")
	if files == nil then return end
	for k, v in pairs(files) do		
		print(PATH..v)
		if LuaState == "CL" then
			if SERVER then
				AddCSLuaFile(PATH..v)
			else
				print("[JustBenDev Lua Loader] : Lua "..PATH..v.." added.")
				if Execute then include(PATH..v) end
			end
		elseif LuaState == "SH" then
			if SERVER then
				AddCSLuaFile(PATH..v)
			end
			print("[JustBenDev Lua Loader] : Lua "..PATH..v.." added.")
			if Execute then include(PATH..v) end
		elseif LuaState == "SV" and SERVER then
			print("[JustBenDev Lua Loader] : Lua "..PATH..v.." added.")
			if Execute then include(PATH..v) end
		end
	end
end

Bens.Func.PlayerInside = function (Ent)
	local MinV , MaxV = Ent:GetModelBounds()
	local Bigest = MaxV[1]

	if MaxV[2] > Bigest then
		Bigest = MaxV[2]
	end
	if MaxV[3] > Bigest then
		Bigest = MaxV[3]
	end

	for k,v in pairs(ents.FindInSphere( Ent:GetPos(), Bigest )) do
		if v:IsPlayer() then
			return true
		end
	end

	return false
end

hook.Run("jbd:Loader")


-- local DebugFrame = vgui.Create("DFrame")
-- DebugFrame:SetSize(350,350)
-- DebugFrame:Center()
-- DebugFrame:MakePopup()
-- DebugFrame.NewSlider = function(KEY)
-- 	local S = vgui.Create("DNumSlider",DebugFrame)
-- 	S:Dock(TOP)
-- 	S:SetWide(DebugFrame:GetWide())
-- 	S:SetMin(-180)
-- 	S:SetMax(180)
	
-- 	S.OnValueChanged = function(s,val)
-- 		icon.Debug[KEY] = val
-- 		icon:SetCamPos(eyepos-Vector(icon.Debug["a"],icon.Debug["b"],icon.Debug["c"]))
-- 		icon:SetLookAt(eyepos-Vector(icon.Debug["d"],icon.Debug["e"],icon.Debug["f"]))
-- 	end
-- end