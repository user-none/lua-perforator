local perforator = require("perforator")

local p = perforator()

local function func_d()
    for i=1,1000000 do
    	a = 7*44
    end
end

local function func_c(f, v)
    f(v)
end

local function func_b(v)
    local a

    v = v + 1

    if v == 2 then
    	func_c(function(v) local q = v end, v)
    elseif v == 3 then
        func_d()
    elseif v == 5 then
    	return
    end

    for i=1,1000000000 do
    --for i=1,1000000 do
    	a = 7*44
    end

    func_b(v)
end

local function func_a()
    func_b(0)
end

p:start()
func_a()
p:stop()

print("")
print(p:gen_csv())

print("")
print(p:gen_dot())
print("")
print(p:gen_total_time())
