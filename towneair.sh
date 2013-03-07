#!/bin/sh
USERNAME="Transpak"
PASSWORD="r5tyghu8"
SERVER="ftp.towneair.com"
 
# remote directory to pickup *.txt 214 file
FILE="/Instatrace"
 
# local directory to store 214 file
DES="/home/towneairftp"
echo "=================Connnecting FTP Towne Air=============="
 
#mdel *.214
# login to remote server
ftp -n -i $SERVER <<EOF
user $USERNAME $PASSWORD
cd $FILE
lcd $DES
mget *.214
mdel *.214



quit

EOF
