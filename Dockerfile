# Multi-arch (native on arm64 and amd64) image to preview the blog locally.
#
#   docker build -t conan-blog .
#   docker run --rm -p 4000:4000 -v "$PWD":/srv/jekyll conan-blog
#
# Behind a TLS-inspecting proxy, pass its root CA to the build:
#   docker build --secret id=ca,src=/path/to/root-ca.crt -t conan-blog .
FROM ruby:3.3-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

# Same gem versions that GitHub Pages uses, see https://pages.github.com/versions/
RUN --mount=type=secret,id=ca \
    if [ -f /run/secrets/ca ]; then \
        cat /etc/ssl/certs/ca-certificates.crt /run/secrets/ca > /tmp/ca-bundle.crt; \
        export SSL_CERT_FILE=/tmp/ca-bundle.crt; \
    fi \
    && gem install --no-document \
        kramdown:2.4.0 kramdown-parser-gfm:1.1.0 rouge:3.30.0 \
        jekyll:3.10.0 jekyll-paginate:1.1.0 webrick \
    && rm -f /tmp/ca-bundle.crt

WORKDIR /srv/jekyll
EXPOSE 4000
CMD ["jekyll", "serve", "--host", "0.0.0.0", "--future", "--force_polling"]
