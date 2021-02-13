#!/bin/bash

if [ "$#" -ne "1" ]; then
    echo "Usage: $0 IP"
    exit 1
fi
ip=$1

# Create an empty config file, so we don't get the warning "Can't load /etc/samba/smb.conf - run testparm to debug it"
touch /tmp/smb.conf

echo ""
echo "=> Testing //$ip"

# A typical line from smbclient -L (using the -g parameter) looks like this:
# Disk|C$|Default share

smbclient -s /tmp/smb.conf --option='client min protocol=NT1' -N -g -L //$ip | while read -r line; do
    echo $line
    if [[ "$line" == "Disk|"* ]]; then
        share=$(echo $line | cut -d "|" -f 2)
        smbclient -s /tmp/smb.conf --option='client min protocol=NT1' -N //$ip/$share -c "dir"
        if [ "$?" -eq "0" ]; then
            echo "===> READ SUCCESS for //$ip/$share"
            testdir=test_$(shuf -i 100000-999999 -n 1)
            smbclient -s /tmp/smb.conf --option='client min protocol=NT1' -N //$ip/$share -c "mkdir $testdir"
            if smbclient -s /tmp/smb.conf --option='client min protocol=NT1' -N //$ip/$share -c "dir" | grep -q "$testdir"; then
                echo "===> WRITE SUCCESS for //$ip/$share (test directory ${testdir})"
            fi
            smbclient -s /tmp/smb.conf --option='client min protocol=NT1' -N //$ip/$share -c "rmdir $testdir"
        fi
    fi
done
