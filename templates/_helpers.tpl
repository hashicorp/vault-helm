{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to
this (by the DNS naming spec). If release name contains chart name it will
be used as a full name.
*/}}
{{- define "consul.namePrefix" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Compute the maximum number of unavailable replicas for the PodDisruptionBudget.
This defaults to (n/2)-1 where n is the number of members of the server cluster.
*/}}
{{- define "consul.pdb.maxUnavailable" -}}
{{- if .Values.server.disruptionBudget.maxUnavailable -}}
{{ .Values.server.disruptionBudget.maxUnavailable -}}
{{- else -}}
{{- ceil (sub (div (int .Values.server.replicas) 2) 1) -}}
{{- end -}}
{{- end -}}
