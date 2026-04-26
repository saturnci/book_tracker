FROM ruby:4.0.1-slim

RUN apt-get update && apt-get install -y \
  git \
  && rm -rf /var/lib/apt/lists/*

ARG SDK_COMMIT=8e99ca4
RUN git clone https://github.com/saturnci/saturnci-sdk.git /tmp/saturnci-sdk \
  && cd /tmp/saturnci-sdk \
  && git checkout $SDK_COMMIT \
  && gem build saturnci-sdk.gemspec \
  && gem install saturnci-sdk-*.gem \
  && rm -rf /tmp/saturnci-sdk

ENTRYPOINT ["ruby", "-rsaturnci-sdk"]
