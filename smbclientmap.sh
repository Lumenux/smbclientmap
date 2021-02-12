#!/bin/bash

if [ "$#" -ne "1" ]; then
    echo "Usage: $0 IP"
    exit 1
fi
ip=$1

# Create an empty config file, so we don't get the warning "Can't load /etc/samba/smb.conf - run testparm to debug it"
touch /tmp/smb.conf

echo ""
echo "### Testing $ip ###"

stdbuf -i0 -o0 -e0 smbclient -s /tmp/smb.conf --option='client min protocol=NT1' -N -g -L //$ip >temp.txt 2>&1
echo ""
cat temp.txt
echo ""

# A typical line from smbclient -L (using the -g parameter) looks like this:
# Disk|C$|Default share

for share in $(grep -E -o "Disk\|[^\|]+" temp.txt | cut -c 6-); do
    echo "# Testing //$ip/$share #"
    stdbuf -i0 -o0 -e0 smbclient -s /tmp/smb.conf --option='client min protocol=NT1' -N //$ip/$share -c "dir" >temp.txt 2>&1
    status=$?
    if [ "$status" -eq "0" ]; then
        testdir=test_$(shuf -i 100000-999999 -n 1)
        stdbuf -i0 -o0 -e0 smbclient -s /tmp/smb.conf --option='client min protocol=NT1' -N //$ip/$share -c "mkdir $testdir" >temp.txt 2>&1
        stdbuf -i0 -o0 -e0 smbclient -s /tmp/smb.conf --option='client min protocol=NT1' -N //$ip/$share -c "dir" >temp.txt 2>&1
        cat temp.txt
        if grep -q ${testdir} temp.txt; then
            echo "=> WRITE SUCCESS (${testdir} directory)"
        fi
        stdbuf -i0 -o0 -e0 smbclient -s /tmp/smb.conf --option='client min protocol=NT1' -N //$ip/$share -c "rmdir $testdir" >temp.txt 2>&1
        echo "=> READ SUCCESS"
    fi
done

[ -e temp.txt ] && rm -f temp.txt
