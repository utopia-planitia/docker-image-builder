
load test_helper

setup() {
  export DATE=$(date +%s%N)

  export DOCKER_HOST=tcp://builder-0.builder:2375
  docker pull alpine:3.7 >&2
  docker build --build-arg version="$DATE" -t cache-from-rewrite:latest tests/example-build >&2
  export DOCKER_HOST=tcp://builder-1.builder:2375
  docker pull alpine:3.7 >&2
  docker pull busybox >&2
}

@test "cache from :latest tagged image, ignoring --cachefrom image" {
  run docker build --memory-swap=-1 --build-arg version="$DATE" -t cache-from-rewrite:$DATE --cache-from=busybox tests/example-build
  [ "$status" -eq 0 ]
  [ "${lines[7]}" = " ---> Using cache" ]
  [ "${lines[10]}" = " ---> Using cache" ]
  [[ "${lines[12]}" =~ Successfully.* ]]
  [[ "${lines[13]}" =~ Successfully.* ]]
}
