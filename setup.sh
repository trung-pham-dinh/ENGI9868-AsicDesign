#!/bin/bash
  
PROJVAR_PROJECT_ROOT=$(git rev-parse --show-toplevel)
# Set temporary environment variables
export PROJVAR_PROJECT_ROOT="$PROJVAR_PROJECT_ROOT" 
