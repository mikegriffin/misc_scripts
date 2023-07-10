from sys import exit
import MySQLdb

db = MySQLdb.connect(host='localhost',user='root',passwd='s4kila',db='information_schema')
cursor = db.cursor()

def run_query(db, query):
    cursor.execute(query)
    return cursor.fetchall()

def gen_health_command(db):
    try:
        query = "select substring_index(@@version_comment,' ', 1)"
        result = run_query(db, query)
        if result[0][0].find("MySQL") != -1 or result[0][0].find("Percona") != -1:
            query = "select substring_index(@@version,'.', 1)"
            result = run_query(db, query)
            if int(result[0][0]) >= 8:
                return "rs"
            else:
                return "ss"
        else:
            if result[0][0].find("MariaDB") != -1:
                return "ss"
            else:
                print("server version detection failed")
                exit(-1)
    except:
        print("gen_health_command failed")
        exit(-1)

def get_replication_delay(db):
    try:
        if health_command == "ss":
            query = "SHOW SLAVE STATUS"
        else:
            if health_command == "rs":
                query = "SHOW REPLICA STATUS"
            else:
                print("health command invalid")
                exit(-1)
        result = run_query(db, query)
        for idx, tup in enumerate(cursor.description):
            if tup[0] == "Replica_IO_Running" or tup[0] == "Slave_IO_Running":
                if result[0][idx] != "Yes":
                    print(tup[0], result[0][idx])
                    exit(-1)
            if tup[0] == "Replica_SQL_Running" or tup[0] == "Slave_SQL_Running":
                if result[0][idx] != "Yes":
                    print(tup[0], result[0][idx])
                    exit(-1)
            if tup[0] == "Seconds_Behind_Source" or tup[0] == "Seconds_Behind_Master":
                lag = result[0][idx]
            if tup[0] == "SQL_Delay":
                sql_delay = result[0][idx]
            if tup[0] == "SQL_Remaining_Delay":
                if result[0][idx] == "NULL":
                    sql_remaining_delay=0
                else:
                    sql_remaining_delay = result[0][idx]
            if tup[0] == "Replica_SQL_Running_State" or tup[0] == "Slave_SQL_Running_State":
                running_state = result[0][idx]
        if sql_delay > 0:
            if running_state.find("DELAY") != -1:
                print(0)
            else:
                if lag-sql_delay <= 0:
                    print(0)
                else:
                    print(lag-sql_delay)
        else:
            print(lag)
    except:
        print("get_replication_delay failed")
        exit(-1)


health_command = gen_health_command(db)
get_replication_delay(db)
cursor.close()
db.close()
