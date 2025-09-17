#!/bin/bash

while true; do

	echo "Choose a command"
	echo "1) Log Daily Anki Reviews"
	echo "2) Summary of Total Reviews"
	echo "3) exit"

	read -p "Enter your choice: " choice

	if [[ "$choice" == 1 ]]; then

		./ankiCode1.sh #check if all reviews completed today, otherwise, invalid
			
	elif [[ "$choice" == 2 ]]; then
		
		./reviewsSummary.sh
	
	elif [[ "$choice" == 3 ]]; then
		echo "Exiting script..."
		exit 0

	else
		echo "Invalid option, enter only 1, 2, or 3"
	fi

done
