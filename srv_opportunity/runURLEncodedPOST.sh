#!/bin/bash -xv
curl -X POST -H "Content-Type: application/x-www-form-urlencoded" -d @$1 $2
