Noctalia settings are bundled with `packages.myNoctalia` from
`noctalia-config.toml`. Niri and the NixOS Noctalia module use this package.
The build validates the TOML with the same Noctalia binary it wraps.

After rebuilding and logging in, experiment in Settings, then export to a
separate file (never redirect straight over the source):

```sh
noctalia config export > /tmp/noctalia-next.toml
noctalia config validate /tmp/noctalia-next.toml
cp /tmp/noctalia-next.toml ~/.nixconf/modules/features/desktop/noctalia-config.toml
```

Review the diff, commit the config and flake.lock together, and rebuild both
machines. GUI overrides persist while the package and config stay unchanged.
On the first shell startup after either changes, the wrapper moves the old
settings.toml to `settings-backup.XXXXXXXX/settings.toml` in Noctalia's state
directory. It preserves other state, plugins and credentials. This also applies
to rollbacks. Export desired GUI changes before changing package/config.

The wrapper ignores the old Stow config directory, including user-templates.toml.
Copy any wanted custom TOML into this setup deliberately. The initial config is
the previous Git-tracked base; the incompatible schema-15 local overrides have
not been imported or modified.
