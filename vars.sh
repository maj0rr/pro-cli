#!/usr/bin/env bash

# global pro-cli directory
PC_DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
# current pro-cli version
PC_VERSION=$(cd $PC_DIR && git describe --tags `git rev-list --tags --max-count=1`)
# name of the config file
PC_CONF_FILE="pro-cli.json"
# path to the local config file
PC_CONF="$WDIR/$PC_CONF_FILE"


# # # # # # # # # # # # # # # # # # # #
# output manipulation
RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
YELLOW="$(tput setaf 3)"
BLUE="$(tput setaf 4)"
BOLD="$(tput bold)"
NORMAL="$(tput sgr0)"
CLEAR_LINE="\r\033[K"


# # # # # # # # # # # # # # # # # # # #
# returns an attribute of the local config
get_conf() {
    if [ -f $PC_CONF ]; then
        echo $(cat $PC_CONF | jq -r ".$1")
    fi
}

PC_TYPE=$(get_conf 'type')
PC_ENV=$(get_conf 'env')


# # # # # # # # # # # # # # # # # # # #
# shows the help
help() {
    # path to local node_modules
    PC_NPM_CONFIG="$WDIR/src/package.json"
    # spaces until the commands descriptions starts
    SPACE="                      "

    printf "    ${BLUE}pro-cli ${BOLD}v${PC_VERSION}-beta${NORMAL}\n"
    printf "\n"
    printf "    help: project [command]\n"
    printf "\n"
    printf "    COMMANDS:\n"
    printf "        ${BLUE}self-update${NORMAL}${SPACE:11}Update pro-cli.\n"
    printf "        ${BLUE}init${NORMAL}${SPACE:4}Setup default project structure.\n"
    printf "        ${BLUE}install${NORMAL}${SPACE:7}Install application by executing the commands specified in ${BOLD}pro-cli.json${NORMAL}.\n"
    printf "        ${BLUE}update${NORMAL}${SPACE:6}Update project structure and docker images. ${YELLOW}Will overwrite pro-cli project files.${NORMAL}\n"
    printf "\n"

    # # # # # # # # # # # # # # # # # # # #
    # show docker commands help if local config file exists
    if [ -f $PC_CONF ]; then
        printf "    DOCKER COMMANDS:\n"
        printf "        ${BLUE}start${NORMAL}${SPACE:5}Start application.\n"
        printf "        ${BLUE}stop${NORMAL}${SPACE:4}Stop application.\n"
        printf "        ${BLUE}up${NORMAL}${SPACE:2}Start all docker containers and application.\n"
        printf "        ${BLUE}down${NORMAL}${SPACE:4}Stop and remove all docker containers. ${YELLOW}Removes mounted volumes${NORMAL}.\n"
        printf "        ${BLUE}compose${NORMAL}${SPACE:7}Run docker-compose commands.\n"
        printf "        ${BLUE}logs${NORMAL}${SPACE:4}Show application logs.\n"
        printf "        ${BLUE}status${NORMAL}${SPACE:6}List application containers and show the status.\n"
        printf "\n"
    fi

    # # # # # # # # # # # # # # # # # # # #
    # show PHP commands if the current project is of type laravel or PHP
    if [[ -f $PC_CONF && ( $PC_TYPE == "laravel" || $PC_TYPE == "php" )]]; then
        printf "    PHP COMMANDS:\n"
        printf "        ${BLUE}composer${NORMAL}${SPACE:8}Run composer commands.\n"
        printf "        ${BLUE}test${NORMAL}${SPACE:4}Run Unit Tests.\n"
        printf "\n"
    fi

    # # # # # # # # # # # # # # # # # # # #
    # show PHP commands if the current project is of type laravel
    if [ -f $PC_CONF ] && [[ $PC_TYPE == "laravel" ]]; then
        printf "    LARAVEL COMMANDS:\n"
        printf "        ${BLUE}artisan${NORMAL}${SPACE:7}Run artisan commands.\n"
        printf "        ${BLUE}tinker${NORMAL}${SPACE:6}Interact with your application.\n"
        printf "\n"
    fi

    # # # # # # # # # # # # # # # # # # # #
    # show npm commands help if package.json exists
    if [ -f $PC_NPM_CONFIG ]; then
        printf "    NODE COMMANDS:\n"
        printf "        ${BLUE}npm${NORMAL}${SPACE:3}Run npm commands.\n"
        printf "        ${BLUE}yarn${NORMAL}${SPACE:4}Run yarn commands.\n"
        printf "\n"
    fi

    # # # # # # # # # # # # # # # # # # # #
    # show custom commands help if the local config has scripts
    if [ -f "$WDIR/$PC_CONF_FILE" ]; then
        # fetch script keys
        COMMAND_KEYS=$(cat $WDIR/$PC_CONF_FILE | jq -crM '.scripts | keys[]')

        if [ ! -z "$COMMAND_KEYS" ]; then
            printf "    CUSTOM COMMANDS:\n"

            while read -r KEY; do
                # get the command by key selection
                COMMAND=$(cat $WDIR/$PC_CONF_FILE | jq -crM --arg cmd "$KEY" '.scripts[$cmd]')
                # string length
                COUNT=${#KEY}
                printf "        ${BLUE}${KEY}${NORMAL}${SPACE:$COUNT}${COMMAND}\n"
            done <<< "$COMMAND_KEYS"
        fi
    fi
}


# # # # # # # # # # # # # # # # # # # #
# initialize a project
# project init [path] [--type=TYPE]
init_project() {
    local TYPE="laravel"
    # supported types
    local TYPES=("php laravel")
    local DIR=$1

    shift

    # check for available parameters 
    for i in "$@"; do
        case $i in -t=*|--type=*)
            # save type parameter if available
            TYPE="${i#*=}"
            shift
            ;;
        esac
    done

    # check if type is actually supported
    if [[ ! " ${TYPES[@]} " =~ " ${TYPE} " ]]; then
        printf "${RED}Unsupported project type!${NORMAL}\n"
        exit
    fi

    mkdir -p $DIR

    git clone -q https://github.com/chriha/pro-php.git $DIR
    rm -rf $DIR/.git $DIR/README.md

    # create local config from template and set project type
    cat $PC_DIR/$PC_CONF_FILE | jq --arg PROJECT_TYPE $TYPE '.type = $PROJECT_TYPE' > $DIR/$PC_CONF_FILE
}
