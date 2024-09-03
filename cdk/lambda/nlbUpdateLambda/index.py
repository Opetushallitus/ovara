import os
import socket
import boto3

def handler(event, context):
  rds_endpoint = os.environ.get('RDS_ENDPOINT')
  nlb_target_group_arn = os.environ.get('TARGET_GROUP_ARN')
  db_port = os.environ.get('RDS_PORT')
  client = boto3.client('elbv2')

  # DeRegister old IP from NLB
  def deregister_oldip(target_ip, target_port):
    response = client.deregister_targets(
      TargetGroupArn=nlb_target_group_arn,
      Targets=[
        {
          'Id': target_ip,
          'Port': target_port,
        },
      ]
    )

  # Register new IP to NLB
  def register_newip(new_rds_ip, db_port):
    response = client.register_targets(
      TargetGroupArn=nlb_target_group_arn,
      Targets=[
        {
            'Id': new_rds_ip,
            'Port': int(db_port)
        },
      ]
    )

  # Get Master Node IP address
  new_rds_ip = socket.gethostbyname_ex(rds_endpoint)    
  rds_ips = new_rds_ip[2]
  print('IP list from DNS: ', rds_ips)

  # Get Registered IP detail from NLB        
  target_group_instances = client.describe_target_health(
    TargetGroupArn=nlb_target_group_arn
  )

  ip_list = []
  for i in target_group_instances['TargetHealthDescriptions']:
    ip = i.get('Target').get('Id')
    ip_list.append(ip)

  if not ip_list:
    for ip in rds_ips:
      print('Register New IP ', ip, 'Port: ', db_port)
      register_newip(ip, db_port)

  deregister_ips = set(ip_list) - set(rds_ips)
  register_ips = set(rds_ips) - set(ip_list)
  
  if deregister_ips:
    print('IP: ', str(deregister_ips), ' will be DeRegistered from NLB Target')
  
  if register_ips:
    print('IP: ', str(register_ips), ' will be registered to NLB Target')

  for ip in register_ips:
    print('Registering New IP ', ip, 'Port: ', db_port)
    register_newip(ip, db_port)
      
  for ip in target_group_instances['TargetHealthDescriptions']:
    target_ip = ip.get('Target').get('Id')
    target_port = ip.get('Target').get('Port')
    print('IP list from NLB Target Group: ', target_ip)
    if target_ip in deregister_ips:
      print('DeRegister IP: ', target_ip, 'Port; ', target_port)
      deregister_oldip(target_ip, target_port)