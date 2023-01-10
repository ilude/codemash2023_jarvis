# syntax=docker/dockerfile:1

FROM python:3-alpine

WORKDIR /app

ENV LANGUAGE=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV TZ=America/New_York

RUN apk --no-cache add \
  bash \
  build-base \
  ca-certificates \
  curl \
  tzdata \
  portaudio-dev && \
  ln -snf /etc/localtime /usr/share/zoneinfo/$TZ && echo $TZ > /etc/timezone && \
  echo "alias l='ls -lha --color=auto --group-directories-first'" >> /etc/profile.d/aliases.sh && \
  rm -rf /var/cache/apk/* 

COPY requirements.txt requirements.txt

RUN pip3 install -r requirements.txt

COPY . .

