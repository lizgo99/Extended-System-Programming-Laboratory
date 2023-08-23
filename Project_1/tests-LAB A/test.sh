#!/bin/bash

# Clean
make clean
# Compile the C program using Makefile
make

# Define test cases
test_cases=(
  "test1|+e12345"
  "test2|-e4321"
  "test3"
  "test4|+e1"
  "test5|-itests/test5"
  "test6|-otests/output6"
  "test7|-itests/test7 -otests/output7"
  "test8|-e923 -itests/test8 -otests/output8"
  "test9|+e9021 -itests/test9 -otests/output9"
)

# Set timeout duration
timeout_duration=5s
grace_period=2s

# Initialize failed_tests counter
failed_tests=0

# Remove output files if they exist
for input in "${test_cases[@]}"; do
  test_name=${input%%|*}
  output_file="tests/output${test_name#test}"
  if [[ -f "$output_file" ]]; then
    rm "$output_file"
  fi
done

# Run tests
for input in "${test_cases[@]}"; do
  IFS='|' read -r -a inputs_and_args <<< "$input"
  test_name=${inputs_and_args[0]}
  args=(${inputs_and_args[1]})
  
  input_file="tests/${test_name}"
  expected_output_file="tests/expected${test_name#test}"
  output_file="tests/output${test_name#test}"

  if [[ ! -f "$input_file" || ! -f "$expected_output_file" ]]; then
    echo "Missing input or expected output file for $test_name"
    failed_tests=$((failed_tests+1))
    continue
  fi

  inputs=$(cat "$input_file")
  expected_output=$(cat "$expected_output_file")

 # Check if the "-i" and "-o" flags are present in arguments
  use_stdin=true
  output_to_file=false
  for arg in "${args[@]}"; do
    if [[ ${arg:0:2} == "-i" ]]; then
      use_stdin=false
    elif [[ ${arg:0:2} == "-o" ]]; then
      output_to_file=true
    fi
  done

  # Run the encoder with appropriate input and output handling
  if $use_stdin && ! $output_to_file; then
    actual_output=$(echo -e "$inputs" | timeout --kill-after="$grace_period" "$timeout_duration" ./encoder "${args[@]}")
  elif $use_stdin && $output_to_file; then
    echo -e "$inputs" | timeout --kill-after="$grace_period" "$timeout_duration" ./encoder "${args[@]}"
  elif ! $use_stdin && ! $output_to_file; then
    actual_output=$(timeout --kill-after="$grace_period" "$timeout_duration" ./encoder "${args[@]}")
  else
    timeout --kill-after="$grace_period" "$timeout_duration" ./encoder "${args[@]}"
  fi

  exit_status=$?

  if ! $output_to_file; then
    # Write the actual output to the output file
    echo "$actual_output" > "$output_file"
  else
    # Read the output from the output file specified by the encoder
    actual_output=$(cat "$output_file")
  fi

  if [[ $exit_status -eq 124 ]]; then
    echo "Test timed out: $test_name"
    failed_tests=$((failed_tests+1))
    continue
  fi

  if [[ "$actual_output" == "$expected_output" ]]; then
    echo "Test passed: $test_name"
  else
    echo "Test failed: $test_name"
    echo "Expected output: $expected_output"
    echo "Actual output: $actual_output"
    failed_tests=$((failed_tests+1))
  fi
done


# Check if all tests passed
if [[ $failed_tests -eq 0 ]]; then
  echo "All tests passed"
else
  echo "Failed tests: $failed_tests"
fi

grade=$((90-10*failed_tests))
echo "grade: $grade/90"
