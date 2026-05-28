@if(!debug)

package main

// Defaults
values: {
	replicaCount: 1

	image: {
		repository: "listmonk/listmonk"
		pullPolicy: "IfNotPresent"
		tag:        "v6.1.0"
	}

	imagePullSecrets: []
	nameOverride:     ""
	fullnameOverride: ""

	serviceAccount: {
		create:      true
		annotations: {}
		name:        ""
	}

	podAnnotations: {}
	podSecurityContext: {
		fsGroup: 1000
	}
	securityContext: {
		runAsUser:                1000
		runAsNonRoot:             true
		allowPrivilegeEscalation: false
	}

	service: {
		type: "ClusterIP"
		port: 9000
	}

	ingress: {
		enabled:   false
		className: ""
		annotations: {}
		hosts: [{
			host: "example.com"
			paths: [{
				path:     "/"
				pathType: "Prefix"
			}]
		}]
		tls: [{
			secretName: "example-tls"
			hosts: ["example.com"]
		}]
	}

	resources: {
		limits: {
			cpu:    "500m"
			memory: "512Mi"
		}
		requests: {
			cpu:    "100m"
			memory: "128Mi"
		}
	}

	autoscaling: {
		enabled:                        false
		minReplicas:                    1
		maxReplicas:                    3
		targetCPUUtilizationPercentage: 80
	}

	podDisruptionBudget: {
		enabled:      true
		minAvailable: 0
	}

	nodeSelector: {}
	tolerations:  []
	affinity:     {}

	livenessProbe: {
		enabled: true
		httpGet: {
			path: "/health"
			port: 9000
		}
		initialDelaySeconds: 60
		periodSeconds:       10
		timeoutSeconds:      5
		failureThreshold:    3
	}

	readinessProbe: {
		enabled: true
		httpGet: {
			path: "/health"
			port: 9000
		}
		initialDelaySeconds: 30
		periodSeconds:       10
		timeoutSeconds:      5
		failureThreshold:    3
	}

	startupProbe: {
		enabled: true
		httpGet: {
			path: "/health"
			port: 9000
		}
		initialDelaySeconds: 10
		periodSeconds:       5
		timeoutSeconds:      3
		failureThreshold:    30
	}

	admin: {
		username: "admin"
		password: "change-me"
	}

	app: {
		address: "0.0.0.0:9000"
		lang:    "en"
	}

	database: {
		host:           "listmonk-postgres"
		port:           5432
		name:           "listmonk"
		user:           "listmonk"
		sslMode:        "disable"
		maxOpen:        25
		maxIdle:        25
		maxLifetime:    "300s"
		existingSecret: ""
		passwordKey:    "password"
	}

	postgres: {
		enabled: true
		image: {
			repository: "postgres"
			tag:        "18"
		}
		migration: {
			enabled: true
			image:   "registry.k8s.io/kubectl:v1.36.1"
		}
		podDisruptionBudget: {
			enabled:      true
			minAvailable: 1
		}
		waitForDatabase: true
		storage: {
			size:         "4Gi"
			storageClass: ""
		}
		resources: {
			requests: {
				cpu:    "100m"
				memory: "256Mi"
			}
			limits: {
				cpu:    "500m"
				memory: "1Gi"
			}
		}
	}

	smtp: {
		enabled:        false
		existingSecret: ""
		host:           "smtp.example.com"
		port:           587
		username:       "user@example.com"
		password:       "change-me"
		from:           "noreply@example.com"
		authProtocol:   "login"
		tlsEnabled:     true
		tlsSkipVerify:  false
		maxConns:       10
		idleTimeout:    "15s"
		waitTimeout:    "5s"
		maxMsgRetries:  2
		helloHostname:  ""
	}

	init: {
		enabled:   true
		runAsHook: false
	}
}
