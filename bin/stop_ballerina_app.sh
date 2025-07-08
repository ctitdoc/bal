#!/bin/bash -xv
## stops a ballerina program execution using java jps:
## this is mainly used to stop ballerina services:
## pass the jar of the service as parameter and this service is stoped
## a program runs several services then run jps command alone to identify
## how/if jps identifies the execution a particular service and pass
## the identifier as parameter, the the command below greps on it and
## kills the retrievd PID. If this identifier match several execution
## the it is not an 'execution unique identifier' so it will kill one of
## the PID identified by it so it's not a valid way to kill a single execution.
kill -9 `jps | grep $1 | awk {'print $1'}`
