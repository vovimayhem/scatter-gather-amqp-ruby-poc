# I: Runtime Stage: ============================================================
# This is the stage where we build the runtime base image, which is used as the
# common ancestor by the rest of the stages, and contains the minimal runtime
# dependencies required for the application to run:

# 1: Use ruby 2.5.1 (alpine 3.7) as base:
FROM ruby:2.5.1-alpine AS runtime

# 2: We'll set the application path as the working directory
WORKDIR /usr/src

# 3: We'll set the working dir as HOME and add the app's binaries path to $PATH:
ENV HOME=/usr/src PATH=/usr/src/bin:$PATH

# 4: Install the runtime dependencies from plain apk:
RUN apk add --no-cache \
 ca-certificates \
 less \
 openssl \
 tzdata

# II: Development Stage: =======================================================
# In this stage we'll build the image used for development, including compilers,
# and development libraries. This is also a previous step for building a
# releasable Docker image:

# 1: Start off from the runtime stage image:
FROM runtime AS development

# 2: Install the development dependency packages:
RUN apk add --no-cache build-base git

# 3: Copy the project's Gemfile + lock:
ADD Gemfile* /usr/src/

# 4: Install the current project gems - they can be safely changed later during
# development via `bundle install` or `bundle update`:
RUN bundle install --jobs=4 --retry=3
