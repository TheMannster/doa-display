Config = {}

-------------------------------------------------------------------------------
-- Modules
-------------------------------------------------------------------------------
-- Toggle entire feature modules on/off here. The server console will print
-- which modules are active when the resource starts.
Config.Modules = {
    display  = true,   -- Static display vehicles around a dealership / showroom
    citycars = true,   -- Random ambient parked cars rotating around the city
}

-------------------------------------------------------------------------------
-- Display module
-------------------------------------------------------------------------------
-- Color IDs reference: https://wiki.rage.mp/index.php?title=Vehicle_Colors
Config.Display = {
    -- How close (in meters) a player must be before the display vehicles spawn
    -- in. Keeps things lightweight when nobody is near the shop.
    SpawnDistance = 80.0,

    -- One entry per display car.
    --   model  : spawn name of the vehicle (e.g. 'adder', 'zentorno')
    --   coords : vec4(x, y, z, heading) - heading is the direction the car faces
    --   color  : {primary, secondary} GTA color IDs - omit for default
    Vehicles = {
        {
            model  = 'm2',
            coords = vec4(-302.83, -1371.72, 31.44, 82.74),
        },
        {
            model  = 'tempesta',
            coords = vec4(-302.66, -1347.25, 32.6, 87.69),
            color  = {27, 27},     -- metallic red
        },
    },
}

-------------------------------------------------------------------------------
-- CityCars module
-------------------------------------------------------------------------------
-- Spawns a configurable amount of each model around the city in random parking
-- spots. Every RotationInterval the cars are deleted and respawned at new
-- random unused locations.
--
-- Requirements: OneSync (or OneSync infinity) must be enabled on the server,
-- since vehicles are spawned server-side so every player sees them at the
-- same place.
Config.CityCars = {
    -- Time between location rotations (in milliseconds).
    RotationInterval = 10 * 60 * 1000,   -- 10 minutes

    -- If true the license plate is overwritten with 8 blank spaces so the
    -- plate appears empty (simulates a stolen / hot car with no plate).
    BlankPlates = true,

    -- A car is "released" from our system if a player has sat in any seat
    -- OR the vehicle has moved further than this many meters from its
    -- spawn point. Released cars are NOT despawned - they're left in the
    -- world for the player / AdvancedParking to take ownership of. The
    -- freed slot will be refilled on the NEXT rotation tick (not instantly).
    StolenDistance = 10.0,

    -- Models to spawn around the city.
    --   model     : vehicle spawn name
    --   maxActive : how many of this model exist in the city at any given time
    Vehicles = {
        { model = 'sultan', maxActive = 3 },
        { model = 'futo',   maxActive = 2 },
        { model = 'comet2', maxActive = 1 },
    },

    -- All possible parking locations the cars may pick from.
    -- The total number of locations should be GREATER than the sum of all
    -- maxActive values, otherwise rotations will pick the same spots every
    -- round.
    -- vec4(x, y, z, heading)
    Locations = {
        vec4(215.30,  -810.10, 30.30, 250.0),
        vec4(-56.40, -1096.50, 26.40, 30.0),
        vec4(127.40, -1031.20, 29.30, 70.0),
        vec4(-1037.50, -2737.30, 20.20, 240.0),
        vec4(294.80,  -566.20, 43.20, 340.0),
        vec4(-714.80,  -154.30, 37.40, 30.0),
        vec4(-1156.50, -1518.00, 10.60, 30.0),
        vec4(-490.20,  -707.40, 33.20, 180.0),
        -- add as many as you like; only a random subset will be used per round
    },
}
