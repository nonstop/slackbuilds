#!/bin/sh -e

function die
{
    echo $1
    echo 1
}

ls -l /var/log/packages/ | grep -q gcc-go && die "gcc-go should be uninstalled"

if [ -z "$GOROOT" ]; then
    . /etc/profile.d/go.sh
fi
OUTPUT=/tmp

settings_file=$HOME/.buildpkg
if [ -f "$settings_file" ]; then
    source "$settings_file"
fi
TAG=_evgeny

function build__
{
    removepkg $1 || true
    cd $1
    OUTPUT=`pwd` ./$1.SlackBuild
    /sbin/installpkg ./$1-*t?z
    cd ..
}

build__ tini
build__ runc
build__ containerd
build__ docker-proxy
build__ docker
build__ docker-cli
