# pandoc.nvim

## Description
A simple and (not yet) configurable neovim plugin that wraps pandoc.

At this time it can convert a markdown file to:
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

this header will create a slides html file with reveal.js with a custom css theme

## Roadmap
- make it configurable:
    - html templates
    - custom css
    - engines
- support more export formats
