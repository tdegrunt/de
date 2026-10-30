# de

Development environments: every checkout of a repository, the main one and
each git worktree, runs in its own devcontainer on OrbStack, with its own
services, volumes and network. Nothing is shared between environments, so
several branches can run their tests at the same time.

This repository is the source of truth for `bin/de`, the script that manages
them, and the template a repository starts from. Each repository gets its own
copy of `bin/de`, so it works for everyone who checks it out, in every
worktree and from editors, without this repository. What differs per
repository lives in its `.devcontainer/env.conf`, `docker-compose.yml`,
`devcontainer.json` and `postStart.sh`.

## Worktrees

What are worktrees? Git has a really good [documentation on worktrees](https://git-scm.com/docs/git-worktree). In short, a worktree allows you to have multiple working directories for the same repository, each checked out to a different branch. This is useful for working on multiple branches simultaneously without having to constantly switch branches in a single working directory.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/tdegrunt/de/main/install.sh | sh
```

This clones the repository to `~/.local/share/de` (`DE_HOME`), or updates it
when it's already there, and links `~/.local/bin/de` (`BIN_DIR`) to its
`bin/de`. Arguments go on to `de`, so this also sets up the repository you're
in:

```sh
curl -fsSL https://raw.githubusercontent.com/tdegrunt/de/main/install.sh | sh -s -- init
```

Working on de itself, link your own checkout instead:
`ln -sfn ~/Developer/entdec/de/bin/de ~/.local/bin/de`.

`~/.local/bin` has to be on your PATH, e.g. in `~/.zshrc`:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

`de` then sets repositories up, and runs any other command with the `bin/de`
of the checkout you're in: `de up`, `de exec bin/rails test`, `de code main`.
That replaces an alias like `alias de='"$(git rev-parse --show-toplevel)/bin/de"'`:
remove it, as an alias takes precedence over the PATH. A shorthand to open a
checkout in VS Code still works as `alias vc='de code'` (`vc main`).

Needs OrbStack, Node (for `npx @devcontainers/cli`, unless `devcontainer` is
installed), Git 2.48 or later, and jq when you have a
`~/.config/de/config.json`.

## Setting up a repository

```sh
de init ~/code/myapp    # or `de init` from inside it
```

- Always updated: `bin/de`. Don't change it in a repository, change it here
  and run `de init` there again.
- Copied once, then the repository's own: everything in
  [template/](template/), `.devcontainer/` (`env.conf`, `devcontainer.json`,
  `docker-compose.yml`, `postStart.sh`), `.worktreeinclude` and `orca.yaml`.
  `--force` replaces them with the template again. `@REPO@` becomes the
  repository's name, `@UP_COMMAND@` how it prepares its test database.
- `.devcontainer/.env`, `.devcontainer/de-host/` and `mise.local.toml` are
  added to its `.gitignore`.

Then adapt, commit, and `bin/de up`:

- `env.conf`: `ENV_REPO`, `PERSISTENT_BRANCHES`, `PRIMARY_BRANCHES`,
  `SELENIUM_URL` and `UP_COMMAND`.
- `docker-compose.yml`: the services. Keep the `x-env-labels` anchor on every
  service, volume and network, the two `/workspaces` mounts of the `app`
  service, and `restart: ${ENV_RESTART:-no}`.
- `devcontainer.json`: the features. Keep `./de-host`, `initializeCommand`
  and `workspaceFolder`.
- `postStart.sh`: how the app installs its dependencies and prepares its
  databases.

## Kinds

The branch decides the kind (`PRIMARY_BRANCHES` and `PERSISTENT_BRANCHES` in
`env.conf`):

- **Persistent**: the primary branches `main` and `master`, and e.g.
  `staging` and `develop`. Their data survives restarts and `bin/de down`,
  and `bin/de prune` never touches them.
- **Ephemeral**: any other branch. They start from an empty database, filled
  only from the repository's schema, migrations and seeds, and are removed
  completely when the worktree is done.

An environment is named `<repo>-<branch>` (`ENV_REPO` in `env.conf`, the
branch lowercased with anything but letters, digits and dashes replaced), e.g.
`myapp-fix-login`, or just `<repo>` for a primary branch, e.g. `myapp`, which
makes the app `app.myapp.orb.local`. That's its Docker Compose project, and
every container, volume and network carries the labels `dev.env.name`,
`dev.env.kind`, `dev.env.branch`, `dev.env.path` and `dev.env.gitdir`.
Cleanup selects by these labels only. Services are reachable from the Mac as
`<service>.<env>.orb.local`, e.g. `postgres.myapp-fix-login.orb.local:5432`;
no host ports are published.

## Commands

| Command | |
| --- | --- |
| `bin/de new <branch>` | Create a worktree next to the main checkout (`<repo>-<branch>`) and start its environment. Existing local or remote branches are checked out, new ones start from the default branch (`--from <ref>` for another) |
| `bin/de up` | Create or start this checkout's environment and prepare its databases. `--rebuild` after changing `.devcontainer/` |
| `bin/de exec <cmd>` | Run a command in it, in the same directory relative to the checkout, e.g. `bin/de exec bin/rails test` |
| `bin/de status` | Name, kind, containers, health and URLs |
| `bin/de code [checkout]` | Open a checkout in VS Code inside its devcontainer, starting the environment first if needed. Takes a branch, environment name or worktree folder. `CODE=cursor` for another editor |
| `bin/de down` | Ephemeral: remove it with its data. Persistent: stop it, keeping the data (`--destroy-persistent` deletes it after typing the name) |
| `bin/de prune` | Remove ephemeral environments whose worktree or branch is gone (`--yes` skips the prompt) |

`de <command>` does the same from anywhere inside a checkout. Every command
prints the docker and devcontainer commands it runs.

## Worktrees and folder layout

Worktrees can live next to the main checkout or anywhere else, e.g.

```
~/code/myapp                     main checkout (main, persistent)
~/code/myapp-develop             worktree (develop, persistent)
~/workspaces/myapp/<name>        other worktrees (ephemeral)
```

Inside the container a checkout is mounted at `/workspaces/<host path>`,
together with the repository's `.git`, and `/workspaces/<repo>` links to it.
Worktrees use relative paths (`git config worktree.useRelativePaths true`,
set by `bin/de up`), so their `.git` link resolves inside the container too.

To make worktrees with plain git:

```sh
bin/de new fix-login     # git worktree add ../myapp-fix-login + bin/de up
cd ../myapp-fix-login
bin/de exec bin/rails test
bin/de code              # open in VS Code
bin/de down && cd - && git worktree remove ../myapp-fix-login
bin/de prune             # catches anything removed without bin/de down
```

`git worktree add` followed by `bin/de up` works the same.

## Local files and secrets

Ignored files listed in `.worktreeinclude`, like `.envrc` and
`mise.local.toml`, are copied (never linked) from the main checkout into new
worktrees by `bin/de up`. Secrets the container needs, such as a package
registry token for `bundle install`, go in `mise.local.toml`:

```toml
[env]
BUNDLE_RUBYGEMS__PKG__GITHUB__COM = "..."
```

## System tests

System tests use the environment's own headless Selenium container
(`SELENIUM_URL` in `env.conf`). To watch a failing test in a browser on the
Mac, start a Selenium there and override it for one command:

```sh
SELENIUM_URL=http://host.docker.internal:4444/ HEADLESS=0 bin/de exec bin/rails test:system
```

## Your own tools

Tools you want in every environment of every repository, but that aren't a
repository's business, such as coding agents, go in `~/.config/de/config.json`
on the Mac (`DE_CONFIG` for another file), see
[config.example.json](config.example.json):

```json
{
  "extensions": ["anthropic.claude-code", "openai.chatgpt", "kilocode.kilo-code"],
  "npm": ["@anthropic-ai/claude-code", "@openai/codex", "@kilocode/cli"],
  "features": {}
}
```

- `extensions`: editor extensions, installed in the container by VS Code or
  Cursor whoever starts it.
- `npm`: packages installed globally into the image, so their commands work
  in every terminal and with `bin/de exec`.
- `features`: more devcontainer features, as in `devcontainer.json`.

`bin/de initialize` turns it into a local feature, `.devcontainer/de-host/`
(ignored), which `devcontainer.json` includes as `./de-host`. Without the file
the feature installs nothing. It's part of the image, so a change applies
after `bin/de up --rebuild`, which keeps the data.
