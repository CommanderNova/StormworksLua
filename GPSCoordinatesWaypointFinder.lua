
local defaultMarkers = {
	[90]  = "E",
	[180] = "S",
	[270] = "W",
	[360] = "N",
}

local waypointMarker = "v"
local bearingIcon = "-"
local leftIcon = "<"
local rightIcon = ">"

local function sign(number)
	return number > 0 and 1 or (number == 0 and 0 or -1)
end

local function clone(maintable)
	tablecopy = {}
	for k, v in pairs(maintable) do
		tablecopy[k] = v
	end
	return tablecopy
end

local function wrapBearing(number)
	return number % 360
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function signedAngleToBearing(angle)
	local bearing = angle
	if angle <= 0 then
		bearing = angle + 360
	end
	return bearing
end

vector2D = vector2D or {}

function vector2D.new(x, y)
	return {x, y}
end

function vector2D.magnitude(vec)
	return math.sqrt(vec[1] ^ 2 + vec[2] ^ 2)
end

function vector2D.normalize(vec)
	local magnitude = vector2D.magnitude(vec)
	if magnitude == 0 then
		return vector2D.new(0, 0)
	end
	
	return vector2D.new(vec[1] / magnitude, vec[2] / magnitude)
end

function vector2D.direction(vec1, vec2)
	local dir = vector2D.new(vec1[1] - vec2[1], vec1[2] - vec2[2])
	return vector2D.normalize(dir)
end

function vector2D.dot(vec1, vec2)
	return vec1[1] * vec2[1] + vec1[2] * vec2[2]
end

function vector2D.angle(vec1, vec2)
	local dot = vector2D.dot(vec1, vec2)
	local acos = math.acos(dot)
	local deg = math.deg(acos)
	return deg
end

function vector2D.signedAngle(vec1, vec2)
	local angle = vector2D.angle(vec1, vec2)
	local rotatedVec1 = vector2D.new(vec1[2], -vec1[1])
	local dot = vector2D.dot(rotatedVec1, vec2)
	local sign = sign(dot)
	return angle * sign
end

-- expects a rotation to north that is N=0, E=-0.25, S=(-)0.5, W=0.25 
function vector2D.rotationToDirection(rot)
	local _, adjRot = math.modf(rot + 1)
	local tau = math.pi * 2
	local x = math.sin(adjRot * tau)
	local y = math.cos(adjRot * tau)
	return vector2D.normalize(vector2D.new(x, y))
end

local function getCompassText()
	local dirToWaypoint = vector2D.direction(waypoint, gps)
	local dirToSelf = vector2D.rotationToDirection(-rotation)
	local dirToNorth = vector2D.new(0, 1)
	local angleNorthToSelf = vector2D.signedAngle(dirToNorth, dirToSelf)
	local angleNorthToWaypoint = vector2D.signedAngle(dirToNorth, dirToWaypoint)

	local bearing = signedAngleToBearing(angleNorthToSelf)
	local bearingWaypoint = signedAngleToBearing(angleNorthToWaypoint)
	
	local angleSelfToWaypoint = vector2D.signedAngle(dirToSelf, dirToWaypoint)
	local waypointOutOfCompass, waypointCompassDir
	if math.abs(angleSelfToWaypoint) >= maxBearing then
		waypointOutOfCompass = true
		waypointCompassDir = sign(angleSelfToWaypoint)
	else
		waypointOutOfCompass = false 
		waypointCompassDir = 0
	end

	local markers = clone(defaultMarkers)
	markers[bearingWaypoint] = waypointMarker

	local min = bearing - maxBearing
	local max = bearing + maxBearing
	local segmentArray = {}
	for i = 0, maxScreenWidth - 1, 1 do
		local percent = i / maxScreenWidth
		local segment = math.floor(lerp(min, max, percent))
		segmentArray[i + 1] = wrapBearing(segment)
	end

	local closestMarker = {}
	for i = 2, #segmentArray, 1 do
		local segment = segmentArray[i]
		local prevSegment = segmentArray[i - 1]

		local adjSegment = segment
		if segment - prevSegment < 0 then
			adjSegment = segment + 360
		end

		for markerBearing, marker in pairs(markers) do
			if prevSegment < markerBearing and adjSegment >= markerBearing then
				if closestMarker[markerBearing] == nil or closestMarker[markerBearing] ~= waypointMarker then
					closestMarker[i] = marker
				end
			end
		end
	end

	local text = ""
	for i = 1, #segmentArray, 1 do
		local icon = bearingIcon
		if waypointOutOfCompass and i < 3 and waypointCompassDir < 0 then
			icon = leftIcon
		elseif waypointOutOfCompass and i > #segmentArray-3 and waypointCompassDir > 0 then
			icon = rightIcon
		elseif closestMarker[i] ~= nil then
			icon = closestMarker[i]
		end
		text = text .. icon
	end

	return text
end

function onTick()
	gpsX = input.getNumber(1)
	gpsY = input.getNumber(2)
	gps = vector2D.new(gpsX, gpsY)
	
	rotation = input.getNumber(3)
	
	waypointX = input.getNumber(4)
	waypointY = input.getNumber(5)
	waypoint = vector2D.new(waypointX, waypointY)

	maxScreenWidth = math.ceil(property.getNumber("MaxScreenWidth"))
	maxBearing = property.getNumber("MaxBearing")
end

function onDraw()
	local w = screen.getWidth()
	local h = screen.getHeight()
	screen.setColor(0, 255, 0)

	local compassText = getCompassText()
	local text = string.format("X: %.f\nY: %.f\n%s", gpsX, gpsY, compassText)
	screen.drawTextBox(2, 2, w, h, text)
end
