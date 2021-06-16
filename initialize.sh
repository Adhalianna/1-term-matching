#!/bin/sh

echo "---"
echo "INSTALLING DEPENDECIES..."
echo "---"

pip install wikipedia
pip install psycopg2-binary
pip install pdftotext
pip install nltk

echo "---"
echo "PROCEEDING TO CREATE A NEW DATABASE..."
echo "---"

./setup/database.sh

echo "---"
echo "DOWNLOADING THE DATA..."
echo "---"

echo "The scripts that generate dictionaries work as a kind of web crawlers. They can be terminated any time resulting in a smaller dictionary"

./benchmarks/data_sets/prepare_dataset1
./benchmarks/data_sets/prepare_dataset2

echo "---"
echo "PERFORMING THE BENCHMARKS..."
echo "---"

./benchmarks/test_sets/set1.sh wiki_alpha BNW 0
./benchmarks/test_sets/set2.sh wiki_alpha BNW 0
./benchmarks/test_sets/set3.sh wiki_alpha BNW 0
./benchmarks/test_sets/set4.sh wiki_alpha BNW 0

./benchmarks/test_sets/set1.sh wiki_cogn Relativity 1
./benchmarks/test_sets/set2.sh wiki_cogn Relativity 1
./benchmarks/test_sets/set3.sh wiki_cogn Relativity 1
./benchmarks/test_sets/set4.sh wiki_cogn Relativity 1

echo "---"
echo "FINISHED"
echo "---"