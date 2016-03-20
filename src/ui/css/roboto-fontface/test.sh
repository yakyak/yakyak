#!/bin/bash -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for FILE in $DIR/css/*.less; do
  echo "less $FILE"
  lessc "$FILE" >/dev/null
done

for FILE in $DIR/css/*.scss; do
  echo "sass $FILE"
  node-sass "$FILE" >/dev/null
done
