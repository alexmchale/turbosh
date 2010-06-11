# EXIT CODES
# 71 = Path does not exist.
# 72 = Path is not a directory.
# 73 = Path is unreadable.

TARGET_PATH=___TARGET_PATH___
FIND_PARAMETERS=___FIND_PARAMETERS___

if [ ! -e "$TARGET_PATH" ]; then
    exit 71
fi

if [ ! -d "$TARGET_PATH" ]; then
    exit 72
fi

if [[ ! -r "$TARGET_PATH" || ! -x "$TARGET_PATH" ]]; then
    exit 73
fi

exec find "$TARGET_PATH" $FIND_PARAMETERS 2> /dev/null < /dev/null
