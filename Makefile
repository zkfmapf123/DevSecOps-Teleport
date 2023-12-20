plan:
	@cd infra && terraform plan

up:
	@cd infra && terraform apply --auto-approve

destroy:
	@cd infra && terraform destroy --auto-approve