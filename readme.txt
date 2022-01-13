- Preview in local:

sudo apt-get install ruby ruby-dev zlib1g-dev
sudo gem install github-pages
jekyll serve _config.yml --watch

If you are writing a post with a future publication date and you want to check
it out in local, pass `--future` to jekyll. Otherwise, it won't be generated
until the publication date:

jekyll serve _config.yml --watch --future

- Create new post: Just create the file with the format YEAR-MONTH-DAY-title.md
