source 'https://rubygems.org'

# Vanilla Jekyll, not the github-pages gem — this theme expects to be
# built via GitHub Actions and deployed to a separate output repo (see
# .github/workflows/deploy.yml and README "Recommended setup"). That
# unlocks gems the Pages-classic build environment doesn't whitelist.
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
platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem 'tzinfo', '>= 1', '< 3'
  gem 'tzinfo-data'
end
