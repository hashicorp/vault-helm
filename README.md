# vault

![Version: 2.0.1](https://img.shields.io/badge/Version-2.0.1-informational?style=flat-square) ![AppVersion: 1.7.3](https://img.shields.io/badge/AppVersion-1.7.3-informational?style=flat-square)

Official HashiCorp Vault Chart

**Homepage:** <https://www.vaultproject.io>

## Source Code

* <https://github.com/hashicorp/vault>
* <https://github.com/hashicorp/vault-helm>
* <https://github.com/hashicorp/vault-k8s>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| csi.daemonSet.annotations | object | `{}` |  |
| csi.daemonSet.updateStrategy.maxUnavailable | string | `""` |  |
| csi.daemonSet.updateStrategy.type | string | `"RollingUpdate"` |  |
| csi.debug | bool | `false` |  |
| csi.enabled | bool | `false` |  |
| csi.extraArgs | list | `[]` |  |
| csi.image.pullPolicy | string | `"IfNotPresent"` |  |
| csi.image.repository | string | `"hashicorp/vault-csi-provider"` |  |
| csi.image.tag | string | `"0.3.0"` |  |
| csi.livenessProbe.failureThreshold | int | `2` |  |
| csi.livenessProbe.initialDelaySeconds | int | `5` |  |
| csi.livenessProbe.periodSeconds | int | `5` |  |
| csi.livenessProbe.successThreshold | int | `1` |  |
| csi.livenessProbe.timeoutSeconds | int | `3` |  |
| csi.pod.annotations | object | `{}` |  |
| csi.pod.tolerations | string | `nil` |  |
| csi.readinessProbe.failureThreshold | int | `2` |  |
| csi.readinessProbe.initialDelaySeconds | int | `5` |  |
| csi.readinessProbe.periodSeconds | int | `5` |  |
| csi.readinessProbe.successThreshold | int | `1` |  |
| csi.readinessProbe.timeoutSeconds | int | `3` |  |
| csi.resources | object | `{}` |  |
| csi.serviceAccount.annotations | object | `{}` |  |
| csi.volumeMounts | string | `nil` |  |
| csi.volumes | string | `nil` |  |
| global.enabled | bool | `true` |  |
| global.imagePullSecrets | list | `[]` |  |
| global.openshift | bool | `false` |  |
| global.psp.annotations | string | `"seccomp.security.alpha.kubernetes.io/allowedProfileNames: docker/default,runtime/default\napparmor.security.beta.kubernetes.io/allowedProfileNames: runtime/default\nseccomp.security.alpha.kubernetes.io/defaultProfileName:  runtime/default\napparmor.security.beta.kubernetes.io/defaultProfileName:  runtime/default\n"` |  |
| global.psp.enable | bool | `false` |  |
| global.tlsDisable | bool | `true` |  |
| injector.affinity | string | `"podAntiAffinity:\n  requiredDuringSchedulingIgnoredDuringExecution:\n    - labelSelector:\n        matchLabels:\n          app.kubernetes.io/name: {{ template \"vault.name\" . }}-agent-injector\n          app.kubernetes.io/instance: \"{{ .Release.Name }}\"\n          component: webhook\n      topologyKey: kubernetes.io/hostname\n"` |  |
| injector.agentDefaults.cpuLimit | string | `"500m"` |  |
| injector.agentDefaults.cpuRequest | string | `"250m"` |  |
| injector.agentDefaults.memLimit | string | `"128Mi"` |  |
| injector.agentDefaults.memRequest | string | `"64Mi"` |  |
| injector.agentDefaults.template | string | `"map"` |  |
| injector.agentImage.repository | string | `"vault"` |  |
| injector.agentImage.tag | string | `"1.7.3"` |  |
| injector.annotations | object | `{}` |  |
| injector.authPath | string | `"auth/kubernetes"` |  |
| injector.certs.caBundle | string | `""` |  |
| injector.certs.certName | string | `"tls.crt"` |  |
| injector.certs.keyName | string | `"tls.key"` |  |
| injector.certs.secretName | string | `nil` |  |
| injector.enabled | bool | `true` |  |
| injector.externalVaultAddr | string | `""` |  |
| injector.extraEnvironmentVars | object | `{}` |  |
| injector.extraLabels | object | `{}` |  |
| injector.failurePolicy | string | `"Ignore"` |  |
| injector.hostNetwork | bool | `false` |  |
| injector.image.pullPolicy | string | `"IfNotPresent"` |  |
| injector.image.repository | string | `"hashicorp/vault-k8s"` |  |
| injector.image.tag | string | `"0.10.2"` |  |
| injector.leaderElector.enabled | bool | `true` |  |
| injector.leaderElector.image.repository | string | `"gcr.io/google_containers/leader-elector"` |  |
| injector.leaderElector.image.tag | string | `"0.4"` |  |
| injector.leaderElector.ttl | string | `"60s"` |  |
| injector.logFormat | string | `"standard"` |  |
| injector.logLevel | string | `"info"` |  |
| injector.metrics.enabled | bool | `false` |  |
| injector.namespaceSelector | object | `{}` |  |
| injector.nodeSelector | string | `nil` |  |
| injector.objectSelector | object | `{}` |  |
| injector.port | int | `8080` |  |
| injector.priorityClassName | string | `""` |  |
| injector.replicas | int | `1` |  |
| injector.resources | object | `{}` |  |
| injector.revokeOnShutdown | bool | `false` |  |
| injector.service.annotations | object | `{}` |  |
| injector.tolerations | string | `nil` |  |
| server.affinity | string | `"podAntiAffinity:\n  requiredDuringSchedulingIgnoredDuringExecution:\n    - labelSelector:\n        matchLabels:\n          app.kubernetes.io/name: {{ template \"vault.name\" . }}\n          app.kubernetes.io/instance: \"{{ .Release.Name }}\"\n          component: server\n      topologyKey: kubernetes.io/hostname\n"` |  |
| server.annotations | object | `{}` |  |
| server.auditStorage.accessMode | string | `"ReadWriteOnce"` |  |
| server.auditStorage.annotations | object | `{}` |  |
| server.auditStorage.enabled | bool | `false` |  |
| server.auditStorage.mountPath | string | `"/vault/audit"` |  |
| server.auditStorage.size | string | `"10Gi"` |  |
| server.auditStorage.storageClass | string | `nil` |  |
| server.authDelegator.enabled | bool | `true` |  |
| server.dataStorage.accessMode | string | `"ReadWriteOnce"` |  |
| server.dataStorage.annotations | object | `{}` |  |
| server.dataStorage.enabled | bool | `true` |  |
| server.dataStorage.mountPath | string | `"/vault/data"` |  |
| server.dataStorage.size | string | `"10Gi"` |  |
| server.dataStorage.storageClass | string | `nil` |  |
| server.dev.devRootToken | string | `"root"` |  |
| server.dev.enabled | bool | `false` |  |
| server.enabled | bool | `true` |  |
| server.enterpriseLicense.secretKey | string | `"license"` |  |
| server.enterpriseLicense.secretName | string | `""` |  |
| server.extraArgs | string | `""` |  |
| server.extraContainers | string | `nil` |  |
| server.extraEnvironmentVars | object | `{}` |  |
| server.extraInitContainers | string | `nil` |  |
| server.extraLabels | object | `{}` |  |
| server.extraSecretEnvironmentVars | list | `[]` |  |
| server.extraVolumes | list | `[]` |  |
| server.ha.apiAddr | string | `nil` |  |
| server.ha.config | string | `"ui = true\n\nlistener \"tcp\" {\n  tls_disable = 1\n  address = \"[::]:8200\"\n  cluster_address = \"[::]:8201\"\n}\nstorage \"consul\" {\n  path = \"vault\"\n  address = \"HOST_IP:8500\"\n}\n\nservice_registration \"kubernetes\" {}\n\n# Example configuration for using auto-unseal, using Google Cloud KMS. The\n# GKMS keys must already exist, and the cluster must have a service account\n# that is authorized to access GCP KMS.\n#seal \"gcpckms\" {\n#   project     = \"vault-helm-dev-246514\"\n#   region      = \"global\"\n#   key_ring    = \"vault-helm-unseal-kr\"\n#   crypto_key  = \"vault-helm-unseal-key\"\n#}\n"` |  |
| server.ha.disruptionBudget.enabled | bool | `true` |  |
| server.ha.disruptionBudget.maxUnavailable | string | `nil` |  |
| server.ha.enabled | bool | `false` |  |
| server.ha.raft.config | string | `"ui = true\n\nlistener \"tcp\" {\n  tls_disable = 1\n  address = \"[::]:8200\"\n  cluster_address = \"[::]:8201\"\n}\n\nstorage \"raft\" {\n  path = \"/vault/data\"\n}\n\nservice_registration \"kubernetes\" {}\n"` |  |
| server.ha.raft.enabled | bool | `false` |  |
| server.ha.raft.setNodeId | bool | `false` |  |
| server.ha.replicas | int | `3` |  |
| server.image.pullPolicy | string | `"IfNotPresent"` |  |
| server.image.repository | string | `"vault"` |  |
| server.image.tag | string | `"1.7.3"` |  |
| server.ingress.annotations | object | `{}` |  |
| server.ingress.enabled | bool | `false` |  |
| server.ingress.extraPaths | list | `[]` |  |
| server.ingress.hosts[0].host | string | `"chart-example.local"` |  |
| server.ingress.hosts[0].paths | list | `[]` |  |
| server.ingress.labels | object | `{}` |  |
| server.ingress.tls | list | `[]` |  |
| server.livenessProbe.enabled | bool | `false` |  |
| server.livenessProbe.failureThreshold | int | `2` |  |
| server.livenessProbe.initialDelaySeconds | int | `60` |  |
| server.livenessProbe.path | string | `"/v1/sys/health?standbyok=true"` |  |
| server.livenessProbe.periodSeconds | int | `5` |  |
| server.livenessProbe.successThreshold | int | `1` |  |
| server.livenessProbe.timeoutSeconds | int | `3` |  |
| server.logFormat | string | `""` |  |
| server.logLevel | string | `""` |  |
| server.networkPolicy.egress | list | `[]` |  |
| server.networkPolicy.enabled | bool | `false` |  |
| server.nodeSelector | string | `nil` |  |
| server.postStart | list | `[]` |  |
| server.preStopSleepSeconds | int | `5` |  |
| server.priorityClassName | string | `""` |  |
| server.readinessProbe.enabled | bool | `true` |  |
| server.readinessProbe.failureThreshold | int | `2` |  |
| server.readinessProbe.initialDelaySeconds | int | `5` |  |
| server.readinessProbe.periodSeconds | int | `5` |  |
| server.readinessProbe.successThreshold | int | `1` |  |
| server.readinessProbe.timeoutSeconds | int | `3` |  |
| server.resources | object | `{}` |  |
| server.route.annotations | object | `{}` |  |
| server.route.enabled | bool | `false` |  |
| server.route.host | string | `"chart-example.local"` |  |
| server.route.labels | object | `{}` |  |
| server.service.annotations | object | `{}` |  |
| server.service.enabled | bool | `true` |  |
| server.service.port | int | `8200` |  |
| server.service.targetPort | int | `8200` |  |
| server.serviceAccount.annotations | object | `{}` |  |
| server.serviceAccount.create | bool | `true` |  |
| server.serviceAccount.name | string | `""` |  |
| server.shareProcessNamespace | bool | `false` |  |
| server.standalone.config | string | `"ui = true\n\nlistener \"tcp\" {\n  tls_disable = 1\n  address = \"[::]:8200\"\n  cluster_address = \"[::]:8201\"\n}\nstorage \"file\" {\n  path = \"/vault/data\"\n}\n\n# Example configuration for using auto-unseal, using Google Cloud KMS. The\n# GKMS keys must already exist, and the cluster must have a service account\n# that is authorized to access GCP KMS.\n#seal \"gcpckms\" {\n#   project     = \"vault-helm-dev\"\n#   region      = \"global\"\n#   key_ring    = \"vault-helm-unseal-kr\"\n#   crypto_key  = \"vault-helm-unseal-key\"\n#}\n"` |  |
| server.standalone.enabled | string | `"-"` |  |
| server.statefulSet.annotations | object | `{}` |  |
| server.tolerations | string | `nil` |  |
| server.updateStrategyType | string | `"OnDelete"` |  |
| server.volumeMounts | string | `nil` |  |
| server.volumes | string | `nil` |  |
| ui.activeVaultPodOnly | bool | `false` |  |
| ui.annotations | object | `{}` |  |
| ui.enabled | bool | `false` |  |
| ui.externalPort | int | `8200` |  |
| ui.publishNotReadyAddresses | bool | `true` |  |
| ui.serviceNodePort | string | `nil` |  |
| ui.serviceType | string | `"ClusterIP"` |  |
| ui.targetPort | int | `8200` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.5.0](https://github.com/norwoodj/helm-docs/releases/v1.5.0)
