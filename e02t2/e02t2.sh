#!/bin/bash

(crontab -l 2>/dev/null; echo "*/9 * * * * $PWD/printSysInfo.sh") | crontab -;
(crontab -l 2>/dev/null; echo "@reboot sleep 12000 && $PWD/openEmailClient.sh") | crontab -;
(crontab -l 2>/dev/null; echo "37 23 * * sat,sun $PWD/doBackup.sh") | crontab -;
(crontab -l 2>/dev/null; echo "59 23 31 12 * $PWD/printHappyNewYear.sh") | crontab -;

./printCrontabInfo.sh;
