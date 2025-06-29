-- Draws the GPS location and the direction to the waypoint coordinates


vector2D = vector2D or {}

local function sign(number)
    return number > 0 and 1 or (number == 0 and 0 or -1)
end

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
	local _, adjRot = math.modf(rot + 1, 1)
	local tau = math.pi * 2
	local x = math.sin(adjRot * tau)
	local y = math.cos(adjRot * tau)
	return vector2D.normalize(vector2D.new(x, y))
end

function onTick()
	gpsX = input.getNumber(1)
	gpsY = input.getNumber(2)
	gps = vector2D.new(gpsX, gpsY)
	
	rotation = input.getNumber(3)
	
	waypointX = input.getNumber(4)
	waypointY = input.getNumber(5)
	waypoint = vector2D.new(waypointX, waypointY)
end

--TODO: actually draw compass and not just direction to waypoint
local function drawCompass()
	local dirToWaypoint = vector2D.direction(waypoint, gps)
	local selfDirection = vector2D.rotationToDirection(rotation)
	local angle = vector2D.signedAngle(selfDirection, dirToWaypoint)
	if math.abs(angle) < 45 then
		return "| O |"
	elseif angle > 45 then
		return "| O >"
	else
		return "< O |"
	end
end

function onDraw()
	local w = screen.getWidth()
	local h = screen.getHeight()
	screen.setColor(0, 255, 0)

	local dirToWaypoint = vector2D.direction(waypoint, gps)
	local selfDirection = vector2D.rotationToDirection(rotation)
	local angle = vector2D.signedAngle(selfDirection, dirToWaypoint)
	local text = string.format("X: %.f\nY: %.f\n%.f, %s", gpsX, gpsY, angle, drawCompass())
	screen.drawTextBox(2, 2, w, h, text)
end