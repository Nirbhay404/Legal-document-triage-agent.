.PHONY: install run test audit eval versions cuad-gold cuad-eval secret-scan offline-proof

install:
	python -m pip install -r requirements.txt

run:
	streamlit run app.py --server.address 127.0.0.1 --browser.gatherUsageStats false

test:
	pytest -q

audit:
	python scripts/static_privacy_audit.py

eval:
	python scripts/run_evals.py

cuad-gold:
	@echo "Extracting CUAD gold cases from data.zip …"
	unzip -o -d /tmp/cuad_extract scripts/data.zip CUADv1.json
	python scripts/cuad_to_gold.py \
	  --src /tmp/cuad_extract/CUADv1.json \
	  --subset dev --contracts 20 --out .
	@rm -rf /tmp/cuad_extract

cuad-eval: cuad-gold
	@echo "Running CUAD benchmark …"
	python scripts/score_cuad.py \
	  --gold eval/gold/cuad_gold.json \
	  --contracts-dir data/cuad_eval/contracts \
	  --out evidence/cuad-eval
	@echo "Report written to evidence/cuad-eval.json"

secret-scan:
	@echo "Scanning tracked files for secrets (gate G5)…"
	@if git grep -nIE -i \
	  -e "(api[_-]?key|secret[_-]?key|password|token)[\"']?[[:space:]]*[:=][[:space:]]*[\"'][^\"'[:space:]]{8,}[\"']" \
	  -e "sk-[A-Za-z0-9]{20,}" \
	  -- ':!*.md' ':!*.txt' ':!.env.example' ':!tests/' ; then \
	  echo "⚠ Potential secrets found – review above before pushing"; exit 1; \
	else echo "✅ No obvious secrets detected"; fi

versions:
	bash scripts/collect_versions.sh

offline-proof:
	@echo "Running offline proof (macOS pfctl – requires sudo) …"
	bash scripts/offline_proof.sh $(SAMPLE)
