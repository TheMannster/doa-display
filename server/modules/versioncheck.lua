if Config.VersionCheck and Config.VersionCheck.Enabled == false then return end

local REPO     = 'TheMannster/tm-streetside'
local RESOURCE = GetCurrentResourceName()
local LOCAL    = GetResourceMetadata(RESOURCE, 'version', 0) or '0.0.0'

local function parseVersion(str)
    str = tostring(str or ''):gsub('^[vV]', '')
    local parts = {}
    for chunk in str:gmatch('[^%.]+') do
        parts[#parts + 1] = tonumber(chunk) or 0
    end
    return parts
end

local function compareVersions(a, b)
    local pa, pb = parseVersion(a), parseVersion(b)
    local n = math.max(#pa, #pb)
    for i = 1, n do
        local av, bv = pa[i] or 0, pb[i] or 0
        if av < bv then return -1
        elseif av > bv then return 1 end
    end
    return 0
end

local function jsonString(body, key)
    local val = body:match('"' .. key .. '"%s*:%s*"(.-)"')
    if not val then return nil end
    return (val:gsub('\\r\\n', '\n'):gsub('\\n', '\n'):gsub('\\"', '"'):gsub('\\\\', '\\'))
end

local function printChangelog(body)
    if not body or body == '' then return end
    TM.Log.info('version', 'changelog:')
    for line in (body .. '\n'):gmatch('([^\n]*)\n') do
        if line ~= '' then
            print(('  ^7%s'):format(line))
        end
    end
end

CreateThread(function()
    Wait(3000)

    local url = ('https://api.github.com/repos/%s/releases/latest'):format(REPO)
    PerformHttpRequest(url, function(status, body, _headers)
        if status == 404 then
            TM.Log.info('version',
                ('no releases published yet on ^2%s^7 (running ^2v%s^7)'):format(REPO, LOCAL))
            return
        end

        if status ~= 200 or not body then
            TM.Log.warn('version',
                ('check failed (HTTP %s) - running ^2v%s^7'):format(tostring(status), LOCAL))
            return
        end

        local remoteTag = jsonString(body, 'tag_name')
        if not remoteTag then
            TM.Log.warn('version', 'could not parse tag_name from GitHub response')
            return
        end

        if compareVersions(LOCAL, remoteTag) >= 0 then
            TM.Log.info('version',
                ('up to date (^2v%s^7, latest ^2%s^7)'):format(LOCAL, remoteTag))
            return
        end

        TM.Log.warn('version',
            ('^1OUTDATED^7 - running ^3v%s^7, latest is ^2%s^7'):format(LOCAL, remoteTag))
        TM.Log.info('version',
            ('download: ^4https://github.com/%s/releases/latest^7'):format(REPO))
        printChangelog(jsonString(body, 'body'))
    end, 'GET', '', { ['User-Agent'] = 'tm-streetside-versioncheck' })
end)
