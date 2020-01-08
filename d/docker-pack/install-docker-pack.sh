#!/bin/sh -e

GOROOT="/usr/lib64/go1.11.4/go"
PATH="$GOROOT/bin:$PATH"
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

exit 0

removepkg libseccomp || true
cd libseccomp
OUTPUT=`pwd` buildpkg libseccomp.SlackBuild
installpkg ./libseccomp-*t?z
cd ..

removepkg runc || true<F2>
cd runc
OUTPUT=`pwd` buildpkg runc.SlackBuild
installpkg ./runc-*t?z
cd ..

removepkg containerd || true
cd containerd
OUTPUT=`pwd` buildpkg containerd.SlackBuild
installpkg ./containerd-*t?z
cd ..

removepkg tini || true
cd tini
OUTPUT=`pwd` buildpkg tini.SlackBuild
installpkg ./tini-*t?z
cd ..

removepkg docker-proxy || true
cd docker-proxy
OUTPUT=`pwd` buildpkg docker-proxy.SlackBuild
installpkg ./docker-proxy-*t?z
cd ..

removepkg docker || true
cd docker
OUTPUT=`pwd` buildpkg docker.SlackBuild
installpkg ./docker-*t?z
cd ..
