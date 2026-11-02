# Working with this configuration

## Consult before adding things

- Trivial fixes with no meaningful implementation decisions may be made directly
  without a proposal or approval. Validate them and report the result.
- For other code changes, present a concrete proposal before editing and wait for the
  user's approval. This includes fixes, refactors, moves, and removals, as well
  as additions. Name the exact files, show the proposed code or a focused diff,
  and briefly explain the reason and how it fits the existing architecture.
- Keep proposals concise and specific enough to review. Read-only inspection
  and evaluation may proceed before approval. Once a concrete proposal is
  approved, implement and validate it without asking again within that scope.
- Before adding a service, module, dependency, configuration block, or other new
  functionality, explain the proposed change and wait for the user's approval.
- Show a concrete code snippet, name the exact files and locations, explain why
  the addition is needed, and describe how it connects to the existing environment.
- A broad request to implement something does not replace this consultation.
  Once the user approves a concrete proposal, proceed within that agreed scope
  without repeatedly asking for confirmation.
- For changes requiring consultation, inspect and explain first; do not make the configuration change and only then
  present it for review. A specific request to update these instructions
  authorizes that documentation edit.

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
