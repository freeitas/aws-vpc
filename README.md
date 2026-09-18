## Architecture decisions

### Why SSM Parameter Store and not remote state here

The VPC id and the nine subnet ids are written to `/<project>/vpc/*` in Parameter Store (`parameters_store.tf`); `output.tf` re-exports those parameter resources and marks every one `sensitive`. I rejected `terraform_remote_state`: each stack holds its own state file (`environment/dev/backend.tfvars.example`, `key = "vpc/dev/state"`), so a consumer reading it would need `s3:GetObject` on the whole file — every attribute of every resource — just to learn ten ids, and would break the day I move the bucket or the key. A path prefix is the smaller grant and the stabler contract.

### Why the database tier has no route table at all

`database_subnets.tf` creates three subnets and zero `aws_route_table_association` — the omission *is* the control. They stay on the VPC main route table, which carries only the local `10.0.0.0/16` route: no IGW, no NAT, in or out. Attaching them to the per-AZ private tables, as most three-tier layouts do, would hand the database egress it never needs — a compromised engine can dial out, and every byte bills as NAT processing. The cost I accept: nothing in these subnets reaches an AWS API without an endpoint, and this repo creates none.

### Why three NAT gateways and not one

`nat_gateway.tf` builds an EIP and a NAT gateway in each public subnet, and `private_subnets.tf` gives every AZ its own route table sending `0.0.0.0/0` to the NAT in that AZ. A single shared NAT in 1a would cut the fixed bill to a third, and I turned that down: every byte leaving 1b and 1c would cross an AZ boundary and be billed twice (transfer plus NAT processing), and losing 1a would take egress away from two healthy AZs — which defeats the point of spreading across three.

### Why hard-coded AZ letters and not `aws_availability_zones`

Subnets pin their AZ with `format("%sa", var.region)` instead of indexing a data source. An index into that list is not guaranteed to land on the same physical AZ in another account, and `availability_zone` forces replacement — Terraform destroys and recreates the subnet and everything in it. Pinning also keeps `/<project>/vpc/subnet_private_1a` meaning the same AZ for the life of the account, which is what makes the SSM contract worth publishing. The price: this module only runs in regions exposing a/b/c, and `variables.tf` takes nothing but `project_name` and `region`, neither with a default.

### Why /20 private and /24 public/database

Private subnets get `10.0.0.0/20`, `10.0.16.0/20` and `10.0.32.0/20` — 4,091 usable each — while public and database are /24s packed above them at `.48` through `.53`. Uniform /24s would read tidier and cap the private tier at 251 addresses per AZ; one ENI takes one address, so that ceiling shows up as a placement failure mid scale-up, not as a warning. Packing the /24s at the top leaves `10.0.54.0` upward contiguous for a new tier without renumbering anything.

![Architecture](/arch.jpg)
![Architecture](/arch2.jpg)

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.42.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eip.vpc_eip_1a](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eip.vpc_eip_1b](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eip.vpc_eip_1c](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_internet_gateway.gw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.nat_1a](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_nat_gateway.nat_1b](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_nat_gateway.nat_1c](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route.private_access_1a](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.private_access_1b](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.private_access_1c](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.private_internet_access_1a](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.private_internet_access_1b](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.private_internet_access_1c](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public_internet_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private_1a](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.private_1b](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.private_1c](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public_1a](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public_1b](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public_1c](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_ssm_parameter.databases_1a](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.databases_1b](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.databases_1c](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.private_1a](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.private_1b](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.private_1c](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.public_1a](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.public_1b](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.public_1c](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_subnet.databases_subnet_1a](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.databases_subnet_1b](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.databases_subnet_1c](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.private_subnet_1a](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.private_subnet_1b](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.private_subnet_1c](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public_subnet_1a](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public_subnet_1b](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public_subnet_1c](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name. This variable will be a prefix for resources created within this project | `any` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region where resources will be created | `string` | `"us-east-1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ssm_subnet_databases_1a"></a> [ssm\_subnet\_databases\_1a](#output\_ssm\_subnet\_databases\_1a) | Database subnet ID in availability zone 1a. This ID is retrieved from AWS Systems Manager Parameter Store and used for provisioning database instances in this specific zone. |
| <a name="output_ssm_subnet_databases_1b"></a> [ssm\_subnet\_databases\_1b](#output\_ssm\_subnet\_databases\_1b) | Database subnet ID in availability zone 1b. Obtained from AWS Systems Manager Parameter Store, it is essential for allocating database instances that need to be isolated in this zone. |
| <a name="output_ssm_subnet_databases_1c"></a> [ssm\_subnet\_databases\_1c](#output\_ssm\_subnet\_databases\_1c) | Database subnet ID in availability zone 1c, sourced from AWS Systems Manager Parameter Store. Used for provisioning database instances that require isolation in this zone. |
| <a name="output_ssm_subnet_private_1a"></a> [ssm\_subnet\_private\_1a](#output\_ssm\_subnet\_private\_1a) | Private subnet ID in availability zone 1a. Value stored in AWS Systems Manager Parameter Store, used to provision resources in a specific private subnet. |
| <a name="output_ssm_subnet_private_1b"></a> [ssm\_subnet\_private\_1b](#output\_ssm\_subnet\_private\_1b) | Private subnet ID in availability zone 1b. Stored in AWS Systems Manager Parameter Store, used for allocating resources that require isolation within this availability zone. |
| <a name="output_ssm_subnet_private_1c"></a> [ssm\_subnet\_private\_1c](#output\_ssm\_subnet\_private\_1c) | Private subnet ID in availability zone 1c. Stored in AWS Systems Manager Parameter Store, it is crucial for creating resources that need to be isolated in this specific zone. |
| <a name="output_ssm_subnet_public_1a"></a> [ssm\_subnet\_public\_1a](#output\_ssm\_subnet\_public\_1a) | Public subnet ID in availability zone 1a. This ID, sourced from AWS Systems Manager Parameter Store, is used to provision publicly accessible resources in this zone. |
| <a name="output_ssm_subnet_public_1b"></a> [ssm\_subnet\_public\_1b](#output\_ssm\_subnet\_public\_1b) | Public subnet ID in availability zone 1b. Available via AWS Systems Manager Parameter Store, enables the deployment of resources with public access in this specific zone. |
| <a name="output_ssm_subnet_public_1c"></a> [ssm\_subnet\_public\_1c](#output\_ssm\_subnet\_public\_1c) | Public subnet ID in availability zone 1c, stored in AWS Systems Manager Parameter Store. Used to configure resources that need public access in this zone. |
| <a name="output_ssm_vpc_id"></a> [ssm\_vpc\_id](#output\_ssm\_vpc\_id) | VPC ID stored in AWS Systems Manager Parameter Store. This ID is used to identify the VPC where resources will be provisioned. |
