IMAGE = schoolscout/mysql-backup

build:
		docker build -t ${IMAGE} .

test: build
		./test.sh

push: build
		docker push ${IMAGE}
