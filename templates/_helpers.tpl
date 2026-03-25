{{- define "to_millicores" -}}
  {{- $value := toString . -}}
  {{- if hasSuffix "m" $value -}}
    {{ trimSuffix "m" $value }}
  {{- else -}}
    {{ mulf $value 1000 }}
  {{- end -}}
{{- end -}}

{{- /*
Common labels - generates standard Kubernetes labels
Usage: include "myapp.labels" (dict "root" . "name" "custom_name" "processedByOperator" false "context" $ )
Parameters:
  - root: The root context (usually .)
  - name: Override for app.kubernetes.io/name (optional)
  - component: Override for app.kubernetes.io/component (optional)
  - instance: Override for app.kubernetes.io/instance (optional)
  - processedByOperator: set to true if app.kubernetes.io/processed-by-operator label is required
*/}}
{{- define "myapp.labels" -}}
{{- $root := .root -}}
{{- $name := .name | default $root.Values.SERVICE_NAME -}}
{{- $component := .component | default $root.Values.SERVICE_NAME -}}
{{- $instance := .instance | default (printf "%s-%s" $name ($root.Values.NAMESPACE | default "default")) | trunc 63 | trimSuffix "-" -}}
app.kubernetes.io/name: {{ $name | quote }}
app.kubernetes.io/instance: {{ $instance | quote }}
app.kubernetes.io/component: {{ $component | quote }}
app.kubernetes.io/version: {{ $root.Chart.Version | quote }}
app.kubernetes.io/part-of: {{ $root.Values.APPLICATION_NAME | quote }}
app.kubernetes.io/managed-by: {{ "Helm" | quote }}
{{- if .processedByOperator }}
app.kubernetes.io/processed-by-operator: {{ "istiod" | quote }}
{{- end -}}
{{- end -}}