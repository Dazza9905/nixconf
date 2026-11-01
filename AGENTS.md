# Working with this configuration

## Consult before adding things

- Before adding a service, module, dependency, configuration block, or other new
  functionality, explain the proposed change and wait for the user's approval.
- Show a concrete code snippet, name the exact files and locations, explain why
  the addition is needed, and describe how it connects to the existing environment.
- A broad request to implement something does not replace this consultation.
  Once the user approves a concrete proposal, proceed within that agreed scope
  without repeatedly asking for confirmation.
- Inspect and explain first; do not make the configuration change and only then
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
- Preserve existing users, data paths, provider access, network routes, and
  customizations unless the agreed change requires otherwise.
- Keep changes small and preserve unrelated user edits. Run targeted evaluation
  checks; leave full NixOS builds and rebuilds to the user unless explicitly asked.
- Report what changed, what was checked, and what still needs activation or testing.
