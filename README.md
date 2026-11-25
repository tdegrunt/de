# de

A share-nothing development environment for every git worktree.

Each checkout of a repository, the main one and every
[worktree](https://git-scm.com/docs/git-worktree), runs in its own
devcontainer with its own database, services, volumes and network. Nothing is
shared, so you can work on, and run the tests of, several branches at once.

- `de procs` runs all your app's processes (`Procfile.dev`) in the container.
- `de code` opens the checkout in VS Code inside the same container, if you
  want an editor too.

## Install

Needs Docker ([OrbStack](https://orbstack.dev) recommended), Node and Git
2.48 or later.

```sh
curl -fsSL https://raw.githubusercontent.com/tdegrunt/de/main/install.sh | sh
```

Make sure `~/.local/bin` is on your PATH, then set up a repository:

```sh
de init ~/code/myapp    # or `de init` from inside it
```

Adapt the files it adds in `.devcontainer/` to your app, commit them, and
start with `de up`.

## Commands

| Command | |
| --- | --- |
| `de new <branch>` | Create a worktree for a branch and start its environment. `--copy-data` starts it with a copy of the data of the environment it branches off |
| `de up` | Create or start this checkout's environment. `--rebuild` after changing `.devcontainer/` |
| `de exec <cmd>` | Run a command in it, e.g. `de exec bin/rails test` |
| `de kamal <args>` | Run the checkout's `bin/kamal` in it, e.g. `de kamal deploy -d staging`, with a Docker config of its own |
| `de procs` | Run the processes from `Procfile.dev` in [mprocs](https://github.com/pvolok/mprocs), each in the container |
| `de code [checkout]` | Open a checkout in VS Code inside its devcontainer (`CODE=cursor` for another editor) |
| `de start` | `de code`, then `de procs` |
| `de site [subdomain]` | Open the app in a browser |
| `de db [database]` | Open the database in your database app, e.g. TablePlus, as `config/database.yml` connects to it |
| `de status` | Name, kind, containers, health and URLs |
| `de down` | Remove an ephemeral environment, or stop a persistent one (`main`, `develop`, …) keeping its data |
| `de prune` | Remove environments whose worktree or branch is gone |
| `de init [repo]` | Set up a repository |
| `de update [repo]` | Update a repository's `bin/de` |
| `de upgrade` | Update de itself |

Each repository gets its own copy of the script as `bin/de`, so
`bin/de <command>` works too, without de installed.

## More

Setting up a repository, persistent and ephemeral environments, copying data,
secrets, system tests and your own tools in every environment: see
[docs/details.md](docs/details.md).

## License

MIT, see [LICENSE](LICENSE).
