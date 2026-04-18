Config = {}

-- How close (in meters) a player must be before the display vehicles spawn in.
-- Keeps things lightweight when nobody is near the shop.
Config.SpawnDistance = 80.0

-- Color IDs reference: https://wiki.rage.mp/index.php?title=Vehicle_Colors
-- Set color to nil to let the game pick a random color.
Config.DisplayVehicles = {
    -- Copy/paste a block for each display car.
    -- model  : spawn name of the vehicle (e.g. 'adder', 'zentorno')
    -- coords : vector4(x, y, z, heading)  — use heading to face the car however you like
    -- color  : {primary, secondary} using GTA color IDs — set to nil for random
    {
        model  = 'm2',
        coords = vec4(-302.83, -1371.72, 31.44, 82.74),
    },
    {
        model  = 'tempesta',
        coords = vec4(-302.66, -1347.25, 32.6, 87.69),
        color  = {27, 27},     -- metallic red
    },
    -- {
    --     model  = 't20',
    --     coords = vector4(-325.39, -136.84, 39.01, 180.0),
    --     color  = {64, 64},  -- metallic blue
    -- },
}
