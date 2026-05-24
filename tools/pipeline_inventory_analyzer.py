#!/usr/bin/env python3
"""
Module B: Legacy pipeline discovery and migration inventory.
Classifies each pipeline by source_control, runner, build_tool,
secrets, artifact_store, deployment_method, environments,
approvals, risk_score, risk_factors, and migration_complexity.
Outputs: reports/pipeline_inventory.json + reports/pipeline_inventory.csv
"""
import csv
import json
from pathlib import Path

REPO_ROOT   = Path(__file__).resolve().parents[1]
LEGACY_ROOT = REPO_ROOT / "pipelines" / "legacy-migration" / "legacy-ci"
JSON_OUT    = REPO_ROOT / "reports" / "pipeline_inventory.json"
CSV_OUT     = REPO_ROOT / "reports" / "pipeline_inventory.csv"

CSV_FIELDS = [
    "tool","path","source_control","runner_model","build_tool",
    "secrets_model","artifact_store","deployment_method",
    "target_environments","approval_model","risk_score",
    "risk_factors","migration_complexity",
]

def detect_tool(path):
    if path.name == "Jenkinsfile":    return "jenkins"
    if "bamboo" in path.as_posix():  return "bamboo"
    return "gitlab"

def detect_source_control(content, tool):
    if "github.com" in content:    return "github"
    if "gitlab" in content:        return "gitlab"
    if "bitbucket" in content:     return "bitbucket"
    if tool == "bamboo":           return "bitbucket-or-bamboo-linked"
    return "git-unspecified"

def detect_runner(tool, content):
    if tool == "jenkins":
        return "jenkins-labelled-agent" if "agent { label" in content else "jenkins-agent-any"
    if tool == "bamboo":
        return "bamboo-remote-agent" if "remote" in content else "bamboo-local-agent"
    return "gitlab-runner-tagged (docker)" if "tags:" in content else "gitlab-runner-shared"

def detect_build_tool(content):
    if "./mvnw" in content or "mvnw" in content: return "maven-wrapper"
    if "mvn "   in content:                      return "maven"
    if "./gradlew" in content:                   return "gradle-wrapper"
    if "npm "   in content:                      return "node"
    if "dotnet" in content:                      return "dotnet"
    return "unknown"

def detect_secrets(content):
    markers = {
        "withcredentials":   "jenkins-withCredentials",
        "usernamepassword":  "jenkins-usernamePassword-binding",
        "secrettext":        "jenkins-secretText-binding",
        "variables:":        "pipeline-variables-block",
        "bamboo.":           "bamboo-plan-variables",
        "password":          "plain-text-password-reference",
    }
    found = [v for k, v in markers.items() if k in content]
    return "; ".join(found) if found else "none-detected"

def detect_artifact_store(content):
    s = []
    if "docker push"      in content: s.append("container-registry")
    if "archiveartifacts" in content: s.append("jenkins-build-artifacts")
    if "artifacts:"       in content: s.append("pipeline-artifacts")
    if "nexus" in content or "artifactory" in content: s.append("artifact-repository")
    return "; ".join(s) if s else "unknown"

def detect_deploy_method(content):
    m = []
    if "deploy-vm.sh" in content or "ssh " in content: m.append("vm-scripted-ssh")
    if "kubectl"      in content:                       m.append("kubernetes-kubectl")
    if "helm"         in content:                       m.append("kubernetes-helm")
    if "az webapp"    in content:                       m.append("azure-app-service")
    return "; ".join(m) if m else "unknown"

def detect_environments(content):
    found = [e for e in ["dev","test","staging","uat","prod","production"] if e in content]
    return "; ".join(found) if found else "unspecified"

def detect_approvals(content):
    if "input(" in content or "input {" in content: return "jenkins-input-step (manual gate)"
    if "manual: true" in content:                   return "bamboo-manual-stage"
    if "when: manual"  in content:                  return "gitlab-manual-job"
    return "pipeline-driven (no explicit gate)"

def calculate_risk(content):
    factors = []
    if "password"         in content: factors.append("plain-text password reference")
    if "deploy-vm.sh"     in content: factors.append("VM scripted deployment (fragile)")
    if "nexus" in content or "jfrog" in content: factors.append("on-prem artifact repo dependency")
    if "withcredentials"  in content: factors.append("Jenkins-native credential binding")
    if "bamboo."          in content: factors.append("Bamboo plan variable references")
    if "docker push"      in content: factors.append("manual Docker push (no immutable tag)")
    if "agent any"        in content: factors.append("uncontrolled agent selection")
    n = len(factors)
    score = "critical" if n >= 4 else "high" if n >= 2 else "medium" if n == 1 else "low"
    return score, factors

def migration_complexity(risk, tool):
    matrix = {
        ("critical","jenkins"): "large — plugin audit + credential migration",
        ("critical","bamboo"):  "large — plan-variable and agent rework",
        ("critical","gitlab"):  "large — runner and protected-variable migration",
        ("high","jenkins"):     "medium-large — shared library and credential mapping",
        ("high","bamboo"):      "medium-large — deployment project migration",
        ("high","gitlab"):      "medium — runner tag and variable lift",
        ("medium","jenkins"):   "medium — stage/post condition translation",
        ("medium","bamboo"):    "medium — stage/job/task mapping",
        ("medium","gitlab"):    "small-medium — stages and artifacts map cleanly",
        ("low","jenkins"):      "small — declarative pipeline maps to ADO YAML",
        ("low","bamboo"):       "small — YAML Specs map to ADO stage/job",
        ("low","gitlab"):       "small — stages map to ADO dependsOn",
    }
    return matrix.get((risk, tool), "medium — manual review recommended")

def classify_pipeline(path):
    text   = path.read_text(encoding="utf-8")
    lower  = text.lower()
    tool   = detect_tool(path)
    risk, factors = calculate_risk(lower)
    return {
        "tool":               tool,
        "path":               str(path.relative_to(REPO_ROOT)),
        "source_control":     detect_source_control(lower, tool),
        "runner_model":       detect_runner(tool, lower),
        "build_tool":         detect_build_tool(lower),
        "secrets_model":      detect_secrets(lower),
        "artifact_store":     detect_artifact_store(lower),
        "deployment_method":  detect_deploy_method(lower),
        "target_environments":detect_environments(lower),
        "approval_model":     detect_approvals(lower),
        "risk_score":         risk,
        "risk_factors":       factors,
        "migration_complexity": migration_complexity(risk, tool),
    }

def write_csv(pipelines):
    with CSV_OUT.open("w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=CSV_FIELDS)
        w.writeheader()
        for p in pipelines:
            row = {k: p[k] for k in CSV_FIELDS if k in p}
            row["risk_factors"] = " | ".join(p.get("risk_factors", []))
            w.writerow(row)

def main():
    pipelines = []
    for path in sorted(LEGACY_ROOT.rglob("*")):
        if path.is_file() and path.name in {"Jenkinsfile","bamboo-specs.yml",".gitlab-ci.yml"}:
            pipelines.append(classify_pipeline(path))

    JSON_OUT.parent.mkdir(parents=True, exist_ok=True)
    JSON_OUT.write_text(json.dumps({"pipelines": pipelines}, indent=2), encoding="utf-8")
    write_csv(pipelines)
    print(f"Wrote {JSON_OUT}")
    print(f"Wrote {CSV_OUT}")

    print("\n=== Pipeline Inventory Summary ===")
    for p in pipelines:
        print(f"\n[{p['tool'].upper()}] {p['path']}")
        for k in CSV_FIELDS[2:]:
            val = p[k] if k != "risk_factors" else " | ".join(p[k])
            print(f"  {k:<24}: {val}")

if __name__ == "__main__":
    main()