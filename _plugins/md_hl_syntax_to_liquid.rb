# frozen_string_literal: true

# Convert markdown highlight lines feature syntax to liquid syntax
# Author: https://github.com/jekyll/jekyll/issues/8621#issuecomment-839184339
# Usage:
# ```py{1 2-3}
# def foo():
#     print("Hello World")
#     a = 42
# ```

Jekyll::Hooks.register(:documents, :pre_render) do |document, payload|
  docExt = document.extname.tr(".", "")

  # only process if we deal with a markdown file
  if payload["site"]["markdown_ext"].include?(docExt)
    document.content.gsub!(
      /^\`\`\`([A-z]+){([\d\s]+)}$(.*?)^\`\`\`$/im,
      "{% highlight \\1 mark_lines=\"\\2\" %}\\3{% endhighlight %}"
    )
  end
end
