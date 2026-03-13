#!/bin/bash

# 1. Get Backend Details
BACKEND_IP=$(kubectl get pod -n cilium-test -l app=backend -o jsonpath='{.items[0].status.podIP}')
echo "Target Backend IP: $BACKEND_IP"
echo "------------------------------------------------"

# 2. Test Authorized Access (Frontend)
echo "[TEST 1] Accessing from FRONTEND (app=frontend)..."
FRONTEND_POD=$(kubectl get pod -n cilium-test -l app=frontend -o name)
kubectl exec -n cilium-test $FRONTEND_POD -- curl -s -m 5 --fail $BACKEND_IP > /dev/null

if [ $? -eq 0 ]; then
    echo "SUCCESS: Frontend reached Backend."
else
    echo "FAILURE: Frontend could not reach Backend."
fi

echo "------------------------------------------------"

# 3. Test Unauthorized Access (Stranger)
echo "[TEST 2] Accessing from STRANGER (no label)..."
echo "Expect this to TIMEOUT if policy is working."

# Using 'authorized' as the pod name but NOT giving it the label in the metadata
kubectl run stranger --image=curlimages/curl --rm -it --restart=Never -- \
  curl --connect-timeout 5 -s $BACKEND_IP

if [ $? -ne 0 ]; then
    echo -e "\nSUCCESS: Stranger was BLOCKED by Cilium."
else
    echo -e "\nSECURITY BREACH: Stranger reached Backend!"
fi

