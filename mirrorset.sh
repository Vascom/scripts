#!/bin/bash

# Change this to your preferred mirror URL
mirror="https://mirror.karneval.cz/pub/linux"
mirror_rpmfusion="https://mirror.karneval.cz/pub/linux/rpmfusion"

# Repositories to change
main_repos="fedora fedora-updates fedora-updates-testing"
rpmfusion_repos="rpmfusion-free rpmfusion-free-updates rpmfusion-free-updates-testing \
rpmfusion-nonfree rpmfusion-nonfree-updates rpmfusion-nonfree-updates-testing"

# Don't need to change values by default
pre_mirror="http://download.example/pub"
pre_mirror_rpmfusion="http://download1.rpmfusion.org"

meta0="metalink"
meta1="#metalink"
base0="#baseurl"
base1="baseurl"

function repo_url_replace(){
    if [ -z "$1" ] || [ -z $2 ] || [ -z $3 ]
    then
        echo "Some parameters is abscent. Exit now"
        exit 1
    fi

    if [ "$action" = "devset" ] || [ "$action" = "devunset" ]
    then
        if [ "$action" = "devset" ]
        then
            start="releases"
            end="development"
        elif [ "$action" = "devunset" ]
        then
            start="development"
            end="releases"
        fi

        for repo in $1
        do
            sed -i "s|$start|$end|" /etc/yum.repos.d/$repo.repo
        done
        break
    fi

    local pre_mirror=$2
    local mirror=$3
    local pre_meta=$meta0
    local meta=$meta1
    local pre_base=$base0
    local base=$base1
    if [ "$action" = "unset" ]
    then
        pre_mirror=$3
        mirror=$2
        pre_meta=$meta1
        meta=$meta0
        pre_base=$base1
        base=$base0
    fi

    for repo in $1
    do
        sed -i -e"s|^$pre_meta|$meta|" \
        -e "s|^$pre_base|$base|" \
        -e "s|baseurl=$pre_mirror|baseurl=$mirror|" \
        /etc/yum.repos.d/$repo.repo
    done
}

case "$1" in
    "set")      action="set";;
    "unset")    action="unset";;
    "devset")   action="devset";;
    "devunset") action="devunset";;
    *)          echo -e "Use:
                \r  set     Set new URL as baseurl.
                \r  unset   Set mirrorlist as default."
                exit 0
esac

repo_url_replace "$main_repos" $pre_mirror $mirror
repo_url_replace "$rpmfusion_repos" $pre_mirror_rpmfusion $mirror_rpmfusion
