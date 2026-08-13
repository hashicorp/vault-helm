This PR provides a way to set extra environmental variables through the downward API.
Why?
We manage mutiple clusters where the differences between helm values boils down to the `authPath` which is set to a path including the cluster unique ID.
Each deployment has the cluster ID information provided by ArgoCD via the `argocd.argoproj.io/tracking-id` annotation. 
Leveraging the downward API we can programmatically set the `authPath` for all clusters without the need for a cluster specific value file.

Example:
Generate the injector deployment:
```
helm template       --show-only templates/injector-deployment.yaml --set 'injector.annotations.argocd\.argoproj\.io/tracking-id=cluster-1234'      --set "injector.extraEnvironmentVarsFieldPath.CLUSTER_ID=metadata.annotations['argocd.argoproj.io/tracking-id']" --set 'injector.authPath=/auth/Kubernetes/$(CLUSTER_ID)' .
```

This will produce the yaml:
```
...
  template:
    metadata:
      labels:
        app.kubernetes.io/name: vault-agent-injector
        app.kubernetes.io/instance: release-name
        component: webhook
      annotations:
        argocd.argoproj.io/tracking-id: cluster-1234
...
          env:
            
            - name: "CLUSTER_ID"
              valueFrom:
                fieldRef:
                  fieldPath: metadata.annotations['argocd.argoproj.io/tracking-id']
...
            - name: AGENT_INJECT_VAULT_AUTH_PATH
              value: /auth/Kubernetes/$(CLUSTER_ID)
```

The resulting env in the running pod shows:
```
CLUSTER_ID=cluster-1234
AGENT_INJECT_VAULT_AUTH_PATH=/auth/Kubernetes/cluster-1234
```

This configuration is valid for any cluster removing the need for cluster specific values