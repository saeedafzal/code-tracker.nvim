local group = vim.api.nvim_create_augroup("CodeTracker", { clear = true })

-- The interval of how long a bucket records for: 10s.
local INTERVAL_MS = 10000

-- Helper to get current time as milliseconds since epoch.
local function get_time_ms()
    local sec, usec = vim.uv.gettimeofday()
    return (sec * 1000) + math.floor(usec / 1000)
end

-- Can check if 'now' is part of current 10s interval.
local function bucket_start(now)
    return now - (now % INTERVAL_MS)
end

-- Current reference of bucket to be tracked.
local bucket = {
    started_at = bucket_start(get_time_ms()),
    activity = {}
}

-- Publishes the bucket if there is activity within.
-- TODO: Implement actual API publishing.
local function publish_bucket()
    if next(bucket.activity) == nil then
        return
    end
    print(vim.json.encode(bucket))
end

-- Publishes and rolls over bucket to the next 'INTERVAL_MS' interval.
local function rollover_bucket(now)
    local current_start = bucket_start(now)

    if current_start == bucket.started_at then
        return
    end

    publish_bucket()
    bucket = {
        started_at = bucket_start(current_start),
        activity = {}
    }
end

-- Timer to rollover idle buckets at the defined interval.
local timer = vim.uv.new_timer()
local now_ms = get_time_ms()
local delay = INTERVAL_MS - (now_ms % INTERVAL_MS)
timer:start(delay, INTERVAL_MS, vim.schedule_wrap(function()
    rollover_bucket(get_time_ms())
end))

local function shutdown()
end

-- Tracks buffer changes to add to activity counter per filetype on current bucket.
vim.api.nvim_create_autocmd({
    "TextChanged",
    "TextChangedI",
    "TextChangedP"
}, {
    group = group,
    callback = function()
        local now_ms = get_time_ms()
        rollover_bucket(now_ms)

        local filetype = vim.bo.filetype

        if bucket.activity[filetype] == nil then
            bucket.activity[filetype] = {
                count = 0,
                first_activity_at = now_ms,
                last_activity_at = now_ms
            }
        end

        bucket.activity[filetype].count = bucket.activity[filetype].count + 1
        bucket.activity[filetype].last_activity_at = now_ms
    end
})

-- Shutdown hook.
-- On editor close, stop the timer, publish current bucket if it has activity and close timer handle.
vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
        if timer and not timer:is_closing() then
            timer:stop()
        end

        publish_bucket()

        if timer and not timer:is_closing() then
            timer:close()
        end
    end
})
