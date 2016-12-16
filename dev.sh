./node_modules/.bin/gulp watch &
sleep 1; ./node_modules/.bin/electron app
killall gulp
