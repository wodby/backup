.PHONY: backup-dir mirror-s3 check-ready check-live

check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Required parameter is missing: $1$(if $2, ($2))))

default: backup-dir

backup-dir:
	$(call check_defined, dir, filepath)
	cd $(dir) && tar -zcf $(filepath) .

mirror-s3:
	$(call check_defined, key_id, access_key, bucket, region, filepath)
	AWS_ACCESS_KEY_ID=$(key_id) AWS_SECRET_ACCESS_KEY=$(access_key) go-aws-s3 $(bucket) $(region) $(filepath)

check-ready:
	exit 0

check-live:
	@echo "OK"
