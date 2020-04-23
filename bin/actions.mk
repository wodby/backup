check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Required parameter is missing: $1$(if $2, ($2))))

days ?= 7
zip ?= ""
exclude ?= ""
mark ?= ""
region ?= ""
secret ?= ""
scope ?= ""

max_concurrent_requests ?= 1
max_bandwidth = ""
storage_class ?= STANDARD

default: backup-dir

backup-dir:
	$(call check_defined, dir, filepath)
	backup $(dir) $(filepath) $(zip) "$(exclude)" "$(mark)"
.PHONY: backup-dir

upload:
	$(call check_defined, provider, scope, key, bucket, filepath)
	upload \
		$(provider) $(scope) $(key) $(secret) \
		$(filepath) $(bucket) \
		$(max_concurrent_requests) $(max_bandwidth) $(storage_class)
.PHONY: upload

backup-and-upload:
	$(call check_defined, provider, scope, dir, key, bucket, destination)
	backup_and_upload \
		$(provider) $(scope) $(key) $(secret) \
		$(dir) $(exclude) $(mark) $(bucket) $(destination) \
		$(max_concurrent_requests) $(max_bandwidth) $(storage_class)
.PHONY: backup-and-upload

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
