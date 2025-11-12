#!/bin/bash
# ===========================================================
# Script: script_importador.sh
# Autor: MManuel (adaptado por MAX)
# Función:
#   Importa todos los recursos de AWS excuido el recuro
#   de IAM con terraformer
# ===========================================================
resources=(
acm alb api_gateway cloudformation cloudfront cloudwatch config docdb dynamodb ebs ec2_instance eip elb eni igw lambda logs kms nacl nat rds redshift resourcegroups route53 route_table s3 secretsmanager ses sg sqs subnet vpc waf
)

for r in "${resources[@]}"; do
  echo "=== Importando recurso: $r ==="
  terraformer import aws --resources=$r --excludes=iam --connect=true --regions=us-east-1 --profile=PROFILE
done
