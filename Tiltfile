# -*- mode: Python -*-

custom_build('localhost:5000/apps/demo', 
  './mvnw spring-boot:build-image -P devtools -D image=$EXPECTED_REF',
  ['./src/main/java', './src/main/resources', 'pom.xml'],
)
k8s_yaml(kustomize('./src/k8s/demo'))
k8s_resource('hello-world', port_forwards=8080)