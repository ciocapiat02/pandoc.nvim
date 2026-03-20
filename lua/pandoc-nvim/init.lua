local server = require("pandoc-nvim.server")

local M = {
    file_to_watch = nil,
    already_connected = false,
}

local configs = {
    auto_open = false, -- wether to automatically open the file after conversion
    html_template = nil, -- User can set a default template path here, the template must be in the same directory of the actual file
    default_export_path = "./pandoc_output/", -- default path in which the export file will be put (don't forget to add the '/' character at the end)
    enable_katex = true, -- whether to add or not the --katex flag
}

local function check_output_dir(directory)
    if vim.fn.isdirectory(directory) == 0 then vim.fn.mkdir(directory, "p") end
end

local function connect_client(link)
    M.already_connected = true
    vim.system({
        "xdg-open",
        link,
    })
end

local function call_pandoc(opts)
    opts = opts or {}
    local current_file = vim.fn.fnamemodify(opts.file_path, ":t:r")
    local output_file = opts.export_path .. current_file .. "." .. opts.export_ext
    local cwd = vim.fn.fnamemodify(opts.file_path, ":h")
    local cmd = { "pandoc", "-t", opts.template, "-s", opts.file_path, "-o", output_file }
    check_output_dir(opts.export_path)

    -- add custom html template if set
    local html_template = opts.html_template or configs.html_template
    if html_template and vim.fn.filereadable(html_template)==1 then
        table.insert(cmd, 2, "--template=" .. html_template)
    end

    -- add katex rendering
    local html_template = opts.html_template or configs.html_template
    if html_template then table.insert(cmd, 2, "--katex") end

    -- call pandoc
    local conversion_result = vim.system(cmd, { text = true, cwd = cwd }):wait()

    vim.notify(conversion_result.stdout, vim.log.levels.INFO)

    return output_file
end

-- opts is a table containing
-- {file: file name, kind: {"file" | "server"} }
local function open_file(opts)
    if opts.kind == "file" then
        file = opts.file
        vim.system({
            "xdg-open",
            file,
        })
    elseif opts.kind == "server" then
        if not server.get_server_started() then server.start_server(M.file_to_watch) end
        if not M.already_connected then
            connect_client(opts.file)
        else
            server.update()
        end
    end
end

local function convert(opts)
    local subcmd = opts.fargs[1]
    local current_buffer = vim.api.nvim_get_current_buf()
    local filetype = vim.api.nvim_buf_get_option(current_buffer, "filetype")
    local current_file_path = vim.api.nvim_buf_get_name(current_buffer)
    if filetype == "markdown" then
        if subcmd == "html" then
            local output_file = call_pandoc({
                template = "html",
                file_path = current_file_path,
                export_path = configs.default_export_path,
                export_ext = "html",
            })

            M.file_to_watch = output_file

            if configs.auto_open then open_file({ kind = "server", file = "http://127.0.0.1:9090" }) end
        elseif subcmd == "pdf" then
            local output_file = call_pandoc({
                template = "pdf",
                file_path = current_file_path,
                export_path = configs.default_export_path,
                export_ext = "pdf",
            })

            if configs.auto_open then open_file({ kind = "file", file = output_file }) end
        elseif subcmd == "slides" then
            local output_file = call_pandoc({
                template = "revealjs",
                file_path = current_file_path,
                export_path = configs.default_export_path,
                export_ext = "html",
            })

            M.file_to_watch = output_file

            if configs.auto_open then open_file({ kind = "server", file = "http://127.0.0.1:9090" }) end
        else
            vim.notify("Not a know export type", vim.log.levels.WARNING)
        end
    else
        vim.notify("Not a markdown file", vim.log.levels.WARNING)
    end
end

---@param conf pandoc-nvim.UserConfig?
function M.setup(conf)
    configs = vim.tbl_deep_extend("force", configs, conf or {})

    vim.api.nvim_create_user_command("Pandoc", function(opts) convert(opts) end, {
        nargs = "*",
        complete = function(arglead, cmdline, cursorpos) return { "html", "pdf", "slides" } end,
    })
end

return M
