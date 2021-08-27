
# Inner Loop with Spring Boot and Kubernetes

Twitter: [@david_syer  ](https://twitter.com/david_syer)  
Email: dsyer@vmware.com  
Github: https://github.com/dsyer/inner-loop-boot-k8s

- [Inner Loop with Spring Boot and Kubernetes](#inner-loop-with-spring-boot-and-kubernetes)
  - [Inner Loop and Outer Loop](#inner-loop-and-outer-loop)
  - [Getting Set Up](#getting-set-up)
  - [Run the Sample App](#run-the-sample-app)
  - [Spring Boot Devtools](#spring-boot-devtools)
  - [Build a Container](#build-a-container)
  - [Skaffold](#skaffold)
  - [Telepresence](#telepresence)
  - [Telepresence 0.1](#telepresence-01)
  - [Tilt](#tilt)

## [Inner Loop](https://github.com/spring-projects/spring-boot/issues/22691) and Outer Loop

Inner Loop:

* Make a small change to code
* See it wiggle
* Debugger
* Iterate

Outer Loop:

* Push a change to remote repository
* Automation builds, tests and promotes code to runtime
* Continuous Deployment
* Testing in production 

## Getting Set Up

To explore the examples in this project you will need a Kubernetes cluster, and some command line tools: `kubectl`, `kustomize` (optionally), [`skaffold`](https://skaffold.dev), [`telepresence`](https://www.getambassador.io/docs/telepresence/) and [`tilt`](https://tilt.dev/). If you want a local cluster you can use `kind` and there is a utility script to set the cluster up in `kind-setup.sh`.

If you are able to use [Nix](https://nixos.org/guides/install-nix.html) then you can install everything you need with `nix-shell` (on the command line in the root of the project).

```
$ nix-shell
   ___                         _                       
 _|_ _|_ __  _ __   ___ _ __  | |    ___   ___  _ __ _ 
(_)| || '_ \| '_ \ / _ \ '__| | |   / _ \ / _ \| '_ (_)
 _ | || | | | | | |  __/ |    | |__| (_) | (_) | |_) | 
(_)___|_| |_|_| |_|\___|_|    |_____\___/ \___/| .__(_)
                                               |_|     
Cluster already active: kind
Setting up kubeconfig
configmap/local-registry-hosting unchanged
NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/kubernetes     ClusterIP   10.96.0.1       <none>        443/TCP   4h29m
```

An IDE will be useful. [VSCode](https://code.visualstudio.com/) has excellent Kubernetes features that you can install as extensions.

Optionally install Knative Serving

```
curl -sL https://raw.githubusercontent.com/csantanapr/knative-kind/master/02-serving.sh | bash
curl -sL https://raw.githubusercontent.com/csantanapr/knative-kind/master/02-kourier.sh | bash
```

## Run the Sample App

Run the `main()` method from your IDE or the command line:

```
./mvnw spring-boot:run
```

Verify that it works at http://localhost:8080.

## Spring Boot Devtools

[Devtools](https://docs.spring.io/spring-boot/docs/current/reference/html/using-spring-boot.html#using-boot-devtools) is a Spring Boot feature that watches for changes in source code and restarts the app. It's pretty fast because the JVM is not re-started and most of the classes (all the non-local ones) stay loaded. It's really designed to work when you run the app locally, on bare metal, but it's not impossible to make it work in a container, and that is what we will need if we are going to use it in Kubernetes.

To enable devtools we need an extra dependency, and to make it work in a container we need to make sure that dependency is included in the image. One way to do that is via a Maven profile:

```
<profiles>
    <profile>
        <id>devtools</id>
        <dependencies>
            <dependency>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-devtools</artifactId>
                <scope>runtime</scope>
            </dependency>
        </dependencies>
    </profile>
</profiles>
```

Then you can run the app from the command line like this:

```
./mvnw spring-boot:run -P devtools
```

```
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::                (v2.4.4)

2021-03-30 08:19:30.701  INFO 1 --- [  restartedMain] com.example.demo.DemoApplication         : Starting DemoApplication v0.0.1-SNAPSHOT using Java 11.0.10 on eb73ffec252e with PID 1 (/workspace/BOOT-INF/classes started by cnb in /workspace)
2021-03-30 08:19:30.702  INFO 1 --- [  restartedMain] com.example.demo.DemoApplication         : No active profile set, falling back to default profiles: default
2021-03-30 08:19:30.759  INFO 1 --- [  restartedMain] .e.DevToolsPropertyDefaultsPostProcessor : Devtools property defaults active! Set 'spring.devtools.add-properties' to 'false' to disable
2021-03-30 08:19:30.759  INFO 1 --- [  restartedMain] .e.DevToolsPropertyDefaultsPostProcessor : For additional web related logging consider setting the 'logging.level.web' property to 'DEBUG'
2021-03-30 08:19:31.699  INFO 1 --- [  restartedMain] o.s.b.d.a.OptionalLiveReloadServer       : LiveReload server is running on port 35729
2021-03-30 08:19:31.810  INFO 1 --- [  restartedMain] o.s.b.web.embedded.netty.NettyWebServer  : Netty started on port 8080
2021-03-30 08:19:31.832  INFO 1 --- [  restartedMain] com.example.demo.DemoApplication         : Started DemoApplication in 1.462 seconds (JVM running for 1.862)
```

The signature that it is working is the thread name "restartedMain". When you see that, you know you can make changes to the application in your IDE and the app will restart. The restart is fast because the JVM is already warm.

## Build a Container

There are many ways to build a container from a Spring Boot application. Here we will use [Paketo Build Packs](https://paketo.io/docs/buildpacks/). Spring Boot has a build plugin that uses buildpacks:

```
./mvnw spring-boot:build-image
```

Then you can run it

```
docker run -p 8080:8080 registry.local:5000/apps/demo
```

```
Setting Active Processor Count to 8
Calculating JVM memory based on 16202804K available memory
Calculated JVM Memory Configuration: -XX:MaxDirectMemorySize=10M -Xmx15809483K -XX:MaxMetaspaceSize=86120K -XX:ReservedCodeCacheSize=240M -Xss1M (Total Memory: 16202804K, Thread Count: 50, Loaded Class Count: 12791, Headroom: 0%)
...
```

To run the app in a container with devtools you would need to re-build it:

```
./mvnw spring-boot:build-image -P devtools
```

then at runtime you need a JVM system property:

```
docker run -p 8080:8080 -e JAVA_TOOL_OPTIONS=-Dspring.devtools.restart.enabled=true registry.local:5000/apps/demo
```

```
Setting Active Processor Count to 8
Calculating JVM memory based on 16202804K available memory
Calculated JVM Memory Configuration: -XX:MaxDirectMemorySize=10M -Xmx15809483K -XX:MaxMetaspaceSize=86120K -XX:ReservedCodeCacheSize=240M -Xss1M (Total Memory: 16202804K, Thread Count: 50, Loaded Class Count: 12791, Headroom: 0%)
...
08:19:30.358 [restartedMain] INFO org.springframework.boot.devtools.restart.RestartApplicationListener - Restart enabled irrespective of application packaging due to System property 'spring.devtools.restart.enabled' being set to true
...
```

Running like that in a fixed docker container isn't much help though. You also need to copy changes to local source code into the running container so that the devtools notice them and restart the app. That's not impossible, but it's a pain to set up. Skaffold does it for you out of the box.

## Skaffold

[Skaffold](https://skaffold.dev/) is a build automation tool that you can use at dev time as well as to push apps into production. It has native support for buildpacks, but you can also use it with other container builders.

Remember the Maven profile above, and we can set that with an environment variable for the buildpack `BP_MAVEN_BUILD_ARGUMENTS`. Here's the `skaffold.yaml`:

```
apiVersion: skaffold/v2beta10
kind: Config
build:
  artifacts:
    - image: registry.local:5000/apps/demo
      buildpacks:
        builder: paketobuildpacks/builder:base
        env:
          - BP_MAVEN_BUILD_ARGUMENTS=-P devtools package
...
```

Then:

```
skaffold dev --port-forward
```

The app comes up on port 4503. You can make changes and they will be synced to the running container, where they are picked up by devtools and the app will restart.

Skaffold supports debugging nicely as well. Remember to add the `--auto-sync` flag (it's off by default in debug mode):

```
skaffold debug --auto-sync --port-forward
```

and attach to port 5005 in the running pod. Your IDE can probably do that for you if it has a Kubernetes plugin of some sort.

## Telepresence

Instead of using Skaffold to sync the changes with your source code into a running container, you can run the code locally (and debug it), and tunnel through to the k8s cluster using [Telepresence](https://github.com/telepresenceio/telepresence/tree/release/v2). The new shiny Telepresence 2.x is slick. First build a container (or use the one from `skaffold` above):

```
./mvnw spring-boot:build-image
docker push registry.local:5000/apps/demo
```

and make sure there is a service running:

```
kubectl apply -f <(kustomize build src/k8s/demo/)
```

Then get it connected (you will need to give it sudo access):

```
telepresence connect
```

You might need a timeout to be configured (telepresence will tell you if it times out connecting):

```
$ cat > ~/.config/telepresence/config.yml
timeouts:
  trafficManagerConnect: 120
  trafficManagerAPI: 120
```

Then add an intercept for the service:

```
telepresence intercept hello-world --port 8080:http
```
```
    Intercept name   : hello-world
    State            : ACTIVE
    Workload kind    : Deployment
    Destination      : 127.0.0.1:8080
    Service Port Name: http
    Intercepting     : all TCP connections
```

Anything running on port 8080 locally will now be connected to the k8s service "hello-world", and that includes an app running in the debugger. Even neater, Telepresence maps DNS on the cluster to localhost, so you can connect to the app via http://hello-world.default/.

To shut down the tunnel:

```
telepresence leave hello-world
```

and clean up:

```
telepresence uninstall --everything
```

Getting started tutorial: https://www.telepresence.io/tutorials/kubernetes.

## Telepresence 0.1

The older version of [Telepresence](https://github.com/telepresenceio/telepresence) also still works, and this is the one you probably find in your OS package manager by default. Set up a "hello world" service in Kubernetes:

```
kubectl apply -f <(kustomize build src/k8s/demo)
```

It runs on port 80 so we can port forward

```
kubectl port-forward services/hello-world 8000:80
```

and curl it:

```
$ curl localhost:8000
Hello Spring!
```

Now replace the app pod with a local Spring Boot app:

```
telepresence --swap-deployment hello-world --run ./mvnw spring-boot:run
```

Run the app and make a change locally. You can connect to it through the cluster. Yay!

```
$ curl localhost:8000
Hello, Spring (local)!
```

## Tilt

[Tilt](https://tilt.dev/) is another tool that can sync local files with a running container (it's a bit more than that, but we can concentrate on that part here). The configuration options cover similar territory to Skaffold - building, syncing, deploying to Kubernetes - but because it uses Python it is quite flexible and expressive by comparison. A simple Spring Boot app like this project can be deployed and synced with a port forward using a short `Tiltfile`:

```
# -*- mode: Python -*-

custom_build('registry.local:5000/apps/demo', 
  './mvnw spring-boot:build-image -P devtools -D image=$EXPECTED_REF',
  ['pom.xml', './target/classes'],
  live_update = [
    sync('./target/classes', '/workspace/BOOT-INF/classes')
  ]
)
k8s_yaml(kustomize('./src/k8s/demo'))
k8s_resource('hello-world', port_forwards="8080:8080")
```

You just do `tilt up` on the command line, and that's it. The local port forward is explicitly on port 8080 there (and it connects to the pod not the service by default). We are syncing the build results the same as with Skaffold.