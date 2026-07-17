{{/*
Expand the name of the chart.
*/}}
{{- define "sshpiper.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "sshpiper.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "sshpiper.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "sshpiper.labels" -}}
helm.sh/chart: {{ include "sshpiper.chart" . }}
{{ include "sshpiper.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "sshpiper.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sshpiper.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "sshpiper.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- $name := printf "%s-reader" (include "sshpiper.fullname" .) }}
{{- default $name .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Image tag depends on required plugins
We take full image if more than Kubernetes plugin is required.
*/}}
{{- define "sshpiper.imageTag" -}}
{{- if .Values.sshpiper.failtoban.enabled }}
{{- $tag := printf "full-%s" .Chart.AppVersion }}
{{- default $tag .Values.image.tag }}
{{- else }}
{{- $tag := printf "%s" .Chart.AppVersion }}
{{- default $tag .Values.image.tag }}
{{- end }}
{{- end }}

{{/*
Container arguments
Pass arguments to enable individual plugins or allow complete arguments override.
*/}}
{{- define "sshpiper.containerArgs" -}}
{{- if .Values.sshpiper.argsOverride }}
{{- toYaml .Values.sshpiper.argsOverride }}
{{- else }}
- /sshpiperd/plugins/kubernetes
{{- if .Values.sshpiper.failtoban.enabled }}
- --
- /sshpiperd/plugins/failtoban
{{- end }}
{{- end }}
{{- end }}