VER="6.4.3"
ENABLED_SERVICES=BUILD PROD
ARCH=arm64
NID_DIR=$(pwd)/NSO-Vol
#Change below variable to "build" for newer versions 
BUILD_CONT=build


build:
	docker volume create run
	docker volume create logging
	-rm ./nso/run/cdb/compact.lock
	docker container create --name dummy -v run:/nso hello-world
	docker cp ./nso dummy:/
	#docker cp ./ncs dummy:/etc/ncs
	docker rm dummy
	docker load -i ./images/nso-${VER}.container-image-${BUILD_CONT}.linux.${ARCH}.tar.gz
	docker load -i ./images/nso-${VER}.container-image-prod.linux.${ARCH}.tar.gz
	#docker build -t mod-nso-prod:${VER}  --no-cache --network=host --build-arg type="prod"  --build-arg ver=${VER} --file Dockerfile .
	#docker build -t mod-nso-dev:${VER}  --no-cache --network=host --build-arg type=${BUILD_CONT}  --build-arg ver=${VER} --file Dockerfile .
	cp util/Makefile ./packages/


deep_clean: clean_log clean_run clean

clean_images: 
	-docker image rm -f cisco-nso-${BUILD_CONT}:${VER}
	-docker image rm -f cisco-nso-prod:${VER}
	-docker image rm -f mod-nso-prod:${VER}  
	-docker image rm -f mod-nso-dev:${VER} 

clean: stop
	-docker volume rm run

stop:
	-docker stop nso-build && docker rm nso-build
	-docker stop nso-prod && docker rm nso-prod

start:
	docker run -d --name nso-prod -e ADMIN_USERNAME=admin -e ADMIN_PASSWORD=admin -e EXTRA_ARGS=--with-package-reload-force -v run:/nso -v ./packages:/nso/run/packages cisco-nso-prod:${VER} 
	docker run -d --name nso-build -v ./packages:/nso/run/packages cisco-nso-build:${VER}

start_compose:
	VER=${VER} docker-compose up ${ENABLED_SERVICES} -d


stop_compose:
	export VER=${VER} ;docker-compose down  ${ENABLED_SERVICES}


compile_packages:
	docker exec -it nso-build make all -C /nso/run/packages

cli-c:
	docker exec -it nso-prod ncs_cli -C -u admin

cli-j:
	docker exec -it nso-prod ncs_cli -J -u admin
