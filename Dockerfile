# syntax=docker/dockerfile:1
# Development (Compose): `docker compose build` uses target `development` by default.
# Production (AMD64/ARM64): build final stage — same Dockerfile on Apple Silicon runners and ubuntu-latest CI.

ARG RUBY_VERSION=3.4.9

# -----------------------------------------------------------------------------
# development — Ruby image with build deps; bind-mount `.` when using Compose.
# -----------------------------------------------------------------------------
FROM docker.io/library/ruby:${RUBY_VERSION}-bookworm AS development

WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      curl \
      default-libmysqlclient-dev \
      default-mysql-client \
      git \
      libvips \
      libyaml-dev \
      pkg-config \
      shared-mime-info \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_APP_CONFIG="/usr/local/bundle" \
    RAILS_ENV="development"

COPY Gemfile Gemfile.lock ./
COPY vendor/ ./vendor/

RUN bundle install --jobs 4 --retry 3

COPY . .

ENTRYPOINT ["./bin/docker-entrypoint"]

EXPOSE 3000

CMD ["./bin/rails", "server", "-b", "0.0.0.0"]

# -----------------------------------------------------------------------------
# production — slim runtime + jemalloc; matches Rails 8 Kamal-oriented defaults.
# -----------------------------------------------------------------------------
FROM docker.io/library/ruby:${RUBY_VERSION}-slim AS base

WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl default-mysql-client libjemalloc2 libvips shared-mime-info && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"

FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential default-libmysqlclient-dev git libvips libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock ./
COPY vendor/ ./vendor/

RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile -j 1 --gemfile

COPY . .

RUN bundle exec bootsnap precompile -j 1 app/ lib/

RUN SECRET_KEY_BASE_DUMMY=1 REDIS_URL=redis://ignored:6380/1 ./bin/rails assets:precompile

FROM base

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash
USER 1000:1000

COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /rails /rails

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 80

CMD ["./bin/thrust", "./bin/rails", "server"]
