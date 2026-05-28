package templates

import (
	apps "k8s.io/api/apps/v1"
)

#Deployment: apps.#Deployment & {
	#config: #Config
	#helpers: #Helpers & {#config: #config}

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      #helpers.fullname
		namespace: #config.metadata.namespace
		labels:    #helpers.labels
	}
	spec: {
		if !#config.autoscaling.enabled {
			replicas: #config.replicaCount
		}
		selector: matchLabels: #helpers.selectorLabels
		template: {
			metadata: {
				if #config.podAnnotations != _|_ {
					annotations: #config.podAnnotations
				}
				labels: #helpers.selectorLabels
			}
			spec: {
				if #config.imagePullSecrets != _|_ {
					imagePullSecrets: #config.imagePullSecrets
				}
				if #config.postgres.enabled && #config.postgres.waitForDatabase {
					initContainers: [
						{
							name:            "wait-for-db"
							image:           "\(#config.postgres.image.repository):\(#config.postgres.image.tag)"
							imagePullPolicy: "IfNotPresent"
							command: ["pg_isready", "-h", #config.database.host, "-p", "\(#config.database.port)", "-U", #config.database.user]
							env: [
								{
									name: "PGPASSWORD"
									valueFrom: secretKeyRef: {
										name: #helpers.dbSecretName
										key:  #config.database.passwordKey
									}
								},
							]
						},
					]
				}
				serviceAccountName: #helpers.serviceAccountName
				securityContext:    #config.podSecurityContext
				containers: [
					{
						name: "listmonk"
						securityContext: #config.securityContext
						image:           "\(#config.image.repository):\(#config.image.tag)"
						imagePullPolicy: #config.image.pullPolicy
						volumeMounts: [
							{
								name:      "listmonk-config"
								mountPath: "/listmonk/config.toml"
								subPath:   "config.toml"
							},
						]
						ports: [
							{
								name:          "http"
								containerPort: 9000
								protocol:      "TCP"
							},
						]
						envFrom: [
							{
								configMapRef: name: #helpers.fullname
							},
						]
						env: [
							{
								name: "LISTMONK_db__password"
								valueFrom: secretKeyRef: {
									name: #helpers.dbSecretName
									key:  #config.database.passwordKey
								}
							},
						]
						if #config.livenessProbe.enabled {
							livenessProbe: {
								httpGet:             #config.livenessProbe.httpGet
								initialDelaySeconds: #config.livenessProbe.initialDelaySeconds
								periodSeconds:        #config.livenessProbe.periodSeconds
								timeoutSeconds:       #config.livenessProbe.timeoutSeconds
								failureThreshold:     #config.livenessProbe.failureThreshold
							}
						}
						if #config.readinessProbe.enabled {
							readinessProbe: {
								httpGet:             #config.readinessProbe.httpGet
								initialDelaySeconds: #config.readinessProbe.initialDelaySeconds
								periodSeconds:        #config.readinessProbe.periodSeconds
								timeoutSeconds:       #config.readinessProbe.timeoutSeconds
								failureThreshold:     #config.readinessProbe.failureThreshold
							}
						}
						if #config.startupProbe.enabled {
							startupProbe: {
								httpGet:             #config.startupProbe.httpGet
								initialDelaySeconds: #config.startupProbe.initialDelaySeconds
								periodSeconds:        #config.startupProbe.periodSeconds
								timeoutSeconds:       #config.startupProbe.timeoutSeconds
								failureThreshold:     #config.startupProbe.failureThreshold
							}
						}
						resources: #config.resources
					},
				]
				volumes: [
					{
						name: "listmonk-config"
						configMap: {
							name: #helpers.fullname
							items: [
								{
									key:  "config.toml"
									path: "config.toml"
								},
							]
						}
					},
				]
				if #config.nodeSelector != _|_ {
					nodeSelector: #config.nodeSelector
				}
				if #config.affinity != _|_ {
					affinity: #config.affinity
				}
				if #config.tolerations != _|_ {
					tolerations: #config.tolerations
				}
			}
		}
	}
}
