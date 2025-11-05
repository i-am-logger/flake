# MCP Servers SubSystem

Collection of Model Context Protocol (MCP) server implementations.

## Available Servers

- **mcp-github**: GitHub integration MCP server
- **rs-mcp-***: Rust-based MCP server implementations (commented out)

## Structure

```
mcp-servers/
├── default.nix          # Main entry point, exports all servers
├── servers/             # Individual server implementations
│   ├── github-mcp-server.nix
│   ├── filesystem.nix
│   ├── git.nix
│   └── ...
└── README.md
```

## Usage

```nix
{
  imports = [ ./Systems/SubSystems/mcp-servers ];
}
```

## Adding New Servers

1. Add server definition to `servers/`
2. Export in `default.nix`
3. Enable as needed in system configuration
