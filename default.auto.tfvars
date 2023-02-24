### Global variables:
aws_profile    = "magios-cli"
aws_region     = "us-east-1"
# route_table_id = ["tgw-rtb-01c2c602a519651e0", "tgw-rtb-02c9328b84995ac97"]
attach_vpn     = "tgw-attach-0d219857615e47644"
attach_dxc     = "tgw-attach-017c30359ad63cbe7"
cidr_block     = "10.0.0.0/16"

project-tags = {
  Service   = "Failover - Failback Routetable",
  CreatedBy = "Hermes.vargas@cloudhesive.com"
  Env       = "Produccion"
}


