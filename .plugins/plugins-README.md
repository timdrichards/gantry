# Dev Container Plugins

Plugins extend the dev container with custom commands, scripts, and tools.
Each plugin is a git repository cloned into this directory.

## Directory Structure

```
.plugins/
├── .registry.json      # Plugin registry (managed automatically)
├── .loader.sh          # Auto-generated shell loader (do not edit)
├── plugins-README.md   # This file
└── <plugin-name>/      # Each installed plugin
    ├── plugin.json     # Manifest: name, version, description, dependencies
    ├── bin/            # Executables added to PATH
    ├── lib/
    │   └── shell.sh    # Shell aliases/functions sourced at login
    └── docs/
        └── README.md   # Plugin documentation
```

## Managing Plugins

```bash
plugin install <git-url>                # Install a plugin
plugin install <git-url> --pin v1.0.0  # Pin to a specific tag or branch
plugin list                             # List installed plugins
plugin remove <name>                    # Uninstall a plugin
plugin update --all                     # Update all plugins
plugin docs [name]                      # View plugin documentation
plugin audit <name>                     # Inspect lib/shell.sh before sourcing
plugin check-updates                    # Check for available updates
plugin help                             # Full usage guide
```

## Plugin Manifest (plugin.json)

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "What this plugin does",
  "author": "Your Name",
  "repository": "https://github.com/you/my-plugin",
  "dependencies": [],
  "env": {}
}
```
