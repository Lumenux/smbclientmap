# smbclientmap

For security testing purposes I needed a tool to find readable and writable SMB shares in a network.

I found existing tools such as smbmap and nmap's smb-enum-shares were not 100% reliable. However, I had positive experiences using smbclient. So I wrote a wrapper for smbclient.

The script smbclientmap.sh does the following:
- Given an IP address, the script lists all available shares via smbclient -N -L //ip
- For each share, the script attempts to run the command "dir". If it works, then we have READ ACCESS.
- If we have READ ACCESS, then the script will attempt to run the command mkdir "testdir". If it works, then we have WRITE ACCESS.

# Scan multiple servers

Create a new file with one IP address per line.

Now run smbclientmap as follows:

```
for ip in $(cat ips.txt); do bash smbclientmap.sh $ip; done
```

# SMBv1

Samba turned off SMBv1. When smbclient connects to an SMBv1 server, then it will display the following error: `protocol negotiation failed: NT_STATUS_CONNECTION_DISCONNECTED`.

To turn on SMBv1 support, I added the parameter `--option='client min protocol=NT1'` to smbclient. 
