import os
import subprocess
from threading import current_thread
from threading import get_ident
from threading import get_native_id
#import http.client
#import time, datetime
from concurrent.futures import ThreadPoolExecutor
#from base64 import b64encode


def process_file(filepath):
    thread = current_thread()
    print(f'Worker thread: name={thread.name}, idnet={get_ident()}, id={get_native_id()}')
	#print("TODO - ",filepath)
    #subprocess.run(["docker-compose exec broker1 kafka-topics --bootstrap-server broker1:9092 --topic test-topic --replication-factor 3 --partitions 3 --create --config min.insync.replicas=2"])
	#os.system("echo x"
    result = subprocess.run(["docker-compose", "exec", "broker1", "kafka-topics", "--bootstrap-server", "broker1:9092"], capture_output=True, text=True)
    print("Have {} bytes in stdout:\n{}".format(len(result.stdout), result.stdout))
        
	#, "--topic", "test-topic", "--replication-factor", "3", 
    #            "--partitions", "3", "--create", "--config min.insync.replicas=2"])
        #(["docker-compose exec broker1 kafka-topics --bootstrap-server broker1:9092 --topic test-topic --replication-factor 3 --partitions 3 --create --config min.insync.replicas=2"])
	#["ls", "-l"]
    
					
# initialise a Thread Pool (32 worker threads) for concurrent operations
#executor = concurrent.futures.ThreadPoolExecutor(max_workers=32)

# traverse the directory from a given root with os.walk(".")
#for x in range(1000):
	# task a single thread with the processing for that file
#	executor.submit(process_file(x))

    # create a thread pool
with ThreadPoolExecutor(32) as executor:
        # submit some tasks
        _ = executor.map(process_file, range(5))	


    # docker-compose exec broker1 kafka-topics --bootstrap-server broker1:9092 --topic test-topic --replication-factor 3 --partitions 3 --create --config min.insync.replicas=2