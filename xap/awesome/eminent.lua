-----------------------------------------------------------------------------------
-- Eminent:
--  A lua library for dynamic tagging in awesome
--
-- Author: Lucas `GGLucas` de Vries <lucasdevries@gmail.com>
-----------------------------------------------------------------------------------

--Get package name
local P = {}
    if _REQUIREDNAME == nil then
    eminent = P
else
    _G[_REQUIREDNAME] = P
end

-- Grab environment
local ipairs = ipairs
local pairs = pairs
local print = print
local type = type
local tonumber = tonumber
local math = math
local table = table
local awful = awful
local awesome = awesome
local hooks = hooks
local client = client
local screen = screen
local tag = tag
local mouse = mouse
local os = os
local io = io
local string = string
local tostring = tostring

-- Reset env
setfenv(1, P)

-- Init vars
local tags = {}
local tag_names = {}
local settings = {
    default_mwfact = 0.618033988769,
    start_tagn = 5,
    dialog_font = '-*-terminus-*-r-normal-*-*-120-*-*-*-*-iso8859-*',
    dialog_fg_normal = '#888888',
    dialog_fg_focus = '#ffffff',
    dialog_bg_normal = '#222222',
    dialog_bg_focus = '#285577'
}

awful.hooks.user.create('newtag')

-- Get current screen
function get_screen()
    local sel = client.focus
    local s
    if sel then
        s = sel.screen
    else
        s = mouse.screen
    end
    return s
end

-- Create a new tag on current screen
function newtag(s, nb)
    if nb == nil then
        nb = 1
    end

    if s == nil then
        s = get_screen()
    end

    if tags[s] == nil then
        tags[s] = {}
        tag_names[s] = {}
    end

    p = {}

    for x= 1,nb do
        local i = table.maxn(tags[s])+1
        local n = (tag_names[s][i] or tostring(i))

        tags[s][i] = tag({name = n})
       
        local t = tags[s][i]
        t.screen = s
        t.mwfact = settings['default_mwfact']

        table.insert(p, t)
        awful.hooks.user.call('newtag', i)
    end

    if nb == 1 then
        return p[1]
    else
        return p
    end
end

function tag_getnext(s)
    if s == nil then
        s = get_screen()
    end
    
    local p = get_occupied(s)
    local curtag = awful.tag.selected()

    local t = 0

    -- Get tag #
    if isoccupied(s, curtag) then
        for x in pairs(p) do
            if curtag == p[x] then 
                t = x
            end
        end
    end

    local lasto = 1
    local o = 0

    for x in pairs(tags[s]) do
        if curtag == tags[s][x] then 
            o = x
        end

        if isoccupied(s, tags[s][x]) then
            lasto = x
        end
    end

    -- Now: t is # in non-empty, o is # in all
    
    if o == table.maxn(tags[s]) then
        -- We're the last tag, create a new one
        if t == 0 then
            -- We're empty, go to first
            return tags[s][1]
        else
            -- We're occupied, create new
            return newtag()
        end
    else
        if t == 0 then
            -- We're empty, check if we're last
            if o > lasto then
                -- We're also later than the last non-empty
                -- Wrap to first
                return tags[s][1]
            else
                -- Nevermind, get the next
                return tags[s][o+1]
            end
        else
            -- Return next tag
            return tags[s][o+1]
        end
    end

end

function tag_getprev(s)
    if s == nil then
        s = get_screen()
    end
    
    local p = get_occupied(s)
    local curtag = awful.tag.selected()

    local t = 0

    -- Get tag #
    if isoccupied(s, curtag) then
        for x in pairs(p) do
            if curtag == p[x] then 
                t = x
            end
        end
    end

    local lasto = 1
    local o = 0

    for x in pairs(tags[s]) do
        if curtag == tags[s][x] then 
            o = x
        end

        if isoccupied(s, tags[s][x]) then
            lasto = x
        end
    end

    -- Now: t is # in non-empty, o is # in all
    
    if o == 1 then
        -- We're the very first tag, wrap around
        return p[ table.maxn(p) ]
    else
        -- We're not first, just go prev
        return tags[s][o-1]
    end

end

function tag_next(s)
    awful.tag.viewonly(tag_getnext(s))
end

function tag_prev(s)
    awful.tag.viewonly(tag_getprev(s))
end

function tag_getn(n, s, abs)
    if s == nil then
        s = get_screen()
    end

    if abs == nil then
        abs = false
    end

    -- If abs=true, then 2 will be tag 2, no
    -- matter if it's hidden or not, otherwise,
    -- the numbers correspond to the position in 
    -- the taglist.

    if abs then
        return tags[s][n]
    else
        return get_occupied(s)[n]
    end
end

function tag_goto(n, s, abs)
    awful.tag.viewonly(tag_getn(n, s, abs))
end

function tag_toggle(n, s, abs)
    local t = tag_getn(n, s, abs)
    t.selected = not t.selected
end

function isoccupied(s, t)
    if not t or not t:clients() then
        return false 
    end

    for c in pairs(t:clients()) do
        return true
    end

    return false
end

function get_occupied(s)
    if s == nil then
        s = get_screen()
    end

    local p = {}

    for t in pairs(tags[s]) do
        t = tags[s][t]
        if isoccupied(s, t) then
            table.insert(p, t)
        end
    end

    return p
end

function tag_new(s)
    if s == nil then
        s = get_screen()
    end

    local o = 1

    for t in pairs(tags[s]) do
        if isoccupied(s, tags[s][t]) then
            o = t
        end
    end

    -- Check if last tag = empty
    if tags[s][o+1] ~= nil then
        -- It's empty, go to it
        return tags[s][o+1]
    else
        -- Create a new one
        return newtag(s)
    end
end

function tag_name(i, s, name)
    if s == nil then
        s = 1
    end

    if tag_names[s] == nil then
        tag_names[s] = {}
    end

    if tags[s] == nil then
        tags[s] = {}
    end

    tag_names[s][i] = name

    if tags[s][i] ~= nil then
        tags[s][i].name = name
    end
end

function name_dialog(s, i)
    if s == nil then
        s = get_screen()
    end

    if i == nil then
        i = awful.tag.selected()
    end

    local pi = 1

    for t in pairs(tags[s]) do
        if tags[s][t] == i then
            pi = t
            break
        end
    end

    code = 'ex=`echo "Input Name..." | dmenu -fn \''..settings['dialog_font']..'\' -nb \''..settings['dialog_bg_normal']..'\' -nf \''..settings['dialog_fg_normal']..'\' -sb \''..settings['dialog_bg_focus']..'\' -sf \''..settings['dialog_fg_focus']..'\'` && echo "eminent.tag.name('..s..', '..pi..', \'$ex\')" | awesome-client'

    awful.spawn(code)
end

-- Create first tag
for s = 1, screen.count() do
    tags[s] = {}
    tag_names[s] = {}
    
    t = newtag(s, settings['start_tagn'])  

    tags[s][1].selected = true
end

-- Build function list
P.get_screen = get_screen
P.get_occupied = get_occupied
P.newclient = newclient
P.name_dialog = name_dialog
P.newtag = newtag
P.tag = {
    name = tag_name;
    new = tag_new;
    next = tag_next;
    prev = tag_prev;
    getnext = tag_getnext;
    getprev = tag_getprev;
    goto = tag_goto;
    getn = tag_getn;
    isoccupied = isoccupied;
}

P.tags = tags
P.settings = settings
P.tag_names = tag_names

return P
