#!/bin/bash

logpath=log3.txt;

printHelp() {
local usage="Supported commands:
	exit			stop running script
	help			print help
	show-passwd		print /etc/passwd data
	show-groups		print groups info
	show-users		print users info
	rename-group		set new name for group
	edit-gid		set new GID for group
	rename-user		set new name for user
	change-usr-passwd	change user's password
";

	echo "$usage";
}

printToLog()  {
	echo $(date):$'\n'"$@" >> $logpath;	
}

showPasswd() {
	cat /etc/passwd;
	printToLog "show-passwd command executed";
}

showGroups() {
	local result=$(cat /etc/group | awk -F':' 'OFS=":" { print $3, $1; }');
	local result="GID:Group Name"$'\n'"$result";

	echo "$result" | column -t -s ':';

	printToLog "show-groups command executed";
}

showUsers() {
	local result=$(cat /etc/passwd | awk -F':' 'OFS=":" { print $3, $4, $1; }');
	local result=$"UID:GID:Username"$'\n'"$result";

	echo "$result" | column -t -s ':';

	printToLog "show-users command executed";
}

renameGroup() {
	echo "Enter old name of the group:";
	read oldGroupName;
	echo "Enter new name for the group:";
	read newGroupName;

	successStatus="Operation error";
	groupmod -n $newGroupName $oldGroupName 1>/dev/null 2>/dev/null && successStatus="Operation successful";

	echo "$successStatus";
	printToLog "group name $oldGroupName change to $newGroupName : $successStatus";
}

editGid() {
	echo "Enter name of the group:";
	read groupName;
	echo "Enter new GID value";
	read newGid;

	if [[ ! "$newGid" =~ [0-9]+ ]]; then
		echo "GID can contain only digits!";
		echo "Aborting...";
		return;
	fi;

	echo "Are you sure want to modify GID? [y/N]?";
	read answer;

	[[ ! "$answer" =~ y|Y ]] && { echo "Aborting..."; return; };

	successFlag=false;
	groupmod -g $newGid $groupName 1>/dev/null 2>/dev/null && successFlag=true;

	if [[ "$successFlag" == true ]]; then 
		echo "Do not stop executing! Editing dependecies...";
		find / -gid $newGid -exec chgrp $groupName {} \;;
		echo "Modifying GID for group $groupName to $newGid successful!";
		printToLog "modify gid for group $groupname to $newgid: Operation successful";
	else
		echo "Modifying GID for group $groupName to $newGid error!";
		printToLog "modify gid for group $groupname to $newgid: Operation error";
	fi;
}

renameUser() {
	echo "Enter old username:";
	read oldUsername;
	echo "Enter new username:";
	read newUsername;

	local successFlag="Operation error";
	pkill -u $oldUsername; 
	pkill -9 -u $oldUsername;
 	usermod -l $newUsername $oldUsername && successFlag="Operation successful";
	groupmod -n $newUsername $oldUsername;
	usermod -d /home/$newUsername -m $newUsername;
	
	echo "$successFlag";
	printToLog "user name $oldUserName change to $newUsername : $successFlag";
}

changeUserPassword() {
	echo "Enter user name to change password:";
	read userName;
	
	local succesFlag="Operation error";
	passwd $userName && successFlag="Operation success";

	printToLog "change password for user $username: $successFlag";
}

# sudo test
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root";
   exit 1;
fi;

printToLog "Start session";
while true; do
	echo "Enter command:";

	read command;
	case $command in
		show-passwd)
			showPasswd;
			;;
		show-groups)
			showGroups;
			;;
		show-users)
			showUsers;
			;;
		rename-group)
			renameGroup;
			;;
		edit-gid)
			editGid;
			;;
		rename-user)
			renameUser;
			;;
		change-usr-passwd)
			changeUserPassword;
			;;
		exit)
			printToLog "Session closed normally";
			echo "Exit...";
			exit 0;
			;;
		help)
			printHelp;
			;;
		*)
			echo "Wrong command!";
			printHelp;
			;;
	esac;	
done;
