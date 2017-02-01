#!/bin/bash

#******************************************************************************
#YOU CAN SET THIS OPTIONS IN THE DOCKER COMPOSE FILE OR USING ENVIROMENT OPTIONS
#******************************************************************************
if [[ "$ADMIN_EMAIL" == "" ]]; then
	echo "ADMIN EMAIL NOT SET, USING DEFAULT..."
	ADMIN_EMAIL="admin@paintomics.es"; #WILL BE USED FOR LOGIN AS ADMIN
fi

if [[ "$ADMIN_PASS" == "" ]]; then
	echo "ADMIN PASS NOT SET, USING DEFAULT..."
	ADMIN_PASS="40bd001563085fc35165329ea1ff5c5ecbdbbeef"; #PASSWORD CODIFIED IN SHA1
fi

if [[ "$ADMIN_AFFILIATION" == "" ]]; then
	echo "ADMIN AFFILIATION NOT SET, USING DEFAULT..."
	ADMIN_AFFILIATION="My awesome workplace"
fi
#DO NOT CHANGE THIS OPTIONS
ADMIN_USER="admin";
SETTINGS_FILE="/usr/local/apache2/htdocs/PaintomicsServer/src/conf/serverconf.py"
DATA_DIR="/data/paintomics3";
#DATA_HOST="http://bioinfo.cipf.es/paintomics"
DATA_HOST="http://172.17.0.1:8090"
#*********************************************************


#*********************************************************
#STEP 1. CREATE THE SETTINGS FOR PAINTOMICS IF NOT EXIST
#*********************************************************
if [ ! -f $SETTINGS_FILE ]; then
	echo "UNABLE TO FIND SETTINGS FOR PAINTOMICS, AUTOCREATING..."
	cp /usr/local/apache2/htdocs/PaintomicsServer/src/resources/example_serverconf.py $SETTINGS_FILE
	cp /usr/local/apache2/htdocs/PaintomicsServer/src/resources/logging.cfg /usr/local/apache2/htdocs/PaintomicsServer/src/conf/logging.cfg
	touch /usr/local/apache2/htdocs/PaintomicsServer/src/conf/__init__.py
fi


#*********************************************************
#STEP 2. CHECK IF THE PAINTOMICS DATABASES EXIST
#*********************************************************
mongo --host paintomics3-mongo <<EOF
function db_exists(db_name) {
    db = db.getSiblingDB('admin');
    db.runCommand('listDatabases').databases.forEach(function(db_entry){
        if (db_entry.name == db_name) {
            // quit with exit code zero if we found our db
            quit(0);
        }
    });

    // quit with exit code 1 if db was not found
    quit(1);
}
db_exists('PaintomicsDB');
EOF
exist=$?


#*********************************************************
#STEP 3. CREATE THE MAIN DATABASE IF NOT EXISTS
#*********************************************************
if [[ "$exist" == "1" ]]; then
	echo "UNABLE TO FIND PAINTOMICS DATABASE, AUTOCREATING..."
cat <<EOF > /tmp/mongo.js
use PaintomicsDB;
db.dropDatabase();
use PaintomicsDB;
db.createCollection("featuresCollection");
db.createCollection("jobInstanceCollection");
db.createCollection("pathwaysCollection");
db.createCollection("userCollection");
db.createCollection("fileCollection");
db.createCollection("messageCollection");
db.createCollection("counters");
db.userCollection.insert({userID:"0",userName:"${ADMIN_USER}",email:"${ADMIN_EMAIL}",password:"${ADMIN_PASS}", affiliation:"${ADMIN_AFFILIATION}", activated:"True"});
db.counters.insert({_id:"userID",sequence_value:1});
db.userCollection.ensureIndex( { userID : 1 } );
db.jobInstanceCollection.ensureIndex( { jobID: 1, userID : 1 } );
db.featuresCollection.ensureIndex( { jobID: 1, featureType: 1 } );
db.pathwaysCollection.ensureIndex( { jobID: 1, ID: 1 } );
db.visualOptionsCollection.ensureIndex( { jobID: 1 } );
db.fileCollection.ensureIndex( { userID: 1 } );
EOF
	mongo --host paintomics3-mongo < /tmp/mongo.js
	rm /tmp/mongo.js
fi


#*********************************************************
#STEP 4. CHECK IF THE DATABASES FRO DEFAULT SPECIES EXIST
#*********************************************************
mongo --host paintomics3-mongo <<EOF
function db_exists(db_name) {
    db = db.getSiblingDB('admin');
    db.runCommand('listDatabases').databases.forEach(function(db_entry){
        if (db_entry.name == db_name) {
            // quit with exit code zero if we found our db
            quit(0);
        }
    });

    // quit with exit code 1 if db was not found
    quit(1);
}
db_exists('global-paintomics');
EOF
exist=$?


#*********************************************************
#STEP 5. DOWNLOAD AND CREATE THE DEFAULT SPECIES DATABASE
#*********************************************************
if [[ "$exist" == "1" ]]; then #DATABASE NOT IN MONGO
	echo "UNABLE TO FIND PAINTOMICS DEFAULT SPECIES DATABASES"
	echo "DOWNLOADING DATA (THIS MAY TAKE FEW MINUTES)..."
	wget --quiet $DATA_HOST/paintomics-dbs.tar.gz --directory-prefix=/tmp/
	echo "EXTRACTING AND INSTALLING DATA... "
	tar -zxvf /tmp/paintomics-dbs.tar.gz -C /tmp/
	mv /tmp/paintomics-dbs/KEGG_DATA/ $DATA_DIR
	chown -R www-data:www-data $DATA_DIR/KEGG_DATA/
	mongorestore --host paintomics3-mongo  --db mmu-paintomics /tmp/paintomics-dbs/dump/mmu-paintomics/
	mongorestore --host paintomics3-mongo  --db global-paintomics /tmp/paintomics-dbs/dump/global-paintomics/
	rm -r  /tmp/paintomics-dbs
	rm -r  /tmp/paintomics-dbs.tar.gz
cat <<EOF > $DATA_DIR/KEGG_DATA/last/species/species.json
{"success": true, "species": [
        {"name": "Mus musculus (mouse)", "value": "mmu"}
]}
EOF
fi

if [ ! -d $DATA_DIR/CLIENT_TMP ]; then
	echo "UNABLE TO FIND CLIENTS DIRECTORY, AUTOCREATING..."
	mkdir $DATA_DIR/CLIENT_TMP
	mkdir $DATA_DIR/CLIENT_TMP/0
	mkdir $DATA_DIR/CLIENT_TMP/0/inputData
	mkdir $DATA_DIR/CLIENT_TMP/0/jobsData
	mkdir $DATA_DIR/CLIENT_TMP/0/tmp
	chown -R www-data:www-data $DATA_DIR/CLIENT_TMP/
fi


#*********************************************************
#STEP 6. LAUNCH SERVICES
#*********************************************************
# Apache gets grumpy about PID files pre-existing
rm -f /usr/local/apache2/logs/httpd.pid

#Fix problems with mounted volumes ownership
chown -R www-data:www-data /usr/local/apache2/htdocs/

#Launch apache
httpd -DFOREGROUND
