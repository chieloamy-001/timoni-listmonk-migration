package templates

import (
	batch "k8s.io/api/batch/v1"
)

#PostgresMigrationJob: batch.#Job & {
	#config: #Config
	#helpers: #Helpers & {#config: #config}

	if #config.postgres.enabled && #config.postgres.migration.enabled {
		apiVersion: "batch/v1"
		kind:       "Job"
		metadata: {
			name:      "\(#helpers.fullname)-postgres-migration"
			namespace: #config.metadata.namespace
			labels:    #helpers.labels
			annotations: {
				"timoni.sh/action": "pre-upgrade"
			}
		}
		spec: {
			ttlSecondsAfterFinished: 300
			activeDeadlineSeconds:   300
			backoffLimit:            1
			template: {
				metadata: labels: #helpers.selectorLabels & {
					"app.kubernetes.io/component": "postgres-migration"
				}
				spec: {
					restartPolicy: "OnFailure"
					containers: [
						{
							name:            "kubectl"
							image:           #config.postgres.migration.image
							imagePullPolicy: "IfNotPresent"
							command: [
								"/bin/sh",
								"-c",
								"""
									# Scale down StatefulSet and delete it --cascade=orphan
									# to allow Helm/Timoni to recreate it with new volume templates
									kubectl scale sts \(#helpers.postgresStatefulSetName) --replicas=0 || true
									kubectl delete sts \(#helpers.postgresStatefulSetName) --cascade=orphan || true
									""",
							]
						},
					]
					serviceAccountName: #helpers.serviceAccountName
				}
			}
		}
	}
}
