local isEnabled = CreateConVar(
    "gm_sqlerr_cl_enabled", 0,
    FCVAR_ARCHIVE + FCVAR_REPLICATED,
    "Enable SQL error reporting on clients"
)

if SERVER then
    isEnabled = CreateConVar(
        "gm_sqlerr_sv_enabled", 0,
        FCVAR_ARCHIVE + FCVAR_PROTECTED,
        "Enable SQL error reporting on the server"
    )
end

_G._SQLErr_Originals = {}
local originals = _G._SQLErr_Originals

local function wrap( name )
    local original = sql[name]
    originals[name] = originals[name] or original

    sql[name] = function( query, ... )
        local result = original( query, ... )
        if result == false then
            local err = sql.LastError()
            if err ~= "" then
                local msg = "SQL Error: " .. err
                print( query )
                ErrorNoHaltWithStack( msg )
            end
        end

        return result
    end
end

local function unwrap( name )
    sql[name] = originals[name]
end

local function wrapAll()
    wrap( "Query" )
    wrap( "QueryRow" )
    wrap( "QueryValue" )
end

local function unwrapAll()
    unwrap( "Query" )
    unwrap( "QueryRow" )
    unwrap( "QueryValue" )
end

hook.Add( "OnGamemodeLoaded", "GM_SqlErr_Init", function()
    if isEnabled:GetBool() then
        wrapAll()
    end
end )

local cvarName = SERVER and "gm_sqlerr_sv_enabled" or "gm_sqlerr_cl_enabled"
cvars.AddChangeCallback( cvarName, function( _, _, new )
    if new == "1" then
        wrapAll()
    else
        unwrapAll()
    end
end, "GM_SqlErr_Callback" )
