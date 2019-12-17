#!/bin/bash

if [[ ! -f e02t1_config ]]; then
        echo "Couldn't open config file 'e02t1_config'";
        exit 1;
fi;

echo "Enter the name of command:";
read commandName;

echo "Enter path to the output file:";
read foutPath;

manRes=$(man $commandName) || exit 1;
chapters=$(cat e02t1_config);

while IFS= read -r chapterLine; do
        writeFlag=false;
        while IFS= read -r manLine; do
		if [[ "$manLine" == "$chapterLine" ]]; then
                        writeFlag=true;
		elif [[ "$manLine" =~ ^[[:alpha:]]+.*$ ]]; then
                        writeFlag=false;
                fi;

                if [[ "$writeFlag" == "true" ]]; then
                        result=$result$manLine$'\n';
                fi;
        done <<< "$manRes";
done <<< "$chapters"

echo -e "\nChapters you requested:"
echo "$result";
echo "$result" > $foutPath;
