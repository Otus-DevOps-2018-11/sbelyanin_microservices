export USERNAME=sbelyanin
export MONGOD_EXP=v0.6.3 
export BLACKBOX_EXP=v0.14.0
export COMPOSE_TLS_VERSION=TLSv1_2


build-all:
	docker build -t $(USERNAME)/prometheus monitoring/prometheus/
	docker build -t $(USERNAME)/comment src/comment/
	docker build -t $(USERNAME)/post src/post-py/
	docker build -t $(USERNAME)/ui src/ui/
	docker build -t $(USERNAME)/blackbox_exporter:$(BLACKBOX_EXP) monitoring/blackbox_exporter/
	docker build -t $(USERNAME)/mongod_exporter:$(MONGOD_EXP) monitoring/mongod_exporter/
#
build-ui:
	docker build -t $(USERNAME)/ui src/ui/
build-comment:
	docker build -t $(USERNAME)/comment src/comment/
build-post:
	docker build -t $(USERNAME)/post src/post-py/
build-prometheus:
	docker build -t $(USERNAME)/prometheus monitoring/prometheus/
build-blackbox-exp:
	docker build -t $(USERNAME)/blackbox_exporter:$(BLACKBOX_EXP) monitoring/blackbox_exporter/
build-mongod-exp:
	docker build -t $(USERNAME)/mongod_exporter:$(MONGOD_EXP) monitoring/mongod_exporter/

push-all:
	docker push $(USERNAME)/prometheus
	docker push $(USERNAME)/comment
	docker push $(USERNAME)/post
	docker push $(USERNAME)/ui
	docker push $(USERNAME)/blackbox_exporter:$(BLACKBOX_EXP)
	docker push $(USERNAME)/mongod_exporter:$(MONGOD_EXP)

