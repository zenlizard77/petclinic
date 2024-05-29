There is no `Dockerfile` in this project. The container is built using Spring Boot build plugin via Buildpacks:
./mvnw spring-boot:build-image

I do understand Dockerfiles and we can dive in deeper if needed, but for this pipeline Maven, Gradle, and Image Builder all use a similar method. This file is a placeholder as the technical assessment called it out. 
