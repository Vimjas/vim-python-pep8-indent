FROM ruby:2.4.0-slim
RUN apt-get update && \
    apt-get install -y vim-gtk xvfb && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /vim-python-pep8-indent
ADD Gemfile .
RUN bundle install
ADD . /vim-python-pep8-indent
ENTRYPOINT ["sh", "-c", "xvfb-run rspec spec $@", "ignore"]
