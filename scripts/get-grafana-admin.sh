#!/bin/bash
echo "Grafana username is:"
echo "admin"
echo "Grafana password is:"
kubectl get secret --namespace loki-stack loki-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo