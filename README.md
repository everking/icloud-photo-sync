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

3. Edit `eric.env`: set **`ICLOUD_USERNAME`** and **`ICLOUD_PASSWORD`** (see [upstream auth](https://icloud-photos-downloader.github.io/icloud_photos_downloader/authentication.html)). Optionally set `DATA_FOLDER`, `TZ`, `COOKIE_FOLDER`, `INTERVAL`, and `UNTIL_FOUND` (defaults below).

4. On the host, ensure directories exist as needed, for example:

   - **`${DATA_FOLDER}/<instance>/`** — download mount → `/data` in the container (`DATA_FOLDER` defaults to `./data` under your **current working directory** when you run the script)  
   - **Cookie directory** — defaults to `cookies/` under that same **current working directory** → `/app/cookie`, or set `COOKIE_FOLDER` in the env file

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
| **AUTH** | Runs `icloudpd --auth-only` with a TTY (`-it --rm`) so you can complete Apple / web MFA and refresh cookies. Container name: `<instance>-auth-only-icloudpd`. Creates `COOKIE_FOLDER` if missing (`mkdir -p`). |
| **SYNC** | Runs a detached watcher (`-it -d --rm`) with `--until-found` and `--watch-with-interval`. Container name: `<instance>-sync-icloudpd`. The resolved `COOKIE_FOLDER` must already exist as a directory (e.g. after **AUTH** created it). |

Examples:

```bash
./icloud-photo-sync.sh eric AUTH
./icloud-photo-sync.sh eric SYNC
```

Before each run, the script stops and removes the container for that mode and instance (if it exists), then starts a new one.

## Environment file

Configuration is read from **`<instance_name>.env`** in the same directory as `icloud-photo-sync.sh` (for example `eric.env` for `./icloud-photo-sync.sh eric …`).

Variables **must** be set (the script exits with an error if either is missing or empty):

| Variable            | Purpose |
|---------------------|--------|
| `ICLOUD_USERNAME`   | Apple ID email passed to `icloudpd --username` |
| `ICLOUD_PASSWORD`   | Password (or app-specific password, per upstream docs) for `icloudpd --password` |

Optional (defaults in parentheses):

- `DATA_FOLDER` — host root for `${DATA_FOLDER}/<instance>` → `/data` (default: `data` under the process **current working directory**, i.e. `${PWD}/data`)
- `COOKIE_FOLDER` — host directory mounted at `/app/cookie` (default: `cookies` under **current working directory**, i.e. `${PWD}/cookies`). Set explicitly if you run several Apple IDs and need separate cookie directories.
- `INTERVAL` — watch poll interval in seconds (`36000`)
- `UNTIL_FOUND` — passed to `--until-found` (`500`)
- `TZ` — container timezone, e.g. for folder dates (`America/Los_Angeles`)
- `ICLOUDPD_IMAGE` — Docker image passed to `docker run` (`icloudpd/icloudpd:latest` by default); use a locally built tag for unmerged upstream fixes (see below)

## Security

- Real instance files (`*.env`) are **gitignored**. Do not commit credentials.
- Commit only `.env.example` (or sanitized templates) without secrets.

## Linux / Ubuntu notes

- Use **LF** line endings in `*.env` files if you edit them on Windows, or paths and logins can break on Linux.
- `AUTH` needs an interactive terminal for MFA prompts.
- **Current working directory matters** for the default `DATA_FOLDER` and `COOKIE_FOLDER`: `cd` to the directory you want those paths anchored under before running the script, or set both variables explicitly in the env file.

## Patched / custom `icloudpd` image (e.g. PR #1327)

The Hub image `icloudpd/icloudpd:latest` is built from **released** sources. To run an **unmerged** fix (such as [PR #1327](https://github.com/icloud-photos-downloader/icloud_photos_downloader/pull/1327) for 2FA push behavior), build a local image that installs the project from Git, then point the script at it:

```bash
docker build -f Dockerfile.icloudpd-pr1327 -t icloudpd:pr1327 .
```

Set **`ICLOUDPD_IMAGE`** (environment or in your `*.env`) to that tag, e.g. `ICLOUDPD_IMAGE=icloudpd:pr1327`.

The Dockerfile accepts a build arg if you want another ref, for example PR [#1335](https://github.com/icloud-photos-downloader/icloud_photos_downloader/pull/1335) (reported by some users to work when #1327 triggers “Incorrect Verification Code” after entering the code):

```bash
docker build -f Dockerfile.icloudpd-pr1327 --build-arg ICLOUDPD_GIT_REF=refs/pull/1335/head -t icloudpd:pr1335 .
```

To build **and** set `ICLOUDPD_IMAGE` in the **current** shell (not a subshell), use **`source`**: `source ./build.sh` (see `build.sh`).

## Upstream

Behavior and flags follow [icloud-photos-downloader / icloudpd](https://github.com/icloud-photos-downloader/icloud_photos_downloader). See upstream docs for password types, two-factor flow, and CLI options.
