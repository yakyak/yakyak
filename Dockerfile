FROM node
RUN apt-get update
RUN apt-get update && apt-get install -y wine zip xvfb
RUN dpkg --add-architecture i386 && apt-get update
RUN apt-get install -y wine32
RUN wine wineboot --init

ENV DISPLAY=""
ENV DEBUG=electron-packager,extract-zip

WORKDIR /data

RUN git clone https://github.com/yakyak/yakyak.git yakyak

WORKDIR /data/yakyak

RUN npm install
