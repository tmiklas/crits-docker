FROM ubuntu:latest

MAINTAINER @tomaszmiklas

RUN apt-get -qq update
# git command
RUN apt-get install -y git
# pip command
RUN apt-get install -y python-pip
# lsb_release command
RUN apt-get install -y lsb-release 
# sudo command
RUN apt-get install -y sudo
# add-apt-repository command
RUN apt-get install -y software-properties-common

# Clone the repo
RUN git clone -b stable_4 --depth 1 https://github.com/crits/crits.git 

# Added by Tomasz Miklas <230130+tmiklas@users.noreply.github.com>:
# - Fix the broken build script - needed until PR is merged upstream
ADD bootstrap /crits/script/bootstrap

WORKDIR crits

# first fix broken m2crypto
RUN mv requirements.txt requirements.old && grep -v m2crypto requirements.old > requirements.txt && rm requirements.old

# Install the dependencies
RUN TERM=xterm sh ./script/bootstrap < docker_inputs

# Added by Tomasz Miklas <230130+tmiklas@users.noreply.github.com>:
# - roll back to older mongoengine release - as CRITS authors didn't pin module version, new release on mongoengine preaks the next step
#   patching Dockerfile because CRITS seems to have stopped merging PRs long time ago :-(
RUN pip install mongoengine==0.17.0
# switching to stable_4 branch requires newer pymongo, or it will fail with m2crypto - go figure
RUN pip install pymongo==3.0

# Create a new admin. Username: "admin" , Password: "pass1PASS123!"
#RUN sh contrib/mongo/mongod_start.sh && python manage.py users -R UberAdmin -u admin -p "pass1PASS123!" -s -i -a -e admin@crits.crits -f "first" -l "last" -o "no-org"
# this works ok with stable_4 branch - -R is no longer valid
RUN sh contrib/mongo/mongod_start.sh && python manage.py users -u admin -p "pass1PASS123!" -s -i -a -A -e admin@ctrits.crits -f Admin -l User -o none

EXPOSE 8080

CMD sh contrib/mongo/mongod_start.sh && python manage.py runserver 0.0.0.0:8080
