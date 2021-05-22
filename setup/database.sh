#!/bin/sh

echo "The script will now create a database in postgres and add a new user to your system that will be used to"\
" access the database. To achieve so 'sudo' will be invoked a couple of times. It is assumed that Postgres is"\
" already installed on the system. If the behaviour of the script seems suspicious or you wish to perform those"\
" steps manually choose 'No' right now, then open the script in a text editor and investigate on your own."
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

# Creating a new user: term_matcher
adduser --help &> /dev/null
exitcode=$?
if [ $exitcode -ne 0 ]; then
    echo "Command 'adduser' not found, using 'useradd'"
    sudo useradd term_matcher -M -p term_matcher
else
    sudo adduser term_matcher -M -p term_matcher
fi
exitcode=$?
case $exitcode in
    0)
        echo "Successfully created a user 'term_matcher' with a password 'term_matcher'"
        ;;
    9)
        ;;
    *)
        echo "Failed to create a user. Quitting."
        exit 1
        ;;
esac


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
cd setup #move to correct directory

# Now, just load the database.sql file
sql "\ir database.sql"

cd ..
echo "Remember to remove the term_matcher from your users on OS and Postgres when you no longer need it."
