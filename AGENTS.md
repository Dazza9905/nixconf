# Working with this configuration

## Propose and implement

- Inspect relevant configuration first. Before nontrivial edits, briefly propose
  the change, name exact files, show a focused snippet or diff when useful, and
  explain how it fits the existing architecture.
- Propose and then implement and validate without pausing for approval. Do not
  require the user to say yes for fixes, refactors, moves, removals, additions,
  services, modules, or dependencies within the requested scope.
- The user will object if they disagree. Revert the relevant changes when asked,
  preserving unrelated user edits.
- Trivial fixes may be made directly. Ask only when missing information prevents
  a sound implementation, not for routine confirmation.

## Fit the existing architecture

- Read the relevant configuration, imports, options, dependencies, and nearby
  examples before proposing an implementation.
- Prefer existing NixOS modules and project abstractions. Extend them using the
  repository's conventions instead of introducing parallel mechanisms.
- Reusable homelab services belong in `modules/homelab/services/<service>/default.nix`,
  are imported by `modules/homelab/services/default.nix`, and expose options under
  `homelab.services.<service>` using `lib.mkEnableOption` and `lib.mkIf`.
- Keep host configuration focused on imports, enabling features, and host-specific
  values. Avoid embedding reusable service implementations in a host file.
- Keep each feature module in its own `modules/features/<feature>/` directory,
  with the Nix module in `default.nix` and supporting configuration files beside
  it. Follow this layout for new features and when organizing existing ones.
- Preserve existing users, data paths, provider access, network routes, and
  customizations unless the agreed change requires otherwise.
- Keep changes small and preserve unrelated user edits. Run targeted evaluation
  checks; leave full NixOS builds and rebuilds to the user unless explicitly asked.
- Report what changed, what was checked, and what still needs activation or testing.
# User preferences

- Manage system configuration, packages, and development environments declaratively through their existing configuration files.
- Never use `nix profile` or imperative package installation commands such as `nix-env -i`.
- Do not introduce imperative installation steps, persistent shell workarounds, or manual environment changes as substitutes for fixing declarative configuration or the underlying software.
- Read-only inspection and temporary builds or tests are allowed. Keep persistent changes in declarative configuration; do not switch to an imperative installation when a declarative build is difficult.
- For Nix work, read the global skill at `/home/dazza/.codex/skills/nix/SKILL.md`. Maintain it as needed with reusable preferences and verified lessons, keeping project-specific details out.
