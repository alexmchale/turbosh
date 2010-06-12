# EXIT CODES
# 71 = Path does not exist.
# 72 = Path is not a directory.
# 73 = Path is unreadable.

ROOT_PATH=___ROOT_PATH___

if [ ! -e "$ROOT_PATH" ]; then
    exit 71
fi

if [ ! -d "$ROOT_PATH" ]; then
    exit 72
fi

if [[ ! -r "$ROOT_PATH" || ! -x "$ROOT_PATH" ]]; then
    exit 73
fi

if [ -f "~/.turbosh" ]; then
    . ~/.turbosh > /dev/null 2>&1
fi

cd $ROOT_PATH
exec ___COMMAND___ < /dev/null
