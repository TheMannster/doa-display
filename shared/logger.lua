-- Shared console logger / banner for tm-streetside.
-- Provides a multiscript-style startup banner and tagged log helpers for both
-- client and server contexts.

TM = TM or {}
TM.Log = {}

local RESOURCE = GetCurrentResourceName()
local VERSION  = GetResourceMetadata(RESOURCE, 'version', 0) or '?.?.?'

local function p(s)
    print(s .. '^7')
end

function TM.Log.banner()
    p('')
    p('^5====================================================')
    p('^5  TM-STREETSIDE ^7v' .. VERSION)
    p('^5  Modular vehicle system')
    p('^5====================================================')
end

function TM.Log.module(name, enabled, info)
    local label = name .. string.rep(' ', math.max(1, 12 - #name))
    if enabled then
        p(('  [^2OK^7] ^2%s^9 - ^7%s'):format(label, info or 'active'))
    else
        p(('  [^1--^7] ^9%s - disabled'):format(label))
    end
end

function TM.Log.footer(active, total)
    p('^5----------------------------------------------------')
    p(('^2  Started ^7(^2%d^7/^2%d^7 modules active)'):format(active, total))
    p('^5====================================================')
    p('')
end

function TM.Log.info(tag, msg)
    p(('^5[TM:%s]^7 %s'):format(tag, msg))
end

function TM.Log.warn(tag, msg)
    p(('^3[TM:%s WARN]^7 %s'):format(tag, msg))
end

function TM.Log.err(tag, msg)
    p(('^1[TM:%s ERR]^7 %s'):format(tag, msg))
end
