#!/bin/bash

echo "hiya"

%{ for config_key, config_value in proxy_config ~}
%{ if config_value != null ~}
export ${config_key}="${config_value}"
%{ endif ~}
%{ endfor ~}

templatefile("templates/dummy.sh", {proxy_config = {http_proxy = "http://bloop.io", https_proxy = "https://bonk.io", no_proxy = null} })
