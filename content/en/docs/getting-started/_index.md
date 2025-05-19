---
title: Getting Started
description: Install the operator in your Kubernetes cluster and try your first CRD deployment.
weight: 2
---

{{% pageinfo %}}
This section will help you install OpenResty Operator into your Kubernetes cluster and deploy your first proxy using CRDs.
{{% /pageinfo %}}

## Prerequisites

- A Kubernetes cluster (v1.21+ recommended)
- `kubectl` installed and configured
- Helm v3.7+ installed
- Access to a GitOps workflow (e.g., Argo CD) is optional but recommended

## Installation

You can install OpenResty Operator via Helm:

```bash
helm repo add openresty-operator https://huangzehong.me/openresty-operator
helm install openresty-operator openresty-operator/openresty-operator
```

You can verify the deployment with:

```bash
kubectl get pods -l app.kubernetes.io/name=openresty-operator
```

## Setup

After installation, you can start deploying your own API gateways by defining CRDs like `OpenRestyApp`, `ServerBlock`, `Location`, and `Upstream`.

## Try it out!

Here's a basic example to deploy an OpenResty instance with a static location:

```yaml
apiVersion: openresty.io/v1alpha1
kind: OpenRestyApp
metadata:
  name: demo-app
spec:
  replicas: 1
  image: openresty/openresty:alpine
  serverRefs:
    - name: demo-server
---
apiVersion: openresty.io/v1alpha1
kind: ServerBlock
metadata:
  name: demo-server
spec:
  port: 80
  locationRefs:
    - name: hello-location
---
apiVersion: openresty.io/v1alpha1
kind: Location
metadata:
  name: hello-location
spec:
  path: /
  proxyPass: https://httpbin.org/get
```

Apply these YAMLs and check the resulting service:

```bash
kubectl apply -f ./demo.yaml
kubectl port-forward svc/demo-server 8080:80
curl http://localhost:8080
```

You should see a response from httpbin.org, routed through your OpenResty instance managed by the Operator.
