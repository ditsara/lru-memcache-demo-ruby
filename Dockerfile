FROM ruby:2.3.1
# RUN apt-get update -qq && apt-get install -y \
#   build-essential libpq-dev nodejs-legacy
RUN gem install bundler

WORKDIR /app
# ADD Gemfile /app/Gemfile
# ADD lru-memcache-demo.gemspec /app/lru-memcache-demo.gemspec
# ADD Gemfile.lock /app/Gemfile.lock

ADD . /app
RUN bundle install
