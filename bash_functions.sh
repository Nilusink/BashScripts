#!/bin/sh

export CLR_RESET='\033[1;0m'
export STL_BOLD='\033[1;1m'
export CLR_RED='\033[0;31m'
export CLR_GREEN='\033[0;32m'
export CLR_BLUE='\033[0;34m'


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
        echo "#include <stdio.h>\n\n\nvoid main()\n{\n\tprintf(\"hello world!\");\n}\n" > "$TMPMAIN"
    else
        echo "#include <iostream>\n\n\nint main()\n{\n\tstd::cout << \"hello world!\\\n\";\n\treturn 0;\n}\n" > "$TMPMAIN"
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

