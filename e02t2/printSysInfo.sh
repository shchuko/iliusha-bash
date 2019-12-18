#!/bin/bash

echo "System: "`lsb_release -d --short` `uname -m`                            
echo "Kernel: "`uname -r`"  DE: $XDG_CURRENT_DESKTOP   Session: $GDMSESSION"
echo "----------------------------------"                                  
echo "Processor: "`cat /proc/cpuinfo | grep "model name" -m1 | cut -c14-` 
echo "Memory (Gb): "`free | grep Mem | awk '{print int($2/10485.76)/100}'`
echo "Video: "`lspci -k | egrep 'VGA|3D' -A2`                            
echo "----------------------------------"                               
