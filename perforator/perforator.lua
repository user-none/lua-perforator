-- Copyright (c) 2016 John Schember <john@nachtimwald.com>
--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

local os = require("os")
local debug = require("debug")

local M = {}
local M_mt = { __metatable = {}, __index = M }

local function timer_start(timer)
    timer.running = true
    timer.last = os.clock()
end

local function timer_stop(timer)
    timer.running = false
    timer.time = timer.time + os.clock() - timer.last
    timer.last = 0
end

function M:new()
    if self ~= M then
        return nil, "First argument must be self"
    end
    local o = setmetatable({}, M_mt)

    -- Number of times a function has been called
    o._count = {}
    -- Time a function takes to run.
    -- value: {
    --   running: Function running
    --   time: Total time function took to run
    --   last: Last time the function started running
    -- }
    o._time = {}
    -- function name and table of functions it calls.
    o._calls = {}
    -- List of parent functions above the current function.
    o._parent = {}

    return o
end
setmetatable(M, { __call = M.new })

function M:start()
    -- Wrapper function used to pass the object
    -- into the debug hook function.
    local function wrapper(e)
        M.trace(self, e)
    end
    debug.sethook(wrapper, "cr")
end

function M:stop()
    local info
    local name

    debug.sethook()

    -- Remove the stop call from what we're tracking.
    info = debug.getinfo(1, "nSlt")
    name = info.source .. ":" .. info.linedefined .. ":" .. (info.name or "")
    self._count[name] = nil
    self._time[name] = nil
    self._calls[name] = nil

    self._parent = {}
    for _,v in ipairs(self._time) do
        v.running = false
        v.last = 0
    end
end

function M:trace(e)
    local info
    local parent
    local name

    e = e:lower()

    info = debug.getinfo(3, "nSlt")

    if info.what:lower() ~= "lua" then
        return
    end
    if e ~= "call" and e ~= "tail call" and e ~= "return" then
        return
    end
    -- "call" and "tail call" should have set the call as parent so there
    -- should always be a parent. If there isn't then we're returning to
    -- functions that were called before the profiler was started.
    --
    -- This can cause "holes" because there could be a few returns then
    -- the next call will start recording.
    if e == "return" and #self._parent == 0 then
        return
    end

    -- We use all data to generate the name because it's valid for function's
    -- passed as an argument to have the same function name between functions.
    -- Also multiple files can have the same function names if they're local.
    -- It's also possible for a function not to have a name.
    name = info.source .. ":" .. info.linedefined .. ":" .. (info.name or "")

    if e == "call" or e == "tail call" then
        -- increment the count
        self._count[name] = (self._count[name] or 0) + 1

        -- If this function has never been seen setup the time table.
        if not self._time[name] then
            self._time[name] = { running = false, time = 0, last = 0 }
        end

        -- If there is a parent we need to record a bit of info.
        if #self._parent ~= 0 then
            parent = self._parent[#self._parent]

            -- The parent called this function so record that this is
            -- a call path.
            if not self._calls[parent] then
                self._calls[parent] = {}
            end
            self._calls[parent][name] = true

            -- We need to stop the parent's time because we've now gone into
            -- a different function. We're trying to record the execution time
            -- of the function not the funciton plus all functions it calls.
            --
            -- It's possible the function is calling itself but we still want
            -- to stop the timer. We'll start it again later.
            timer_stop(self._time[parent])
        end

        -- This function is now the parent so if it calls something we know
        -- what called it, even if it called itself.
        self._parent[#self._parent+1] = name

        timer_start(self._time[name])
    elseif e == "return" then
        -- Stop the timer because the function has finished running.
        timer_stop(self._time[name])

        -- Remove the parent from the table because it's this function.
        table.remove(self._parent, #self._parent)

        -- Restart the function's parent's timer.
        if #self._parent ~= 0 then
            parent = self._parent[#self._parent]
            timer_start(self._time[parent])
        end
    end
end

function M:gen_csv()
    local stats = {}
    local line
    local p

    stats[#stats+1] = "id, file, line, name, count, average time, total time"

    for k,v in pairs(self._count) do
        line = {}

        line[1] = k

        line[2] = k:gsub(":.*$", "")
        p = k:gsub("^[^:]*:", "")
        line[3] = p:gsub(":.*$", "")
        line[4] = p:gsub("^[^:]*:", "")

        line[5] = v

        p = self._time[k]
        if p ~= nil then
            line[6] = string.format("%f", p.time/v) 
            line[7] = string.format("%f", p.time) 
        end

        stats[#stats+1] = table.concat(line, ", ")
    end

    return table.concat(stats, "\n")
end

function M:gen_dot()
    local dot = {}

    dot[#dot+1] = "digraph graphname {"

    for k,v in pairs(self._calls) do
        for n,_ in pairs(v) do
            dot[#dot+1] = "\"" .. k .. "\" -> \"" .. n .. "\";"
        end
    end

    dot[#dot+1] = "}"

    return table.concat(dot, "\n")
end

function M:gen_total_time()
    local total = 0

    for _,v in pairs(self._time) do
        total = total + v.time
    end

    return total
end

return M
