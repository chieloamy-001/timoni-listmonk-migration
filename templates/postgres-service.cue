package templates

import (
	core "k8s.io/api/core/v1"
)

#PostgresService: core.#Service & {
	#config: #Config
	#helpers: #Helpers & {#config: #config}

	if #config.postgres.enabled {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:      "listmonk-postgres"
			namespace: #config.metadata.namespace
			labels:    #helpers.labels
		}
		spec: {
			type: "ClusterIP"
			ports: [
				{
					name:       "postgres"
					port:       5432
					targetPort: 5432
				},
			]
			selector: {
				"app.kubernetes.io/name":     #helpers.postgresStatefulSetName
				"app.kubernetes.io/instance": #config.metadata.name
			}
		}
	}
}
