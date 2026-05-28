package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

#PostgresMigrationJob: {
	#config: #Config
	#helpers: #Helpers

	job: {
		apiVersion: "batch/v1"
		kind:       "Job"
		metadata: {
			name:      "\(#helpers.fullname)-postgres-migration"
			namespace: #config.metadata.namespace
			labels:    #helpers.labels
		}
		spec: batchv1.#JobSpec & {
			ttlSecondsAfterFinished: 300
			activeDeadlineSeconds:   300
			backoffLimit:            3
			template: {
				metadata: name: "postgres-migration"
				spec: corev1.#PodSpec & {
					restartPolicy:      "OnFailure"
					serviceAccountName: "\(#helpers.fullname)-migration"
					containers: [{
						name:  "migrate"
						image: #config.postgres.migration.image
						command: [
							"/bin/bash",
							"-c",
							"""
								set -e
								STS="\(#helpers.postgresStatefulSetName)"
								NS="\(#config.metadata.namespace)"
								SELECTOR="app.kubernetes.io/name=${STS},app.kubernetes.io/instance=\(#config.metadata.name)"

								echo "Checking if StatefulSet migration is needed..."
								if ! kubectl get statefulset "$STS" -n "$NS" >/dev/null 2>&1; then
								  echo "No existing StatefulSet found, skipping migration."
								  exit 0
								fi

								echo "StatefulSet exists; scaling down (preserving PVCs)..."
								kubectl scale statefulset "$STS" -n "$NS" --replicas=0

								echo "Waiting for pods to terminate..."
								if kubectl get pods -n "$NS" -l "$SELECTOR" -o name 2>/dev/null | head -1 | grep -q .; then
								  # Wait for delete if possible, otherwise just continue
								  kubectl wait --for=delete pod -l "$SELECTOR" -n "$NS" --timeout=120s || true
								fi

								echo "Deleting StatefulSet (--cascade=orphan, PVCs preserved)..."
								kubectl delete statefulset "$STS" -n "$NS" --cascade=orphan

								echo "Migration complete. StatefulSet will be recreated by Timoni."
								""",
						]
					}]
				}
			}
		}
	}

	sa: {
		apiVersion: "v1"
		kind:       "ServiceAccount"
		metadata: {
			name:      "\(#helpers.fullname)-migration"
			namespace: #config.metadata.namespace
		}
	}

	role: {
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "Role"
		metadata: {
			name:      "\(#helpers.fullname)-migration"
			namespace: #config.metadata.namespace
		}
		rules: [{
			apiGroups: ["apps"]
			resources: ["statefulsets"]
			resourceNames: [#helpers.postgresStatefulSetName]
			verbs: ["get", "list", "delete", "patch"]
		}, {
			apiGroups: ["apps"]
			resources: ["statefulsets/scale"]
			resourceNames: [#helpers.postgresStatefulSetName]
			verbs: ["get", "patch", "update"]
		}, {
			apiGroups: [""]
			resources: ["pods"]
			verbs: ["get", "list", "watch"]
		}]
	}

	rolebinding: {
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "RoleBinding"
		metadata: {
			name:      "\(#helpers.fullname)-migration"
			namespace: #config.metadata.namespace
		}
		roleRef: {
			apiGroup: "rbac.authorization.k8s.io"
			kind:     "Role"
			name:     "\(#helpers.fullname)-migration"
		}
		subjects: [{
			kind:      "ServiceAccount"
			name:      "\(#helpers.fullname)-migration"
			namespace: #config.metadata.namespace
		}]
	}
}
