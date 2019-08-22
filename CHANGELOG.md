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
