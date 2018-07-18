.PHONY: backup-dir mirror-s3 rotate delete check-ready check-live

check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Required parameter is missing: $1$(if $2, ($2))))

days ?= 7
zip ?= ""
exclude ?= ""
mark = ""

# mirroring
max_concurrent_requests ?= 10
max_bandwidth = ""

default: backup-dir

backup-dir:
	$(call check_defined, dir, filepath)
	backup $(dir) $(filepath) $(zip) "$(exclude)" "$(mark)"

mirror-s3:
	$(call check_defined, key_id, access_key, bucket, region, filepath)
	aws_s3_copy \
		$(key_id) $(access_key) \
		$(filepath) $(bucket) $(region) \
		$(max_concurrent_requests) $(max_bandwidth)

rotate:
	$(call check_defined, dir)
	find $(dir) -mindepth 1 -mtime +$(days) -delete

delete:
	$(call check_defined, filepath)
	rm -f $(filepath)

check-ready:
	exit 0

check-live:
	@echo "OK"
