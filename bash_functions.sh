#!/bin/sh

export CLR_RESET='\033[1;0m'
export STL_BOLD='\033[1;1m'
export CLR_RED='\033[0;31m'
export CLR_GREEN='\033[0;32m'
export CLR_BLUE='\033[0;34m'

export FUNCTION_ASSETS_DIR="$(echo ~)/bash_scripts/presets"  # replace with your path
export PYTHON_PROJECTS_DIR="$(echo ~)/PycharmProjects"  # replace with your path


function cl()
{
    # change and list directory
    DIR="$*";
    # if no DIR given, go home
    if [ $# -lt 1 ]; then
        DIR=$HOME;
    fi;
    builtin cd "${DIR}" && ls
}


function mkcd()
{
    # make directory and cd into it
    DIR="$*";
    mkdir "${DIR}" && cd "${DIR}"
}


function mdreader()
{
    # read a MARKDOWN-formatted file
    FILE="$*";
    pandoc "${FILE}" | lynx -stdin
}


function cppshell()
{
    # creates an IDE-like envoirement for quick C / C++ testing
    TMPDIR="$(mktemp -d)"

    if [ "$1" = "-c" ]
    then
        ISC=true;
    else
        ISC=false;
    fi

    printf "${CLR_BLUE}${STL_BOLD}::${CLR_RESET} setting up environment...\n"

    if [ $ISC = true ]
    then
        printf "${CLR_BLUE}${STL_BOLD}::${CLR_RESET} selected language: ${CLR_GREEN}C${CLR_RESET}, using ${CLR_GREEN}gcc${CLR_RESET}\n"
        TMPMAIN="src/main.c"
    else
        printf "${CLR_BLUE}${STL_BOLD}::${CLR_RESET} selected language: ${CLR_GREEN}C++${CLR_RESET}, using ${CLR_GREEN}g++${CLR_RESET}\n"
        TMPMAIN="src/main.cpp"
    fi

    TMPEXEC="bin/main"
    COMPFILE="./compile_and_run.bash"
    alias="$COMPFILE"

    # setup envoirement
    cd "$TMPDIR"
    mkdir "src"
    mkdir "bin"
    touch "$TMPMAIN"

    # create compile file because I'm sure I will forget the command
    echo "#!/bin/sh" >> $COMPFILE
    echo "echo \"$CLR_BLUE::$CLR_RESET compiling...\"" >> $COMPFILE

    # configure compiler (gcc or g++)
    if [ $ISC = true ]
    then
	    echo "gcc \"$TMPMAIN\" --output \"$TMPEXEC\"" >> "$COMPFILE"
    else
        echo "g++ \"$TMPMAIN\" --output \"$TMPEXEC\" -std=c++17" >> "$COMPFILE"
    fi

    echo "chmod +X \"$TMPEXEC\"" >> $COMPFILE
    echo "echo \"$CLR_BLUE::$CLR_RESET done! \\n\"" >> $COMPFILE
    echo "$TMPEXEC" >> $COMPFILE

    chmod +x $COMPFILE

    # write default to file
    if [ $ISC = true ]
    then
        cat "$FUNCTION_ASSETS_DIR/default.c" > "$TMPMAIN"
    else
        cat "$FUNCTION_ASSETS_DIR/default.cpp" > "$TMPMAIN"
    fi

    # open in editor
    printf "${CLR_GREEN}->${CLR_RESET} opening editor\n"
    nvim "$TMPMAIN"

    $COMPFILE
}


function install_tar()
{
    # compile and install a .tar.gz package
    FILE="$1"

    TMPDIR="$(mktemp -d)"
    cp "$FILE" "$TMPDIR"
    cd "$TMPDIR"

    tar -zxvf "$FILE" -C ./
    rm "$FILE"
    
    DIREC="$(ls)"
    cd "$DIREC"

    makepkg -si
}


function pproject()
{
    # help menu
    if [ "$1" = "-h" ]
    then
        echo "pproject [-h] <project_name> <python_path>"
	return
    fi;

    local PNAME="$1"
    local PYVER=""
    local PPATH="$PYTHON_PROJECTS_DIR"

    while getopts ":n:d:e:" option; do
        case $option in
            n)
                PNAME="$OPTARG"
		;;
            d)
		PPATH="$OPTARG"
		;;
	    e)
		PYVER="$OPTARG"
		;;
	    *)
		echo "Usage: $0 [-n project_name] [-d project_directory] [-e python_executable]"
		exit 1
		;;
	esac
    done
                
                

    # check if python path is given 
    if [ "$PYVER" = "" ]
    then
        local PYPATH="$(where python3 | head -n 1)"
    else
        local PYPATH="$PYVER"
    fi;

    printf "${CLR_BLUE}::${CLR_RESET} python version: ${CLR_GREEN}$($PYPATH --version)${CLR_RESET}\n"
 
    # get project directory
    local PPATH="$PPATH/$PNAME"
    printf "${CLR_BLUE}::${CLR_RESET} creating ${CLR_GREEN}${PPATH}${CLR_RESET}\n"

    # create directory + files
    mkdir "$PPATH"

    ## venv
    printf "${CLR_BLUE}::${CLR_RESET} creating venv ...\r"
    "$PYPATH" -m venv "$PPATH/venv"
    printf "${CLR_BLUE}::${CLR_RESET} creating venv ${CLR_GREEN}done${CLR_RESET}\n"
    printf "${CLR_BLUE}::${CLR_RESET} activating venv ...\r"
    source "$PPATH/venv/bin/activate"
    printf "${CLR_BLUE}::${CLR_RESET} activating venv ${CLR_GREEN}done${CLR_RESET}\n"


    ## main.py
    printf "${CLR_BLUE}::${CLR_RESET} creating files ...\r"
    printf "#! venv/bin/python\n" > "$PPATH/main.py"
    chmod ug+x "$PPATH/main.py"

    ## requirements syncer
    echo '#! /usr/bin/zsh\necho "${$(pip freeze)//==/~=}" > requirements.txt' > "$PPATH/sync_requirements"
    chmod ug+x "$PPATH/sync_requirements" 

    ## other files
    touch "$PPATH/requirements.txt"

    printf "${CLR_BLUE}::${CLR_RESET} creating files ${CLR_GREEN}done${CLR_RESET}\n"

    # change into directory
    cd "$PPATH"
}
