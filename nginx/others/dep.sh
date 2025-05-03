#!/bin/bash

# Define the existing application names and their respective namespaces
declare -a app_names=("app1" "app2" "app3" "app4" "app5" "app6" "app7" "app8" "app9")
declare -a app_namespaces=("namespace1" "namespace2" "namespace3")

# Iterate over the applications and their namespaces
for i in "${!app_names[@]}"; do
    app_name=${app_names[$i]}
    app_namespace=${app_namespaces[$i]}

    # Get the deployment status
    deployment_status=$(kubectl get deployment "$app_name" -n "$app_namespace" -o jsonpath='{.status.availableReplicas}')

    # Check if the deployment is available
    if [ "$deployment_status" != "0" ]; then
        echo "Deployment $app_name is running in namespace $app_namespace."
    else
        echo "Error: Deployment $app_name is not running in namespace $app_namespace."
    fi

    # Get the service status
    service_status=$(kubectl get service "$app_name" -n "$app_namespace" -o jsonpath='{.status.loadBalancer.ingress}')

    # Check if the service is available
    if [ -n "$service_status" ]; then
        echo "Service $app_name is running in namespace $app_namespace."
    else
        echo "Error: Service $app_name is not running in namespace $app_namespace."
    fi
done



















apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    deployment.kubernetes.io/revision: "61"
    keel.sh/policy: major
    keel.sh/pollSchedule: '@every 5m'
    keel.sh/trigger: poll
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"apps/v1","kind":"Deployment","metadata":{"annotations":{"keel.sh/policy":"major","keel.sh/pollSchedule":"@every 5m","keel.sh/trigger":"poll"},"labels":{"app.kubernetes.io/instance":"ds-data-saver","app.kubernetes.io/managed-by":"Helm","app.kubernetes.io/name":"ds-data-saver","helm.sh/chart":"application-0.1"},"name":"ds-data-saver","namespace":"development"},"spec":{"replicas":1,"selector":{"matchLabels":{"app.kubernetes.io/instance":"ds-data-saver","app.kubernetes.io/name":"ds-data-saver"}},"template":{"metadata":{"labels":{"app.kubernetes.io/instance":"ds-data-saver","app.kubernetes.io/name":"ds-data-saver"}},"spec":{"containers":[{"env":[{"name":"SPRING_CLOUD_CONFIG_PASSWORD","valueFrom":{"secretKeyRef":{"key":"SPRING_CLOUD_CONFIG_PASSWORD","name":"spring-secret"}}},{"name":"SPRING_CLOUD_CONFIG_USERNAME","valueFrom":{"secretKeyRef":{"key":"SPRING_CLOUD_CONFIG_USERNAME","name":"spring-secret"}}},{"name":"SPRING_PROFILES_ACTIVE","valueFrom":{"secretKeyRef":{"key":"SPRING_PROFILES_ACTIVE","name":"spring-secret"}}}],"image":"769294742237.dkr.ecr.us-east-2.amazonaws.com/ds-data-saver:R10.2024.06.05-53","imagePullPolicy":"Always","lifecycle":{"postStart":{"exec":{"command":["/bin/sh","-c","echo started \u003e /proc/1/fd/1"]}},"preStop":{"exec":{"command":["/bin/sh","-c","curl -XPOST http://localhost:8081/actuator/shutdown \u003e /proc/1/fd/1"]}}},"livenessProbe":{"failureThreshold":3,"httpGet":{"path":"/actuator/health","port":8081,"scheme":"HTTP"},"initialDelaySeconds":60,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":10},"name":"ds-data-saver","ports":[{"containerPort":8081,"name":"mgmt-port","protocol":"TCP"},{"containerPort":8080,"name":"server-port","protocol":"TCP"}],"readinessProbe":{"failureThreshold":5,"httpGet":{"path":"/actuator/health","port":8081,"scheme":"HTTP"},"initialDelaySeconds":60,"periodSeconds":10,"successThreshold":1,"timeoutSeconds":10},"resources":{"limits":{"cpu":"1500m","memory":"1500Mi"},"requests":{"cpu":"500m","memory":"500Mi"}}}],"imagePullSecrets":[{"name":"ecrreg"}],"terminationGracePeriodSeconds":60,"tolerations":[{"effect":"NoSchedule","key":"be-app","operator":"Equal","value":"api"}]}}}}
  creationTimestamp: "2023-12-28T11:55:30Z"
  generation: 1987
  labels:
    app.kubernetes.io/instance: ds-data-saver
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: ds-data-saver
    helm.sh/chart: application-0.1
  name: ds-data-saver
  namespace: development
  resourceVersion: "165034600"
  uid: f311d5cb-09cd-4e78-9e71-6ccc376e13f2
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app.kubernetes.io/instance: ds-data-saver
      app.kubernetes.io/name: ds-data-saver
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      annotations:
        kubectl.kubernetes.io/restartedAt: "2024-05-21T09:25:54Z"
      creationTimestamp: null
      labels:
        app.kubernetes.io/instance: ds-data-saver
        app.kubernetes.io/name: ds-data-saver
    spec:
      containers:
      - env:
        - name: SPRING_CLOUD_CONFIG_PASSWORD
          valueFrom:
            secretKeyRef:
              key: SPRING_CLOUD_CONFIG_PASSWORD
              name: spring-secret
        - name: SPRING_CLOUD_CONFIG_USERNAME
          valueFrom:
            secretKeyRef:
              key: SPRING_CLOUD_CONFIG_USERNAME
              name: spring-secret
        - name: SPRING_PROFILES_ACTIVE
          valueFrom:
            secretKeyRef:
              key: SPRING_PROFILES_ACTIVE
              name: spring-secret
        image: 769294742237.dkr.ecr.us-east-2.amazonaws.com/ds-data-saver:R10.2024.06.05-53
        imagePullPolicy: Always
        lifecycle:
          postStart:
            exec:
              command:
              - /bin/sh
              - -c
              - echo started > /proc/1/fd/1
          preStop:
            exec:
              command:
              - /bin/sh
              - -c
              - curl -XPOST http://localhost:8081/actuator/shutdown > /proc/1/fd/1
        livenessProbe:
          failureThreshold: 3
          httpGet:
            path: /actuator/health
            port: 8081
            scheme: HTTP
          initialDelaySeconds: 60
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 10
        name: ds-data-saver
        ports:
        - containerPort: 8081
          name: mgmt-port
          protocol: TCP
        - containerPort: 8080
          name: server-port
          protocol: TCP
        readinessProbe:
          failureThreshold: 5
          httpGet:
            path: /actuator/health
            port: 8081
            scheme: HTTP
          initialDelaySeconds: 60
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 10
        resources:
          limits:
            cpu: 1500m
            memory: 1500Mi
          requests:
            cpu: 500m
            memory: 500Mi
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      imagePullSecrets:
      - name: ecrreg
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 60
      tolerations:
      - effect: NoSchedule
        key: be-app
        operator: Equal
        value: api
status:
  availableReplicas: 1
  conditions:
  - lastTransitionTime: "2024-05-21T09:25:54Z"
    lastUpdateTime: "2024-06-05T05:18:11Z"
    message: ReplicaSet "ds-data-saver-6cc88f598f" has successfully progressed.
    reason: NewReplicaSetAvailable
    status: "True"
    type: Progressing
  - lastTransitionTime: "2024-06-05T12:03:02Z"
    lastUpdateTime: "2024-06-05T12:03:02Z"
    message: Deployment has minimum availability.
    reason: MinimumReplicasAvailable
    status: "True"
    type: Available
  observedGeneration: 1987
  readyReplicas: 1
  replicas: 1
  updatedReplicas: 1