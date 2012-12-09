#!/bin/sh
USERNAME="transpak"
PASSWORD="!T%@nsP@cK!"
SERVER="ftp.forwardair.com"
 
# remote directory to pickup *.txt 214 file
FILE="/transpak/Instatrace"
 
# local directory to store 214 file
DES="/home/forwardairftp"
echo "=================Connnecting FTP Forward Air=============="
 
#mdel *.214
# login to remote server
ftp -n -i $SERVER <<EOF
user $USERNAME $PASSWORD
cd $FILE
lcd $DES
mget *.214



quit

EOF
