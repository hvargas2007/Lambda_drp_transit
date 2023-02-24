import json, logging, os
import boto3

client = boto3.client('ec2')

attach_vpn = os.environ['attach_vpn']
attach_dxc = os.environ['attach_dxc']
rt_id = os.environ['route_table_id']
cidr_block = os.environ['cidr_block']

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info('event: {}'.format(event))

    try:
        if event["Action"] == "Failover":
            # Aqui llamas a las funciones en el orden que las necesites.
            disable_rt_propagation()
            create_static_route()

            # aqui deberia haber un `return` de algo

        elif event["Action"] == "Failback":
            enable_rt_propagation()

            # aqui deberia haber un `return` de algo

    except Exception as error:
        logger.error(error)

        return {
            'statusCode': 400,
            'message': 'An error has occurred',
            'moreInfo': {
                'Lambda Request ID': '{}'.format(context.aws_request_id),
                'CloudWatch log stream name': '{}'.format(context.log_stream_name),
                'CloudWatch log group name': '{}'.format(context.log_group_name)
                }
            }
        
# Deshabilitar la propagacion del DirectConnect    
def disable_rt_propagation():   
    for rt in rt_id:
        disable = client.disable_transit_gateway_route_table_propagation(
            TransitGatewayRouteTableId=rt,
            TransitGatewayAttachmentId=attach_dxc,
        )

# Crea la routa estatica        
def create_static_route():
    for rt in rt_id:
        create = client.create_transit_gateway_route(
            DestinationCidrBlock=cidr_block,
            TransitGatewayRouteTableId=rt,
            TransitGatewayAttachmentId=attach_vpn,
        )


# Habilita la propagacion del DirectConnect
def enable_rt_propagation():
    for rt in rt_id:
        enable = client.enable_transit_gateway_route_table_propagation(
             TransitGatewayRouteTableId=rt,
             TransitGatewayAttachmentId=attach_dxc,
        )
