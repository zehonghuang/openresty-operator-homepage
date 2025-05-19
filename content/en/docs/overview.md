---
title: Overview
description: Learn what OpenResty Operator is, how it works, and whether it's right for your API gateway use case.
weight: 1
---

{{% pageinfo %}}
OpenResty Operator is a Kubernetes-native Operator for managing OpenResty as an internal API gateway.  
It supports CRD-driven configuration, GitOps workflows, Prometheus integration, and hot reload — all without the need for etcd or admin APIs.
{{% /pageinfo %}}

## What is it?

OpenResty Operator is a lightweight Kubernetes controller that manages API gateway configuration using Custom Resource Definitions (CRDs).  
It allows developers to declaratively configure reverse proxy routes, upstream logic, and request normalization via GitOps tools such as Argo CD or Flux.

The Operator renders Nginx-compatible configurations based on CRDs like `Location`, `ServerBlock`, and `Upstream`, enabling flexible internal API composition without relying on heavy gateway solutions like Kong or APISIX.

## Why do I want it?

OpenResty Operator is ideal for:

- Teams proxying many third-party APIs with similar patterns
- Lightweight internal gateways that don't need a full service mesh
- GitOps-native Kubernetes environments using Helm/Kustomize
- Clusters that require hot-reloadable Nginx and built-in Prometheus observability

**What it is not good for:**

- Full-fledged public API management with advanced traffic policies
- Complex multi-tenant gateway scenarios

**Coming soon:**

- Webhook-based CRD validation
- Advanced normalize rule sets with JSONPath/Lua fallback

## Where should I go next?

- [Getting Started](/docs/getting-started/): Learn how to install and try OpenResty Operator
- [Examples](/docs/examples/): Browse real-world use cases and YAML examples
- [CRDs](https://github.com/zehonghuang/openresty-operator/tree/main/charts/openresty-operator/crds): Understand the declarative resources used in the Operator
