# Pinned deliberately. Upstream's `:latest` meant the running version was
# whatever the last rebuild happened to pull, so this instance silently sat on
# 2026.4.24 for three months. Google patched the user-agent trick that build's
# `google` engine relied on in July 2026, and the engine then returned zero
# results while raising no error, which read as "the web has nothing" rather
# than "search is broken".
#
# Dependabot opens a PR when a new tag ships (see .github/dependabot.yml), so
# upgrades are deliberate and reviewable, and a rollback is a revert.
# After bumping, verify BOTH of these against the deployed instance:
#   1. the JSON API still answers  (searxng/settings.yml -> search.formats)
#   2. result relevance            (claos: node scripts/eval/bench-web-search.mjs)
FROM docker.io/searxng/searxng:2026.8.1-8892414dc

# Use the environment variables that Railway injects at build time (non-sensitive ones)
ARG SEARXNG_BASE_URL
ARG SEARXNG_UWSGI_WORKERS
ARG SEARXNG_UWSGI_THREADS
ARG PORT

# Set Railway-specific environment variables
ENV BASE_URL=${SEARXNG_BASE_URL}
ENV PORT=${PORT:-8080}
ENV UWSGI_WORKERS=${SEARXNG_UWSGI_WORKERS:-4}
ENV UWSGI_THREADS=${SEARXNG_UWSGI_THREADS:-4}

# Copy custom configuration to both locations (for volume mount scenarios)
COPY ./searxng /etc/searxng
COPY ./searxng /etc/searxng-backup

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]