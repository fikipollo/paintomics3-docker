#!/bin/bash

file="/usr/local/apache2/htdocs/src/conf/serverconf.py"
ADMIN_USER="admin";
ADMIN_EMAIL="admin@paintomics.es"; #WILL BE USED FOR LOGIN AS ADMIN
ADMIN_PASS="40bd001563085fc35165329ea1ff5c5ecbdbbeef"; #PASSWORD CODIFIED IN SHA1
ADMIN_AFFILIATION="ADMIN"
DATA_DIR="/data";

if [ ! -f "$file" ]; then
	cp /usr/local/apache2/htdocs/src/resources/example_serverconf.py /usr/local/apache2/htdocs/src/conf/serverconf.py
	cp /usr/local/apache2/htdocs/src/resources/logging.cfg /usr/local/apache2/htdocs/src/conf/logging.cfg
	touch /usr/local/apache2/htdocs/src/conf/logging.cfg
fi

if [[ 1 == 1 ]]; then #nOT DATABASES IN MONGO
	#*********************************************************
	#INITIALIZE MONGO DB
	#*********************************************************
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
	db.createCollection("counters")
	db.userCollection.insert({userID:"0",userName:"${ADMIN_USER}",email:"${ADMIN_EMAIL}",password:"${ADMIN_PASS}", affiliation:"${ADMIN_AFFILIATION}", activated:"True"})
	db.counters.insert({_id:"userID",sequence_value:1})

	db.userCollection.ensureIndex( { userID : 1 } )
	db.jobInstanceCollection.ensureIndex( { jobID: 1, userID : 1 } )
	db.featuresCollection.ensureIndex( { jobID: 1, featureType: 1 } )
	db.pathwaysCollection.ensureIndex( { jobID: 1, ID: 1 } )
	db.visualOptionsCollection.ensureIndex( { jobID: 1 } )
	db.fileCollection.ensureIndex( { userID: 1 } )

EOF

	mongo --host paintomics3-mongo < /tmp/mongo.js
	rm /tmp/mongo.js

	wget http://bioinfo.cipf.es/paintomics/paintomics-dbs.tar.gz --directory-prefix=/tmp/
	tar -zxvf /tmp/paintomics-dbs.tar.gz -C /tmp/

	mv /tmp/paintomics-dbs/KEGG_DATA/ $DATA_DIR
	mongorestore --host paintomics3-mongo  --db mmu-paintomics /tmp/paintomics-dbs/dump/mmu-paintomics/
	mongorestore --host paintomics3-mongo  --db global-paintomics /tmp/paintomics-dbs/dump/global-paintomics/
	rm -r  /tmp/paintomics-dbs
	rm -r  /tmp/paintomics-dbs.tar.gz

fi

if [ ! -d "$DATA_DIR/CLIENT_TMP" ]; then
	mkdir $DATA_DIR/CLIENT_TMP
	mkdir $DATA_DIR/CLIENT_TMP/0
	mkdir $DATA_DIR/CLIENT_TMP/0/inputData
	mkdir $DATA_DIR/CLIENT_TMP/0/jobsData
	mkdir $DATA_DIR/CLIENT_TMP/0/tmp
fi

# Apache gets grumpy about PID files pre-existing
rm -f /usr/local/apache2/logs/httpd.pid

#Fix problems with mounted volumes ownership
chown -R www-data:www-data /usr/local/apache2/htdocs/

#Launch apache
httpd -DFOREGROUND
