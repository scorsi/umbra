#!/usr/bin/env bash

echo "----------------------------------------------------------"
echo "Ensuring Elixir is installed..."
echo "----------------------------------------------------------"
command -v elixir >/dev/null 2>&1 || {
  echo "This app requires Elixir, but it was not found on your system."
  echo "Install it using the instructions at http://elixir-lang.org"
  exit 1
}
echo "Done!"

echo "----------------------------------------------------------"
echo "Running Tests..."
echo "----------------------------------------------------------"

MIX_ENV="dev" mix compile --warnings-as-errors --force || { echo 'Please fix all compiler warnings.'; exit 1; }
MIX_ENV="test" mix credo --strict || { echo 'Credo linting failed. See warnings above.'; exit 1; }
MIX_ENV="test" mix docs || { echo 'Docs were not generated!'; exit 1; }
MIX_ENV="test" mix test || { echo 'Test failed!'; exit 1; }

if [ "$CI" ]; then
  if [ "$TRAVIS" ]; then
    echo "----------------------------------------------------------"
    echo "Running coveralls.travis..."
    echo "----------------------------------------------------------"
    MIX_ENV="test" mix coveralls.travis || { echo 'Coverage failed!'; exit 1; }
    echo "Done!"
#    echo "----------------------------------------------------------"
#    echo "Running inch.report..."
#    echo "----------------------------------------------------------"
#    MIX_ENV="docs" mix inch.report || { echo 'Inch report failed!'; exit 1; }
#    echo "Done!"
  else
    echo "----------------------------------------------------------"
    echo "Running coveralls..."
    echo "----------------------------------------------------------"
    MIX_ENV="test" mix coveralls || { echo 'Coverage failed!'; exit 1; }
    echo "Done!"
  fi
fi
