#!/bin/bash

midnight=$(date -d "$(date +%F) 00:00:00" +%s)000
failButton=1
passButton=3

read -p "Enter the name of your Anki deck (case sensitive): " deckName

todaysDate=$(date +"%Y-%m-%d")
daily_file="dates_${deckName// /_}.json"
json_file="reviewResults_${deckName// /_}.json"
json_file_acc="totalAccuracy_${deckName// /_}.json"

if [[ ! -f "$daily_file" ]] || ! jq empty "$daily_file" >/dev/null 2>&1; then
            echo "[]" > "$daily_file"
        fi


reviews_left=$(curl -s localhost:8765 \
    -X POST \
    -d "{\"action\": \"findCards\", \"version\": 6, \"params\": {\"query\": \"deck:\\\"$deckName\\\" (is:due)\"}}" \
    | jq '.result | length')

if [[ "$reviews_left" -gt 0 ]]; then
    echo "You still have $reviews_left reviews left in '$deckName'."
    echo "Run this command again after you have completed your reviews for today."
    exit 1
else
    if ! jq -e --arg date "$todaysDate" 'index($date)' "$daily_file" > /dev/null; then
 	   	jq --arg date "$todaysDate" '. + [$date]' "$daily_file" > tmp.json && mv tmp.json "$daily_file"
    		
	else
    	echo "Reviews already logged for today."
        exit 1
	fi
fi

echo "All reviews completed for '$deckName'. Running script..."

results_file=$(mktemp)

curl -s localhost:8765 \
    -X POST \
    -d "{\"action\": \"cardReviews\", \"version\": 6, \"params\": {\"deck\": \"$deckName\", \"startID\": $midnight}}" | jq -c \
    --argjson passButton "$passButton" --argjson failButton "$failButton" '
        .result 
        | sort_by(.[1])
        | group_by(.[1])
        | map({ 
                cardID: .[0][1], 
                passes: map(select(.[3] == $passButton)) | length,
                fails: map(select(.[3] == $failButton)) | length 
        })[]
    ' | while IFS= read -r result; do

    cardID=$(echo "$result" | jq '.cardID')
    pass=$(echo "$result" | jq '.passes')
    fail=$(echo "$result" | jq '.fails')

    totalReviews=$((pass+fail))

    if [[ $totalReviews -gt 0 ]]; then
        accuracy=$(echo "scale=2; 100 * $pass / $totalReviews" | bc)
    else
        accuracy=0
    fi

    curl -s localhost:8765 \
        -X POST \
        -d "{\"action\": \"cardsInfo\", \"version\": 6, \"params\": {\"cards\": [$cardID]}}" | jq -c '
        .result[0].fields |
        {
            vocab: .Word.value,
            reading: .["Word Reading"].value,
            meaning: .["Word Meaning"].value
        }' | while IFS= read -r cardValues; do

        vocab=$(echo "$cardValues" | jq -r '.vocab')
        reading=$(echo "$cardValues" | jq -r '.reading')
        translation=$(echo "$cardValues" | jq -r '.meaning' | sed 's/&nbsp;/ /g')



        if [[ ! -f "$json_file" ]] || ! jq empty "$json_file" >/dev/null 2>&1; then
            echo "[]" > "$json_file"
        fi

        if [[ ! -f "$json_file_acc" ]] || ! jq empty "$json_file_acc" >/dev/null 2>&1; then
            echo '{"totalPass": 0, "totalFail": 0}' > "$json_file_acc"
        fi



        exists=$(jq --arg vocab "$vocab" 'any(.[]; .vocab == $vocab)' "$json_file")
        
        jq --arg vocab "$vocab" --argjson pass "$pass" --argjson fail "$fail" '
                    .totalPass += $pass |
                    .totalFail += $fail
            ' "$json_file_acc" > temp.json && mv temp.json "$json_file_acc"

        if [[ "$exists" == "true" ]]; then
            jq --arg vocab "$vocab" --argjson pass "$pass" --argjson fail "$fail" '
                map(
                    if .vocab == $vocab then
                        .pass = (.pass + $pass) |
                        .fail = (.fail + $fail)
                    else
                        .
                    end
                )
            ' "$json_file" > temp.json && mv temp.json "$json_file"
        else
            jq --arg vocab "$vocab" --arg reading "$reading" --arg translation "$translation" \
            --argjson accuracy "$accuracy" --argjson pass "$pass" --argjson fail "$fail" \
            '. += [{vocab: $vocab, reading: $reading, translation: $translation, accuracy: $accuracy, pass: $pass, fail: $fail}]' \
            "$json_file" > temp.json && mv temp.json "$json_file"

        fi

        

        echo -e "$accuracy\t$translation\t$pass\t$fail\t Card $vocab ($reading): $translation | $accuracy% correct ($pass correct, $fail incorrect)" \
            >> "$results_file"

    done
done

totalPass=$(awk -F'\t' '{ sum+= $3 } END {print sum}' "$results_file")
totalFail=$(awk -F'\t' '{ sum+= $4 } END {print sum}' "$results_file")
overallAccuracy=$(echo "scale=2; 100 * $totalPass / ($totalPass + $totalFail)" | bc)

sort -t$'\t' -n -k1,1 -k2,2 "$results_file" | cut -f5-
rm "$results_file"

echo "TOTAL ACCURACY = $overallAccuracy ($totalPass correct, $totalFail incorrect)"
jq 'sort_by(.accuracy)' "$json_file" > temp.json && mv temp.json "$json_file"

