#!/bin/bash

echo "Running tests with $MATLAB..."
export PATH=$MATLAB_ROOT/bin:$PATH
touch startup.m
matlab -nodisplay -nodesktop -r "addpath(getenv('MATLAB_XUNIT_PATH'));javaaddpath(getenv('OVATION_JAR_PATH')); runtestsuite test; exit(0)"