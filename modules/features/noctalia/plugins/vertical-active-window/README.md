# Vertical active window

`dazza/vertical-active-window:window` shows Niri's focused window icon and title,
rotated +90° by default. Choose **Text rotation** in widget settings to switch
between +90° (top to bottom) and −90° (bottom to top). The icon stays upright at
the top. This widget is intended for vertical bars and always renders vertically.
It polls Niri every 250 ms and rewrites its runtime SVG only when the content,
font family, or theme foreground changes. No focused window hides it.

The Nix wrapper in `../../default.nix` declares a `dazza-local` path source at
`/home/dazza/.nixconf/modules/features/noctalia/plugins`. Plugin code stays outside
the Nix store so `.luau` edits hot-reload. Manifest edits need a Noctalia config
reload. The wrapper uses the unmodified cached Noctalia package.

The rendered content uses the existing bar's 700 font weight and palette
foreground, an upright 16 px app icon at the top, and 14 px rotated text below it.
The title length adapts using estimated character widths with no length limit
or ellipsis. SVG text fitting scales the label to its allocated width with 4 px
of internal clearance at each end. There is a 12 px icon-to-text gap and 4 px
end padding. The rounded SVG background follows this widget's `capsule_fill`
setting (including hex colours), inheriting the `min-vertical` bar's value when
unset. The text uses `on_secondary_container`. Colours update with settings and
theme changes. Native
active-window title scrolling is not available through this SVG presentation.

The session needs Niri and `XDG_RUNTIME_DIR`; `NOCTALIA_PLUGIN_NIRI` is supplied by
the Nix wrapper. Runtime SVGs are written to the user's session runtime directory.
