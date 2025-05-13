# Fix My WindowServer

A Zsh utility for macOS that automates:

- **rm**      — Remove Chromium, Chrome & Keystone updater  
- **bkup**    — Back up WindowServer preferences  
- **reset**   — Clear preferences and reboot  
- **restore** — Restore preferences and reboot  
- **fix**     — Run `rm` → `bkup` → `reset` in one step  

## Information
I recently began using Mac OS X 15.4, and now 15.5 Beta on an M4 Pro. 
The battery life and performance claims were absent in my end-user experience-
"WindowServer" is mostly responsible for this significant impact, with no fix.
That's why I created the repository to resolve complaints with a quick-fix script.
This script does **not** solve the entire WS issue- only the majority compute waste.

All working solutions for Sequoia 15.5 are welcome to contributors.
Ideally, is a first-party solution to the WindowServer issue (e.g. faults @ 500/s).
I'll update upon discovering any new fix, fingers crossed for an upstream patch.

- Reference: [Chrome is Bad](https://chromeisbad.com)

## Prerequisites

- **Operating System:** macOS (Darwin)
- **Shell:** Zsh (`#!/usr/bin/env zsh`)
- **Privileges:** Administrator (sudo) for system-level operations

## Installation

1. Download the script to a directory on your `$PATH`, for example `/usr/local/bin`:
   ```bash
   sudo curl -Lo /usr/local/bin/fixmywindowserver \
     https://raw.githubusercontent.com/yourusername/fixmywindowserver/main/fixmywindowserver
   ```
2. Make it executable:
   ```bash
   sudo chmod +x /usr/local/bin/fixmywindowserver
   ```
3. Verify installation:
   ```bash
   which fixmywindowserver
   # → /usr/local/bin/fixmywindowserver
   ```

## Usage

Run with root privileges:

```bash
sudo fixmywindowserver <command> [backup_dir]
```

**Commands**:

| Command   | Description                                        |
|-----------|----------------------------------------------------|
| `rm`      | Delete Chromium, Chrome & Keystone (no reboot)     |
| `bkup`    | Back up WindowServer `.plist` files to `backup_dir`|
| `reset`   | Clear WindowServer prefs and reboot                |
| `restore` | Restore prefs from `backup_dir` and reboot         |
| `fix`     | Run `rm`, then `bkup`, then `reset` (one reboot)   |

- **backup_dir** *(optional)*: Custom path for `bkup`, `restore`, or `fix`. Defaults to `~/.local/share/windowserver_backup`.

## Examples

```bash
# Remove Chrome & Keystone
sudo fixmywindowserver rm

# Back up to default directory
sudo fixmywindowserver bkup

# Back up to a custom directory
sudo fixmywindowserver bkup ~/Documents/ws_backup

# Run full fix sequence
sudo fixmywindowserver fix
```

## Contributing

1. Fork the repository  
2. Create a branch: `git checkout -b feature/YourFeature`  
3. Commit changes: `git commit -m "Add new feature"`  
4. Push: `git push origin feature/YourFeature`  
5. Open a Pull Request  

Please follow existing code style and document changes clearly.

## License

MIT © Logician
