-- Shared console logger / banner for DOA-Display.
-- Provides a tm-script-multiscript style startup banner and tagged log helpers
-- for both client and server contexts.

DOA = DOA or {}
DOA.Log = {}

local RESOURCE = GetCurrentResourceName()
local VERSION  = GetResourceMetadata(RESOURCE, 'version', 0) or '?.?.?'

local function p(s)
    print(s .. '^7')
end

function DOA.Log.banner()
    p('')
    p('^5====================================================')
    p('^5  DOA-DISPLAY ^7v' .. VERSION)
    p('^5  Modular vehicle system')
    p('^5====================================================')
end

function DOA.Log.module(name, enabled, info)
    local label = name .. string.rep(' ', math.max(1, 12 - #name))
    if enabled then
        p(('  [^2OK^7] ^2%s^9 - ^7%s'):format(label, info or 'active'))
    else
        p(('  [^1--^7] ^9%s - disabled'):format(label))
    end
end

function DOA.Log.footer(active, total)
    p('^5----------------------------------------------------')
    p(('^2  Started ^7(^2%d^7/^2%d^7 modules active)'):format(active, total))
    p('^5====================================================')
    p('')
end

function DOA.Log.info(tag, msg)
    p(('^5[DOA:%s]^7 %s'):format(tag, msg))
end

function DOA.Log.warn(tag, msg)
    p(('^3[DOA:%s WARN]^7 %s'):format(tag, msg))
end

function DOA.Log.err(tag, msg)
    p(('^1[DOA:%s ERR]^7 %s'):format(tag, msg))
end
