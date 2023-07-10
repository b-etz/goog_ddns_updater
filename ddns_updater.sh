#!/bin/bash
# Google Domains DDNS Updater
# Every 30 minutes, run this job to check for an IP address update from the ISP.
# Warning: Uses this machine's public IP address as seen by Google for the update. DO NOT run this behind a VPN.
#          User must ensure this machine's public IP address will be the same as the application server that 
#		   requires DDNS and/or port forwarding.

my_hostname="example.com"  # Change as required
my_local_file="public_ip.txt"  # Change as required
google_userpass="****************:****************"  # Change as required

now=$(date)
echo "$now -- Running local Google DDNS update script..."

ip_prev=$(cat $my_local_file)
if [ -z "$ip_prev" ]; then
	ip_prev="0.0.0.0"
elif ! [[ "$ip_prev" =~ ^[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+$ ]]; then
	echo "The stored IP file is malformed or the local filename is incorrect."
	echo "Check for a text file named \"$my_local_file\" in the running directory."
	echo -e "Stored data must be a plain 4-octet IPV4 address in a single line.\n"
	read -p "DDNS update script failed. PRESS ENTER TO DISMISS..."; exit
fi

ip_resp=$(curl -s -X GET https://domains.google.com/checkip)
if ! [[ "$ip_resp" =~ ^[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+$ ]]; then
	echo "Request to https://domains.google.com/checkip returned an unexpected value."
	echo -e "Recovered result is: $ip_resp\n"
	read -p "DDNS update script failed. PRESS ENTER TO DISMISS..."; exit
fi
echo "Current public IP address is $ip_resp"

[ "$ip_prev" == "$ip_resp" ] && exit # This machine's public IP address has not changed
echo "Previous public IP address was $ip_prev"
echo "This machine's public IP address has changed! Updating local store..."
echo -n "$ip_resp" > $my_local_file  # Otherwise, store the new IP address in our local file

echo "Sending request to Google Domains DDNS service..."
ddns_resp=$(curl -s https://$google_userpass@domains.google.com/nic/update?hostname=$my_hostname&myip=$ip_resp)
echo -e "Google's response is: $ddns_resp\n"

read -p "PRESS ENTER TO DISMISS..."