.PHONY: help install inspect targets clean-data rfm db-up db-down db-load report pipeline clean

PYTHON := python

help:
	@echo "Sales Operations & MIS Analytics — Task Commands"
	@echo "------------------------------------------------"
	@echo "make install     : Install dependencies from requirements.txt"
	@echo "make inspect     : Run data discovery and SHA-256 provenance checks"
	@echo "make targets     : Generate reproducible synthetic sales targets (seed 42)"
	@echo "make clean-data  : Execute data cleaning, anomaly tagging, and quarantine"
	@echo "make rfm         : Run RFM customer segmentation and cohort retention"
	@echo "make report      : Generate executive Excel MIS pack (.xlsx)"
	@echo "make pipeline    : Run end-to-end master analytics orchestrator"
	@echo "make db-up       : Spin up PostgreSQL 16 warehouse container"
	@echo "make db-down     : Stop PostgreSQL warehouse container"
	@echo "make db-load     : Ingest staging, build star schema, and create KPI views"
	@echo "make clean       : Remove python cache files and temporary logs"

install:
	$(PYTHON) -m pip install --upgrade pip
	pip install -r requirements.txt

inspect:
	$(PYTHON) python/inspect_data.py

targets:
	$(PYTHON) python/generate_targets.py

clean-data:
	$(PYTHON) python/clean_data.py

rfm:
	$(PYTHON) python/rfm_analytics.py

db-up:
	docker compose up -d

db-down:
	docker compose down

db-load:
	$(PYTHON) python/load_database.py

report:
	$(PYTHON) python/generate_mis_report.py --period 2018-06 --source csv

pipeline:
	$(PYTHON) python/run_pipeline.py

clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +

