package templates

import (
	core "k8s.io/api/core/v1"
)

#ServiceAccount: core.#ServiceAccount & {
	#config: #Config
	#helpers: #Helpers & {#config: #config}

	if #config.serviceAccount.create {
		apiVersion: "v1"
		kind:       "ServiceAccount"
		metadata: {
			name:      #helpers.serviceAccountName
			namespace: #config.metadata.namespace
			labels:    #helpers.labels
			if #config.serviceAccount.annotations != _|_ {
				annotations: #config.serviceAccount.annotations
			}
		}
	}
}
