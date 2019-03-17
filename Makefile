export USERNAME=sbelyanin
export MONGOD_EXP=v0.6.3 
export BLACKBOX_EXP=v0.14.0
export COMPOSE_TLS_VERSION=TLSv1_2
export SRC=src

build-all:
	docker build -t $(USERNAME)/prometheus monitoring/prometheus/
	docker build -t $(USERNAME)/comment $(SRC)/comment/
	docker build -t $(USERNAME)/post $(SRC)/post-py/
	docker build -t $(USERNAME)/ui $(SRC)/ui/
	docker build -t $(USERNAME)/blackbox_exporter:$(BLACKBOX_EXP) monitoring/blackbox_exporter/
	docker build -t $(USERNAME)/mongod_exporter:$(MONGOD_EXP) monitoring/mongod_exporter/
	docker build -t $(USERNAME)/alertmanager monitoring/alertmanager/
	docker build -t $(USERNAME)/telegraf monitoring/telegraf/
	docker build -t $(USERNAME)/fluentd logging/fluentd/
#
build-fluentd:
	docker build -t $(USERNAME)/fluentd logging/fluentd/
build-ui:
	docker build -t $(USERNAME)/ui $(SRC)/ui/
build-comment:
	docker build -t $(USERNAME)/comment $(SRC)/comment/
build-post:
	docker build -t $(USERNAME)/post $(SRC)/post-py/
build-prometheus:
	docker build -t $(USERNAME)/prometheus monitoring/prometheus/
build-alertmanager:
	docker build -t $(USERNAME)/alertmanager monitoring/alertmanager/
build-telegraf:
	docker build -t $(USERNAME)/telegraf monitoring/telegraf/
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
	docker push $(USERNAME)/alertmanager
	docker push $(USERNAME)/telegraf
