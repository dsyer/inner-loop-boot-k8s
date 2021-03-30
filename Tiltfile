# -*- mode: Python -*-

custom_build('localhost:5000/apps/demo', 
  './mvnw spring-boot:build-image -P devtools -D image=$EXPECTED_REF',
  ['pom.xml', './target/classes'],
  live_update = [
    sync('./target/classes', '/workspace/BOOT-INF/classes')
  ]
)
k8s_yaml(kustomize('./src/k8s/demo'))
k8s_resource('hello-world', port_forwards="8080:8080")