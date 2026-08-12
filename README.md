# neovim-nix

My  personal Neovim configuration, built and packaged as a [Nix](https://nixos.org/) flake.

This repo was generated from the
[`nix-community/kickstart-nix.nvim`](https://github.com/nix-community/kickstart-nix.nvim)
template, which this config was built on top of. This
README documents what's actually in *this* repo: the specific plugins,
keymaps, and customizations layered on top of the template, and how to
install it from here rather than from upstream.

## Philosophy

Inherited from the template:

- KISS principle with sane defaults.
- Manage plugins + external dependencies using Nix
  (managing plugins shouldn't be the responsibility of a plugin).
- Configuration entirely in Lua. Vimscript is also possible.
- Use Neovim's built-in loading mechanisms. See:
  - [`:h initialization`](https://neovim.io/doc/user/starting.html#initialization)
  - [`:h runtimepath`](https://neovim.io/doc/user/options.html#'runtimepath')
  - [`:h packadd`](https://neovim.io/doc/user/repeat.html#%3Apackadd)
- Use Neovim's built-in LSP client, with Nix managing language servers.

## Installation

### NixOS (with flakes)

1. Add this flake to NixOS flake inputs:

   ```nix
   inputs.neovim-nix.url = "github:swarringa/neovim-nix";
   ```

1. Add the overlay it provides:

   ```nix
   nixpkgs.overlays = [
       inputs.neovim-nix.overlays.default
   ];
   ```

1. Add the overlay's output to `systemPackages`:

   ```nix
   environment.systemPackages = with pkgs; [
       nvim-pkg # the default package added by the overlay
   ];
   ```

> [!IMPORTANT]
>
> This flake uses `nixpkgs.wrapNeovimUnstable`, which has an unstable
> signature. If `nixpkgs.follows = "nixpkgs";` is set when importing this
> into another flake, it may break — especially if that flake's
> `nixpkgs` input pins a different branch than the one this flake locks.

### Non-NixOS

With Nix installed (flakes enabled):

```console
nix profile add "git+ssh://git@github.com/swarringa/neovim-nix.git#nvim"
```

Or, from a local clone:

```console
nix profile add .#nvim
```

> [!TIP]
>
> `nix profile add` derives the profile entry's display name from the
> targeted flake attribute. Targeting the generic `#default` attribute over
> an SSH flake ref (`git+ssh://...`) can leave the entry registered under
> the entire ugly ref string instead of a short name — target `#nvim`
> explicitly (as above) to avoid that.
>
> To upgrade later: `nix profile upgrade nvim --refresh` (`--refresh` is
> needed because Nix otherwise caches the git fetch and won't notice new
> commits pushed to this repo).

Unfree packages (currently just `eyeliner.nvim`) are allowed by default in
this flake's own `nixpkgs` instantiation (`config.allowUnfree = true;` in
`flake.nix`), so no `--impure` or `NIXPKGS_ALLOW_UNFREE` is required.

## Design

Directory structure:

```sh
── flake.nix
── nvim # Neovim configs (lua), equivalent to ~/.config/nvim
── nix # Nix configs
```

### Neovim configs

- Options are set in `nvim/init.lua`.
- Autocommands, user commands, keymaps, and plugin configuration each live
  in their own file under `nvim/plugin/`.
- Filetype-specific scripts (e.g. starting an LSP client) live in
  `nvim/ftplugin/`.
- Shared library modules live in `nvim/lua/user/`.

Directory structure:

```sh
── nvim
  ├── ftplugin      # Sourced when opening a filetype
  │  ├── lua.lua    # Starts lua-language-server
  │  └── nix.lua    # Starts nil (Nix LSP)
  ├── init.lua       # Always sourced: options, diagnostics config
  ├── lua
  │  └── user
  │     └── lsp.lua  # Shared LSP client-capabilities helper
  ├── plugin         # Automatically sourced at startup
  │  ├── autocommands.lua # LSP keymaps/autocmds, misc autocmds
  │  ├── claudecode.lua   # Claude Code integration + keymaps
  │  ├── commands.lua     # :Q (delete current buffer)
  │  ├── completion.lua   # nvim-cmp + luasnip
  │  ├── diffview.lua     # diffview.nvim keymaps
  │  ├── eyeliner.lua     # f/F/t/T highlight config
  │  ├── gitsigns.lua     # gitsigns.nvim config + keymaps
  │  ├── keymaps.lua      # General-purpose keymaps
  │  ├── lualine.lua      # Statusline + winbar + nvim-navic
  │  ├── neogit.lua       # neogit config + keymaps
  │  ├── plugins.lua      # Misc `setup()`-only plugins (nvim-surround)
  │  ├── statuscol.lua    # Statuscolumn config
  │  ├── telescope.lua    # telescope.nvim config + keymaps
  │  ├── treesitter.lua   # Highlighting, folding, textobjects
  │  └── which-key.lua    # which-key.nvim config
  └── after            # Empty in this repo
     ├── plugin
     └── ftplugin
```

> [!IMPORTANT]
>
> - Configuration variables (e.g. `vim.g.<plugin_config>`) go in
>   `nvim/init.lua` or a module `require`d from there.
> - Configuration for plugins that need explicit initialization (a call
>   to `setup()`) goes in `nvim/plugin/<plugin>.lua`.
> - See [Initialization order](#initialization-order) for details.

### Nix

Neovim derivations are declared in `nix/neovim-overlay.nix`.

```sh
── flake.nix
── nix
  ├── mkNeovim.nix        # Function that builds the Neovim derivation
  └── neovim-overlay.nix  # Overlay that adds the derivation to nixpkgs
```

Plugins are added as a flat list to `all-plugins` in
`nix/neovim-overlay.nix`, sourced from `pkgs.vimPlugins`
([search nixpkgs plugins](https://search.nixos.org/packages?channel=unstable&query=vimPlugins)).
`mkNeovim.nix` also supports adding plugins as flake inputs for
bleeding-edge versions not yet in nixpkgs (see the commented-out
`wf-nvim` example in `flake.nix` and `mkNvimPlugin` in the overlay) —
unused in this repo today, but left in place as a template for later.

`extraPackages` in the overlay adds non-plugin runtime dependencies to
the wrapped Neovim's `PATH`: `lua-language-server`, `nil` (Nix LSP), and
`claude-code` (the CLI `claudecode.nvim` drives).

### Initialization order

The generated `init.lua`:

1. Prepends `nvim/lua` to the `runtimepath`.
1. Runs the content of `nvim/init.lua`.
1. Prepends `nvim/*` to the `runtimepath`.
1. Prepends `nvim/after` to the `runtimepath`.

Modules in `nvim/lua` can be `require`d from `init.lua` and `nvim/*/*.lua`.
Modules in `nvim/plugin/` are sourced automatically, as if they were
plugins, after the rest of `init.lua` and after other plugins are loaded.

## Installed plugins & customizations

Full list with links: [`nix/neovim-overlay.nix`](./nix/neovim-overlay.nix).
Config for each: `nvim/plugin/<name>.lua` unless noted otherwise.

### Completion & snippets

- **[nvim-cmp](https://github.com/hrsh7th/nvim-cmp)** with
  [luasnip](https://github.com/l3mon4d3/luasnip),
  [lspkind.nvim](https://github.com/onsails/lspkind.nvim) for icons, and
  sources for LSP, buffer, path, cmdline/cmdline-history, and
  `nvim_lua`. See `nvim/plugin/completion.lua`.

### LSP

- No LSP plugin manager (no `nvim-lspconfig` / `mason`) — language servers
  are started directly via `vim.lsp.start()` in `nvim/ftplugin/`, one file
  per filetype (`lua.lua` starts `lua-language-server`, `nix.lua` starts
  `nil`), both provided via Nix (`extraPackages`) rather than installed
  by the plugin.
- Shared LSP keymaps, code-lens auto-refresh, and
  [nvim-navic](https://github.com/SmiteshP/nvim-navic) attachment live in
  the `LspAttach` autocommand in `nvim/plugin/autocommands.lua`.

### Treesitter

- **[nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)**
  (`withAllGrammars`), on nixpkgs' packaging of the rewritten `main`
  branch (no `nvim-treesitter.configs` module — see
  `nvim/plugin/treesitter.lua`).
  - Highlighting enabled per-buffer via `vim.treesitter.start()` on
    `FileType`, skipping files over 100 KiB.
  - Folding via `v:lua.vim.treesitter.foldexpr()`.
  - **[nvim-treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects)**
    for select/move/swap text objects (`af`/`if`, `ac`/`ic`, `]m`/`[m`,
    argument swap on `<leader>b`/`<leader>B`, etc.)
  - **[nvim-treesitter-context](https://github.com/nvim-treesitter/nvim-treesitter-context)**
    for a sticky scope header.
  - **[nvim-ts-context-commentstring](https://github.com/joosepalviste/nvim-ts-context-commentstring)**
    for context-aware `commentstring`.

### Git

- **[gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim)**: hunk
  navigation (`]g`/`[g`), stage/reset/preview/blame under `<leader>h*`,
  current-line-blame toggle on `<leader>glb`, hunk text object (`ih`).
- **[neogit](https://github.com/TimUntersberger/neogit)**: `<leader>go`
  open, `<leader>gs` open split, `<leader>gc` commit. Integrates with
  diffview and telescope.
- **[diffview.nvim](https://github.com/sindrets/diffview.nvim)**:
  `<leader>gd` open, `<leader>gfb`/`<leader>gfc` file history (buffer /
  cwd), `<leader>gft` toggle file panel.
- **[vim-fugitive](https://github.com/tpope/vim-fugitive)**: no extra
  config, used as a library by other git plugins (also wired into
  lualine's `extensions`).

### Fuzzy finding

- **[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)**
  + `telescope-fzy-native-nvim`, with sqlite-backed command history. Main
  keymaps live under `<leader>t*` (`tp` find files, `tf` fuzzy grep, `tg`
  project files, `tc` quickfix, `tq` command history, `tl` loclist, `tr`
  registers, `tbb`/`tbf` buffers, `td` LSP document symbols, `to` LSP
  workspace symbols), plus `<M-p>` old files, `<C-g>` live grep, `<M-f>`/
  `<M-g>` filetype-scoped fuzzy/live grep.

### UI

- **[lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)**:
  global statusline, `nvim-navic` breadcrumb in the statusline, filename
  in the winbar, macro-recording/executing indicator.
- **[statuscol.nvim](https://github.com/luukvbaal/statuscol.nvim)**:
  custom statuscolumn (sign column + line numbers).
- **[which-key.nvim](https://github.com/folke/which-key.nvim)**: `helix`
  preset, picks up `desc` from every keymap above automatically.

### Editing / navigation

- **[nvim-surround](https://github.com/kylechui/nvim-surround)**,
  **[vim-unimpaired](https://github.com/tpope/vim-unimpaired)** (`]`/`[`
  navigation family), **[vim-repeat](https://github.com/tpope/vim-repeat)**.
- **[eyeliner.nvim](https://github.com/jinh0/eyeliner.nvim)**: highlights
  the unique target character for `f`/`F`/`t`/`T`, only after the key is
  pressed.
- **[nvim-unception](https://github.com/samjwill/nvim-unception)**:
  prevents nested `nvim` sessions (e.g. from `git commit` inside a
  terminal buffer) from opening a new TUI instance.

### Claude Code integration

- **[claudecode.nvim](https://github.com/coder/claudecode.nvim)**
  (packaged in nixpkgs as `claudecode-nvim`), with
  **[snacks.nvim](https://github.com/folke/snacks.nvim)** for its
  terminal UI (falls back to Neovim's native terminal if snacks is
  unavailable) and `claude-code` in `extraPackages` so the `claude` CLI
  it drives is always on `PATH`.
- Terminal split width set to 50% of the window (`split_width_percentage
  = 0.5`, default is 30%).
- `auto_insert = false`: the Claude terminal buffer does *not*
  auto-switch to Terminal mode just because it gained focus (e.g. via
  `<C-w>` window navigation) — it stays in whatever mode it was left in.
- Keymaps, all under `<leader>a`:
  | Keymap | Action |
  | --- | --- |
  | `<leader>ac` | Toggle the Claude terminal |
  | `<leader>af` | Focus the Claude terminal |
  | `<leader>ar` | Resume last session (`--resume`) |
  | `<leader>aC` | Continue last session (`--continue`) |
  | `<leader>am` | Select model |
  | `<leader>ab` | Add current buffer (`%`) |
  | `<leader>as` (visual) | Send selection |
  | `<leader>aa` | Accept diff |
  | `<leader>ad` | Deny diff |

  Note: `<leader>t` was already the telescope prefix throughout this
  config, so the treesitter argument-swap keymaps were moved to
  `<leader>b`/`<leader>B` to free up `<leader>a` for this group.

### Options (`nvim/init.lua`)

Line numbers (absolute + relative), cursorline, spell-check on by default
(`en`), 2-space indent, persistent undo, `splitright`/`splitbelow`,
`cmdheight=0`, a 100-column colorcolumn, and custom diagnostic
signs/virtual-text formatting (requires a Nerd Font). Also sets
`vim.g.sqlite_clib_path` so `sqlite.lua` (a dependency of gitsigns'
history and telescope's history) finds the Nix-provided `sqlite`.

## Test drive

```console
nix run "github:swarringa/neovim-nix"
```

## Editing the config

Since this Neovim setup is a Nix derivation, editing it demands a
different workflow than a plain dotfiles-based config would:

- Make the changes and stage any new files[^1].
- Run `nix run /path/to/neovim-nix#nvim` (or
  `nix run /path/to/neovim-nix#nvim -- <nvim-args>`).

[^1]: Nix flakes only pick up files that are tracked by git (staged is
      enough — they don't need to be committed). A new, unstaged file
      under `nvim/` will silently be excluded from the build.

This rebuilds the `nvim` derivation, but has the advantage that if
anything breaks, it's only broken during that test run.

For a faster, impure feedback loop, `$XDG_CONFIG_HOME/nvim` (or
`$NVIM_APPNAME`, which defaults to `nvim`) can instead point at a local
checkout, editable directly[^2]. Caveat: the wrapper Nix generates for
the packaged derivation invokes `nvim -u
/nix/store/.../generated-init.lua`, so it never sources a local
`init.lua` — anything that needs to be picked up this way has to go in
`nvim/plugin/` or `nvim/after/plugin/` instead, since those are sourced
from the runtime path regardless.

[^2]: Assuming Linux; see `:h initialization` for Darwin paths.
