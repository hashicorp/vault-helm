---
name: Bug report
about: Let us know about a bug!
title: ''
labels: bug
assignees: ''

---

<!-- Please reserve GitHub issues for bug reports and feature requests.

For questions, the best place to get answers is on our [discussion forum](https://discuss.hashicorp.com/c/vault), as they will get more visibility from experienced users than the issue tracker.

Please note: We take Vault's security and our users' trust very seriously. If you believe you have found a security issue in Vault Helm, _please responsibly disclose_ by contacting us at [security@hashicorp.com](mailto:security@hashicorp.com).

-->

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Install chart
2. Run vault command
3. See error (vault logs, etc.)

Other useful info to include: vault pod logs, `kubectl describe statefulset vault` and `kubectl get statefulset vault -o yaml` output

**Expected behavior**
A clear and concise description of what you expected to happen.

**Environment**
* Kubernetes version: 
  * Distribution or cloud vendor (OpenShift, EKS, GKE, AKS, etc.):
  * Other configuration options or runtime services (istio, etc.):
* vault-helm version:

Chart values:

```yaml
# Paste your user-supplied values here (`helm get values <release>`).
# Be sure to scrub any sensitive values!
```

**Additional context**
Add any other context about the problem here.
