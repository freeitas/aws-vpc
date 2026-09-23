# aws-vpc

A three-tier VPC for container workloads. It has public, private and database subnets in three availability zones, and one NAT gateway per zone. The VPC and subnet IDs are saved in SSM Parameter Store so other stacks can read them.

## Architecture decisions

### SSM Parameter Store instead of remote state

`parameters_store.tf` writes the VPC ID and the nine subnet IDs to Parameter Store under `/<project>/vpc/`. `output.tf` exposes the same values and marks them `sensitive`.

The alternative is `terraform_remote_state`. With that, every stack that needs a subnet ID must be able to read this stack's whole state file, not just the IDs. It also ties those stacks to the bucket and key where the state lives. With Parameter Store, other stacks only need read access to the `/<project>/vpc/` parameters.

### The database subnets have no route to the internet

`database_subnets.tf` creates three subnets and does not associate them with any route table. They use the VPC's main route table, which only has the local `10.0.0.0/16` route. There is no internet gateway or NAT route, so nothing in these subnets can reach the internet and the internet cannot reach them.

The limitation: these subnets also cannot reach AWS APIs such as S3 or DynamoDB unless VPC endpoints are added. This repo does not create any.

### Three NAT gateways, one per AZ

`nat_gateway.tf` creates an Elastic IP and a NAT gateway in each public subnet. `private_subnets.tf` gives each AZ its own route table, which sends `0.0.0.0/0` to the NAT in the same AZ.

A single NAT gateway costs less: one hourly charge instead of three. But if the AZ with that NAT fails, private subnets in the other two AZs lose internet access too. One NAT per AZ keeps each AZ independent. It also avoids paying for traffic that crosses AZs to reach a NAT.

The downside: outbound traffic leaves from three public IPs instead of one. If a partner allowlists your IPs on their firewall, they need all three.

### AZs are hardcoded letters

Subnets set their AZ with `format("%sa", var.region)`, `%sb` and `%sc`. This is a shortcut: it is the simplest way to put three subnets in three AZs. It has limits:

- It only works in regions that have AZs `a`, `b` and `c`.
- AZ names point to different physical zones in different AWS accounts. Only AZ IDs, such as `use1-az1`, are the same everywhere.
- Changing `availability_zone` on a subnet makes Terraform destroy and recreate it, along with everything inside it.

A more flexible approach is to take a list of AZs from a variable or from `aws_availability_zones` and create the subnets with `for_each`. This repo does not do that.

### /20 private subnets, /24 public and database subnets

The private subnets are `10.0.0.0/20`, `10.0.16.0/20` and `10.0.32.0/20`, with 4,091 usable addresses each. The public and database subnets are /24s, from `10.0.48.0` to `10.0.53.0`, with 251 usable addresses each.

The private subnets hold the container workloads, and every task or pod with its own network interface uses one IP address. A /24 would run out of addresses as those workloads scale. The public and database subnets hold fewer resources, so /24 is enough. The range from `10.0.54.0` up is still free for another tier later.

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
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Project name, used as a prefix for resource names. | `any` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region where resources will be created. | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ssm_subnet_databases_1a"></a> [ssm\_subnet\_databases\_1a](#output\_ssm\_subnet\_databases\_1a) | Database subnet ID in AZ 1a, stored in Parameter Store. |
| <a name="output_ssm_subnet_databases_1b"></a> [ssm\_subnet\_databases\_1b](#output\_ssm\_subnet\_databases\_1b) | Database subnet ID in AZ 1b, stored in Parameter Store. |
| <a name="output_ssm_subnet_databases_1c"></a> [ssm\_subnet\_databases\_1c](#output\_ssm\_subnet\_databases\_1c) | Database subnet ID in AZ 1c, stored in Parameter Store. |
| <a name="output_ssm_subnet_private_1a"></a> [ssm\_subnet\_private\_1a](#output\_ssm\_subnet\_private\_1a) | Private subnet ID in AZ 1a, stored in Parameter Store. |
| <a name="output_ssm_subnet_private_1b"></a> [ssm\_subnet\_private\_1b](#output\_ssm\_subnet\_private\_1b) | Private subnet ID in AZ 1b, stored in Parameter Store. |
| <a name="output_ssm_subnet_private_1c"></a> [ssm\_subnet\_private\_1c](#output\_ssm\_subnet\_private\_1c) | Private subnet ID in AZ 1c, stored in Parameter Store. |
| <a name="output_ssm_subnet_public_1a"></a> [ssm\_subnet\_public\_1a](#output\_ssm\_subnet\_public\_1a) | Public subnet ID in AZ 1a, stored in Parameter Store. |
| <a name="output_ssm_subnet_public_1b"></a> [ssm\_subnet\_public\_1b](#output\_ssm\_subnet\_public\_1b) | Public subnet ID in AZ 1b, stored in Parameter Store. |
| <a name="output_ssm_subnet_public_1c"></a> [ssm\_subnet\_public\_1c](#output\_ssm\_subnet\_public\_1c) | Public subnet ID in AZ 1c, stored in Parameter Store. |
| <a name="output_ssm_vpc_id"></a> [ssm\_vpc\_id](#output\_ssm\_vpc\_id) | VPC ID, stored in Parameter Store. |
