#!/bin/bash

echo '=== Start'
date

# Prune remote accounts that never interacted with a local user
echo '--- Prune remote accounts that never interacted with a local user'
date
tootctl accounts prune;

# Remove remote statuses that local users never interacted with older than 4 days
echo '--- Remove remote statuses that local users never interacted with older than 4 days'
date
tootctl statuses remove --days 4;

# Remove media attachments older than 4 days
echo '--- Remove media attachments older than 4 days'
date
tootctl media remove --days 4;

# Remove all headers (including people I follow)
echo '--- Remove all headers (including people I follow)'
date
tootctl media remove --remove-headers --include-follows --days 0;

# Remove link previews older than 4 days
echo '--- Remove link previews older than 4 days'
date
tootctl preview_cards remove --days 4;

# Remove files not linked to any post
echo '--- Remove files not linked to any post'
date
tootctl media remove-orphans;

echo '=== End'
date
