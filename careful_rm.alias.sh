#######################################################################
#              careful_rm aliases for sh, bash, and zsh               #
#######################################################################

# Get PATH to the careful_rm.py python script, works with sh, bash, zsh,
# and dash
if [ -n "${ZSH_VERSION}" ]; then
    SOURCE="$0:A"
elif [ -n "${BASH_SOURCE}" ]; then
    SOURCE="${BASH_SOURCE}"
elif [ -f "$0" ]; then
    SOURCE="$0"
else
    SOURCE="$_"
fi
# resolve $SOURCE until the file is no longer a symlink
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  # if $SOURCE was a relative symlink, we need to resolve it relative to the
  # path where the symlink file was located
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
CAREFUL_RM_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# Try to use our version first
CAREFUL_RM="${CAREFUL_RM_DIR}/careful_rm.py"

# Just use the python that is globally available.
_PY="python"
_pyver=$(${_PY} --version 2>&1 | sed 's/.* \([0-9]\).\([0-9]\).*/\1\2/')
if [[ _pyver -lt 26 ]]; then
  echo "[careful_rm] Fatal error: No compatible python was found!"
  return 1
  exit 1
fi

# Only use our careful_rm if it exists, if not, try for a version on the
# PATH, failing that, fall back to rm -I
_USE_PIP=0
if [ ! -f "${CAREFUL_RM}" ]; then
    # Installed by pip
    if hash careful_rm 2>/dev/null; then
        _USE_PIP=1
        CAREFUL_RM="$(command -v careful_rm)"
    # Installed directly
    elif hash careful_rm.py 2>/dev/null; then
        CAREFUL_RM="$(command -v careful_rm.py)"
    else
        CAREFUL_RM=""
    fi
fi

# Set the aliases
if [ -z "${_USE_PIP}" ]; then
    alias rm="${CAREFUL_RM}"
    alias trash_dir="${CAREFUL_RM} --get-trash \${PWD}"
elif [ -f "${CAREFUL_RM}" ]; then
    alias rm="${_PY} ${CAREFUL_RM}"
    # Alias careful_rm if it isn't installed via pip already
    if ! hash careful_rm 2>/dev/null; then
        alias careful_rm="${_PY} ${CAREFUL_RM}"
    fi
    alias trash_dir="${_PY} ${CAREFUL_RM} --get-trash \${PWD}"
else
    echo "careful_rm.py is not available, using regular rm"
    alias rm="rm -I"
fi

unset _PY _USE_PIP _pth _pos_paths _pyver

export CAREFUL_RM CAREFUL_RM_DIR
