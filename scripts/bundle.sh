find ./docs -name "*.yaml" -type f -exec sh -c './node_modules/.bin/redocly bundle "$1" --output "bundled/$(basename "$1" .yaml).yaml"' _ {} \;
