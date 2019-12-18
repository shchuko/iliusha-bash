#!/bin/bash

logpath=log3.txt;
acceptedUsers=(^us10.* ^vv10.*);
acceptedGroups=(^gg10.* ^ee10.*);
	
isUserInUsers() {
	local result=1;
	for i in ${acceptedUsers[@]}; do [[ "$1" =~ $i ]] && result=0; done;
	return $result;
}

isGroupInGroups() {
	local result=1;
	for i in ${acceptedGroups[@]}; do [[ "$1" =~ $i ]] && result=0; done;
	return $result;
}

printHelp() {
local usage="Supported commands:
	exit			stop running script
	help			print help
	show-passwd		print /etc/passwd data
	show-groups		print groups info
	show-users		print users info
	rename-group		set new name for group
	edit-gid		set new GID for group
	create-group		create new group
	delete-group		delete existing group
	rename-user		set new name for user
	change-usr-passwd	change user's password
	create-user		create new user, set password
	delete-user		delete existing user
	change-user-home-place	change user's home directory place
	show-user-groups	show groups related to user
	add-user-to-group	add user to group
	del-user-group		delete user from group
	get-passw-expire	get password expire info for user
	set-passw-expire	set password expire date for user
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
	isGroupInGroups $oldGroupName || { echo "Don't have access to this group"; return 1; };

	echo "Enter new name for the group:";
	read newGroupName;

	successStatus="Operation error";
	groupmod -n $newGroupName $oldGroupName && successStatus="Operation successful";

	echo "$successStatus";
	printToLog "group name $oldGroupName change to $newGroupName : $successStatus";
}

editGid() {
	echo "Enter name of the group:";
	read groupName;
	isGroupInGroups $groupName || { echo "Don't have access to this group"; return 1; };
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
	groupmod -g $newGid $groupName && successFlag=true;

	if [[ "$successFlag" == true ]]; then 
		echo "Do not stop executing! Editing dependecies...";
		find / -gid $newGid -exec chgrp $groupName {} \;;
		echo "Modifying GID for group $groupName to $newGid successful!";
		printToLog "modify gid for group $groupName to $newGid: Operation successful";
	else
		echo "Modifying GID for group $groupName to $newGid error!";
		printToLog "modify gid for group $groupName to $newGid: Operation error";
	fi;
}


createGroup() {
	echo "Enter name for the new group:";
	read groupName;
	isGroupInGroups $groupName || { echo "Don't have access to this group"; return 1; };

	echo "Enter GID for the new group (left it blank if you want to create it autimatically):";
	read gid;
	
	local successFlag="Operation error";
	if [[  "$gid" =~ [:space:]* ]]; then
		groupadd $groupName && successFlag="Operation success";
	elif [[ ! "$gid" =~ [0-9]+ ]]; then
		echo "GID can contain only digits!";
		echo "Aborting...";
		return;
	else
		groupadd -g $gid $groupName && successFlag="Operation success";
	fi;

	echo "$successFlag";
	printToLog "creation new group on name $groupName: $successFlag";
}

deleteGroup() {
	echo "Enter name for the group:";
	read groupName;
	isGroupInGroups $groupName || { echo "Don't have access to this group"; return 1; };
	
	local successFlag="Operation error";
	groupdel $groupName && successFlag="Operation success";

	echo "$successFlag"
	printToLog "deleting group $groupName: $successFlag"
}

renameUser() {
	echo "Enter old username:";
	read oldUsername;
	isUserInUsers $oldUsername || { echo "Don't have access to this user"; return 1; };
	
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
	isUserInUsers $userName || { echo "Don't have access to this user"; return 1; };
	
	local succesFlag="Operation error";
	passwd $userName && successFlag="Operation success";

	printToLog "change password for user $userName: $successFlag";
}

createUser() {
	echo "Enter user name:";
	read userName;
	isUserInUsers $userName || { echo "Don't have access to this user"; return 1; };
	
	local successFlag=false;
	useradd $userName && successFlag=true;

	if [[ "$successFlag" == false ]]; then
		echo "User creation unsuccessful";
		echo "Aborting...";
		printToLog "create new user on username $userName: Operation error";
		return;
	fi;

	successFlag=false;
	passwd $userName && successFlag=true;
	
	if [[ "$successFlag" == true ]]; then 
		echo "Operation success";
		printToLog "create new user on username $userName: Operation successful";
		printToLog "create password for user on username $userName: Operation successful";
	else
		echo "Creating new user operation successful";
		echo "Password creating error";
		echo "Try to create password for user $userName manually using command 'passwd $userName'";
		printToLog "create new user on username $userName: Operation successful";
		printToLog "create password for user on username $userName: Operation error";
	fi;

}

deleteUser() {
	echo "Enter user name:";
	read userName;
	isUserInUsers $userName || { echo "Don't have access to this user"; return 1; };
	
	local successFlag="Operation eror";
	userdel $userName && successFlag="Operation success";

	echo "$successFlag";
	printToLog "deleting user on username $userName: $successFlag";	

}

changeUserHomeDirPlace() {
	echo "Enter user name:";
	read userName;
	isUserInUsers $userName || { echo "Don't have access to this user"; return 1; };
	
	echo "Enter path to destination directory:";
	read dirPath;

	if [[ ! -d dirPath ]]; then
		echo "Directory $dirPath not exists";
		echo "Aborting...";
		return 1;
	fi;
	
	local successFlag="Operation error";
	usermod -d $dirPath/$userName -m $userName && successFlag="Operation success";
	
	echo "$successFlag";
	printToLog "changing user $userName home directory place:  $successFlag";
}


showUserGroups() {
	echo "Enter user name:";
	read userName;
	isUserInUsers $userName || { echo "Don't have access to this user"; return 1; };
	
	local successFlag="Operation error";
	groups $userName && successFlag="Operation success";
	
	echo "$successFlag";
	printToLog "show groups of use $userName: $successFlag";
}

addUserToGroup() {
	echo "Enter user name:";
	read userName;
	isUserInUsers $userName || { echo "Don't have access to this user"; return 1; };
	
	echo "Enter name of the group:";
	read groupName;
	isGroupInGroups $groupName || { echo "Don't have access to this group"; return 1; };
	
	local successFlag="Operation error";
	usermod -a -G ${groupName} ${userName} && successFlag="Operation success";
	
	echo "$successFlag";
	printToLog "adding user $userName to the group $groupName: $successFlag";
}

delUserFromGroup() {
	echo "Enter username:";
	read userName;
	isUserInUsers $userName || { echo "Don't have access to this user"; return 1; };
	
	echo "Enter name of the group:";
	read groupName;
	isGroupInGroups $groupName || { echo "Don't have access to this group"; return 1; };
	
	local successFlag="Operation error";
	deluser $userName $groupName && successFlag="Operation success";
	
	echo "$successFlag";
	printToLog "deleting user $userName from the group $groupName: $successFlag";
	
}

getPasswordExp() {
	echo "Enter username:";
	read userName;
	isUserInUsers $userName || { echo "Don't have access to this user"; return 1; };
	
	local successFlag="Operation error";
	chage -l $userName && successFlag="Operation success";
	
	echo "$successFlag";
	printToLog "getting password expiration info for user $userName: $successFlag";
}

setPasswordExp() {
	echo "Enter username:";
	read userName;
	isUserInUsers $userName || { echo "Don't have access to this user"; return 1; };
	
	echo "Enter days in password will expire (left blank if want to remove expire control):";
	read days;
	
	local successFlag="Operation error";
	if [[ "$days" =~ [:space:]* ]]; then
		echo "Removing expire control";
		chage -I -1 -m 0 -M 99999 -E -1 $userName && successFlag="Operation success";
	elif [[ ! "$days" =~ [0-9]+ ]]; then
		echo "Days can contain only digits!";		
	else
		chage -M $days $userName && successFlag="Operation success";
	fi;


	echo "$successFlag";
	printToLog "setting password expiration date for user $userName: $successFlag";

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
		create-group)
			createGroup;
			;;
		delete-group)
			deleteGroup;
			;;
		rename-user)
			renameUser;
			;;
		change-usr-passwd)
			changeUserPassword;
			;;
		create-user)
			createUser;
			;;
		delete-user)
			deleteUser;
			;;
		change-user-home-place)
			changeUserHomeDirPlace;
			;;
		show-user-groups)
			showUserGroups;
			;;
		add-user-to-group)
			addUserToGroup;
			;;
		del-user-group)
			delUserFromGroup;
			;;
		get-pass-expire)
			getPasswordExp;
			;;
		set-pass-expire)
			setPasswordExp;
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
