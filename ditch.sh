#!/bin/bash

declare -a RUN_ARGS
declare -a BINDS

IMG_SOURCE=docker://ghcr.io/aaltorse/moat:v0.4.0
IMG="$HOME"/sys/moat-0.4.0.sif

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            cat <<EOF
ditch.sh [options] [RUN_ARGUMENTS ...]

Run the moat Apptainer image quickly and without configuration,
isolating $PWD and using fake home directory (note: the fake home is
shared across projects and persistent).  RUN_ARGUMENTS should be used
to specified what you want to run (e.g. opencode, codex, codium --wait
., etc.).  It is up to you to configure the agent to connect where you
want.

Options must preceed RUN_ARGUMENTS (and -- options/values must be separated by a space, not '=')

RUN_ARGUMENTS  Run these commands in the container.  Specify the agent
               you want by command line name.  If not given, runs bash
               inside the container so you can see how it's set up.
--ro           Read-only $PWD and fake $HOME
--ro-pwd       Read-only $PWD
--ro-home      Read only fake $HOME (may not work for all agents)
--ro-git       Read-only $PWD/.git
--img IMG.sif  Override apptainer image file
--bind BIND    Extra binds (may be given multiple times)
               Same format as apptainer.  Must be absolute path.
--bind-ro BIND Like above but expanded to BIND:BIND:ro
--verbose      Run with set -x

EOF
            exit 0
            ;;
        --verbose)    set -x ;                             shift   ;;
        --img)        IMG="$2";
                      if [ ! -e "$IMG" ] ; then echo "not present: $IMG" ; exit 1 ; fi ;
                                                           shift 2 ;;
        --ro)         DITCH_RO_HOME=1 ; DITCH_RO_PWD=1 ;   shift 1 ;;
        --ro-home)    DITCH_RO_HOME=1 ;                    shift 1 ;;
        --ro-pwd)     DITCH_RO_PWD=1 ;                     shift 1 ;;
        --ro-git)     DITCH_RO_GIT=1 ;                     shift 1 ;;
        --bind)       BINDS+=("${2}") ;                    shift 2 ;;
        --bind-ro)    BINDS+=("${2}:${2}:ro") ;            shift 2 ;;
        *)            RUN_ARGS+=("$@") ;                   break   ;;
    esac
done

if [ "$PWD" = "$HOME" ] ; then
    echo "\$PWD is currently \$HOME, refusing to run like this."
    exit 1
fi


if test ! -e "$IMG" ; then
    apptainer pull "${IMG}" "${IMG_SOURCE}"
    ret=$?
    if [ $ret -ne 0 ] ; then
        echo "Failed pulling ${IMG_SOURCE} to ${IMG}"
        exit 1
    fi
fi


MOAT_HOME=$HOME/.moat/home/
# Must make mountpoint for $PWD within the fake home
mkdir -p "$MOAT_HOME"/"$(realpath "$PWD" --relative-to "$HOME")"

# Options for read-only $PWD and $HOME
if [ -n "$DITCH_RO_PWD" ] ; then
    BINDS+=("${PWD}:${PWD}:ro")
else
    BINDS+=("${PWD}:${PWD}")
fi
if [ -n "$DITCH_RO_HOME" ] ; then
    BINDS+=("${MOAT_HOME}:${HOME}/:ro")
else
    BINDS+=("${MOAT_HOME}:${HOME}/")
fi
if [ -n "$DITCH_RO_GIT" ] ; then
    BINDS+=("${PWD}/.git/:${PWD}/.git/:ro")
fi

# Other binds
BINDS+=("/tmp/.X11-unix/")

apptainer exec \
          --containall --writable-tmpfs \
	  --env LANG=C --env LC_ALL=C \
          --env XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
          --env DISPLAY="$DISPLAY" \
          --cwd "$PWD" \
          "${BINDS[@]/#/--bind=}" \
          "$IMG" \
          bash -c "source /opt/nvm/nvm.sh ; mkdir -p \"\$XDG_RUNTIME_DIR\" ; chmod 700 \"\$XDG_RUNTIME_DIR\" ; \${@:-bash}" "[in-container]" "${RUN_ARGS[@]}"
