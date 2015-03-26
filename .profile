
# elastic beanstalk
export PATH=$PATH:/Users/ahulce/AWS-ElasticBeanstalk-CLI-2.6.3/eb/macosx/python2.7

# MacPorts Installer addition on 2012-02-29_at_15:43:38: adding an appropriate PATH variable for use with MacPorts.
#export PATH=/opt/local/bin:/opt/local/sbin:/usr/local/share/npm/bin:$PATH
# 20150307 - Uninstalled homebrew's installation of npm and installed it next to node in /usr/local/bin/
# This means 2 of the dirs above are now empty. @todo: See if I can remove MacPorts altogether
export PATH=/opt/local/bin:$PATH
# Finished adapting your PATH environment variable for use with MacPorts.

#pcre
export PATH=/usr/local/pcre/bin:$PATH

#gitawareprompt
export GITAWAREPROMPT=~/.bash/git-aware-prompt
source $GITAWAREPROMPT/main.sh
export PS1="\u@\h \w \[$txtcyn\]\$git_branch\[$txtred\]\$git_dirty\[$txtrst\]\$ "
#end gitawareprompt

# stop merge message prompt
export GIT_MERGE_AUTOEDIT=no

# mysql
export PATH=/usr/local/mysql/bin:$PATH

# lein
export PATH=~/bin:$PATH

#alias smile="curl http://smiley.meatcub.es:1337"
smile(){
	if [ ! -d /tmp/node_modules/cool-ascii-faces ]; then
		npm install --prefix /tmp cool-ascii-faces > /dev/null
	fi
	node /tmp/node_modules/cool-ascii-faces/cli.js
}

echocute(){
	echo $1
	eval "$1"
}

poo(){
	currentBranch=`git branch | grep '*' | head -n1 | sed -n 's/^\* //p'`
	msg="$@"
	if [ "$msg" == "" ]; then
		msg=`smile`
	fi
	git add --all .
	git commit -a -m "$msg"
	git pull origin $currentBranch
	git push origin $currentBranch
}

pop(){
	git fetch
	git checkout prod
	git pull origin prod
	git merge master && git push origin prod && git checkout master
}

mastit(){
	currentBranch=`git branch | grep '*' | head -n1 | sed -n 's/^\* //p'`
	echo "current branch: $currentBranch"
	echocute 'git checkout master'
	echocute 'git fetch'
	echocute 'git pull origin master'
	echocute "git checkout $currentBranch"
	echocute "git merge master && git push origin $currentBranch"
}

bitch() {
	if [[ $1 -eq "please" ]]; then
		eval "sudo $(fc -ln -1)"
	else
		sudo "$@"
	fi
}

gropen2() {
	# old way, waits till the end
	_IFS=$IFS
	IFS=$'\n'
	g=`grep -l "$@"`
	for file in $g; do
		open $file
	done
	IFS=$_IFS
}

gropen() {
	app='/Applications/Sublime Text 2.app'
	grep -l --line-buffered "$@" | xargs -n1 open -a"$app"
}

fsh() {
	ip=$1
	user=$2
	if [ "$user" == "" ]; then
		user='ec2-user'
	fi
	if [ "$ip" == "" ]; then
		echo "please supply an ip"
	else
		ssh -i/Users/ahulce/.ssh/fabfitfun2.pem -oStrictHostKeyChecking=no $user@"$ip"
	fi
}

myec2() {
	ip=`cat /etc/hosts | grep myec2 | head -n1 | awk '{print $1}'`
	if [ "$ip" == "" ]; then
		echo "requires 'myec2' entry in /etc/hosts"
	else
		echocute "ssh -t $@ ubuntu@$ip 'sudo -i'"
		#c='cd /root/sire'
		#c="cd /var/www"
		#ssh -t ubuntu@$ip "sudo -i su -c '$c; /bin/bash'"
	fi
}

shudo() {
	# shudo ec2-107-20-26-208.compute-1.amazonaws.com
	s='2>/dev/null'
	c="cd /var/www && cd api_internal $s || cd platform-v2 $s || cd wordpress $s && cd current"
	ssh -t ubuntu@$1 "sudo -i su -c '$c; /bin/bash'"
}

shudi() {
	echocute "ssh -t ubuntu@$1 'sudo -i'"
}

topen() {
	if [ "$1" != "" ]; then
		app='/Applications/Sublime Text 2.app'
		mkdir -p `dirname "$1"`
		touch $1
		open -a"$app" $1
	fi
}

if [ "`which realpath`" == "" ]; then
	realpath() {
		if [ ! -f "$1" ] && [ ! -d "$1" ]; then
			>&2 echo 'path does not exist'
		else
			dir=`dirname "$1"`
			path=`cd "${dir}";pwd`
			if [ -f "$1" ]; then
				path=$path/`basename "$1"`
			fi
			echo $path
		fi
	}
fi


# zat (app maker for zendesk) doesnt like echoes in .profile
#echo "yay profile"
