package templates

import (
	core "k8s.io/api/core/v1"
)

#PostgresSecret: core.#Secret & {
	#config: #Config
	#helpers: #Helpers & {#config: #config}

	if #config.postgres.enabled && #config.database.existingSecret == "" {
		apiVersion: "v1"
		kind:       "Secret"
		metadata: {
			name:      #helpers.dbSecretName
			namespace: #config.metadata.namespace
			labels:    #helpers.labels
		}
		type: "Opaque"
		stringData: {
			username: #config.database.user
			database: #config.database.name
			password: #config.admin.password // Use admin password as default if not specified
		}
	}
}
