if [ ! -e ___TARGET_PATH___ ]; then
    exit 71;
fi;

if [ ! -d ___TARGET_PATH___ ]; then
    exit 72;
fi;

if [ ! -r ___TARGET_PATH___ ]; then
    exit 73;
fi;

if [ ! -x ___TARGET_PATH___ ]; then
    exit 74;
fi;

exec find ___TARGET_PATH___ ___FIND_PARAMETERS___ 2> /dev/null < /dev/null;
