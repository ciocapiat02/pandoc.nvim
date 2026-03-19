local ServerModule = {
    server_started = false,
    server = nil,
    host = "127.0.0.1",
    port = 9090,
    file_to_watch = nil,
    reload_script = [[
        <script>
            const eventSource = new EventSource('/live-reload');

            eventSource.onmessage = (event) => {
                if (event.data === 'reload') {
                    window.location.reload();
                }
            };

        </script>
    ]],
    clients = {},
}

local function on_connect(sock)
    sock:read_start(function(err, data)
        if err or not data then
            ServerModule.clients[sock] = nil
            if not sock:is_closing() then sock:close() end
            return
        end
        if data:find(".*/live%-reload.*") then
            -- Keep the connection open for SSE
            ServerModule.clients[sock] = true
            local sse_header = "HTTP/1.1 200 OK\r\n"
                .. "Content-Type: text/event-stream\r\n"
                .. "Cache-Control: no-cache\r\n"
                .. "Connection: keep-alive\r\n"
                .. "Access-Control-Allow-Origin: *\r\n\r\n"
            sock:write(sse_header)
            sock:read_stop()
        elseif data:find("GET / ") or data:find("GET /index.html") then
            -- FILE SERVING
            local f = io.open(ServerModule.file_to_watch, "r")
            if f then
                local content = f:read("*all")
                f:close()
                local injected = content:gsub("</body>", ServerModule.reload_script .. "</body>")

                local response = "HTTP/1.1 200 OK\r\n"
                    .. "Content-Type: text/html\r\n"
                    .. "Content-Length: "
                    .. #injected
                    .. "\r\n"
                    .. "Connection: close\r\n\r\n" -- Tell browser we are done
                    .. injected

                sock:write(response, function()
                    sock:close() -- Close ONLY after the HTML is sent
                end)
            end
        else
            -- Catch-all for favicons or other requests
            sock:write("HTTP/1.1 404 Not Found\r\n\r\n")
            sock:close()
        end
    end)
end

function ServerModule.start_server(file)
    ServerModule.file_to_watch = file

    if not ServerModule.server_started then
        ServerModule.server = vim.uv.new_tcp()
        ServerModule.server_started = true
    else
        vim.notify("http server already started", vim.log.levels.WARNING)
        return
    end

    ServerModule.server:bind(ServerModule.host, ServerModule.port)
    ServerModule.server:listen(128, function(err)
        assert(not err, err)
        local sock = vim.uv.new_tcp()
        if ServerModule.server:accept(sock) then
            on_connect(sock)
        else
            sock:close()
        end
    end)
end

function ServerModule.update()
    for client_sock, _ in pairs(ServerModule.clients) do
        if not client_sock:is_closing() then
            client_sock:write("data: reload\n\n", function(err)
                if err then 
                    ServerModule.clients[client_sock] = nil
                else
                    print("reload event sent to client")
                end
            end)
        else
            ServerModule.clients[client_sock] = nil
        end
    end
end

function ServerModule.get_server_started() return ServerModule.server_started end

return ServerModule
