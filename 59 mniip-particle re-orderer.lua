local math_floor = math.floor
local sim_partCreate = sim.partCreate
local sim_partKill = sim.partKill
local sim_partProperty = sim.partProperty
local sim_parts = sim.parts

local FIELD_TYPE = sim.FIELD_TYPE
local FIELD_LIFE = sim.FIELD_LIFE
local FIELD_CTYPE = sim.FIELD_CTYPE
local FIELD_X = sim.FIELD_X
local FIELD_Y = sim.FIELD_Y
local FIELD_VX = sim.FIELD_VX
local FIELD_VY = sim.FIELD_VY
local FIELD_TEMP = sim.FIELD_TEMP
local FIELD_PAVG0 = sim.FIELD_PAVG0
local FIELD_PAVG1 = sim.FIELD_PAVG1
local FIELD_FLAGS = sim.FIELD_FLAGS
local FIELD_TMP = sim.FIELD_TMP
local FIELD_TMP2 = sim.FIELD_TMP2
local FIELD_DCOLOUR = sim.FIELD_DCOLOUR

local function copy_particle(id)
	if FIELD_PAVG0 then
		return {
				[0] = id,
				sim_partProperty(id, FIELD_TYPE),
				sim_partProperty(id, FIELD_LIFE),
				sim_partProperty(id, FIELD_CTYPE),
				sim_partProperty(id, FIELD_X),
				sim_partProperty(id, FIELD_Y),
				sim_partProperty(id, FIELD_VX),
				sim_partProperty(id, FIELD_VY),
				sim_partProperty(id, FIELD_TEMP),
				sim_partProperty(id, FIELD_PAVG0),
				sim_partProperty(id, FIELD_PAVG1),
				sim_partProperty(id, FIELD_FLAGS),
				sim_partProperty(id, FIELD_TMP),
				sim_partProperty(id, FIELD_TMP2),
				sim_partProperty(id, FIELD_DCOLOUR)
			}
	else
		return {
				[0] = id,
				sim_partProperty(id, FIELD_TYPE),
				sim_partProperty(id, FIELD_LIFE),
				sim_partProperty(id, FIELD_CTYPE),
				sim_partProperty(id, FIELD_X),
				sim_partProperty(id, FIELD_Y),
				sim_partProperty(id, FIELD_VX),
				sim_partProperty(id, FIELD_VY),
				sim_partProperty(id, FIELD_TEMP),
				sim_partProperty(id, FIELD_FLAGS),
				sim_partProperty(id, FIELD_TMP),
				sim_partProperty(id, FIELD_TMP2),
				sim_partProperty(id, FIELD_DCOLOUR)
			}
	end
end

local function paste_particle(id, data)
	sim_partCreate(id, data[4], data[5], 1)
	sim_partProperty(id, FIELD_TYPE, data[1])
	sim_partProperty(id, FIELD_LIFE, data[2])
	sim_partProperty(id, FIELD_CTYPE, data[3])
	sim_partProperty(id, FIELD_X, data[4])
	sim_partProperty(id, FIELD_Y, data[5])
	sim_partProperty(id, FIELD_VX, data[6])
	sim_partProperty(id, FIELD_VY, data[7])
	sim_partProperty(id, FIELD_TEMP, data[8])
	if FIELD_PAVG0 then
		sim_partProperty(id, FIELD_PAVG0, data[9])
		sim_partProperty(id, FIELD_PAVG1, data[10])
		sim_partProperty(id, FIELD_FLAGS, data[11])
		sim_partProperty(id, FIELD_TMP, data[12])
		sim_partProperty(id, FIELD_TMP2, data[13])
		sim_partProperty(id, FIELD_DCOLOUR, data[14])
	else
		sim_partProperty(id, FIELD_FLAGS, data[9])
		sim_partProperty(id, FIELD_TMP, data[10])
		sim_partProperty(id, FIELD_TMP2, data[11])
		sim_partProperty(id, FIELD_DCOLOUR, data[12])
	end
end

local function reorder_all()
	local parts = {}
	local num_parts = 0
	for id in sim_parts() do
		local data = copy_particle(id)
		num_parts = num_parts + 1
		parts[num_parts] = data
	end
	for i = 1, num_parts do
		sim_partKill(parts[i][0])
	end
	table.sort(parts, function(a, b)
			local ya = math_floor(a[5] + 0.5)
			local yb = math_floor(b[5] + 0.5)
			if ya == yb then
				local xa = math_floor(a[4] + 0.5)
				local xb = math_floor(b[4] + 0.5)
				if xa == xb then
					return a[0] < b[0]
				end
				return xa < xb
			end
			return ya < yb
		end)
	for i = 1, num_parts do
		paste_particle(i - 1, parts[i])
	end
end

local function key(char, code, mod, status)
	if char == 'r' and status == 1 and math_floor(mod / 256) % 2 == 1 then
		reorder_all()
		return false
	end
end

tpt.register_keypress(key)
