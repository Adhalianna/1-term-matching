#!/bin/sh

cd $(dirname $0)

echo "The initialization script will create a new Postgres database and a new user. It requires sudoers rights to be able to act as a postgres user on the system."
read -r -p "Do you wish to proceed? [Y/n]" input

# Do you?
case $input in
    [yY][eE][sS]|[yY])
        ;;
    [nN][oO]|[nN])
        exit
        ;;
    *)
        echo "Invalid input..."
        exit 1
        ;;
esac

# NOTE:
# In case of Manjaro, after downloading all postgres packages to install the server run:
# sudo su postgres -l
# initdb --locale $LANG -E UTF8 -D '/var/lib/postgres/data/'
# exit
# sudo systemctl start postgresql
# sudo systemctl enable postgresql


# Creating a database in Postgres
sudo su - postgres -c "psql -c \"CREATE DATABASE term_matching_db\""
# There is no point in checking for errors at this step. Exit code is
# always '1' on those which is unhelpful. Errors might arise when the
# script is run once more resulting in attempt to introduce duplicate
# data. So, just ignore. 

# Adding the user to the database
sudo su - postgres -c "psql -c \"CREATE USER term_matcher WITH PASSWORD 'term_matcher'\""

# Granting permissions to the new user
sudo su - postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE term_matching_db TO term_matcher\""

# Testing access
psql -d term_matching_db -U term_matcher -c "\q"
exitcode=$?

if [ $exitcode -eq 0 ]; then
    echo "The process was successful! A new user is ready to work!"
    echo "Loading database schemas..."
else 
    echo "Unexpected error has occured. Quitting."
    exit 1
fi


alias sql="psql -d term_matching_db -U term_matcher -c" #a bit of simplification
#cd setup #move to correct directory

# Now, just load the database.sql file
sql "\ir database.sql"
