# -*- mode: Python -*-

custom_build('registry.local:5000/apps/demo', 
  './mvnw spring-boot:build-image -P devtools -D image=$EXPECTED_REF',
  ['pom.xml', './target/classes'],
  live_update = [
    sync('./target/classes', '/workspace/BOOT-INF/classes')
  ]
)
k8s_yaml('./src/k8s/knative/service.yaml')
k8s_kind('Service', api_version='serving.knative.dev/v1',
         image_json_path='{.spec.template.spec.containers[].image}')
k8s_resource(workload='hello-world', port_forwards='8080:8080', extra_pod_selectors=[{'serving.knative.dev/service':'hello-world'}])
