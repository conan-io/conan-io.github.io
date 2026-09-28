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
