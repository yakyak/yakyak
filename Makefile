.DEFAULT_GOAL := all
.PHONY: all clean npm_install deploy

all: clean npm_install app deploy reload mostlyclean

reload: mostlyclean npm_install app deploy

npm_install:
	npm install

app:
	gulp

deploy:
	./deploy.sh

mostlyclean:
	rm -rf app/
	rm -rf dist/*/*

clean:
	rm -rf app/
	rm -rf dist/

