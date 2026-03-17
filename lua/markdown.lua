
local function call_pandoc(opts)
    opts = opts or {}
    local current_file = vim.fn.fnamemodify(opts.current_file_path, ":t:r")
    local output_file = opts.export_path..current_file..'.'..opts.export_ext

    local conversion_result = vim.system(
        {'pandoc',
            '-t', opts.template,
            '-s', opts.file_path,
            '-o', output_file},
        { text = true }
    ):wait();

    vim.notify(conversion_result.stdout, vim.log.levels.INFO)

    return output_file
end

local function open_file(file)
    file = file
    vim.system({
        "xdg-open", file
    })
end

vim.api.nvim_create_user_command("ExportMarkdown", function(opts)
    local subcmd = opts.fargs[1]
    local current_buffer = vim.api.nvim_get_current_buf()
    local filetype = vim.api.nvim_buf_get_option(current_buffer, "filetype")
    local current_file_path = vim.api.nvim_buf_get_name(current_buffer)

    if filetype == "markdown" then
        if subcmd == "html" then
            local output_file = call_pandoc({
                template = 'html',
                file_path = current_file_path,
                export_path = "/tmp/",
                export_ext = "html"
            })
            open_file(output_file)
        elseif subcmd == "pdf" then
            local output_file = call_pandoc({
                template = 'pdf',
                file_path = current_file_path,
                export_path = "/tmp/",
                export_ext = "pdf"
            })
            open_file(output_file)
        elseif subcmd == "slides" then
            local output_file = call_pandoc({
                template = 'revealjs',
                file_path = current_file_path,
                export_path = "/tmp/",
                export_ext = "html"
            })
            open_file(output_file)
        else
            vim.notify("Not a know export type", vim.log.levels.WARNING)
        end
    else
        vim.notify("Not a markdown file", vim.log.levels.WARNING)
    end
end, { nargs = '*',
    complete = function (arglead, cmdline, cursorpos)
        return { "html", "pdf", "slides" }
    end
})
