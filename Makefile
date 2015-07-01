IMAGE = schoolscout/mysql-backup

build:
		docker build -t ${IMAGE} .

push: build
		docker push ${IMAGE}
