#!/bin/bash
OK=1
if jq --version > /dev/null; then
  echo "JQ OK"
else
  OK=0;
  echo "JQ in errored state"
fi

if terraform -version > /dev/null; then
  echo "Terraform OK"
else
  OK=0;
  echo "Terraform in errored state"
fi

if poetry --version > /dev/null; then
  echo "Poetry OK"
else
  OK=0;
  echo "Poetry in errored state"
fi

if az --version > /dev/null 2>&1; then
  echo "Azure CLI OK"
else
  OK=0;
  az --version > /dev/null;
  echo "Azure CLI in errored state"
fi

if kubectl version --client --short > /dev/null; then
  echo "Kubectl OK"
else
  OK=0;
  echo "Kubectl in errored state"
fi

if [ $OK == 0 ]; then
  echo "-----------------------------------------"
  echo "-- You are missing some prerequisites. --"
  echo "--       See above for details.        --"
  echo "-----------------------------------------"
else
  echo "-----------------------------------------"
  echo "--     All prerequisites are OK!       --"
  echo "--         You are good to go.         --"
  echo "-----------------------------------------"
fi