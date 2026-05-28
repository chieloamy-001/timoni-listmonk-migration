package templates

import (
	policy "k8s.io/api/policy/v1"
)

#PostgresPodDisruptionBudget: policy.#PodDisruptionBudget & {
	#config: #Config
	#helpers: #Helpers & {#config: #config}

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      #helpers.postgresStatefulSetName
		namespace: #config.metadata.namespace
		labels:    #helpers.labels
	}
	spec: {
		minAvailable: #config.postgres.podDisruptionBudget.minAvailable
		selector: matchLabels: {
			"app.kubernetes.io/name":     #helpers.postgresStatefulSetName
			"app.kubernetes.io/instance": #config.metadata.name
		}
	}
}

#AppPodDisruptionBudget: policy.#PodDisruptionBudget & {
	#config: #Config
	#helpers: #Helpers & {#config: #config}

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: {
		name:      #helpers.fullname
		namespace: #config.metadata.namespace
		labels:    #helpers.labels
	}
	spec: {
		minAvailable: #config.podDisruptionBudget.minAvailable
		selector: matchLabels: #helpers.selectorLabels
	}
}
