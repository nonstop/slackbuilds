-- 'Wicked' lua library, require it in .awesomerc.lua to create dynamic widgets
-- Author: Lucas `GGLucas` de Vries [lucasdevries@gmail.com]

-- Get package name
local P = {}
if _REQUIREDNAME == nil then
    wicked = P
else
    _G[_REQUIREDNAME] = P
end

-- Grab environment
local ipairs = ipairs
local pairs = pairs
local print = print
local type = type
local tonumber = tonumber
local tostring = tostring
local math = math
local table = table
local awful = awful
local awesome = awesome
local client = client
local tag = tag
local mouse = mouse
local os = os
local io = io
local string = string
local hooks = hooks

-- Init variables
local widgets = {}
local nextid = 1
local cpu_total = {}
local cpu_active = {}
local cpu_usage = {}
local Started = 0
local nets = {}
local outputCache = {}

-- Reset environment
setfenv(1, P)

-- Set up hook to clear widget cache
awful.hooks.timer.register(1, function () outputCache = {} end)

function register(widget, type, format, timer, field)
    -- Register a new widget into wicked
    if timer == nil then
        timer = 1
    end

    widgets[nextid] = {
        widget = widget,
        type = type,
        timer = timer,
        count = timer,
        format = format,
        field = field
    }

    -- Add timer
    local id = nextid

    if timer > 0 then
        awful.hooks.timer.register(timer, function () do_update(id) end, true)
    end
    
    -- Incement ID
    nextid = nextid+1
end

function format(format, widget, args)
    -- Format a string with the given arguments
    for var,val in pairs(args) do
        format = string.gsub(format, '$'..var, val)
    end

    return format
end

function splitbywhitespace(str)
    values = {}
    start = 1
    splitstart, splitend = string.find(str, ' ', start)
    
    while splitstart do
        m = string.sub(str, start, splitstart-1)
        if m:gsub(' ','') ~= '' then
            table.insert(values, m)
        end

        start = splitend+1
        splitstart, splitend = string.find(str, ' ', start)
    end

    m = string.sub(str, start)
    if m:gsub(' ','') ~= '' then
        table.insert(values, m)
    end

    return values
end

function widget_update(w)
    for i,p in pairs(widgets) do
        if p['widget'].name == w.name then
            do_update(i)
        end
    end
end

function do_update(id)
    -- Update a specific widget
    local info = widgets[id]
    local args = {}
    local func = nil

    if info['type']:lower() == 'mem' then
        if outputCache['mem'] == nil then
            outputCache['mem'] = get_mem()
        end

        args = outputCache['mem']
    end

    if info['type']:lower() == 'mpd' then
        if outputCache['mpd'] == nil then
            outputCache['mpd'] = get_mpd()
        end

        args = outputCache['mpd']
    end

    if info['type']:lower() == 'cpu' then
        if outputCache['cpu'] == nil then
            outputCache['cpu'] = get_cpu()
        end

        args = outputCache['cpu']
    end

    if info['type']:lower() == 'fs' then
        if outputCache['fs'] == nil then
            outputCache['fs'] = get_fs()
        end

        args = outputCache['fs']
    end

    if info['type']:lower() == 'net' then
        if outputCache['net'] == nil then
            outputCache['net'] = get_net(info)
        end

        args = outputCache['net']
    end

    if info['type']:lower() == 'swap' then
        if outputCache['swap'] == nil then
            outputCache['swap'] = get_swap()
        end

        args = outputCache['swap']
    end

    if info['type']:lower() == 'date' then
        if info['format'] ~= nil then
            args = {info['format']}
        end
        func = get_time
    end

    if type(info['format']) == 'function' then
        func = info['format']
    end

    if type(func) == 'function' then
        output = func(info['widget'], args)
    else
        output = format(info['format'], info['widget'], args)
    end

    if output ~= nil then
        if info['field'] == nil then
            info['widget'].text = output
        else
            if info['widget'].plot_data_add ~= nil then
                info['widget']:plot_data_add(info['field'],tonumber(output))
            elseif info['widget'].bar_data_add ~= nil then
                info['widget']:bar_data_add(info['field'],tonumber(output))
            end
        end
    end
end

function get_cpu()
    -- Calculate CPU usage for all available CPUs / cores and return the
    -- usage

    -- Perform a new measurmenet
    ---- Get /proc/stat
    local cpu_lines = {}
    local cpu_usage_file = io.open('/proc/stat')
    for line in cpu_usage_file:lines() do
        if string.sub(line, 1, 3) == 'cpu' then
            table.insert(cpu_lines, splitbywhitespace(line))
        end
    end
    cpu_usage_file:close()

    ---- Ensure tables are initialized correctly
    while #cpu_total < #cpu_lines do
        table.insert(cpu_total, 0)
    end
    while #cpu_active < #cpu_lines do
        table.insert(cpu_active, 0)
    end
    while #cpu_usage < #cpu_lines do
        table.insert(cpu_usage, 0)
    end

    ---- Setup tables
    total_new     = {}
    active_new    = {}
    diff_total    = {}
    diff_active   = {}

    for i,v in ipairs(cpu_lines) do
        ---- Calculate totals
        total_new[i]    = v[2] + v[3] + v[4] + v[5]
        active_new[i]   = v[2] + v[3] + v[4]
    
        ---- Calculate percentage
        diff_total[i]   = total_new[i]  - cpu_total[i]
        diff_active[i]  = active_new[i] - cpu_active[i]
        cpu_usage[i]    = math.floor(diff_active[i] / diff_total[i] * 100)

        ---- Store totals
        cpu_total[i]    = total_new[i]
        cpu_active[i]   = active_new[i]
    end
    return cpu_usage
end

function get_mpd()
    -- Return MPD currently playing song
    ---- Get data from mpc
    local nowplaying_file = io.popen('mpc')
    local nowplaying = nowplaying_file:read()

    if nowplaying == nil then
        return {''}
    end

    nowplaying_file:close()
    
    nowplaying = nowplaying:gsub('&', '&amp;')

    -- Return it
    return {nowplaying}
end

function get_mem()
    -- Return MEM usage values
    local f = io.open('/proc/meminfo')

    ---- Get data
    for line in f:lines() do
        line = splitbywhitespace(line)

        if line[1] == 'MemTotal:' then
            mem_total = math.floor(line[2]/1024)
        elseif line[1] == 'MemFree:' then
            free = math.floor(line[2]/1024)
        elseif line[1] == 'Buffers:' then
            buffers = math.floor(line[2]/1024)
        elseif line[1] == 'Cached:' then
            cached = math.floor(line[2]/1024)
        end
    end
    f:close()

    ---- Calculate percentage
    mem_free=free+buffers+cached
    mem_inuse=mem_total-mem_free
    mem_usepercent = math.floor(mem_inuse/mem_total*100)

    return {mem_usepercent, mem_inuse, mem_total, mem_free}
end

function get_swap()
    -- Return SWAP usage values
    local f = io.open('/proc/meminfo')

    ---- Get data
    for line in f:lines() do
        line = splitbywhitespace(line)

        if line[1] == 'SwapTotal:' then
            swap_total = math.floor(line[2]/1024)
        elseif line[1] == 'SwapFree:' then
            free = math.floor(line[2]/1024)
        elseif line[1] == 'SwapCached:' then
            cached = math.floor(line[2]/1024)
        end
    end
    f:close()

    ---- Calculate percentage
    swap_free=free+cached
    swap_inuse=swap_total-swap_free
    swap_usepercent = math.floor(swap_inuse/swap_total*100)

    return {swap_usepercent, swap_inuse, swap_total, swap_free}
end

function get_time(widget, args)
    -- Return a `date` processed format
    -- Get format
    if args[1] == nil then
        return os.date()
    else
        return os.date(args[1])
    end
end

function get_fs()
    local f = io.popen('df -h')
    local args = {}

    for line in f:lines() do
        vars = splitbywhitespace(line)
        
        if vars[1] ~= 'Filesystem' then
            args['{'..vars[6]..' size}'] = vars[2]
            args['{'..vars[6]..' used}'] = vars[3]
            args['{'..vars[6]..' avail}'] = vars[4]
            args['{'..vars[6]..' usep}'] = vars[5]:gsub('%%','')
        end
    end

    f:close()
    return args
end

function get_net(info)
    local f = io.open('/proc/net/dev')
    args = {}

    for line in f:lines() do
        line = splitbywhitespace(line)

        local p = line[1]:find(':')
        if p ~= nil then
            name = line[1]:sub(0,p-1)
            line[1] = line[1]:sub(p+1)

            if tonumber(line[1]) == nil then
                line[1] = line[2]
                line[9] = line[10]
            end

            args['{'..name..' rx}'] = bytes_to_string(line[1])
            args['{'..name..' tx}'] = bytes_to_string(line[9])

            args['{'..name..' rx_b}'] = math.floor(line[1]*10)/10
            args['{'..name..' tx_b}'] = math.floor(line[9]*10)/10
            
            args['{'..name..' rx_kb}'] = math.floor(line[1]/1024*10)/10
            args['{'..name..' tx_kb}'] = math.floor(line[9]/1024*10)/10

            args['{'..name..' rx_mb}'] = math.floor(line[1]/1024/1024*10)/10
            args['{'..name..' tx_mb}'] = math.floor(line[9]/1024/1024*10)/10

            args['{'..name..' rx_gb}'] = math.floor(line[1]/1024/1024/1024*10)/10
            args['{'..name..' tx_gb}'] = math.floor(line[9]/1024/1024/1024*10)/10

            if nets[name] == nil then 
                nets[name] = {}
                args['{'..name..' down}'] = 'n/a'
                args['{'..name..' up}'] = 'n/a'
                
                args['{'..name..' down_b}'] = 0
                args['{'..name..' up_b}'] = 0

                args['{'..name..' down_kb}'] = 0
                args['{'..name..' up_kb}'] = 0

                args['{'..name..' down_mb}'] = 0
                args['{'..name..' up_mb}'] = 0

                args['{'..name..' down_gb}'] = 0
                args['{'..name..' up_gb}'] = 0
            else
                down = (line[1]-nets[name][1])/info['timer']
                up = (line[9]-nets[name][2])/info['timer']

                args['{'..name..' down}'] = bytes_to_string(down)
                args['{'..name..' up}'] = bytes_to_string(up)

                args['{'..name..' down_b}'] = math.floor(down*10)/10
                args['{'..name..' up_b}'] = math.floor(up*10)/10

                args['{'..name..' down_kb}'] = math.floor(down/1024*10)/10
                args['{'..name..' up_kb}'] = math.floor(up/1024*10)/10

                args['{'..name..' down_mb}'] = math.floor(down/1024/1024*10)/10
                args['{'..name..' up_mb}'] = math.floor(up/1024/1024*10)/10

                args['{'..name..' down_gb}'] = math.floor(down/1024/1024/1024*10)/10
                args['{'..name..' up_gb}'] = math.floor(up/1024/1024/1024*10)/10
            end

            nets[name][1] = line[1]
            nets[name][2] = line[9]
        end
    end

    f:close()
    return args
end

function bytes_to_string(bytes, sec)
    if bytes == nil or tonumber(bytes) == nil then
        return ''
    end

    bytes = tonumber(bytes)

    signs = {}
    signs[1] = 'b'
    signs[2] = 'KiB'
    signs[3] = 'MiB'
    signs[4] = 'GiB'
    signs[5] = 'TiB'

    sign = 1

    while bytes/1024 > 1 and signs[sign+1] ~= nil do
        bytes = bytes/1024
        sign = sign+1
    end

    bytes = bytes*10
    bytes = math.floor(bytes)/10

    if sec then
        return tostring(bytes)..signs[sign]
    else
        return tostring(bytes)..signs[sign]..'ps'
    end
end

-- Build function list
P.register = register
P.update = widget_update
return P
