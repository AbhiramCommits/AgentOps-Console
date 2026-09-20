#!/bin/sh
# Renders /prometheus/prometheus.yml from the template, substituting the
# optional CopilotGuard / AgentDiff exporter host+port environment variables.
# Jobs whose host variable is empty are dropped entirely so the stack starts
# cleanly when the exporters are absent.
set -e

CONFIG="${PROMETHEUS_CONFIG:-/prometheus/prometheus.yml}"
TEMPLATE=/etc/prometheus/prometheus.yml.tmpl

awk -v copilot="${COPILOTGUARD_HOST:-}" -v copilot_port="${COPILOTGUARD_PORT:-9190}" \
    -v agentdiff="${AGENTDIFF_HOST:-}" -v agentdiff_port="${AGENTDIFF_PORT:-9200}" '
  BEGIN { keep = 1 }
  /^# BEGIN copilotguard/ { keep = (copilot != ""); next }
  /^# END copilotguard/   { keep = 1; next }
  /^# BEGIN agentdiff/    { keep = (agentdiff != ""); next }
  /^# END agentdiff/      { keep = 1; next }
  {
    if (keep) {
      gsub("__COPILOTGUARD_HOST__", copilot)
      gsub("__COPILOTGUARD_PORT__", copilot_port)
      gsub("__AGENTDIFF_HOST__", agentdiff)
      gsub("__AGENTDIFF_PORT__", agentdiff_port)
      print
    }
  }
' "$TEMPLATE" > "$CONFIG"

exec /bin/prometheus "$@"
