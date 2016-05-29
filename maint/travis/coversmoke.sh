if [ -n "$COVERAGE" ] && ! [ "$COVERAGE" == "0" ]; then
  export AUTHOR_TESTING=1
  export RELEASE_TESTING=1
  export SMOKE_TESTING=1
  export AUTOMATED_TESTING=1
fi
