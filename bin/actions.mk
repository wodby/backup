check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Required parameter is missing: $1$(if $2, ($2))))

days ?= 7
gzip ?= ""
exclude ?= ""
mark ?= ""
secret ?= ""
destination ?= ""
content_disposition ?= ""

max_concurrent_requests ?= 1
max_bandwidth = ""
storage_class ?= STANDARD

default: backup-dir

backup-dir:
	$(call check_defined, dir, filepath)
	backup $(dir) $(filepath) $(gzip) "$(exclude)" "$(mark)"
.PHONY: backup-dir

upload:
	$(call check_defined, provider, key, bucket, filepath)
	upload \
		$(provider) $(key) $(secret) \
		$(filepath) $(bucket) $(destination) \
		$(max_concurrent_requests) $(max_bandwidth) $(storage_class) $(content_disposition) $(region)
.PHONY: upload

backup-and-upload:
	$(call check_defined, provider, dir, key, bucket, destination)
	backup_and_upload \
		$(provider) $(key) $(secret) \
		$(dir) $(gzip) $(exclude) $(mark) $(bucket) $(destination) \
		$(max_concurrent_requests) $(max_bandwidth) $(storage_class) $(content_disposition) $(region)
.PHONY: backup-and-upload

import:
	$(call check_defined, source, destination)
	import $(source) $(destination) $(owner) $(group) $(allowed)
.PHONY: import

rotate:
	$(call check_defined, dir)
	find $(dir) -mindepth 1 -mtime +$(days) -delete
.PHONY: rotate

delete:
	$(call check_defined, filepath)
	rm -f $(filepath)
.PHONY: delete

check-ready:
	exit 0
.PHONY: check-ready

check-live:
	@echo "OK"
.PHONY: check-live
