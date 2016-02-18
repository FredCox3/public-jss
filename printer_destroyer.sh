#!/bin/bash
#
# Printer Destroyer Script
# Freddie Cox - January 2016 for Knox County Schools
#
# Use Paramter 4 on JSS Script to remove a specific IP address.
echo "[INFO] printer_destroyer script. Parameter 4 Value: ${4}" 

printer=$(lpstat -s | grep 'socket.*'${4} | awk -F'/' '{print $3}')

if [ -z $printer ]; then
    echo "[INFO] Printer Not Found. No removal necessary."
else
    echo "[INFO] $printer Printer Found. Attempting to remove."
    remove_printer=$(lpstat -s | grep 'socket.*'${4} | awk -F ' ' '{print $3}' | sed s/://g)
    lpadmin -x $remove_printer
 
    printer_check=$(lpstat -s | grep 'socket.*'${4} | awk -F'/' '{print $3}')
    
    # Check if what we did actually worked. 
    if [ -z $printer_check ]; then
        echo "[INFO] Success! Old Printer Removed."
    else
        echo "[ERROR] Something went wrong. Likly two printers with 1 IP. Otherwise, I'm all out of ideas"
    fi
fi
