local strings = import("strings")

local micro = import("micro")
local config = import("micro/config")
local buffer = import("micro/buffer")
local util = import("micro/util")

function luatable(m)
    t = {}
    if m then
        for key, val in m() do
            t[key] = val
        end
    end
    return t
end

function updatemessages(buf)
    buf:ClearMessages("bm")
    local locs = buf.Settings["bm.locs"]
    for i, loc in locs() do
        local loc1 = buffer.Loc(loc.X+1, loc.Y)
        local msg = buffer.NewMessage("bm", "underscored characters are bookmarked", loc, loc1, buffer.MTInfo)
        buf:AddMessage(msg)
    end
end

function clearbookmarks(bp)
    local buf = bp.Buf
    buf.Settings["bm.locs"] = {}
    updatemessages(buf)
end

function togglebookmark(bp)
    local buf, curloc = bp.Buf, -bp.Cursor.Loc
    local locs = luatable(buf.Settings["bm.locs"])
    for i, loc in ipairs(locs) do
        if loc == curloc then
            table.remove(locs, i)
            goto continue
        elseif loc:GreaterThan(curloc) then
            table.insert(locs, i, curloc)
            goto continue
        end
    end
    table.insert(locs, curloc)
    ::continue::
    buf.Settings["bm.locs"] = locs
    updatemessages(buf)
end

function prevbookmark(bp)
    local locs, i = bp.Buf.Settings["bm.locs"], bp.Buf.Settings["bm.i"]
    if not locs or #locs == 0 then
        micro.InfoBar():Error("no bookmark defined")
        return
    end
    i = (not i or i <= 1 or i > #locs) and #locs or i-1
    bp.Buf.Settings["bm.i"] = i
    bp:GotoLoc(locs[i])
end

function nextbookmark(bp)
    local locs, i = bp.Buf.Settings["bm.locs"], bp.Buf.Settings["bm.i"]
    if not locs or #locs == 0 then
        micro.InfoBar():Error("no bookmark defined")
        return
    end
    i = (not i or i >= #locs) and 1 or i+1
    bp.Buf.Settings["bm.i"] = i
    bp:GotoLoc(locs[i])
end

function onBeforeTextEvent(sbuf, t)
    local locs = sbuf.Settings["bm.locs"]
    if not locs then return true end
    local update = false
    for i, loc in locs() do
        for j = #t.Deltas, 1, -1 do -- deltas must be processed in reverse order
            delta = -t.Deltas[j]
            if t.EventType <= 0 then -- delete or replace
                if loc:GreaterEqual(delta.End) then
                    local dx, dy = 0, delta.Start.Y-delta.End.Y
                    if loc.Y == delta.End.Y then dx = delta.Start.X-delta.End.X end
                    loc = buffer.Loc(loc.X+dx, loc.Y+dy)
                elseif loc:GreaterEqual(delta.Start) then
                    loc = delta.Start
                end
            end
            if t.EventType >= 0 and loc:GreaterEqual(delta.Start) then -- insert or replace
                local str = util.String(delta.Text)
                local dx, dy = 0, strings.Count(str, "\n")
                if loc.Y == delta.Start.Y then
                    local i = strings.LastIndex(str, "\n")
                    if i == -1 then
                        dx = util.CharacterCountInString(str)
                    else -- "i+2" instead of "i+1" since Lua is 1-based while Go is 0-based
                        dx = util.CharacterCountInString(str:sub(i+2, -1))
                    end
                end
                loc = buffer.Loc(loc.X+dx, loc.Y+dy)
            end
            if loc ~= locs[i] then
                locs[i] = loc
                update = true
            end
        end
    end
    if update then
        updatemessages(sbuf)
    end
    return true
end

function preinit()
    config.RegisterGlobalOption("bookmark2", "key", "F2")
end

function init()
    local key = config.GetGlobalOption("bookmark2.key")
    config.TryBindKey(key, "lua:bookmark2.nextbookmark", false)
    config.TryBindKey("Shift-"..key, "lua:bookmark2.prevbookmark", false)
    config.TryBindKey("Ctrl-"..key, "lua:bookmark2.togglebookmark", false)
    config.TryBindKey("Ctrl-Shift-"..key, "lua:bookmark2.clearbookmarks", false)
end
