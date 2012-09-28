# vim:set ft= ts=4 sw=4 et fdm=marker:
use lib 'lib';
use Test::Nginx::Socket;

#worker_connections(1014);
#master_on();
#workers(2);
#log_level('warn');

repeat_each(5);

plan tests => repeat_each() * (blocks() * 2 + 1);

our $HtmlDir = html_dir;

#no_diff();
#no_long_string();
run_tests();

__DATA__

=== TEST 1: gmatch
--- config
    location /re {
        content_by_lua '
            for m in ngx.re.gmatch("hello, world", "[a-z]+") do
                if m then
                    ngx.say(m[0])
                else
                    ngx.say("not matched: ", m)
                end
            end
        ';
    }
--- request
    GET /re
--- response_body
hello
world



=== TEST 2: fail to match
--- config
    location /re {
        content_by_lua '
            local it = ngx.re.gmatch("hello, world", "[0-9]")
            local m = it()
            if m then ngx.say(m[0]) else ngx.say(m) end

            local m = it()
            if m then ngx.say(m[0]) else ngx.say(m) end

            local m = it()
            if m then ngx.say(m[0]) else ngx.say(m) end
        ';
    }
--- request
    GET /re
--- response_body
nil
nil
nil



=== TEST 3: match but iterate more times (not just match at the end)
--- config
    location /re {
        content_by_lua '
            local it = ngx.re.gmatch("hello, world!", "[a-z]+")
            local m = it()
            if m then ngx.say(m[0]) else ngx.say(m) end

            local m = it()
            if m then ngx.say(m[0]) else ngx.say(m) end

            local m = it()
            if m then ngx.say(m[0]) else ngx.say(m) end

            local m = it()
            if m then ngx.say(m[0]) else ngx.say(m) end
        ';
    }
--- request
    GET /re
--- response_body
hello
world
nil
nil



=== TEST 4: match but iterate more times (just matched at the end)
--- config
    location /re {
        content_by_lua '
            local it = ngx.re.gmatch("hello, world", "[a-z]+")
            local m = it()
            if m then ngx.say(m[0]) else ngx.say(m) end

            local m = it()
            if m then ngx.say(m[0]) else ngx.say(m) end

            local m = it()
            if m then ngx.say(m[0]) else ngx.say(m) end

            local m = it()
            if m then ngx.say(m[0]) else ngx.say(m) end
        ';
    }
--- request
    GET /re
--- response_body
hello
world
nil
nil



=== TEST 5: anchored match (failed)
--- config
    location /re {
        content_by_lua '
            it = ngx.re.gmatch("hello, 1234", "([0-9]+)", "a")
            ngx.say(it())
        ';
    }
--- request
    GET /re
--- response_body
nil



=== TEST 6: anchored match (succeeded)
--- config
    location /re {
        content_by_lua '
            local it = ngx.re.gmatch("12 hello 34", "[0-9]", "a")
            local m = it()
            ngx.say(m[0])
            m = it()
            ngx.say(m[0])
            ngx.say(it())
        ';
    }
--- request
    GET /re
--- response_body
1
2
nil



=== TEST 7: non-anchored gmatch (without regex cache)
--- config
    location /re {
        content_by_lua '
            local it = ngx.re.gmatch("12 hello 34", "[0-9]")
            local m = it()
            ngx.say(m and m[0])
            m = it()
            ngx.say(m and m[0])
            m = it()
            ngx.say(m and m[0])
            m = it()
            ngx.say(m and m[0])
            m = it()
            ngx.say(m and m[0])
        ';
    }
--- request
    GET /re
--- response_body
1
2
3
4
nil



=== TEST 8: non-anchored gmatch (with regex cache)
--- config
    location /re {
        content_by_lua '
            local it = ngx.re.gmatch("12 hello 34", "[0-9]", "o")
            local m = it()
            ngx.say(m and m[0])
            m = it()
            ngx.say(m and m[0])
            m = it()
            ngx.say(m and m[0])
            m = it()
            ngx.say(m and m[0])
            m = it()
            ngx.say(m and m[0])
        ';
    }
--- request
    GET /re
--- response_body
1
2
3
4
nil



=== TEST 9: anchored match (succeeded)
--- config
    location /re {
        content_by_lua '
            local it = ngx.re.gmatch("12 hello 34", "[0-9]", "a")
            local m = it()
            ngx.say(m[0])
            m = it()
            ngx.say(m[0])
            ngx.say(it())
        ';
    }
--- request
    GET /re
--- response_body
1
2
nil



=== TEST 10: anchored match (succeeded, set_by_lua)
--- config
    location /re {
        set_by_lua $res '
            local it = ngx.re.gmatch("12 hello 34", "[0-9]", "a")
            local m = it()
            return m[0]
        ';
        echo $res;
    }
--- request
    GET /re
--- response_body
1



=== TEST 11: gmatch (look-behind assertion)
--- config
    location /re {
        content_by_lua '
            for m in ngx.re.gmatch("{foobar}, {foobaz}", "(?<=foo)ba[rz]") do
                if m then
                    ngx.say(m[0])
                else
                    ngx.say("not matched: ", m)
                end
            end
        ';
    }
--- request
    GET /re
--- response_body
bar
baz



=== TEST 12: gmatch (look-behind assertion 2)
--- config
    location /re {
        content_by_lua '
            for m in ngx.re.gmatch("{foobarbaz}", "(?<=foo)bar|(?<=bar)baz") do
                if m then
                    ngx.say(m[0])
                else
                    ngx.say("not matched: ", m)
                end
            end
        ';
    }
--- request
    GET /re
--- response_body
bar
baz



=== TEST 13: with regex cache
--- config
    location /re {
        content_by_lua '
            local it = ngx.re.gmatch("hello, 1234", "([A-Z]+)", "io")
            local m = it()
            ngx.say(m and m[0])

            it = ngx.re.gmatch("1234, okay", "([A-Z]+)", "io")
            m = it()
            ngx.say(m and m[0])

            it = ngx.re.gmatch("hi, 1234", "([A-Z]+)", "o")
            m = it()
            ngx.say(m and m[0])
        ';
    }
--- request
    GET /re
--- stap2
F(ngx_http_lua_ngx_re_gmatch_iterator) { println("iterator") }
F(ngx_http_lua_ngx_re_gmatch_gc) { println("gc") }
F(ngx_http_lua_ngx_re_gmatch_cleanup) { println("cleanup") }
--- response_body
hello
okay
nil



=== TEST 14: exceeding regex cache max entries
--- http_config
    lua_regex_cache_max_entries 2;
--- config
    location /re {
        content_by_lua '
            local it = ngx.re.gmatch("hello, 1234", "([0-9]+)", "o")
            local m = it()
            ngx.say(m and m[0])

            it = ngx.re.gmatch("howdy, 567", "([0-9]+)", "oi")
            m = it()
            ngx.say(m and m[0])

            it = ngx.re.gmatch("hiya, 98", "([0-9]+)", "ox")
            m = it()
            ngx.say(m and m[0])
        ';
    }
--- request
    GET /re
--- response_body
1234
567
98



=== TEST 15: disable regex cache completely
--- http_config
    lua_regex_cache_max_entries 0;
--- config
    location /re {
        content_by_lua '
            local it = ngx.re.gmatch("hello, 1234", "([0-9]+)", "o")
            local m = it()
            ngx.say(m and m[0])

            it = ngx.re.gmatch("howdy, 567", "([0-9]+)", "oi")
            local m = it()
            ngx.say(m and m[0])

            it = ngx.re.gmatch("hiya, 98", "([0-9]+)", "ox")
            local m = it()
            ngx.say(m and m[0])
        ';
    }
--- request
    GET /re
--- response_body
1234
567
98



=== TEST 16: gmatch matched but no iterate
--- config
    location /re {
        content_by_lua '
            local it = ngx.re.gmatch("hello, world", "[a-z]+")
            ngx.say("done")
        ';
    }
--- request
    GET /re
--- response_body
done



=== TEST 17: gmatch matched but only iterate once and still matches remain
--- config
    location /re {
        content_by_lua '
            local it = ngx.re.gmatch("hello, world", "[a-z]+")
            local m = it()
            if m then
                ngx.say(m[0])
            else
                ngx.say("not matched")
            end
        ';
    }
--- request
    GET /re
--- response_body
hello



=== TEST 18: gmatch matched but no iterate and early forced GC
--- config
    location /re {
        content_by_lua '
            local a = {}
            for i = 1, 3 do
                it = ngx.re.gmatch("hello, world", "[a-z]+")
                it()
                collectgarbage()
                table.insert(a, {"hello", "world"})
            end
            ngx.say("done")
        ';
    }
--- request
    GET /re
--- response_body
done



=== TEST 19: gmatch iterator used by another request
--- http_config eval
    "lua_package_path '$::HtmlDir/?.lua;;';"
--- config
    location /main {
        content_by_lua '
            package.loaded.foo = nil

            local res = ngx.location.capture("/t")
            if res.status == 200 then
                ngx.print(res.body)
            else
                ngx.say("sr failed: ", res.status)
            end

            res = ngx.location.capture("/t")
            if res.status == 200 then
                ngx.print(res.body)
            else
                ngx.say("sr failed: ", res.status)
            end
        ';
    }

    location /t {
        content_by_lua '
            local foo = require "foo"
            local m = foo.go()
            ngx.say(m and "matched" or "no")
        ';
    }
--- user_files
>>> foo.lua
module("foo", package.seeall)

local it

function go()
    if not it then
        it = ngx.re.gmatch("hello, world", "[a-z]+")
    end

    return it()
end
--- request
    GET /main
--- response_body
matched
sr failed: 500
--- error_log
attempt to use ngx.re.gmatch iterator in a request that did not create it



=== TEST 20: gmatch (empty matched string)
--- config
    location /re {
        content_by_lua '
            for m in ngx.re.gmatch("hello", "a|") do
                if m then
                    ngx.say("matched: [", m[0], "]")
                else
                    ngx.say("not matched: ", m)
                end
            end
        ';
    }
--- request
    GET /re
--- response_body
matched: []
matched: []
matched: []
matched: []
matched: []

