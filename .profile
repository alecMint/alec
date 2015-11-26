if [ -f ~/.secrets ]; then
	. ~/.secrets
fi

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

# php
export PATH=/usr/local/php5/bin:$PATH

# mysql
export PATH=/usr/local/mysql/bin:$PATH

# lein
#export PATH=~/bin:$PATH

### Added by the Heroku Toolbelt
#export PATH="/usr/local/heroku/bin:$PATH"

if [ -d /usr/local/phpunit-git-deploy/bin ]; then export PATH=/usr/local/phpunit-git-deploy/bin:$PATH; fi

# increase max-files-open
ulimit -Sn 2048
#ulimit -S -u 1024 # <-- careful with this one


# for: grep, topen, etc
DEFAULT_TEXT_APP='/Applications/Sublime Text 2.app'
DEFAULT_WEB_APP='/Applications/Google Chrome.app'

saveprofile()(
	src='/Users/ahulce/.profile'
	dest='/Users/ahulce/Dropbox/alec_repo/.profile'
	ls -lh "$dest"
	cp "$src" "$dest"
	ls -lh "$dest"
)

pmo()(
	# @todo: if input is git commit, parse out pivotal ticket number
	# positiveInt='^[1-9][0-9]*$'; if ! [[ "$1" =~ $positiveInt ]]; then ...
	tid=$1
	if [ "${tid:0:1}" == '#' ]; then
		tid=${tid:1}
	fi
	open -a"$DEFAULT_WEB_APP" "https://www.pivotaltracker.com/story/show/$tid"
)

opem()(
	# cuz i suck at typing
	open $@
)

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

poo()(
	# Push changes to current branch
	# poo optional message
	#
	currentBranch=`git branch | grep '*' | head -n1 | sed -n 's/^\* //p'`
	msg="$@"
	if [ "$msg" == "" ]; then msg=`smile`; fi
	git add --all .
	git commit -a -m "$msg"
	git pull origin $currentBranch #|| exit 1 # commented out so we can push new branches at the cost of missing potential merge conflict
	git push origin $currentBranch
)

pop()(
	# Merge master into prod and push prod up
	#
	git fetch
	git checkout prod
	git pull origin prod
	git merge master && git push origin prod && git checkout master
)

mastit()(
	# Sync current branch with origin master
	#
	currentBranch=$1
	if [ "$currentBranch" == "" ]; then
		currentBranch=`git branch | grep '*' | head -n1 | sed -n 's/^\* //p'`
	fi
	echo "current branch: $currentBranch"
	git checkout master || exit 1
	git fetch
	git pull origin master || exit 1
	(git checkout $currentBranch && git merge master && git push origin $currentBranch) || exit 1
	echo 'git diff master...'
	git --no-pager diff master
)

mastif()(
	# Sync local branch with origin. Defaults to master
	# mastif patch-brownies
	#
	branch=$1
	if [ "$branch" == "" ]; then
		branch='master'
	fi
	echocute "git fetch && git checkout $branch && git pull origin $branch && git fetch --tags"
)

gcp()(
	git fetch
	git cherry-pick $1
)

gco()(
	branch=$1
	if [ ! "$branch" ]; then
		branch=`git branch | grep '*' | head -n1 | sed -n 's/^\* //p'`
		if [ "`echo '$branch' | grep 'detached from'`" ]; then
			branch=`git describe --tags`
		fi
	fi
	git fetch && git fetch --tags && git checkout "$branch" && git pull origin "$branch"
)

glc(){
	if [ `which pbcopy` ]; then
		git log $1 | head -n1 | awk '{print $2}' | pbcopy
	fi
	git log $1 | head -n5
}

gbb()(
	git checkout -
)

gbd()(
	# Delete a branch if the last commit is in master
	# gbd patch-sql-updates
	#
	branch=$1
	if [ ! "$branch" ]; then
		>&2 echo 'branch required' 
		exit 1
	fi
	lastCommitIsInMaster=`git log master | grep \`git log "$branch" | head -n1 | awk '{print $2}'\``
	if [ "$lastCommitIsInMaster" ]; then
		# delete branch
		echo "deleting $branch"
		git branch -D "$branch"
	fi
)

bitch() {
	if [[ $1 -eq "please" ]]; then
		eval "sudo $(fc -ln -1)"
	else
		sudo "$@"
	fi
}

grepl() ( # <- for ulimit + local vars
	# grep the last N lines of file, defaults to last 10 lines
	# grepl -R '?>' ./
	# grepl -1 -R '?>' ./
	# grepl -3 -R '?>' ./ | xargs topen
	#
	searchIn=./
	searchLast=10
	for arg in "$@"; do
		if [ $arg == '-r' -o $arg == '-R' ]; then recursive='-r'
		elif [[ "$arg" =~ ^-[0-9]+$ ]]; then searchLast=`echo "$arg" | sed "s/^-//"`
		elif [ ! "$search" ]; then search=$arg
		elif [ ! "$searchIn" ]; then searchIn=$arg
		else args="$args $arg"; fi
	done
	if [ ! "$search" ]; then
		>&2 echo "please provide a search value"
	else
		ulimit -n 5000
		grep -lI $recursive "$search" "$searchIn" 2>/dev/null | xargs tail -$searchLast | grep -B$searchLast "$search" | grep '==> .* <==' | sed 's/==> \(.*\) <==/\1/'
	fi
)

gropen()(
	# Stream open files matched with grep
	# gropen -R 'interesting text' ./
	# @todo: make this work for any list of files, e.g. git diff --name-only 20150821za_release..20150923m_release app/database/
	#
	if [ "$1" == "" ]; then
		# we just grepped but really wish we had gropened instead...
		prevCmd="$(fc -ln -1)"
		if [ "`echo \"$prevCmd\" | grep '|'`" ]; then
			cmd=`echo "$prevCmd" | sed -n 's/grep/gropenList/p'`
		else
			cmd=`echo "$prevCmd" | sed -n 's/grep/gropen/p'`
		fi
		eval "$cmd"
	else
		grep -l --line-buffered "$@" | xargs -n1 open -a"$DEFAULT_TEXT_APP"
	fi
)

gropenList(){
	# For use by gropen() if passing a stream of path strings instead of grepping files
	# The same except for no '-l' option
	#
	grep --line-buffered "$@" | xargs -n1 open -a"$DEFAULT_TEXT_APP"
}

gropen2() {
	# old way, waits till the end before opening
	#
	_IFS=$IFS
	IFS=$'\n'
	g=`grep -l "$@"`
	for file in $g; do
		open $file
	done
	IFS=$_IFS
}

fsh()(
	# Ssh with pem file
	#
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
)

myec2()(
	# Ssh to primary instance. Instance set in hosts file: myec2 123.123.123.123
	#
	ip=`cat /etc/hosts | grep myec2 | head -n1 | awk '{print $1}'`
	if [ "$ip" == "" ]; then
		echo "requires 'myec2' entry in /etc/hosts"
	else
		echocute "ssh -t $@ ubuntu@$ip 'sudo -i'"
		#c='cd /root/sire'
		#c="cd /var/www"
		#ssh -t ubuntu@$ip "sudo -i su -c '$c; /bin/bash'"
	fi
)

get_current_tag()(
	url=$1/id
	cnf=`curl -sS "$url"`
	echo $cnf | sed -n 's/.*"tag":"\([^"]*\).*/\1/p'
)

name_to_ip()(
	d=$1
	if [ "$d" == "-s" ]; then d=$2; fi
	if [ "$d" == "dev1" ]; then d=54.164.7.90
	elif [ "$d" == "dev2" ]; then d=52.4.9.222
	elif [ "$d" == "dev3" ]; then d=54.172.115.236 # old: d=54.165.251.139
	elif [ "$d" == "dev4" ]; then d=54.175.47.224
	elif [ "$d" == "uat" ]; then d=54.84.201.95 # old: d=54.152.199.226
	elif [ "$d" == "stage" -o "$d" == "stage-prod" ]; then d=52.23.225.118 # old: 54.172.164.179
	elif [ "$d" == "qa" ]; then d=52.23.156.43 # old: d=54.152.18.15
	elif [ "$d" == "prod" ]; then d=54.67.7.34
	elif [ "$d" == "scripts" ]; then d=54.183.79.4
	elif [ "$d" == "scripts-old" ]; then d=50.18.217.82
	fi
	echo $d
)

shudo()(
	# Same as: ssh ubuntu@instance, sudo -i, cd to web directory
	# shudo ec2-107-20-26-208.compute-1.amazonaws.com
	#
	d=$1
	if [ "$1" == "-s" -o "$1" == "-u" ]; then d=$2; fi
	s='2>/dev/null'
	c="cd /var/www && cd wagapi $s || cd api_internal $s || cd platform-v2 $s || cd wordpress $s || cd lucky-forwarder $s || cd lucky-bak $s && cd current $s"
	#t="sudo -i su -c '$c; /bin/bash'"
	t='sudo -i' # su -c no longer allows interactive shells, which is annoying when ctrl+c destroys your connection. instead, push your cd command to /root/.bashrc
	if [ "$1" == "-u" ]; then t="$c; /bin/bash"; fi
	
	d=`name_to_ip "$d"`
	echo "$d"
	if [ "$1" != "-s" ] && [ "$2" != "-s" ]; then
		ssh -t ubuntu@$d $t
	fi
)

shtag_head()(
	# Create tag off HEAD and push to env
	# @todo: If tag has already been cut (i.e. last tag == HEAD), then just push it to env
	# shtag_head qa
	#
	# git tag -d 20150821g_release && git push origin :refs/tags/20150821g_release
	#
	env=`name_to_ip $1`
	currentTag=`get_current_tag $env`
	letter=`echo $currentTag | sed 's/[0-9]*\([a-z]\).*/\1/'`
	if [ ! "$letter" ] || [ "$letter" == 'z' ]; then
		>&2 echo "unable to create next tag; letter: $letter" # @todo: continue on past z
		exit 1
	fi
	abc=(a b c d e f g h i j k l m n o p q r s t u v w x y z)
	i=0
	for l in ${abc[@]}; do
			i=$[i+1]
			if [ $letter == $l ]; then break; fi
	done
	nextLetter=${abc[$i]}
	nextTag=`echo $currentTag | sed "s/$letter/$nextLetter/"`
	git tag $nextTag || exit 1
	git push --tags || exit 1
	gitDir=/var/www/html/wag_api # different from prod so we dont accidentally push to live
	remoteCnf="--git-dir=$gitDir/.git --work-tree=$gitDir"
	ssh ubuntu@$env "git $remoteCnf fetch --tags && git $remoteCnf checkout $nextTag" || exit 1
	echo "pushed $nextTag to $env"
)

shelease()(
	# Deploy a tag to multiple instances
	# shelease v0.3.152_release-fbs-dev ec2-54-82-41-81.compute-1.amazonaws.com ec2-54-147-31-5.compute-1.amazonaws.com
	#
	commit=$1
	s='2>/dev/null'
	c="cd /var/www || exit; cd api_internal $s || cd platform-v2 $s || cd wordpress $s || exit; cd current || exit"
	r="git fetch && git fetch --tags && git checkout $commit"
	dir=`pwd`
	if [ "`basename $dir`" == "platform-v2-lucky" ]; then
		r="$r && restart platform-v2 && sleep 1 && /etc/init.d/varnish restart"
	fi
	for arg in "$@"; do
		if [ $arg == "$commit" ]; then continue; fi
		echo $arg
		ssh -t ubuntu@$arg "sudo -i su -c '$c; $r'"
	done
)

topen()(
	# Open a file for editing, creating it if not exists
	# topen dir/that/not/exist/newfile.txt
	#
	if [ "$2" ]; then
		for arg in "$@"; do
			topen "$arg"
		done
		exit
	fi
	if [ "$1" ]; then
		mkdir -p `dirname "$1"`
		touch "$1"
		open -a"$DEFAULT_TEXT_APP" "$1"
	fi
)

wopen()(
	# Open a file in your default web browser
	# wopen dir/that/not/exist/webpage.html
	#
	open -a"$DEFAULT_WEB_APP" "$1"
)

bopen() {
	# Open a file in your browser and text editor
	# Useful if your default application for an .html or .php is your text editor but you want to open it in your browser as well to view
	#
	topen "$1"
	wopen "$1"
}

authme()(
	# Give yourself root access
	# authme ec2-54-159-48-203.compute-1.amazonaws.com
	#
	#ubuntuAuthKey=/Users/ahulce/.ssh/mac.pem
	ubuntuAuthKey=/Users/ahulce/.ssh/wag-api-test.pem
	serverName=`name_to_ip $1`
	if [ "$1" == "prod" -o "$1" == "scripts" -o "$1" == "scripts-old" ]; then
		ubuntuAuthKey=/Users/ahulce/.ssh/wagprod2.pem
	fi
	pubKey=`cat ~/.ssh/id_rsa.pub | sed -n 's/\(.*\) .*$/\1/p'`
	if [ "`ssh -oStrictHostKeyChecking=no ubuntu@$serverName 'echo "ok"'`" != "ok" ]; then
		echo "pushing pubKey for ubuntu..."
		ssh -i$ubuntuAuthKey ubuntu@$serverName "echo '$pubKey' >> ~/.ssh/authorized_keys"
	elif [ "`ssh -oStrictHostKeyChecking=no root@$serverName 'echo "ok"'`" != "ok" ]; then
		echo "pushing pubKey for root..."
		ssh ubuntu@$serverName "echo '$pubKey' | sudo tee -a /root/.ssh/authorized_keys > /dev/null"
	else
		echo "already authed"
	fi
)

shep()(
	# Copy local file to remote
	# Set remote: shep set ec2-54-159-58-209.compute-1.amazonaws.com
	# Copy file: shep docroot/lucky/wp-content/test.txt
	#
	remotePrefix=/var/www/
	sourceFile=`realpath "$1" 2>/dev/null`
	path=$sourceFile
	mem=/tmp/shep_addr
	remoteAppName=
	remotePath=
	addr=`cat "$mem" 2>/dev/null`
	if [ "$1" == "set" ]; then
		echo "$2" > "$mem"
	elif [ "$1" == "get" ] || [ "$1" == "" ]; then
		echo "$addr"
	elif [ "$addr" == "" ]; then
		echo "use shep set <addr> to set a remote address"
	elif [ "$1" == "-a" ]; then
		echo "shepping all modified files..."
		files=`git ls-files -m`
		for file in $files; do
			if [ "$file" != "-a" ]; then # avoid recursion
				echo "$file..."
				shep "$file"
			fi
		done
	else
		while [ "$path" != "" ] && [ "$path" != "/" ]; do
			dir=`basename "$path"`
			if [ "$dir" == "lucky_wordpress" ]; then
				remoteAppName='wordpress'
			elif [ "$dir" == "magento19_api" ]; then
				remoteAppName='api_internal'
			elif [ "$dir" == "magento19" ]; then
				remoteAppName='magento'
			fi
			if [ "$remoteAppName" != "" ]; then
				remotePath=`echo "$sourceFile" | sed -n "s/.*\/$dir\(.*\)\$/$remoteAppName\/current\1/p"`
				#echo "scp \"$sourceFile\" \"root@$addr:$remotePrefix$remotePath\""
				r=`scp "$sourceFile" "root@$addr:$remotePrefix$remotePath" 2>&1`
				#echo "$r"
				r=`echo "$r" | grep 'Permission denied (publickey)'`
				if [ "$r" != "" ]; then
					echo "$r"
					echo "authorizing..."
					authme $addr
					echo "retrying..."
					sleep 1
					shep $@
				fi
				break
			fi
			path=`dirname "$path"`
		done
	fi
)

shrestart()(
	# Restart Pv3 instance from local
	# shrestart ec2-54-145-59-103.compute-1.amazonaws.com
	# shrestart ec2-54-145-59-103.compute-1.amazonaws.com -c v0.3.232_release-1
	#
	instance=$1
	args=
	skipFirst=1
	mem=/tmp/shrestart_addr
	for arg in "$@"; do
		if [ $skipFirst == 0 ]; then
			if [ "$args" == "" ]; then args=$arg; else args=$args" $arg"; fi
		else
			((skipFirst--))
		fi
	done
	if [ "$instance" == "" ]; then
		args=`cat "$mem" 2>/dev/null`
		if [ "$args" != "" ]; then
			echo "no addr supplied, using previous: shrestart $args"
			shrestart $args
		else
			echo "no addr supplied"
		fi
	else
		exec 5>&1
		r=`ssh root@$instance "cd /var/www/platform-v2/current && /bin/bash ./restart.sh $args" 2>&1 | tee /dev/fd/5`
		r=`echo "$r" | grep 'Permission denied (publickey)'`
		if [ "$r" != "" ]; then
			echo "authorizing..."
			authme $instance
			echo "retrying..."
			sleep 1
			shrestart $@
		fi
		echo "$@" > "$mem"
	fi
)

tardir()(
	# Tar+Zip contents of large directory
	# tardir path/to/dir path/to/archive
	#
	# Omit second argument to target cwd
	# tardir path/to/dir
	#
	source=$1
	target=$2
	if [ "$1" == '-x' ]; then
		source=$2
		target=$3
		untardir "$2" "$3"
		exit
	fi
	if [ ! "$target" ]; then target=`pwd`/`basename "$source"`.tar.gz; # tardir /tmp
	elif [ -d "$target" ]; then target=`cd "$target";pwd`/`basename "$source"`.tar.gz; # tardir /tmp ../
	fi

	curdir=`pwd`
	cd "$source"
	includeFile=`mktemp -t tartmp.XXXXXX`
	find . -type f > "$includeFile"

	tar -T "$includeFile" -zcf "$target"

	rm "$includeFile"
	cd "$curdir"
)

untardir()(
	# Untar+unzip archive
	# tardir path/to/archive.tar.gz path/to/target/dir
	#
	# Omit second argument to target cwd
	# untardir path/to/archive.tar.gz
	#
	source=$1
	target=$2
	if [ ! "$target" ]; then target=./; fi

	tar -zxf "$source" -C "$target"
)

mysqlc()(
	mysql -h127.0.0.1 -proot -uroot --port=8889 wagapi -A
)

mysqlq()(
	# mysqlq 'show create table owner' | grep app_version
	# @todo: convert '\n' to newline - currently not working
	# @todo: update config.sh to set and reset pwd
	#
	#. ~/Dropbox/wag/wagapi/config.sh
	cd ~/Dropbox/wag/wagapi
	. ./config.sh
	if [ "$mysqlPort" ]; then port=" --port=$mysqlPort"; fi
	#echo "$@" | mysql -h$mysqlHost $port -u$mysqlUser -p$mysqlPass $mysqlDb -A
	#echo "$@" | mysql -h$mysqlHost $port -u$mysqlUser -p$mysqlPass $mysqlDb -A | tr '\\\n' $'\n'
	echo "$@" | mysql -h$mysqlHost $port -u$mysqlUser -p$mysqlPass $mysqlDb -A | tr '\\\n' $'\n'
)

escape_bash_val()(
	# echo '$wef="w\$ef"' | sed 's/\(["$\]\)/\\\1/g'
	echo "$1" | sed 's/\(["$\]\)/\\\1/g'
)

pushbash()(
	# Push DEV.bashrc to remote
	# pushbash stage-prod
	# pushbash dev1 dev2 dev3 uat qa stage-prod
	#
	localRc=/Users/ahulce/Dropbox/wag/chef-deploy/tools/files/DEV.bashrc
	remoteRc=/root/.bashrc
	if [ "$1" == "prod" -o "$1" == "scripts" ]; then
		localRc=/Users/ahulce/Dropbox/wag/chef-deploy/tools/files/PROD.bashrc
	fi

	if [ "$2" ]; then
		for arg in "$@"; do
			pushbash $arg
		done
		exit
	fi
	remote=`name_to_ip $1`
	tmp1=`mktemp -t pushbash.XXXXXX`
	tmp2=`mktemp -t pushbash.XXXXXX`
	scp "root@$remote:'$remoteRc'" "$tmp1"
	lineNum=`cat "$tmp1" | grep -n '# wag stuff' | head -n1 | sed 's/\([0-9]*\).*/\1/g'`
	if [ "$lineNum" ]; then
		head -n$((lineNum-2)) "$tmp1" > "$tmp2"
	else
		cat "$tmp1" > "$tmp2"
		echo $'\n\n' >> "$tmp2"
	fi
	ssh root@$remote "cp -n '$remoteRc' '$remoteRc.pushbash.bak'"
	ssh root@$remote "cp -n '$remoteRc' '/tmp/pushbash.$(date +%Y%m%d_%H%M%S).bak'"
	cat "$localRc" >> "$tmp2"
	scp "$tmp2" "root@$remote:'$remoteRc'"
	rm "$tmp1"
	rm "$tmp2"
	echo "pushed to $1"
)

if [ "`which realpath`" == "" ]; then
	realpath()(
		if [ ! -f "$1" ] && [ ! -d "$1" ]; then
			>&2 echo 'path does not exist'
		else
			dir=$1
			if [ -f "$1" ]; then
				dir=`dirname "$1"`
			fi
			path=`cd "${dir}";pwd`
			if [ -f "$1" ]; then
				path=$path/`basename "$1"`
			fi
			echo $path
		fi
	)
fi

gp()(
	if [ "$1" ]; then
		gitp_cwd=`pwd`
		cd "$1"
		time (mastif && git gc)
		cd "$gitp_cwd"
	else
		ls
	fi
)

if [ -f /tmp/start.sh ]; then
	./tmp/start.sh
fi

# zat (app maker for zendesk) doesnt like echoes in .profile
#echo "yay profile"
