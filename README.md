# icloud-photo-sync

Small Bash helper around the official [`icloudpd/icloudpd`](https://hub.docker.com/r/icloudpd/icloudpd) image: one script for **interactive auth** (cookie / MFA) and **background sync** per named instance.

## Requirements

- [Docker](https://docs.docker.com/get-docker/) (Engine or Desktop), with permission to run `docker`
- **Bash** (macOS and Ubuntu defaults are fine)
- Do **not** run the script with `sh` (on Ubuntu, `sh` is often **dash** and will fail). Use `./icloud-photo-sync.sh` or `bash icloud-photo-sync.sh`.

## Setup

1. Clone this repo and `cd` into it.

2. Copy the example env and name it after your instance (the first argument to the script):

   ```bash
   cp .env.example eric.env
   ```

3. Edit `eric.env`: set `DATA_FOLDER`, `USERNAME`, `PASSWORD`, and adjust `TZ` if needed. Optional: `COOKIE_FOLDER` (defaults to a `cookies` directory next to the script), `INTERVAL` (default `36000`), `UNTIL_FOUND` (default `500`).

4. On the host, ensure directories exist as needed, for example:

   - `${DATA_FOLDER}/<instance>/` — mounted as `/data` in the container for both modes  
   - Cookie directory — defaults to `<repo>/cookies` → `/app/cookie`, or set `COOKIE_FOLDER` in the env file

5. Make the script executable:

   ```bash
   chmod +x icloud-photo-sync.sh
   ```

## Usage

```text
./icloud-photo-sync.sh <instance_name> [ AUTH | SYNC ]
```

The second argument is case-insensitive (`auth`, `SYNC`, etc.).

| Mode   | What it does |
|--------|----------------|
| **AUTH** | Runs `icloudpd --auth-only` with a TTY (`-it --rm`) so you can complete Apple / web MFA and refresh cookies. Container name: `<instance>-auth-only-icloudpd`. |
| **SYNC** | Runs a detached watcher (`-it -d --rm`) with `--until-found` and `--watch-with-interval`. Container name: `<instance>-sync-icloudpd`. The resolved `COOKIE_FOLDER` must already exist as a directory (e.g. after **AUTH** created it). |

Examples:

```bash
./icloud-photo-sync.sh eric AUTH
./icloud-photo-sync.sh eric SYNC
```

Before each run, the script stops and removes the container for that mode and instance (if it exists), then starts a new one.

## Environment file

Configuration is read from **`<instance_name>.env`** in the same directory as `icloud-photo-sync.sh` (for example `eric.env` for `./icloud-photo-sync.sh eric …`).

Variables **must** be set (the script exits with an error if any are missing):

| Variable      | Purpose |
|---------------|--------|
| `DATA_FOLDER` | Host root used with `<instance>` for the download mount: `${DATA_FOLDER}/<instance>` → `/data` |
| `USERNAME`    | Apple ID email for `icloudpd` |
| `PASSWORD`    | Account password (or app-specific password, per icloudpd docs) |

Optional (defaults in parentheses):

- `COOKIE_FOLDER` — host directory mounted at `/app/cookie` (default: `cookies` next to `icloud-photo-sync.sh`). Set explicitly if you run several Apple IDs and need separate cookie directories.
- `INTERVAL` — watch poll interval in seconds (`36000`)
- `UNTIL_FOUND` — passed to `--until-found` (`500`)
- `TZ` — container timezone, e.g. for folder dates (`America/Los_Angeles`)

## Security

- Real instance files (`*.env`) are **gitignored**. Do not commit credentials.
- Commit only `.env.example` (or sanitized templates) without secrets.

## Linux / Ubuntu notes

- Use **LF** line endings in `*.env` files if you edit them on Windows, or paths and logins can break on Linux.
- `AUTH` needs an interactive terminal for MFA prompts.

## Upstream

Behavior and flags follow [icloud-photos-downloader / icloudpd](https://github.com/icloud-photos-downloader/icloud_photos_downloader). See upstream docs for password types, two-factor flow, and CLI options.
