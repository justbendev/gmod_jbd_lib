-- Lib made by JustBen.Dev
print([[
  ___ ___  ___  _    
 | _ ) __|/ _ \| |   
 | _ \__ \ (_) | |__ 
 |___/___/\__\_\____| LOADED v1.1
]])

-- require( "mysqloo" )
BSQL = {}

local function Reconnect(AddonName,Init) -- Only used for MySQL
	if Init == true or BSQL[AddonName].DB:status() != mysqloo.DATABASE_CONNECTED then
		-- table.insert(BSQL[AddonName].PendingQuery,{["Query"]=Query,["Args"]={...}})
		-- Immediately try reconnecting
		BSQL[AddonName].DB = mysqloo.connect( BSQL[AddonName].Config.host, BSQL[AddonName].Config.username, BSQL[AddonName].Config.password, BSQL[AddonName].Config.dbname , BSQL[AddonName].Config.port or 3306 )
		BSQL[AddonName].DB.onConnectionFailed = function( DB, Err )
			print("[BSQL] - [MySQL] - [ERROR] - ["..AddonName.."] : Cannot connect to database ! \nError : "..Err.."\nRetrying in 5 secs...\n")
			timer.Simple(5, function()
				Reconnect(AddonName)
			end)
		end
		BSQL[AddonName].DB.onConnected = function( DB )
			print("[BSQL] - [MySQL] - [SUCESS] - ["..AddonName.."] : Connected to Database !")
			if #BSQL[AddonName].PendingQuery > 0 then
				for k,v in pairs(BSQL[AddonName].PendingQuery) do
					-- FIX THIS ASAP
				end
			end
		end
		BSQL[AddonName].DB:connect()
		-- return
	end
end

local function DB_Exist(AddonName)
	if BSQL[AddonName] == nil then
		return false
	else
		return true
	end
end

function BSQL.IsMySQL(AddonName)
	if DB_Exist(AddonName) then
		return BSQL[AddonName].IsMySQL
	end
end

function BSQL.tableExists(AddonName,tbl,TrueF,FalseF)
	if !DB_Exist(AddonName) then
		print("[BSQL] - [tableExist] - [WARNING] - ["..AddonName.."] : function called with unregistered AddonName !")
		return
	end

    if !BSQL.IsMySQL(AddonName) then
		local exists = sql.TableExists(tbl)
		if exists and isfunction(TrueF) then 
			TrueF()
		elseif !exists and isfunction(FalseF) then
			FalseF()
		end
	else
		local Query = BSQL[AddonName].DB:query("SHOW TABLES LIKE '"..tbl.."'") -- Should never be used with user input ....
		function Query:onSuccess(DATA)
			if #DATA > 0 and isfunction(TrueF) then
				TrueF()
			elseif #DATA < 1 and isfunction(FalseF) then
				FalseF()
			end
		end
		Query:start()
	end
end

function BSQL.PQuery(AddonName,SQLcmd,FailFunc,SucessFunc,...)
	local args = {...}

	if !DB_Exist(AddonName) then
		print("[BSQL] - [PQuery] - [WARNING] - ["..AddonName.."] : Prepared Statement Query called with unregistered AddonName !")
		return
	end

	if BSQL.IsMySQL(AddonName) then
		Reconnect(AddonName)
		local PQuery = BSQL[AddonName].DB:prepare(SQLcmd)
		for k,v in pairs(args) do -- WARNING PLEASE VERIFY K VALUE FOR START IT SHOULD BE ONE
			if (isstring(v) and ( v == "" or string.lower(v) == "null" )) then
				PQuery:setNull(k)
			elseif isbool(v) then
				PQuery:setBoolean(k,v)
			elseif isstring(v) then
				PQuery:setString(k,v)
			elseif isnumber(v) then
				PQuery:setNumber(k,v)
			else
				PQuery:abort()
				print("[BSQL] - [MySQL] - [WARNING] - ["..AddonName.."] : Prepared Query have been aborted due to an invalid parameter !\nOnly theses types can be send through a prepared statement : String , Bool , Number(Float too) ,NULL/nil\nThe query was : "..SQLcmd.."\n The invalid parameter is index : "..k)
			end
		end

		function PQuery:onError(Query,Err)
			print("[BSQL] - [MySQL] - [ERROR] - ["..AddonName.."] : Prepared Query failed !\nPrepared Query : "..SQLcmd.."\nError : "..Query.."\n")
			if isfunction(FailFunc) then FailFunc(Err,Query) end
		end
		if isfunction(SucessFunc) then 
			function PQuery:onSuccess(Data)
				SucessFunc(Data)
			end
		end
		PQuery:start()
	else -- SQLite
		local Payload = SQLcmd
		

		for k,v in pairs(args) do -- WARNING PLEASE VERIFY K VALUE FOR START IT SHOULD BE ONE
			Payload = string.gsub(Payload, "?", '%%s',1)
			if v == nil or (isstring(v) and (v == "" or string.lower(v) == "null")) then
				Payload = string.format(Payload,"NULL")
			elseif isbool(v) then
				Payload = string.format(Payload,tostring(v))
			elseif isstring(v) then
				Payload = string.format(Payload,tostring(sql.SQLStr(v)))
			elseif isnumber(v) then
				Payload = string.format(Payload,tostring(v))
			else
				print("[BSQL] - [MySQL] - [WARNING] - ["..AddonName.."] : Prepared Query have been aborted due to an invalid parameter !\nOnly theses types can be send through a prepared statement : String , Bool , Number(Float too) ,NULL/nil\nThe query was : "..SQLcmd.."\n The invalid parameter is index : "..k)
				return false
			end
		end
		
		local SQLite_Result = sql.Query(Payload)

		if SQLite_Result == false then 
			local Err = sql.LastError()
			print("[BSQL] - [SQLite] - [ERROR] - ["..AddonName.."] : Query failed !\nQuery : "..Payload.."\nError : "..Err.."\n")
			if isfunction(FailFunc) then FailFunc(Err, PAYLOAD) end
			return false
		else
			if isfunction(SucessFunc) then SucessFunc(SQLite_Result) end
			return true
		end
	end 
end

function BSQL.Query(AddonName,SQLcmd,FailFunc,SucessFunc) -- This should only be used when no User Input is used in the SQL Command ! No Sanitization occur here !
	if !DB_Exist(AddonName) then
		print("[BSQL] - [Query] - [WARNING] - ["..AddonName.."] : Query called with unregistered AddonName !")
		return
	end
	
	if BSQL.IsMySQL(AddonName) then
		Reconnect(AddonName)
		local Query = BSQL[AddonName].DB:query(SQLcmd)
		function Query:onError(Query,Err)
			print("[BSQL] - [MySQL] - [ERROR] - ["..AddonName.."] : Query failed !\nQuery : "..Query.."\nError : "..Err.."\n")
			if isfunction(FailFunc) then FailFunc(Err, Query ) end
		end
		if isfunction(SucessFunc) then 
			function Query:onSuccess( Data )
				SucessFunc(Data)
			end
		end
		Query:start()
	else -- SQLite
		local SQLite_Result = sql.Query(SQLcmd)
		if SQLite_Result == false then
			local Err = sql.LastError()
			print("[BSQL] - [SQLite] - [ERROR] - ["..AddonName.."] : Query failed !\nQuery : "..SQLcmd.."\nError : "..Err.."\n")
			if isfunction(FailFunc) then FailFunc(Err, SQLcmd) end
		else
			if isfunction(SucessFunc) then SucessFunc(SQLite_Result) end
		end
	end
end

function BSQL.Register(AddonName,Config)
	if DB_Exist(AddonName) then
		print("[BSQL] : "..AddonName.." is already registred !")
		return
	else
		BSQL[AddonName] = {}
	end

	BSQL[AddonName].IsMySQL = false
	
	if Config.UseMysql == true then
		BSQL[AddonName].Config = Config
		BSQL[AddonName].IsMySQL = true
		BSQL[AddonName].PendingQuery = {}
		Reconnect(AddonName,true)
	end
end