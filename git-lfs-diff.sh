#!/bin/sh

if [ $# -ne 3 ] ; then
    echo "Usage: $0 <ref> <ref> <filename>"
    exit 1
fi

RevA=$1
RevB=$2
File=$3

object() {
    Rev=$1
    File=$2
    Object=""

    Oid=$(git show $Rev:$File 2> /dev/null | grep "sha256" | cut -d ":" -f 2)
    if [ "$Oid" != "" ]; then
        Oid12=$(echo $Oid | cut -b 1-2)
        Oid34=$(echo $Oid | cut -b 3-4)
        Object=.git/lfs/objects/$Oid12/$Oid34/$Oid
        if [ ! -e "$Object" ] ; then
            echo "Missing file $File at revision $Rev"
            exit 2
        fi
    fi

    echo "$Object"
}


ObjectA=$(object $RevA $File)
EC="$?"
if [ "$EC" != "0" ]; then
    echo "$ObjectA"
    exit "$EC"
fi

ObjectB=$(object $RevB $File)
EC="$?"
if [ "$EC" != "0" ]; then
    echo "$ObjectB"
    exit "$EC"
fi

echo "diff -urN $ObjectA $ObjectB"
diff -urN "$ObjectA" "$ObjectB"
