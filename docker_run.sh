docker build . -t lasote:conanblog
docker run -it -v$(pwd):/home/conan/blog -p4000:4000 /bin/bash -c "blog/serve.sh"
