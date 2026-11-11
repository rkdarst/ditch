# ditch: simple AI agent isolation with Apptainer

A simpler way to isolate AI agent tools.  It's designed for simplicity
and no configuration being needed.

This (code + documentation) is fully human-written with minor machine
review advice.

## Usage

It has the following layers:

1. A docker image with many agents pre-installed.  This is not made as
   part of ditch, but it is part of moat (which has many more
   options).

2. Wrapper script that will automatically download images (if needed)
   and set up the right Apptainer options to isolate `$PWD` and set up
   a fake shared `$HOME` directory (shared across projects).

3. The user specifies what they want to run with command line
   arguments:

   * `ditch.sh` - run bash (lets you understand the container runtime)
   * `ditch.sh omp` - run omp
   * `ditch.sh codium --wait .` - run VSCodium.



## Limitations

These can be fixed if someone requests

* A fake `$HOME` (`~/.moat/home/`) is shared across all projects,
  which can make cross-project leakage.  This is designed so that you
  can configure agents once, but introduces at least some risk.
* There is a separate `$XDG_RUNTIME_DIR` for each invocation.  This
  allows parallel agents to not interact (e.g. multiple VSCodiums),
  which may or may not be what you want.
* The `moat` version and download locations are hard-coded and should
  be made flexible.


To-do:

* Option for per-project fake home
* ~~Investigate --containall~~
* --no-home or --home-ro options.
* ~~--ro, --ro-home, and --ro-pwd options.~~ Implemented but can break
  certain agents.  I will investigate more if someone asks.

## See also

* Moat <https://github.com/AaltoRSE/moat>: more heavyweight,
  cross-platform solution.  This uses the `moat` container.
* venv-apptainer <https://github.com/rkdarst/venv-apptainer>: similar
  concept but designed for building Python and conda environments
  isolated from the world.
