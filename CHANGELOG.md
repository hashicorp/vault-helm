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
