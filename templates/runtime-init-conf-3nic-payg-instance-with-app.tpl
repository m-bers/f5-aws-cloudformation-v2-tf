controls:
  logLevel: info
  logFilename: /var/log/cloud/bigIpRuntimeInit.log
extension_packages:
  install_operations:
    - extensionType: do
      extensionVersion: 1.44.0
      extensionHash: 3b05d9bcafbcf0b5b625ff81d6bab5ad26ed90c0dd202ded51756af3598a97ec
    - extensionType: as3
      extensionVersion: 3.53.0
      extensionHash: 3ab65685de36a5912a764957434b2d92cc8b6f8153080bbf9210c8dcbc621029
    - extensionType: cf
      extensionVersion: 2.1.2
      extensionHash: 476d38a4d32d6474ae5435b5d448b318e638db4655edf049944f854504310839
extension_services:
  service_operations:
    - extensionType: do
      type: url
      value: ${DO_START_PATH}
    - extensionType: cf
      type: url
      value: ${CF_PATH}
    - extensionType: as3
      type: url
      value: ${AS3_PATH}
    - extensionType: do
      type: url
      value: ${DO_END_PATH}
runtime_parameters:
  - name: SECRET_ID
    type: url
    value: file:///config/cloud/secret_id
  - name: BIGIP_PASSWORD
    type: secret
    secretProvider:
      environment: aws
      secretId: "{{{SECRET_ID}}}"
      type: SecretsManager
      version: AWSCURRENT
  - name: HOST_NAME
    type: tag
    tagProvider:
      environment: aws
      key: hostname
  - name: REMOTE_HOST_NAME
    type: tag
    tagProvider:
      environment: aws
      key: bigIpPeerHostname
  - name: FAILOVER_TAG
    type: tag
    tagProvider:
      environment: aws
      key: failoverTag
  - name: SELF_IP_EXTERNAL
    type: metadata
    metadataProvider:
      environment: aws
      type: network
      field: local-ipv4s
      index: 1
  - name: SELF_IP_INTERNAL
    type: metadata
    metadataProvider:
      type: network
      environment: aws
      field: local-ipv4s
      index: 2
  - name: DEFAULT_GW
    type: metadata
    metadataProvider:
      environment: aws
      type: network
      field: local-ipv4s
      index: 1
      ipcalc: first
  - name: REGION
    type: metadata
    metadataProvider:
      environment: aws
      type: uri
      value: "/latest/dynamic/instance-identity/document"
      query: region
${REMOTE_HOST}