#!/bin/bash -xv
curl -X POST -H "Content-Type: application/json" -d @$1 $2
