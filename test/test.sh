#!/bin/bash
TEST_DIR=/

function test () {
  pushd ${TEST_DIR}/$1
  bats .
  popd
}

test unit
