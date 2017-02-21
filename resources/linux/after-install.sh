#!/bin/bash

# Link to the binary
ln -sf /opt/yakyak/yakyak /usr/bin/yakyak

# Update icon cache
/bin/touch --no-create /usr/share/icons/hicolor &>/dev/null
/usr/bin/gtk-update-icon-cache /usr/share/icons/hicolor &>/dev/null || :
