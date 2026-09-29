local h = dofile("tests/helpers.lua")

h.install_fakes()
h.set_time(10001)
h.load_plugin()

h.change("lua")
h.change("lua")
h.set_time(20001)
h.change("typescript")

local published = h.published_buckets()
assert(#published == 1, "expected one published bucket")

local bucket = published[1]
assert(bucket.started_at == 10000)
assert(bucket.activity.lua.count == 2)
assert(bucket.activity.typescript == nil)

h.success("event rollover publishes previous bucket")
