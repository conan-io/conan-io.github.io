# Blog for the Conan Team

- Preview in local:

```sh
sudo apt-get install ruby ruby-dev zlib1g-dev
sudo gem install github-pages
jekyll serve _config.yml --watch
```

If you are writing a post with a future publication date and you want to check
it out in local, pass `--future` to jekyll. Otherwise, it won't be generated
until the publication date:

```sh
jekyll serve _config.yml --watch --future
```

- Preview in local: Docker

```sh
docker run --rm -v $(pwd):/srv/jekyll -p 4000:4000 jekyll/jekyll:latest sh -c "gem install webrick && jekyll serve --host 0.0.0.0"
```

See blog at localhost:4000

- Create new post: Just create the file with the format YEAR-MONTH-DAY-title.md

## Post Front Matter

Each post needs a few fields and there are optional fields as well for SEO optimization

```yaml
---
layout: post
comments: false
title: "Short meaningful title to display on the web page"
meta_title: "(optional) A longer more descriptive title for search engines to index"
description: "A short summary of the post that will be displayed in the search engine results"
last_modified_at: "(optional) the date the post was last updated to improve search results and relevance"
keywords: "(optional) comma, separated, values, for seo optimization"
---
```

> **Note**: SEO Structured Data - This is was attempted but is currently undefined. It was previously done with
[TechArticle](https://schema.org/TechArticle) however that probably is not list by
[Google's supported list](https://developers.google.com/search/docs/appearance/structured-data/article)

## Miscellany

### Highlight specific lines on a code block

As Jekyll 4.4 has not been released yet, some custom plugins have been added to provide that functionality:

- line_highlighting.rb: will provide a liquid API to highlight lines on code block emulating native [not yet released functionality](https://jekyllrb.com/docs/liquid/tags/#marking-specific-lines)
- md_hl_syntax_to_liquid.rb: provide a kramdown API to previous liquid syntax
- inline_highlight.rb: plugin to allow highlight code in-line

Also, when dealing with line highlighting on a enumerate list, kramdown will break the auto enumeration.
The only solution found by the team is to declare each list item as `&nbsp;<number>`

The `&nbsp;` basically blocks auto-numbering for numbered items.
