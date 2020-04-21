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

# mirroring
max_concurrent_requests ?= 1
max_bandwidth = ""
storage_class ?= STANDARD

default: backup-dir

backup-dir:
	$(call check_defined, dir, filepath)
	backup $(dir) $(filepath) $(zip) "$(exclude)" "$(mark)"
.PHONY: backup-dir

mirror-s3:
	$(call check_defined, key_id, access_key, bucket, region, filepath)
	AWS_ACCESS_KEY_ID=$(key_id) AWS_SECRET_ACCESS_KEY=$(access_key) aws_s3_copy \
		$(filepath) $(bucket) $(region) \
		$(max_concurrent_requests) $(max_bandwidth) $(storage_class)
.PHONY: mirror-s3

backup-and-copy:
	$(call check_defined, dir, key_id, access_key, bucket, region)
	AWS_ACCESS_KEY_ID=$(key_id) AWS_SECRET_ACCESS_KEY=$(access_key) backup_and_copy \
		$(dir) $(exclude) $(mark) \
		$(bucket) $(region) \
		$(max_concurrent_requests) $(max_bandwidth) $(storage_class)
.PHONY: backup-and-copy

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
