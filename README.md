# Vocabulary-Flashcard-Tracker
A Bash scripting system that automates tracking vocabulary flashcard statistics.


# Anki Review Logger

A Bash script that connects to AnkiConnect API to log daily Anki reviews for a given deck. 
It tracks:
- Daily completion
- Individual card pass/fail counts
- Overall accuracy
- Summary of all reviews

Results are stored in JSON and can be analyzed later.

--- 

## Project Structure
.
├── ankiCodeMenu.sh                 # Main script menu
├── ankiCode1.sh                    # Logs today's Anki reviews
├── reviewsSummary.sh               # Generates summaries from JSON logs
│
├── dates_Kaishi_1.5k.json          # Log of dates the script has logged reviews
├── reviewResults_Kaishi_1.5k.json  # Per-card review stats (pass/fail/accuracy)
└── totalAccuracy_Kaishi_1.5k.json  # Cumulative pass/fail totals for the deck

## Installation

### 1. Install Anki + AnkiConnect
- Download and install [Anki](https://apps.ankiweb.net/).
- In Anki, go to **Tools → Add-ons → Get Add-ons** and paste this code: 2055492159
Installation

### 2. Install dependencies
Your scripts need **bash** and **jq**:

#### On Ubuntu/Debian:

sudo apt-get update
sudo apt-get install jq

### 3. Download/clone this repo

Put all scripts in one folder (e.g. anki-tracker).

### 4. Make scripts executable

Run this in the project folder:

chmod +x ankiCodeMenu.sh ankiCode1.sh reviewsSummary.sh

## Configuration

You may need to adjust these variables depending on your deck setup:

1. Button Mapping

Inside the script:

failButton = 1
passButton = 3

These correspond to Anki’s review buttons. Adjust if your mappings differ.


2. Field Names

The script assumes your notes have these fields:

Word
Word Reading
Word Meaning

Change these in the code if your note type uses different field names.

## Usage

1. Open Anki and ensure you have completed your daily reviews for a given deck
2. Run ./ankiCodeMenu.sh in the terminal
3. Choose "1) Log Daily Anki Reviews" to log today's Anki reviews for a given deck.
4. Choose "2) Summary of Total Reviews" to obtain a log of every review for a given deck.




