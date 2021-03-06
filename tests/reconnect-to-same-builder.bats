
load test_helper

@test "reconnect to same builder" {
  docker pull alpine:3.7 >&2
  docker build --build-arg version="$DATE" -t reconnect-$DATE-2 tests/example-build >&2
  run docker build --memory-swap=-1 --build-arg version="$DATE" -t reconnect-$DATE-2 tests/example-build
  [ "$status" -eq 0 ]
  [ "${lines[7]}" = " ---> Using cache" ]
  [ "${lines[10]}" = " ---> Using cache" ]
  [[ "${lines[12]}" =~ Successfully.* ]]
}
