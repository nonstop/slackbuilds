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

function build__
{
    removepkg $1 || true
    cd $1
    OUTPUT=`pwd` buildpkg $1.SlackBuild
    installpkg ./$1-*t?z
    cd ..
}

build__ tini
build__ libseccomp
build__ runc
build__ containerd
build__ docker-proxy
build__ docker
