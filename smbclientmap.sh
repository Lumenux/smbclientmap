#!/bin/bash

if [ "$#" -ne "1" ]; then
    echo "Usage: $0 IP"
    exit 1
fi
ip=$1

echo ""
echo "### Testing $ip ###"

stdbuf -i0 -o0 -e0 smbclient --option='client min protocol=NT1' -N -g -L //$ip >output.txt 2>&1
echo ""
cat output.txt
echo ""

# A typical line from smbclient -L (using the -g parameter) looks like this:
# Disk|C$|Default share

for share in $(grep -E -o "Disk\|[^\|]+" output.txt | cut -c 6-); do
    echo "# Testing //$ip/$share #"
    stdbuf -i0 -o0 -e0 smbclient --option='client min protocol=NT1' -N //$ip/$share -c "dir" >output.txt 2>&1
    status=$?
    if [ "$status" -eq "0" ]; then
        testdir=test_$(shuf -i 100000-999999 -n 1)
        stdbuf -i0 -o0 -e0 smbclient --option='client min protocol=NT1' -N //$ip/$share -c "mkdir $testdir" >output.txt 2>&1
        stdbuf -i0 -o0 -e0 smbclient --option='client min protocol=NT1' -N //$ip/$share -c "dir" >output.txt 2>&1
        cat output.txt
        if grep -q ${testdir} output.txt; then
            echo "=> WRITE SUCCESS (${testdir} directory)"
        fi
        stdbuf -i0 -o0 -e0 smbclient --option='client min protocol=NT1' -N //$ip/$share -c "rmdir $testdir" >output.txt 2>&1
        echo "=> READ SUCCESS"
    fi
done

[ -e output.txt ] && rm -f output.txt
