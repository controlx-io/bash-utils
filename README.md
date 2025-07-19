# pm2alt - A Simple Process Manager for systemd

`pm2alt` is a lightweight command-line tool that acts as a user-friendly wrapper around `systemd`. It provides a `pm2`-like interface for managing your applications as robust system services, without needing Node.js or `pm2` itself.

It's ideal for developers who are comfortable with `pm2`'s workflow but want to use the native, powerful process manager built into modern Linux distributions.

## Features

-   **Familiar Syntax:** Uses simple commands like `start`, `stop`, `restart`, and `logs`.
-   **No Dependencies:** It's a single Bash script. It doesn't require `npm`, `node`, or any other runtime.
-   **Systemd Power:** Leverages `systemd` for process supervision, automatic restarts on failure, and centralized logging via `journald`.
-   **Auto-Configuration:** Automatically finds the full path to your script's executable (e.g., `deno`, `node`, `python`) to avoid common `systemd` `PATH` issues.

## Prerequisites

-   A Linux distribution that uses `systemd` (e.g., Debian 10+, Ubuntu 16.04+, CentOS 7+, Arch Linux).
-   `sudo` or root access to install the script and manage services.
-   `curl` to use the installer.

---

## Installation

You can install `pm2alt` with a single command. It will download the script to `/usr/local/bin/pm2alt` and make it executable.

```bash
curl -sL https://raw.githubusercontent.com/controlx-io/bash-utils/refs/heads/main/pm2alt_install.sh | sudo -E bash -
```

## How to Use

All commands must be run with `sudo` because they interact with the `systemd` daemon.

### Starting an Application

The `start` command creates a new `systemd` service, enables it to start on boot, and starts it immediately.

```bash
sudo pm2alt start -n <app-name> -s "<command>" [options]
```

**Arguments:**

-   `-n, --name`: **(Required)** A unique name for your service (e.g., `my-api`).
-   `-s, --script`: **(Required)** The full command to run your app, enclosed in quotes.
-   `-u, --user`: The Linux user to run the process as (default: `nodeapp`).
-   `-w, --cwd`: The working directory for your application (default: the current directory).

**Example (Deno):**

```bash
sudo pm2alt start -n my-deno-app -s "/home/nodeapp/.deno/bin/deno run --allow-net server.ts" -u nodeapp -w /home/nodeapp/my-project
# as above, if the deno binary is not in the PATH of the current user, you can specify the full path to the deno executable
```

**Example (Node.js):**

```bash
sudo pm2alt start -n my-node-app -s "node index.js" -u www-data -w /var/www/my-app
```

### Checking Status

To see the status of a specific service, including whether it's active, its PID, and recent logs:

```bash
sudo pm2alt status my-deno-app
```

To see the status of all `systemd` services, run it without a name:
```bash
sudo pm2alt status
```

### Viewing Logs

To view the live logs for an application (similar to `pm2 logs`):

```bash
sudo pm2alt logs my-deno-app
```
(Press `Ctrl+C` to exit the log stream).

### Restarting an Application

To restart a running service:

```bash
sudo pm2alt restart my-deno-app
```

### Stopping an Application

The `stop` command will stop the service, disable it from starting on boot, and give you the option to permanently delete its `.service` configuration file.

```bash
sudo pm2alt stop my-deno-app
```

You will be prompted to confirm the deletion of the service file.

---

## How it Works

The `pm2alt` script is a wrapper that constructs and manages `systemd` unit files (`.service` files) in `/etc/systemd/system/`.

-   `pm2alt start` generates a `.service` file with the parameters you provide and uses `systemctl` to enable and start it.
-   All other commands (`stop`, `restart`, etc.) are convenient shortcuts for their `systemctl` equivalents (`systemctl stop`, `systemctl restart`, etc.).
-   Logs are automatically handled by `journald`, which is the standard `systemd` logging daemon.

This approach gives you the simplicity of `pm2` while using the robust, native process management tools of your operating system.
