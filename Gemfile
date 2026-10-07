source 'https://rubygems.org'

ruby file: '.ruby-version'

# Vanilla Jekyll, not the github-pages gem. Both publishing paths build
# through GitHub Actions, either to the public fork's own Pages site or a
# separate public output repo. This allows build-time math in both modes.
gem 'jekyll', '~> 4.3'

# Renders LaTeX math at build time via KaTeX (no client-side JS engine
# at runtime — only KaTeX's CSS for glyph styling). Requires Node.js
# on the build machine; pre-installed on ubuntu-latest runners.
gem 'kramdown-math-katex'

group :jekyll_plugins do
  gem 'jekyll-paginate'
end

# Windows and JRuby do not include zoneinfo files; ship a copy with
# the build if you develop on Windows.
platforms :windows, :jruby do
  gem 'tzinfo', '>= 1', '< 3'
  gem 'tzinfo-data'
end
