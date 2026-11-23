#!/bin/sh
# Installs or updates de: clones this repository to DE_HOME (default
# ~/.local/share/de), or pulls it when it's already there, and links its
# bin/de to ~/.local/bin/de. Arguments are passed on to de, e.g. to set up
# the repository you're in:
#
#   curl -fsSL https://raw.githubusercontent.com/tdegrunt/de/main/install.sh | sh -s -- init
set -eu

DE_HOME="${DE_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/de}"
DE_REPO="${DE_REPO:-https://github.com/tdegrunt/de.git}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

command -v git >/dev/null 2>&1 || die "de needs git"

if [ -d "$DE_HOME/.git" ]; then
  log "Updating $DE_HOME"
  git -C "$DE_HOME" pull --ff-only --quiet
else
  [ ! -e "$DE_HOME" ] || die "$DE_HOME exists but isn't a git checkout"
  log "Cloning $DE_REPO to $DE_HOME"
  git clone --quiet "$DE_REPO" "$DE_HOME"
fi

mkdir -p "$BIN_DIR"
if [ -e "$BIN_DIR/de" ] && [ ! -L "$BIN_DIR/de" ]; then
  die "$BIN_DIR/de exists and isn't a link, remove it first"
fi
ln -sfn "$DE_HOME/bin/de" "$BIN_DIR/de"
log "Linked $BIN_DIR/de to $DE_HOME/bin/de"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) printf '\033[1;33mwarning:\033[0m %s is not on your PATH\n' "$BIN_DIR" >&2 ;;
esac

if [ "$#" -gt 0 ]; then
  exec "$DE_HOME/bin/de" "$@"
fi
log "Done, run de init in a repository to set it up"
