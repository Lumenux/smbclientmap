# smbclientmap

For security testing I needed a tool to scan a network for readable and writable SMB shares.

I found that existing tools like smbmap and nmap's smb-enum-shares were not 100% reliable. On the other hand, smbclient was working correctly. So I wrote a wrapper for smbclient which automatically tests read and write permissions of all found shares.

Authentication is done via null sessions (i.e. no username and password).

The script smbclientmap.sh does the following:

1. The script takes one IP address as input.
1. The script lists all available shares on that IP address via smbclient -N -g -L //ip.
2. For each Disk share, the script attempts to run the command "dir". If it works, that means we have READ ACCESS.
3. If we have READ ACCESS, then the script will attempt to run the command "mkdir". If it works, that means we have WRITE ACCESS.

## Usage

```
$ bash smbclientmap.sh 192.168.0.1
```

## Example

```
[tux@system ~]$ ash smbclientmap.sh
Usage: smbclientmap.sh IP

[tux@system ~]$ ash smbclientmap.sh 192.168.0.1
### Testing 192.168.0.1 ###

Disk|print$|Printer Drivers
Disk|storage|
IPC|IPC$|IPC Service (Samba 4.9.5-Debian)

# Testing //192.168.0.1/print$ #
# Testing //192.168.0.1/storage #
  .                                   D        0  Fri Feb 12 10:11:20 2021
  ..                                  D        0  Sun May 17 17:28:54 2020
  test_565335                         D        0  Fri Feb 12 10:11:20 2021
  Documents                           D        0  Thu Aug 13 12:13:40 2020
  notes.txt                           A      320  Sun Jan 17 18:40:56 2021

                15023184 blocks of size 1024. 11779292 blocks available
=> WRITE SUCCESS (test_565335 directory)
=> READ SUCCESS
```

In this example, two shares (print$ and "storage") could be found. The "storage" share had read and write permissions.

## Scan multiple servers

Create a new file with one IP address per line.

Now run smbclientmap as follows:

```
$ for ip in $(cat ips.txt); do bash smbclientmap.sh $ip; done | tee output.txt
```

## SMBv1

When using smbclient, SMBv1 support is turned off by default. When smbclient connects to an SMBv1 server, then it will display the following error: `protocol negotiation failed: NT_STATUS_CONNECTION_DISCONNECTED`.

To turn on SMBv1 support, I added the parameter `--option='client min protocol=NT1'` to smbclient. 

## smb.conf

If the file /etc/samba/smb.conf does not exist, then smbclient will print this warning message:

`Can't load /etc/samba/smb.conf - run testparm to debug it`

The script will create the empty /tmp/smb.conf file to prevent this warning message.
