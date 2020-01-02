## Unreleased

## 0.3.1 (January 2nd, 2020)

Bugs:

* Fixed injection bug causing kube-system pods to be rejected [VK8S-14]

## 0.3.0 (December 19th, 2019)

Features:

* Extra containers can now be added to the Vault pods
* Added configurability of pod probes
* Added Vault Agent Injector 

Improvements:

* Moved `global.image` to `server.image`
* Changed UI service template to route pods that aren't ready via `publishNotReadyAddresses: true`
* Added better HTTP/HTTPS scheme support to http probes
* Added configurable node port for Vault service
* `server.authDelegator` is now enabled by default

Bugs:

* Fixed upgrade bug by removing chart label which contained the version
* Fixed typo on `serviceAccount` (was `serviceaccount`)
* Fixed readiness/liveliness HTTP probe default to accept standbys

## 0.2.1 (November 12th, 2019)

Bugs:

* Removed `readOnlyRootFilesystem` causing issues when validating deployments

## 0.2.0 (October 29th, 2019)

Features:

* Added load balancer support
* Added ingress support
* Added configurable for service types (ClusterIP, NodePort, LoadBalancer, etc)
* Removed root requirements, now runs as Vault user

Improvements:

* Added namespace value to all rendered objects
* Made ports configurable in services
* Added the ability to add custom annotations to services
* Added docker image for running bats test in CircleCI
* Removed restrictions around `dev` mode such as annotations
* `readOnlyRootFilesystem` is now configurable
* Image Pull Policy is now configurable

Bugs:

* Fixed selector bugs related to Helm label updates (services, affinities, and pod disruption)
* Fixed bug where audit storage was not being mounted in HA mode
* Fixed bug where Vault pod wasn't receiving SIGTERM signals


## 0.1.2 (August 22nd, 2019)

Features:

* Added `extraSecretEnvironmentVars` to allow users to mount secrets as
  environment variables
* Added `tlsDisable` configurable to change HTTP protocols from HTTP/HTTPS 
  depending on the value
* Added `serviceNodePort` to configure a NodePort value when setting `serviceType` 
  to "NodePort"

Improvements:

* Changed UI port to 8200 for better HTTP protocol support
* Added `path` to `extraVolumes` to define where the volume should be 
  mounted.  Defaults to `/vault/userconfig`
* Upgraded Vault to 1.2.2

Bugs:

* Fixed bug where upgrade would fail because immutable labels were being 
  changed (Helm Version label)
* Fixed bug where UI service used wrong selector after updating helm labels
* Added `VAULT_API_ADDR` env to Vault pod to fixed bug where Vault thinks
  Consul is the active node
* Removed `step-down` preStop since it requires authentication.  Shutdown signal
  sent by Kube acts similar to `step-down`


## 0.1.1 (August 7th, 2019)

Features:

* Added `authDelegator` Cluster Role Binding to Vault service account for
  bootstrapping Kube auth method

Improvements:

* Added `server.service.clusterIP` to `values.yml` so users can toggle
  the Vault service to headless by using the value `None`.
* Upgraded Vault to 1.2.1

## 0.1.0 (August 6th, 2019)

Initial release
