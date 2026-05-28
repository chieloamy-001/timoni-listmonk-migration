package templates

import (
	core "k8s.io/api/core/v1"
)

#Secret: core.#Secret & {
	#config: #Config
	#helpers: #Helpers & {#config: #config}

	if #config.smtp.enabled && #config.smtp.existingSecret == "" {
		apiVersion: "v1"
		kind:       "Secret"
		metadata: {
			name:      #helpers.smtpSecretName
			namespace: #config.metadata.namespace
			labels:    #helpers.labels
		}
		type: "Opaque"
		stringData: {
			"smtp-host":     #config.smtp.host
			"smtp-port":     "\(#config.smtp.port)"
			"smtp-username": #config.smtp.username
			"smtp-password": #config.smtp.password
			"smtp-from":     #config.smtp.from
		}
	}
}
