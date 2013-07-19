#!/usr/bin/env bash

wdir=$(pwd -P)
bdir=$(readlink -f $(dirname $0))

echo "Working dir : $wdir"
echo "Bin dir     : $bdir"

cd $bdir/..
tarfile=bwmonitor_$(grep VERSION lib/BWMonitor/Cmd.pm | awk -F\' '{print $2}')_$(date +%s).tar
tar -cvf $wdir/$tarfile $(git ls-files)
gzip -9 -f $wdir/$tarfile

(cd $wdir && md5sum $tarfile.gz | tee $tarfile.gz.md5)
(cd $wdir && ls -lh bwmonitor_*)

# restore path
cd -

