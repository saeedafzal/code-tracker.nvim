local h = dofile("tests/helpers.lua")

h.install_fakes()
h.set_time(10001)
h.load_plugin()

h.change("lua")
h.change("lua")
h.change("typescript")
h.change("python")
h.change("python")
h.change("python")
h.set_time(20001)
h.fire_timer()

local published = h.published_buckets()
assert(#published == 1, "expected one published bucket")

local activity = published[1].activity
assert(activity.lua.count == 2)
assert(activity.typescript.count == 1)
assert(activity.python.count == 3)

h.success("tracks activity by filetype")
