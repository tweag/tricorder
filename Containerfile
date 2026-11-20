# This is an example container image to demonstrate how to use tricorder from
# within a container.
FROM docker.io/haskell:9-slim
MAINTAINER Victor victor.bakke@tweag.io
WORKDIR /src
RUN cabal update && cabal install tricorder
ENTRYPOINT ["/root/.local/bin/tricorder"]
CMD ["--help"]
