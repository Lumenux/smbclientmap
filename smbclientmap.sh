#!/bin/bash

if [ "$#" -ne "1" ]; then
    echo "Usage: $0 IP"
    exit 1
fi
ip=$1

echo ""
echo "# Testing $ip #"

stdbuf -i0 -o0 -e0 smbclient --option='client min protocol=NT1' -N -L //$ip >temp.txt 2>&1
cat temp.txt
echo ""

for share in $(cat temp.txt | tr -d '\t' | tr -s ' ' | grep -P -o "^[^\s]+ Disk" | rev | cut -c 6- | rev); do
    echo "# Testing //$ip/$share #"
    stdbuf -i0 -o0 -e0 smbclient --option='client min protocol=NT1' -N //$ip/$share -c "dir" >temp.txt 2>&1
    status=$?
    if [ "$status" -eq "0" ]; then
        testdir=test_$(shuf -i 100000-999999 -n 1)
        stdbuf -i0 -o0 -e0 smbclient --option='client min protocol=NT1' -N //$ip/$share -c "mkdir $testdir" >temp.txt 2>&1
        stdbuf -i0 -o0 -e0 smbclient --option='client min protocol=NT1' -N //$ip/$share -c "dir" >temp.txt 2>&1
        cat temp.txt
        if grep -q ${testdir} temp.txt; then
            echo "=> WRITE SUCCESS (${testdir} directory)"
        fi
        stdbuf -i0 -o0 -e0 smbclient --option='client min protocol=NT1' -N //$ip/$share -c "rmdir $testdir" >temp.txt 2>&1
        echo "=> READ SUCCESS"
    fi
done

[ -e temp.txt ] && rm -f temp.txt
