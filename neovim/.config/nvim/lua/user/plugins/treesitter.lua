-- Compatibility shim for nvim-treesitter (archived `main` branch) on Neovim 0.12+.
--
-- Neovim 0.12 always returns captures from `iter_matches()` as arrays
-- (`table<capture_id, TSNode[]>`); the legacy `all = false` option was removed.
-- nvim-treesitter's handlers still treat `match[id]` as a single node, so e.g.
-- `#set-lang-from-info-string!` in its markdown injections query crashes with
-- "attempt to call method 'range' (a nil value)".
--
-- Re-register the affected handlers with array-aware versions.
local function first_node(nodes)
    if type(nodes) == "table" then
        return nodes[1]
    end
    return nodes
end

local function node_text(match, id, bufnr)
    local node = first_node(match[id])
    if not node then
        return nil
    end
    return vim.treesitter.get_node_text(node, bufnr)
end

-- Same fallbacks nvim-treesitter uses for shorthand info strings.
local language_aliases = {
    ex = "elixir",
    pl = "perl",
    sh = "bash",
    ts = "typescript",
    uxn = "uxntal",
}

local mimetype_languages = {
    ["importmap"] = "json",
    ["module"] = "javascript",
    ["application/ecmascript"] = "javascript",
    ["text/ecmascript"] = "javascript",
}

local function define_predicates()
    -- Used by indent queries for c, ecma, groovy, ispc, ocaml, r, ruby, swift.
    vim.treesitter.query.add_predicate("kind-eq?", function(match, _, bufnr, pred)
        local node = first_node(match[pred[2]])
        if not node then
            return true
        end
        local _, _, kind = require("nvim-treesitter.locals").find_definition(node, bufnr)
        return vim.tbl_contains({ unpack(pred, 3) }, kind)
    end, { force = true })
end

local function define_directives()
    vim.treesitter.query.add_directive(
        "set-lang-from-info-string!",
        function(match, _, bufnr, pred, metadata)
            local alias = node_text(match, pred[2], bufnr)
            if not alias then
                return
            end
            alias = alias:lower()
            metadata["injection.language"] = vim.filetype.match({ filename = "a." .. alias })
                or language_aliases[alias]
                or alias
        end,
        { force = true }
    )

    vim.treesitter.query.add_directive(
        "set-lang-from-mimetype!",
        function(match, _, bufnr, pred, metadata)
            local mimetype = node_text(match, pred[2], bufnr)
            if not mimetype then
                return
            end
            local configured = mimetype_languages[mimetype]
            if configured then
                metadata["injection.language"] = configured
            else
                local parts = vim.split(mimetype, "/", {})
                metadata["injection.language"] = parts[#parts]
            end
        end,
        { force = true }
    )

    vim.treesitter.query.add_directive(
        "downcase!",
        function(match, _, bufnr, pred, metadata)
            local id = pred[2]
            metadata[id] = metadata[id] or {}
            metadata[id].text = string.lower(node_text(match, id, bufnr) or "")
        end,
        { force = true }
    )
end

return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    config = function()
        define_predicates()
        define_directives()
    end,
}
