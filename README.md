# Teamspeak for ARM

This repository contains changes to the official Docker image of Teamspeak that
will use `qemu` to make it runnable on a Raspberry PI.

It is using the same entrypoint as the official container from
https://hub.docker.com/_/teamspeak, but is using a `Debian` as a baseimage for
using `qemu` and multiarch.

Some changes to the `alpine` image based `entrypoint.sh` were needed, as the
behavior of some tools differs:

- `sudo` will not keep environment variables from the original shell: preserving
  them requires using `--preserve-env`
