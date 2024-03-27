import json
import boto3 
import ijson
import psycopg2
import logging
import datetime
import time

def lambda_handler(event, context):
    bucket=event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    s3 = boto3.resource('s3')
    logger=logging.getLogger()
    logger.setLevel("INFO")
    
    start =time.time()

    # käyttöoikeudet: muokkaa
    host=
    database=
    user=
    password=
    port=

    conn = psycopg2.connect(
        database=database, user=user, password=password, host=host, port=port
    )
    
    filename = key.replace('%2B','+')
    raw_table = filename.split('__')[0].split('/')[-1]
    export_time = datetime.datetime.strptime(filename.split('__')[1], '%Y-%m-%d_%H.%M.%S%z').strftime("%Y-%m-%d %H:%M:%S%z") 
    file = s3.Object(bucket,filename)
    body = file.get()['Body'].read().decode('utf8')
    parser = ijson.items(body,'item',use_float=True)
    source = filename.split('/')[1]
    
    with conn.cursor() as cursor:
        row=1
        now = datetime.datetime.now()
        query = F"""insert into raw.{raw_table} 
        (data, 
        dw_metadata_source_timestamp_at,
        dw_metadata_dbt_copied_at,
        dw_metadata_filename,
        dw_metadata_file_row_number
        ) values (%s,%s,%s,%s,%s);"""
        
        for d in parser:
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
        conn.commit()
    
    duration = time.time() - start
    logger.info(f'Lähde: {source}; rivien lukumäärä: {row}, ajon kesto: {duration}' )
    
    
    return {
        'statusCode': 200,
        'body': json.dumps('OK')
        
    }