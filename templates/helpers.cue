package templates

#Helpers: {
	#config: #Config

	// Expand the name of the chart.
	name: string
	if #config.nameOverride != "" {
		name: #config.nameOverride
	}
	if #config.nameOverride == "" {
		name: #config.metadata.name
	}

	// Create a default fully qualified app name.
	fullname: string
	if #config.fullnameOverride != "" {
		fullname: #config.fullnameOverride
	}
	if #config.fullnameOverride == "" {
		fullname: #config.metadata.name
	}

	// Common labels
	labels: {
		"helm.sh/chart":                "listmonk-0.1.0"
		"app.kubernetes.io/name":       name
		"app.kubernetes.io/instance":   #config.metadata.name
		"app.kubernetes.io/version":    #config.moduleVersion
		"app.kubernetes.io/managed-by": "timoni"
	}

	// Selector labels
	selectorLabels: {
		"app.kubernetes.io/name":     name
		"app.kubernetes.io/instance": #config.metadata.name
	}

	// Service account name
	serviceAccountName: string
	if #config.serviceAccount.name != "" {
		serviceAccountName: #config.serviceAccount.name
	}
	if #config.serviceAccount.name == "" {
		if #config.serviceAccount.create {
			serviceAccountName: fullname
		}
		if !#config.serviceAccount.create {
			serviceAccountName: "default"
		}
	}

	// Database secret name
	dbSecretName: string
	if #config.database.existingSecret != "" {
		dbSecretName: #config.database.existingSecret
	}
	if #config.database.existingSecret == "" {
		dbSecretName: "\(fullname)-db"
	}

	// SMTP secret name
	smtpSecretName: string
	if #config.smtp.existingSecret != "" {
		smtpSecretName: #config.smtp.existingSecret
	}
	if #config.smtp.existingSecret == "" {
		smtpSecretName: "\(fullname)-smtp"
	}

	// PostgreSQL StatefulSet name
	postgresStatefulSetName: "\(name)-postgres"
}
