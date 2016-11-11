lua-perforator
============

Pure Lua runtime profiling module.

Provides:

* Function call tracing.
* Can generate a Dot file of application flow.
* Function call timing.
* Function call count.
* Generates CSV with statistics.
* Can be started and stopped so only specific
  places can be profiled instead of the entire script.

Note: This will only trace Lua and will not trace C function calls.

Trace ids
---------

Lua allows function names to be the same within different modules. To
account for this an id is generated to differentiate them.

Format:

    @filename : funtion line number : function name
    @test_r.lua:15:func_b

Example
-------

See test/perf-test.lua

### Output
------

#### Stats: gen_csv()

    id, file, line, name, count, average time, total time
    @test_r.lua:15:func_b, @test_r.lua, 15, func_b, 5, 6.721294, 33.606469
    @test_r.lua:5:func_d, @test_r.lua, 5, func_d, 1, 0.019124, 0.019124
    @test_r.lua:36:func_a, @test_r.lua, 36, func_a, 1, 0.000020, 0.000020
    @test_r.lua:21:f, @test_r.lua, 21, f, 1, 0.000007, 0.000007
    @test_r.lua:11:func_c, @test_r.lua, 11, func_c, 1, 0.000011, 0.000011

#### Dot: gen_dot()

    digraph graphname {
        "@test_r.lua:36:func_a" -> "@test_r.lua:15:func_b";
        "@test_r.lua:15:func_b" -> "@test_r.lua:15:func_b";
        "@test_r.lua:15:func_b" -> "@test_r.lua:11:func_c";
        "@test_r.lua:15:func_b" -> "@test_r.lua:5:func_d";
        "@test_r.lua:11:func_c" -> "@test_r.lua:21:f";
    }

#### Total time: gen_total_time()

    33.625631
