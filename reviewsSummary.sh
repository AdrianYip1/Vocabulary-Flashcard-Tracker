#!/bin/bash

read -p "Enter the name of your Anki deck (case sensitive): " deckName

daily_file="dates_${deckName// /_}.json"
json_file="reviewResults_${deckName// /_}.json"
json_file_acc="totalAccuracy_${deckName// /_}.json"

numberOfVocab=$(jq length "$json_file")
datesStudied=$(jq length "$daily_file")
firstLog=$(jq -r '.[0]' "$daily_file")
latestLog=$(jq -r '.[-1]' "$daily_file")
total_pass=$(jq '.totalPass' "$json_file_acc")
total_fail=$(jq '.totalFail' "$json_file_acc")

jq 'map(.accuracy = ((.pass / (.pass + .fail)) * 100 | round*100/100))' "$json_file" > temp.json && mv temp.json "$json_file"
jq 'sort_by(.accuracy)' "$json_file" > temp.json && mv temp.json "$json_file"

echo "Summary of Reviews in: \"$deckName\" (between $firstLog and $latestLog):"
echo "Number of days studied: $datesStudied"
echo "Total number of vocab words studied: $numberOfVocab"

if (( total_pass + total_fail > 0 )); then
    accuracy=$(( total_pass * 100 / (total_pass + total_fail) ))
else
    accuracy=0
fi

echo "Total correct: $total_pass | Total incorrect: $total_fail | Accuracy: ${accuracy}%"

