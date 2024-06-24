#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t -q --no-align -c"

START_GAME() {
  echo "Enter your username:"
  read -r USERNAME

  if [[ ! -z $USERNAME ]]; then
    FIND_USERNAME=$($PSQL "SELECT username_id, username FROM usernames WHERE username='$USERNAME'")
    if [[ $FIND_USERNAME ]]; then
      IFS='|' read -r USERNAME_ID USERNAME <<< "$FIND_USERNAME"
      NUM_GAMES=$($PSQL "SELECT COUNT(*) FROM games WHERE username_id=$USERNAME_ID")
      BEST_GAME=$($PSQL "SELECT MIN(num_of_tries) FROM games WHERE username_id=$USERNAME_ID")
      echo "Welcome back, $USERNAME! You have played $NUM_GAMES games, and your best game took $BEST_GAME guesses."
    else
      echo "Welcome, $USERNAME! It looks like this is your first time here."
      $PSQL "INSERT INTO usernames(username) VALUES('$USERNAME');"
      FIND_USERNAME=$($PSQL "SELECT * FROM usernames WHERE username='$USERNAME'")
      IFS='|' read -r USERNAME_ID USERNAME <<< "$FIND_USERNAME"
    fi
    SECRET_NUMBER=$(( (RANDOM % 1000) + 1 ))
    START_GUESSING $SECRET_NUMBER "Guess the secret number between 1 and 1000:" 1
  else
    echo "Username can't be empty."
    START_GAME
  fi
}

START_GUESSING() {
  echo $2
  read -r GUESS
  if [[ $GUESS =~ ^-?[0-9]+$ ]]; then
    if (( $GUESS == $1 )); then
      echo "You guessed it in $3 tries. The secret number was $1. Nice job!"
      $PSQL "INSERT INTO games(username_id, num_of_tries) VALUES($USERNAME_ID, $3)"
    else
      if (( $GUESS < $1 )); then
        START_GUESSING $1 "It's higher than that, guess again:" $(($3+1))
      elif (( $GUESS > $1 )); then
        START_GUESSING $1 "It's lower than that, guess again:" $(($3+1))
      fi
    fi
  else
    START_GUESSING $1 "That is not an integer, guess again:" $3
  fi
}

START_GAME