
## Skaffold

Remember to set `spring-boot.repackage.excludeDevtools=false` in the build (it's a property in the `pom.xml` in this project). Then:

```
skaffold dev --port-forward
```

App comes up on port 4503.

## Telepresence

Set up a "hello world" service in Kubernetes:

```
kubectl apply -f https://raw.githubusercontent.com/telepresenceio/telepresence/master/docs/tutorials/hello-world.yaml
```

It runs on port 8000 so we can port forward

```
kubectl port-forward services/hello-world 8080:8000
```

and curl it:

```
$ curl localhost:8080
Hello, world!
```

Now replace the app pod with a Spring Boot app:

```
telepresence --swap-deployment hello-world --docker-run --rm -v$(pwd):/build -v $HOME/.m2/repository:/m2 -p 8000:8000 -w /build openjdk:11 ./mvnw -Dmaven.repo.local=/m2 spring-boot:run
```

Yay!

```
$ curl localhost:8080
Hello, Spring!
```