# Packet Atlas

Open `index.html` directly in a browser. No build, dependencies, or internet connection is needed.

For a local web server on this NixOS machine:

```sh
nix shell nixpkgs#python3 -c python3 -m http.server 8765 --directory network-visualizer
```

Then visit http://localhost:8765.

Includes a 14-step HTTPS request/response journey, before/after packet fields, NAT connection mapping, TCP/IP and OSI layer explanations, and an interactive TCP header. Play, pause, scrub, or click a device. The Bigger Picture tab documents setup, assumptions, and linked protocol references.
