# Changelog

## [0.70.1](https://github.com/DramisInfo/platform-helm/compare/platform-core-0.70.0...platform-core-v0.70.1) (2026-08-25)


### Bug Fixes

* **argo-events:** force controller.replicas: 2 to avoid chart 2.4.24 invalid spec ([#92](https://github.com/DramisInfo/platform-helm/issues/92)) ([6365ab4](https://github.com/DramisInfo/platform-helm/commit/6365ab4617367a7ed259c6e2c0bf00253891c501))
* **platform-core:** whitelist k8s manifests in crossplane-compositions source ([#79](https://github.com/DramisInfo/platform-helm/issues/79)) ([d67dc8e](https://github.com/DramisInfo/platform-helm/commit/d67dc8ef8d750a42d9e5c1fad8ef13680a465dc5))

## [0.70.0](https://github.com/DramisInfo/platform-helm/compare/platform-core-0.69.0...platform-core-v0.70.0) (2026-08-02)


### ⚠ BREAKING CHANGES

* migrate XAzureWorkloadIdentity roleAssignment -> roleAssignments

### Features

* add Azure configuration parameters to values.yaml ([4d08e56](https://github.com/DramisInfo/platform-helm/commit/4d08e564185d91e5b1b3219ae917fd8ca5d5187e))
* **beyla:** skip pods labeled beyla.io/skip=true from eBPF instrumentation ([49fa2f9](https://github.com/DramisInfo/platform-helm/commit/49fa2f9ebd090dc028692428d03bd28afbdb8f65))
* **k6-operator:** make ServiceMonitor metrics configuration dynamic based on bootstrap values ([793ae49](https://github.com/DramisInfo/platform-helm/commit/793ae499a71eae6d9d4673b1483dc7ce3dea97f6))
* **keda:** make monitoring configuration dynamic based on bootstrap values ([49969ea](https://github.com/DramisInfo/platform-helm/commit/49969eaf4f044b3ce60636553dd5da0edb99ef39))
* **platform-core:** add read-only hermes-sre ServiceAccount for agent cluster investigation ([#68](https://github.com/DramisInfo/platform-helm/issues/68)) ([5a6ba32](https://github.com/DramisInfo/platform-helm/commit/5a6ba32f6945812ab26763a15b3315182e2c8cc1))


### Bug Fixes

* disable terraform operator by default ([#58](https://github.com/DramisInfo/platform-helm/issues/58)) ([25a1433](https://github.com/DramisInfo/platform-helm/commit/25a1433632308fcde66e33ce14bd6c30bf37c8cd))
* **gatekeeper:** disable native validation path and pin library revision ([#50](https://github.com/DramisInfo/platform-helm/issues/50)) ([3a39723](https://github.com/DramisInfo/platform-helm/commit/3a3972341a83807bb6f8e3fa2eb227cd6f0e8cd9))
* migrate XAzureWorkloadIdentity roleAssignment -&gt; roleAssignments ([ccd2e91](https://github.com/DramisInfo/platform-helm/commit/ccd2e9147e27e12e186124ba88c45dc5e90ef482))
* set gatekeeper VAPs to failurePolicy: Ignore to prevent cold-boot deadlock ([#42](https://github.com/DramisInfo/platform-helm/issues/42)) ([fae307c](https://github.com/DramisInfo/platform-helm/commit/fae307cca93dc073ac85ab779517585ce823276d))
