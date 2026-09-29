local M = {}

function M.load_plugin()
    require("code-tracker")
end

local now_ms = 0
local timer_callback = nil
local published = {}
local real_print = print

function M.install_fakes()
    -- Fake wall-clock time.
    vim.uv.gettimeofday = function()
        local seconds = math.floor(now_ms / 1000)
        local microseconds = (now_ms % 1000) * 1000
        return seconds, microseconds
    end

    -- Make scheduled timer callbacks run directly in tests.
    vim.schedule_wrap = function(callback)
        return callback
    end

    vim.uv.new_timer = function()
        local closing = false
        return {
            start = function(_, _, _, callback)
                timer_callback = callback
            end,
            stop = function() end,
            close = function()
                closing = true
            end,
            is_closing = function()
                return closing
            end
        }
    end

    -- Capture JSON publish_bucket() prints.
    _G.print = function(value)
        local ok, decoded = pcall(vim.json.decode, value)
        if ok and type(decoded) == "table" and decoded.started_at ~= nil and type(decoded.activity) == "table" then
            table.insert(published, decoded)
        end
    end
end

function M.set_time(value)
    now_ms = value
end

-- Deliberately invoke text change events to indicate buffer has been edited.
function M.change(filetype)
    vim.bo.filetype = filetype
    vim.api.nvim_exec_autocmds("TextChanged", {
        buffer = 0
    })
end

function M.fire_timer()
    assert(timer_callback ~= nil, "timer was never started")
    timer_callback()
end

function M.success(message)
    real_print("PASS - " .. message)
end

-- TODO: Will need to be updated when API publishing is done.
function M.published_buckets()
    return published
end

return M
