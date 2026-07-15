#!/bin/bash

# Number guessing game backed by PostgreSQL

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read USERNAME
# Load the player's game history when the username already exists
USER_DATA=$($PSQL "
  SELECT
    u.user_id,
    COUNT(g.game_id),
    MIN(g.guesses)
  FROM users u
  LEFT JOIN games g USING(user_id)
  WHERE u.username='$USERNAME'
  GROUP BY u.user_id;
")

if [[ -z $USER_DATA ]]
then
  echo "Welcome, $USERNAME! It looks like this is your first time here."

  $PSQL "
    INSERT INTO users(username)
    VALUES('$USERNAME');
  " > /dev/null

  USER_ID=$($PSQL "
    SELECT user_id
    FROM users
    WHERE username='$USERNAME';
  ")
else
  IFS="|" read USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_DATA"

  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
NUMBER_OF_GUESSES=0

echo "Guess the secret number between 1 and 1000:"
read GUESS

while [[ $GUESS != $SECRET_NUMBER ]]
do
  ((NUMBER_OF_GUESSES++))

  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
  elif (( GUESS > SECRET_NUMBER ))
  then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi

  read GUESS
done

((NUMBER_OF_GUESSES++))

$PSQL "
  INSERT INTO games(user_id, guesses)
  VALUES($USER_ID, $NUMBER_OF_GUESSES);
" > /dev/null

echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
