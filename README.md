# pandoc.nvim

## Installation
With lazy:
```lua
return {
    "ciocapiat02/pandoc.nvim",

    config = function ()
        require("pandoc-nvim").setup({
            local configs = {
                -- wether to automatically open the file after conversion, if the output is in html format, it will be open in the browser using a web server
                auto_open = false,
                -- User can set a default template path here, the template must be in the same directory of the actual file
                html_template = nil,
                -- default path in which the export file will be put (don't forget to add the '/' character at the end)
                default_export_path = "./pandoc_output/",
                -- whether to add or not the --katex flag
                enable_katex = true,
            }
        }) 
    end
}
```

## Description
A simple and (not yet) configurable neovim plugin that wraps pandoc.

To call it you just need to use the command `pandoc [format]`

At this time it can convert a markdown files to:
- html
- pdf (pdflatex)
- slides (revealjs)

Important informations about the file should be explicitly put in the markdown header, for instance

```yaml
title: "My awesome slides"
subtitle: "This slides explains everything"
author: ciocapiat02
date: March 69, 420
revealjs-url: https://unpkg.com/reveal.js@4.6.0
navigationMode: linear
css: my-theme.css
```

this header will create a slides html file with reveal.js and a custom css theme

## Little tip
## Roadmap
- make it configurable:
    - html templates
    - custom css
    - engines
- support more export formats
