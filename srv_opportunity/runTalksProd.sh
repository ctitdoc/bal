#!/bin/bash -xv
curl -X POST -H "Content-Type: application/json" -d @$1 https://opportunity.itautomotive.fr/api/login_check
