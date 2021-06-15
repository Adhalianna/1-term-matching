#!/bin/sh

echo "---"
echo "INSTALLING DEPENDECIES..."
echo "---"

pip install wikipedia
pip install psycopg2
pip install pdftotext

echo "---"
echo "PROCEEDING TO CREATE A NEW DATABASE..."
echo "---"

./setup/database.sh

echo "---"
echo "PERFORMING INITIAL BENCHMARKS..."
echo "---"

./benchmarks/data2/prepare_dataset2.sh
./benchmarks/data2/test*

echo "---"
echo "ANALYZING THE DATA..."
echo "---"

echo "\ir results/analyze.sql" | psql -d term_matching_db -U term_matcher

echo "---"
echo "FINISHED"
echo "---"