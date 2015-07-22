IMAGE = schoolscout/mysql-backup

build:
		docker build -t ${IMAGE} .

test: test-docker test-external

test-docker: build
		./test.sh docker

test-external: build
		./test.sh external

push: build test
		docker push ${IMAGE}
