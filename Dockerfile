FROM ubuntu:xenial

LABEL maintainer="Luis Martinez de Bartolome <luism@jfrog.com>"
RUN apt-get update
RUN apt-get install ruby ruby-dev zlib1g-dev
RUN gem install github-pages


