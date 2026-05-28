package templates

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	kubeVersion:   string | *"1.25.0"
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.20.0"}
	moduleVersion: string | *"1.0.0"

	metadata: timoniv1.#Metadata & {
		#Version: moduleVersion
		name:      string | *"listmonk"
		namespace: string | *"default"
	}
	metadata: labels: timoniv1.#Labels
	metadata: annotations?: timoniv1.#Annotations

	selector: timoniv1.#Selector & {#Name: metadata.name}

	replicaCount: *1 | int & >0

	image: {
		repository: *"listmonk/listmonk" | string
		pullPolicy: *"IfNotPresent" | string
		tag:        *moduleVersion | string
	}

	imagePullSecrets: [...corev1.#LocalObjectReference]
	nameOverride:     *"" | string
	fullnameOverride: *"" | string

	serviceAccount: {
		create:      *true | bool
		annotations: timoniv1.#Annotations
		name:        *"" | string
	}

	podAnnotations:     timoniv1.#Annotations
	podSecurityContext: corev1.#PodSecurityContext | *{
		fsGroup: 1000
	}
	securityContext: corev1.#SecurityContext | *{
		runAsUser:                1000
		runAsNonRoot:             true
		allowPrivilegeEscalation: false
	}

	service: {
		type: *"ClusterIP" | string
		port: *9000 | int & >0 & <=65535
	}

	ingress: {
		enabled:   *false | bool
		className: *"" | string
		annotations: timoniv1.#Annotations
		hosts: [...{
			host: string
			paths: [...{
				path:     string
				pathType: string
			}]
		}]
		tls: [...{
			secretName: string
			hosts: [...string]
		}]
	}

	resources: corev1.#ResourceRequirements | *{
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
		enabled:                        *false | bool
		minReplicas:                    *1 | int
		maxReplicas:                    *3 | int
		targetCPUUtilizationPercentage: *80 | int
	}

	podDisruptionBudget: {
		enabled:      *true | bool
		minAvailable: *0 | int | string
	}

	nodeSelector: {[string]: string}
	tolerations: [...corev1.#Toleration]
	affinity: corev1.#Affinity

	livenessProbe: {
		enabled: *true | bool
		httpGet: {
			path: *"/health" | string
			port: *9000 | int
		}
		initialDelaySeconds: *60 | int
		periodSeconds:        *10 | int
		timeoutSeconds:       *5 | int
		failureThreshold:     *3 | int
	}

	readinessProbe: {
		enabled: *true | bool
		httpGet: {
			path: *"/health" | string
			port: *9000 | int
		}
		initialDelaySeconds: *30 | int
		periodSeconds:        *10 | int
		timeoutSeconds:       *5 | int
		failureThreshold:     *3 | int
	}

	startupProbe: {
		enabled: *true | bool
		httpGet: {
			path: *"/health" | string
			port: *9000 | int
		}
		initialDelaySeconds: *10 | int
		periodSeconds:        *5 | int
		timeoutSeconds:       *3 | int
		failureThreshold:     *30 | int
	}

	admin: {
		username: *"admin" | string
		password: *"change-me" | string
	}

	app: {
		address: *"0.0.0.0:9000" | string
		lang:    *"en" | string
	}

	database: {
		host:           *"listmonk-postgres" | string
		port:           *5432 | int
		name:           *"listmonk" | string
		user:           *"listmonk" | string
		sslMode:        *"disable" | string
		maxOpen:        *25 | int
		maxIdle:        *25 | int
		maxLifetime:    *"300s" | string
		existingSecret: *"" | string
		passwordKey:    *"password" | string
	}

	postgres: {
		enabled: *true | bool
		image: {
			repository: *"postgres" | string
			tag:        *"15" | string
		}
		migration: {
			enabled: *true | bool
			image:   *"bitnamilegacy/kubectl:1.29.9" | string
		}
		podDisruptionBudget: {
			enabled:      *true | bool
			minAvailable: *1 | int | string
		}
		waitForDatabase: *true | bool
		storage: {
			size:         *"4Gi" | string
			storageClass: *"" | string
		}
		resources: corev1.#ResourceRequirements | *{
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
		enabled:        *false | bool
		existingSecret: *"" | string
		host:           *"smtp.example.com" | string
		port:           *587 | int
		username:       *"user@example.com" | string
		password:       *"change-me" | string
		from:           *"noreply@example.com" | string
		authProtocol:   *"login" | string
		tlsEnabled:      *true | bool
		tlsSkipVerify:   *false | bool
		maxConns:        *10 | int
		idleTimeout:     *"15s" | string
		waitTimeout:     *"5s" | string
		maxMsgRetries:   *2 | int
		helloHostname:   *"" | string
	}

	init: {
		enabled:   *true | bool
		runAsHook: *false | bool
	}

	test: {
		enabled: *false | bool
		image:   timoniv1.#Image & {
			repository: *"cgr.dev/chainguard/curl" | string
			tag:        *"latest" | string
			digest:     *"" | string
		}
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		deployment: #Deployment & {#config: config}
		service:    #Service & {#config: config}
		cm:         #ConfigMap & {#config: config}
		sa:         #ServiceAccount & {#config: config}
		if config.ingress.enabled {
			ingress: #Ingress & {#config: config}
		}
		if config.init.enabled {
			init: #InitJob & {#config: config}
		}
		if config.smtp.enabled && config.smtp.existingSecret == "" {
			smtpSecret: #Secret & {#config: config}
		}
		if config.postgres.enabled {
			pgSts: #PostgresStatefulSet & {#config: config}
			pgSvc: #PostgresService & {#config: config}
			if config.database.existingSecret == "" {
				pgSecret: #PostgresSecret & {#config: config}
			}
			if config.postgres.migration.enabled {
				pgMig: #PostgresMigrationJob & {#config: config}
			}
			if config.postgres.podDisruptionBudget.enabled {
				pgPdb: #PostgresPodDisruptionBudget & {#config: config}
			}
		}
		if config.podDisruptionBudget.enabled {
			appPdb: #AppPodDisruptionBudget & {#config: config}
		}
	}

	tests: {
		"test-svc": #TestJob & {#config: config}
	}
}
