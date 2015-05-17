yakayak
=======

Desktop client for Google Hangouts

Structure

- src/: is where sources live
- src/ui/: holds renderer code
- app/: is where the app is built

Dance goes like this

    npm install .
    npm run compile # builds coffee stuff from src/ to app/
    ./node_modules/.bin/brunch build # builds css from src/ to app/
    ./node_modules/.bin/electron .
