import json
import boto3 
import pg8000.dbapi
import logging
import datetime
import time
import ssl
import os

def lambda_handler(event, context):
    bucket=event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    logger=logging.getLogger()
    logger.setLevel("INFO")
    
    start =time.time()

    s3 = boto3.resource('s3')
    filename = key.replace('%2B','+')
    raw_table = filename.split('__')[0].split('/')[-1]
    export_time = datetime.datetime.strptime(filename.split('__')[1], '%Y-%m-%d_%H.%M.%S%z').strftime("%Y-%m-%d %H:%M:%S%z") 
    file = s3.Object(bucket,filename)
    
    logger.info(f'Käsitellään tiedostoa {filename}.' )
    
    body = file.get()['Body'].read().decode('utf8')
    json_data = json.loads(body)
    
    
    source = filename.split('/')[1]

    host = os.environ.get('host')
    database = os.environ.get('database')
    user=os.environ.get('user')
    port=os.environ.get('port')
    
    client=boto3.client('rds')
    password = client.generate_db_auth_token(
            DBHostname=host, Port=port, DBUsername=user)
    
    ssl_context = ssl.create_default_context()
    ssl_context.verify_mode = ssl.CERT_REQUIRED
    ssl_context.load_verify_locations ('eu-west-1-bundle.pem')

    conn = pg8000.dbapi.connect(
        database=database, user=user, password=password, host=host, port=port
        ,ssl_context=ssl_context
    )


    cursor=conn.cursor()
    #with conn.cursor() as cursor:
    row=1
    now = datetime.datetime.now()
    query = F"""insert into raw.{raw_table} 
    (data, 
    dw_metadata_source_timestamp_at,
    dw_metadata_dbt_copied_at,
    dw_metadata_filename,
    dw_metadata_file_row_number
    ) values (%s,%s,%s,%s,%s);"""
        
    for d in json_data:
        data=json.dumps(d)
        cursor.execute (
            query,  
                (
                    data,
                    export_time,
                    now,
                    filename,
                    row)
       )
        row+=1
        if row % 2500 == 0:
            logger.info(f'Käsitellään riviä {row}, kesto {time.time() - start}' )
    conn.commit()
    conn.close()
    
    duration = time.time() - start
    logger.info(f'Lähde: {source}; rivien lukumäärä: {row}, ajon kesto: {duration}' )
    
    
    return {
        'statusCode': 200,
        'body': json.dumps(f'Lahde: {source}; rivien lukumaara: {row}, ajon kesto: {duration}' )
        
    }