IMAGE = schoolscout/mysql-backup:0.2.0

build:
		docker build -t ${IMAGE} .

test: build
		./test.sh

push: build
		docker push ${IMAGE}
