# smbclientmap

For security testing purposes I needed a tool to find readable and writable SMB shares in a network.

I found that existing tools like smbmap and nmap's smb-enum-shares were not 100% reliable. However, I had positive experiences using smbclient. So I wrote a wrapper for smbclient.

Authentication is done via null sessions (i.e. no username/password is given).

The script smbclientmap.sh does the following:

1. The script takes one IP address as input.
1. The script lists all available shares on that IP address via smbclient -N -g -L //ip.
2. For each Disk share, the script attempts to run the command "dir". If it works, that means we have READ ACCESS.
3. If we have READ ACCESS, then the script will attempt to run the command "mkdir". If it works, that means we have WRITE ACCESS.

## Usage

```
$ bash smbclientmap.sh
Usage: smbclientmap.sh IP

$ bash smbclientmap.sh 192.168.0.1
```

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
