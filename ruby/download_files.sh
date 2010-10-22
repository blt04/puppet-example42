#!/bin/sh

cd `dirname $0`

mkdir -p files

if [ -e /usr/bin/wget ]; then
    /usr/bin/wget -nc -nd -P files/ http://rubyforge.org/frs/download.php/71098/ruby-enterprise_1.8.7-2010.02_amd64_ubuntu10.04.deb

else
    echo "Please install wget!"
    exit 1
fi
