#!/bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Clear existing data
$PSQL "TRUNCATE TABLE games, teams RESTART IDENTITY CASCADE" >/dev/null

# Process games.csv
{
  read -r header # Skip header line
  while IFS="," read -r YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS
  do
    # Escape single quotes in text fields
    ROUND=${ROUND//\'/\'\'}
    WINNER=${WINNER//\'/\'\'}
    OPPONENT=${OPPONENT//\'/\'\'}

    # Get or create winner team
    WINNER_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$WINNER'")
    if [[ -z "$WINNER_ID" ]]
    then
      $PSQL "INSERT INTO teams(name) VALUES('$WINNER')" >/dev/null
      WINNER_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$WINNER'")
    fi

    # Get or create opponent team
    OPPONENT_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$OPPONENT'")
    if [[ -z "$OPPONENT_ID" ]]
    then
      $PSQL "INSERT INTO teams(name) VALUES('$OPPONENT')" >/dev/null
      OPPONENT_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$OPPONENT'")
    fi

    # Insert game record
    $PSQL "INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals) VALUES($YEAR, '$ROUND', $WINNER_ID, $OPPONENT_ID, $WINNER_GOALS, $OPPONENT_GOALS)" >/dev/null
  done
} < games.csv

echo "Data imported successfully"