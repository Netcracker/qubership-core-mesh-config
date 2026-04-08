{{- define "to_millicores" -}}
  {{- $value := toString . -}}
  {{- if hasSuffix "m" $value -}}
    {{ trimSuffix "m" $value }}
  {{- else -}}
    {{ mulf $value 1000 }}
  {{- end -}}
{{- end -}}


{{- define "mesh.labels.common" -}}
{{- $root := .root | default . -}}
{{- $name := .name | default $root.Values.SERVICE_NAME -}}
app.kubernetes.io/name: {{ $name | quote }}
app.kubernetes.io/part-of: {{ $root.Values.APPLICATION_NAME | quote }}
app.kubernetes.io/managed-by: {{ "Helm" | quote }}
{{- if $root.Values.DEPLOYMENT_SESSION_ID }}
deployment.netcracker.com/sessionId: '{{ $root.Values.DEPLOYMENT_SESSION_ID }}'
{{- end }}
{{- end -}}

{{- /*
Common labels - generates standard Kubernetes labels
Usage: include "mesh.labels" (dict "root" . "name" "custom_name" "processedByOperator" true "context" $ )
Parameters:
  - root: The root context (usually .)
  - name: Override for app.kubernetes.io/name (optional)
  - component: Override for app.kubernetes.io/component (optional)
  - instance: Override for app.kubernetes.io/instance (optional)
  - processedByOperator: set to true if app.kubernetes.io/processed-by-operator label is required (optional)
*/}}
{{- define "mesh.labels" -}}
{{- $root := .root | default . -}}
{{- $name := .name | default $root.Values.SERVICE_NAME -}}
{{- $component := .component | default $root.Values.SERVICE_NAME -}}
{{- $instance := .instance | default (printf "%s-%s" $name ($root.Values.NAMESPACE | default "default")) | trunc 63 | trimSuffix "-" -}}
{{- $processedByOperator := .processedByOperator | default false -}}
{{- include "mesh.labels.common" (dict "root" $root "name" $name )}}
app.kubernetes.io/instance: {{ $instance | quote }}
app.kubernetes.io/component: {{ $component | quote }}
app.kubernetes.io/version: {{ $root.Chart.Version | quote }}
{{- if $processedByOperator }}
app.kubernetes.io/processed-by-operator: {{ "istiod" | quote }}
{{- end -}}
{{- end -}}


{{- define "mesh.labels.service" -}}
{{- $root := .root -}}
{{- $name := .name -}}
{{- include "mesh.labels.common" (dict "root" $root "name" $name )}}
{{- end -}}

{{- define "mesh.hpa" -}}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: '{{ .name }}'
  labels:
    app.kubernetes.io/part-of: {{ .root.Values.APPLICATION_NAME }}
    app.kubernetes.io/managed-by: 'Helm'
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: '{{ .targetName }}'
  minReplicas: {{ default .defaultMinReplicas .root.Values.HPA_MIN_REPLICAS }}
  maxReplicas: {{ default .defaultMaxReplicas .root.Values.HPA_MAX_REPLICAS }}
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .averageUtilization }}
  behavior:
    scaleUp:
      stabilizationWindowSeconds: {{ default 0 .root.Values.HPA_SCALING_UP_STABILIZATION_WINDOW_SECONDS }}
      selectPolicy: {{ if .root.Values.HPA_ENABLED }}{{ default "Max" .root.Values.HPA_SCALING_UP_SELECT_POLICY }}{{ else }}Disabled{{ end }}
      policies:
{{- if and .root.Values.HPA_SCALING_UP_PERCENT_VALUE (ge (int .root.Values.HPA_SCALING_UP_PERCENT_PERIOD_SECONDS) 0) }}
        - type: Percent
          value: {{ .root.Values.HPA_SCALING_UP_PERCENT_VALUE }}
          periodSeconds: {{ .root.Values.HPA_SCALING_UP_PERCENT_PERIOD_SECONDS }}
{{- end }}
{{- if and .root.Values.HPA_SCALING_UP_PODS_VALUE (ge (int .root.Values.HPA_SCALING_UP_PODS_PERIOD_SECONDS) 0) }}
        - type: Pods
          value: {{ .root.Values.HPA_SCALING_UP_PODS_VALUE }}
          periodSeconds: {{ .root.Values.HPA_SCALING_UP_PODS_PERIOD_SECONDS }}
{{- end }}
    scaleDown:
      stabilizationWindowSeconds: {{ default 300 .root.Values.HPA_SCALING_DOWN_STABILIZATION_WINDOW_SECONDS }}
      selectPolicy: {{ if .root.Values.HPA_ENABLED }}{{ default "Max" .root.Values.HPA_SCALING_DOWN_SELECT_POLICY }}{{ else }}Disabled{{ end }}
      policies:
{{- if and .root.Values.HPA_SCALING_DOWN_PERCENT_VALUE (ge (int .root.Values.HPA_SCALING_DOWN_PERCENT_PERIOD_SECONDS) 0) }}
        - type: Percent
          value: {{ .root.Values.HPA_SCALING_DOWN_PERCENT_VALUE }}
          periodSeconds: {{ .root.Values.HPA_SCALING_DOWN_PERCENT_PERIOD_SECONDS }}
{{- end }}
{{- if and .root.Values.HPA_SCALING_DOWN_PODS_VALUE (ge (int .root.Values.HPA_SCALING_DOWN_PODS_PERIOD_SECONDS) 0) }}
        - type: Pods
          value: {{ .root.Values.HPA_SCALING_DOWN_PODS_VALUE }}
          periodSeconds: {{ .root.Values.HPA_SCALING_DOWN_PODS_PERIOD_SECONDS }}
{{- end }}
{{- end }}