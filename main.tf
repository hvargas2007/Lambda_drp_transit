module "lambda-failover" {

  source         = "./modules/lambda-failover"
  name_prefix    = "Dxc-Vpn"
  # route_table_id = var.route_table_id
  aws_region = var.aws_region
  attach_vpn     = var.attach_vpn
  attach_dxc     = var.attach_dxc
  cidr_block     = var.cidr_block

}


