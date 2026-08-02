#!/bin/sh

# This repo is the source of truth for configuration. Sync on EVERY boot.
#
# This was previously guarded by `[ ! -f /etc/searxng/settings.yml ]`, so the copy
# ran exactly once, on the first deploy into an empty volume. Every deploy after
# that found the file present and skipped it, which meant the Railway volume
# mounted at /etc/searxng permanently shadowed the image and no change to
# searxng/settings.yml here could ever reach the container. Verified 2026-08-02:
# the live config was still the one seeded on 2026-04-28, while deploys reported
# success. Config looked version-controlled and was not.
#
# Do not reintroduce the existence check. If you need a value to differ per
# environment, use an environment variable and substitute it below, the way
# secret_key is handled, rather than hand-editing the volume.
if [ -f "/etc/searxng-backup/settings.yml" ]; then
    echo "Syncing configuration from image to /etc/searxng..."
    cp -r /etc/searxng-backup/* /etc/searxng/
    echo "Configuration synced"
fi

# Update the secret key from environment variable at runtime
if [ -n "$SEARXNG_SECRET_KEY" ]; then
    if [ -f "/etc/searxng/settings.yml" ]; then
        echo "Updating secret key from environment variable..."
        sed -i "s|secret_key:.*|secret_key: \"${SEARXNG_SECRET_KEY}\"|g" /etc/searxng/settings.yml
    else
        echo "Warning: settings.yml not found, secret key will be set by SearXNG template"
    fi
else
    echo "Warning: SEARXNG_SECRET_KEY environment variable not set, using default"
fi

# Start SearXNG using the original container's startup logic
exec /usr/local/searxng/entrypoint.sh 