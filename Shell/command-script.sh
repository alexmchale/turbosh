if [ ! -e ___ROOT_PATH___ ]; then
    exit 71;
fi;

if [ ! -d ___ROOT_PATH___ ]; then
    exit 72;
fi;

if [[ ! -r ___ROOT_PATH___ || ! -x ___ROOT_PATH___ ]]; then
    exit 73;
fi;

if [ -f "~/.turbosh" ]; then
    . ~/.turbosh > /dev/null 2>&1;
fi;

cd ___ROOT_PATH___;
___COMMAND___
