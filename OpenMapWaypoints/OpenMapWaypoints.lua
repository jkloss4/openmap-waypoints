--------------------------------------------------------------------------------
-- OpenMap Waypoints: OpenMap's pin Import (Pins, Import) also takes TomTom waypoints, as Wowhead and
-- guides give them:
--   /way #1429 41.5 65.8 Marshal Dughan     (a map ID)
--   /way Elwynn Forest 41.5 65.8 Note       (a zone's name, or the start of it)
--   /way 41.5 65.8 Note                     (the zone you're in)
-- one or more, on separate lines or run together. Pressing Add the pins turns them into OpenMap's own
-- code (OMPINS1:map,x,y,colour,note;...) just before OpenMap reads the box, so OpenMap adds them as
-- it does any code.
--------------------------------------------------------------------------------

local CODE = "OMPINS1:"         -- (OpenMap's code of pins: Map/Pins.lua)
local COLOR = 1                 -- (OpenMap's first colour: Gold)
local PREFER = {                -- (a name several maps share: the zone first, then a dungeon, ...)
	[Enum.UIMapType.Zone] = 1, [Enum.UIMapType.Dungeon] = 2, [Enum.UIMapType.Micro] = 3,
	[Enum.UIMapType.Continent] = 4,
}

local function Print(text, ...)
	print("|cffe6b85cOpenMap Waypoints:|r " .. text:format(...))
end

--------------------------------------------------------------------------------
-- Zone names -> map IDs (made once, the first time they're needed)
--------------------------------------------------------------------------------

local names                     -- lower-case name -> { id, rank }

local function Names()
	if names then return names end
	names = {}
	local function Add(info)
		if not (info and info.name and info.name ~= "") then return end
		local key, rank = info.name:lower(), PREFER[info.mapType] or 9
		if not names[key] or rank < names[key].rank then names[key] = { id = info.mapID, rank = rank } end
	end
	for _, root in ipairs({ 946, 947 }) do   -- (the Cosmic map, else Azeroth)
		Add(C_Map.GetMapInfo(root))
		for _, info in ipairs(C_Map.GetMapChildrenInfo(root, nil, true) or {}) do Add(info) end
	end
	return names
end

-- a zone from its name: the whole name, else the one zone whose name starts with it, else contains it
local function ZoneByName(text)
	local want = strtrim(text):lower()
	if want == "" then return end
	local all = Names()
	if all[want] then return all[want].id end
	for _, plain in ipairs({ false, true }) do
		local found, rank
		for name, m in pairs(all) do
			local at = name:find(want, 1, true)
			if at and (plain or at == 1) then
				if found and m.id ~= found and m.rank == rank then found = false break end   -- (more than one)
				if not found or m.rank < rank then found, rank = m.id, m.rank end
			end
		end
		if found then return found end
		if found == false then return end
	end
end

--------------------------------------------------------------------------------
-- /way lines -> OpenMap's code
--------------------------------------------------------------------------------

local function Number(token)
	token = token and token:gsub(",$", "")
	return tonumber(token)
end

local function Escape(note) return (note:gsub("[%%,;]", function(c) return ("%%%02X"):format(c:byte()) end)) end

-- one waypoint (what follows "/way"): map, x, y (0..1), note; or nil and why not
local function Parse(text)
	local tokens = {}
	for t in text:gmatch("%S+") do tokens[#tokens + 1] = t end
	-- the coordinates: the first two numbers in a row (what's before them names the zone)
	local at
	for i = 1, #tokens - 1 do
		if not tokens[i]:find("^#") and Number(tokens[i]) and Number(tokens[i + 1]) then at = i break end
	end
	if not at then return nil, "no coordinates" end
	local x, y = Number(tokens[at]), Number(tokens[at + 1])
	if x < 0 or x > 100 or y < 0 or y > 100 then return nil, "coordinates off the map" end
	local zone = strtrim(table.concat(tokens, " ", 1, at - 1))
	local note = strtrim(table.concat(tokens, " ", at + 2))
	local mapID
	if zone == "" then
		mapID = C_Map.GetBestMapForUnit("player")
		if not mapID then return nil, "no zone, and yours isn't known" end
	elseif zone:match("^#%d+$") then
		mapID = tonumber(zone:sub(2))
	else
		mapID = ZoneByName(zone)
		if not mapID then return nil, ("no single zone called \"%s\""):format(zone) end
	end
	-- (a retail map ID, say, isn't a map here)
	if not C_Map.GetMapInfo(mapID) then return nil, ("map #%d isn't on this client"):format(mapID) end
	return mapID, x / 100, y / 100, note
end

-- the box's text: as it is when it's already a code or has no /way in it, else OpenMap's code of the
-- waypoints; how many it took, and the lines it couldn't
local function Convert(text)
	if text:find(CODE, 1, true) or not text:lower():find("/way", 1, true) then return end
	local parts, skipped = {}, {}
	-- (each "/way" starts a waypoint, whether or not the lines were kept apart)
	for one in ("\n" .. text):gsub("/[Ww][Aa][Yy]%f[%s]", "\1"):gmatch("\1([^\1]*)") do
		local line = strtrim((one:gsub("[\r\n]+", " ")))
		if line ~= "" then
			local mapID, x, y, note = Parse(line)   -- (or nil, why not)
			if mapID then
				parts[#parts + 1] = ("%d,%.4f,%.4f,%d,%s"):format(mapID, x, y, COLOR, Escape(note))
			else
				skipped[#skipped + 1] = ("/way %s (%s)"):format(line, x)   -- (x: why)
			end
		end
	end
	return #parts > 0 and (CODE .. table.concat(parts, ";")) or nil, #parts, skipped
end

--------------------------------------------------------------------------------
-- OpenMap's Import box: made the first time it's opened (Map/Pins.lua's CodeBox), so watched for
--------------------------------------------------------------------------------

local function Hook(frame)
	local button, box = frame.import, frame.box
	if not (button and box) or button.OpenMapWaypoints then return end
	button.OpenMapWaypoints = true
	local original = button:GetScript("OnClick")
	button:SetScript("OnClick", function(self, ...)
		local code, n, skipped = Convert(box:GetText() or "")
		if skipped then
			for _, line in ipairs(skipped) do Print("skipped %s", line) end
			if code then
				Print("%d waypoint(s) turned into map pins.", n)
				box:SetText(code)
			end
		end
		return original(self, ...)
	end)
	-- (it says to paste a code: waypoints too)
	if frame.title then
		hooksecurefunc(frame, "Show", function()
			if not frame.text then frame.title:SetText("Paste a code of map pins, or /way waypoints, here (Ctrl-V), then Add the pins.") end
		end)
		if not frame.text then frame.title:SetText("Paste a code of map pins, or /way waypoints, here (Ctrl-V), then Add the pins.") end
	end
end

local ticker
ticker = C_Timer.NewTicker(0.5, function()
	local frame = _G.OpenMapPinsCode
	if frame then
		Hook(frame)
		ticker:Cancel()
	end
end)
