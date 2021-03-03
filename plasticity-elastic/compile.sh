#!/bin/bash

mkdir output
cmake .. -DCMAKE_BUILD_TYPE=Release -DPRECISION=double -DPLASTICITY=ON
make -j5
