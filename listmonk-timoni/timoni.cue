package main

import (
	templates "timoni.sh/listmonk/templates"
)

values: templates.#Config

timoni: {
	apiVersion: "v1alpha1"

	instance: templates.#Instance & {
		config: values
		config: {
			metadata: {
				name:      string @tag(name)
				namespace: string @tag(namespace)
			}
			moduleVersion: string | *"6.0.0" @tag(mv, var=moduleVersion)
			kubeVersion:   string | *"1.29.0" @tag(kv, var=kubeVersion)
		}
	}

	apply: app: [for obj in instance.objects {obj}]
}
