#!/bin/bash -xv
curl -X POST -H "Content-Type: application/json" -d @$1 http://localhost:9090/schemed_talks
