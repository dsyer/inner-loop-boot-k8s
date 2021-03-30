
# Inner Loop Development with Spring Boot and Kubernetes
- [Inner Loop Development with Spring Boot and Kubernetes](#inner-loop-development-with-spring-boot-and-kubernetes)
  - [Spring Boot Devtools](#spring-boot-devtools)
  - [Skaffold](#skaffold)
  - [Telepresence](#telepresence)
  - [Telepresence 0.1](#telepresence-01)

## Spring Boot Devtools

[Devtools](https://docs.spring.io/spring-boot/docs/current/reference/html/using-spring-boot.html#using-boot-devtools) is a Spring Boot feature that watches for changes in source code and restarts the app. It's pretty fast because the JVM is not re-started and most of the classes (all the non-local ones) stay loaded.

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
        <build>
            <plugins>
                <plugin>
                    <groupId>org.springframework.boot</groupId>
                    <artifactId>spring-boot-maven-plugin</artifactId>
                    <configuration>
                        <excludeDevtools>false</excludeDevtools>
                        <image>
                            <name>localhost:5000/apps/${project.artifactId}</name>
                        </image>
                    </configuration>
                </plugin>
            </plugins>
        </build>
    </profile>
</profiles>
```

then at runtime you also need a JVM system property:

```
docker run -p 8080:8080 -e JAVA_TOOL_OPTIONS=-Dspring.devtools.restart.enabled=true localhost:5000/apps/demo
```

```
Setting Active Processor Count to 8
Calculating JVM memory based on 16202804K available memory
Calculated JVM Memory Configuration: -XX:MaxDirectMemorySize=10M -Xmx15809483K -XX:MaxMetaspaceSize=86120K -XX:ReservedCodeCacheSize=240M -Xss1M (Total Memory: 16202804K, Thread Count: 50, Loaded Class Count: 12791, Headroom: 0%)
...
08:19:30.358 [restartedMain] INFO org.springframework.boot.devtools.restart.RestartApplicationListener - Restart enabled irrespective of application packaging due to System property 'spring.devtools.restart.enabled' being set to true

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

THe signature that it is working is the thread name "restartedMain".

Running like that in a fixed docker container isn't much help though. You also need to copy changes to local source code into the running container so that the devtools notice them and restart the app. That's not impossible, but it's a pain to set up. Skaffold does it for you out of the box.

## Skaffold

Remember to set `spring-boot.repackage.excludeDevtools=false` in the build. You could set it as a property in the `pom.xml` or, as in this project, via a Maven profile, and set that with an environment variable for the buildpack `BP_MAVEN_BUILD_ARGUMENTS`:

```
apiVersion: skaffold/v2beta10
kind: Config
build:
  artifacts:
    - image: localhost:5000/apps/demo
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

App comes up on port 4503.

## Telepresence

Instead of using Skaffold to sync the changes with your source code into a running container, you can run the code locally (and debug it), and tunnel through to the k8s cluster using [Telepresence](https://github.com/telepresenceio/telepresence/tree/release/v2). The new shiny Telepresence 2.x is slick. First build a container (or use the one from `skaffold` above):

```
./mvnw spring-boot:build-image
docker push localhost:5000/apps/demo
```

and make sure there is a service running:

```
kubectl apply -f <(kustomize build src/k8s/demo/)
```

Then get it connected (you will need to give it sudo access):

```
telepresence connect
```

and add an intercept for the service:

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

Anything running on port 8080 locally will now be connected to the k8s service "hello-world", and that includes an app running in the debugger.

To shut down the tunnel:

```
telepresence leave hello-world
```

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
telepresence --swap-deployment hello-world --docker-run --rm -v$(pwd):/build -v $HOME/.m2/repository:/m2 -p 8080:80 -w /build openjdk:11 ./mvnw -Dmaven.repo.local=/m2 spring-boot:run
```

Yay!

```
$ curl localhost:8080
Hello, Spring!
```