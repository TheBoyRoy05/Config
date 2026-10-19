# Config

My settings for git, VS Code-style editors, Obsidian and macOS, plus a script that sets up a new machine / OS from them.

## Setup

Clone this repo over HTTPS into the folder that should hold all your repos, then run the setup script:

```sh
mkdir -p ~/Work && cd ~/Work
git clone https://github.com/TheBoyRoy05/Config.git
./Config/setup.sh
```

The script asks for a machine name, which labels this machine's vault backup commits. If GitHub does not accept an SSH key from this machine yet, it creates one, prints it, and waits while you add it at [GitHub SSH keys](https://github.com/settings/ssh/new). Then it switches this repo's remote to SSH and clones the vault next to it.

Setup is an idempotent operation.
