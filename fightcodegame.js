
/*
	todo
		- make better movement pattern
			- benchmark jitter
		- dont fire if friendly is in path
		- can get stuck on wall
*/

var settings = {
	travelEachTick: 3
	,cannonRotateEachTick: 3
	,cloneRetreat: 150
	,standAndFire: 100
	//,onHitBurst: [-1,75]
	//,switchRotationOnScan: true
	//,jitter: { distance: 50 } ,cloneRetreat: 300
	,indecision: {
		stubborness: 1
		,humility: 2
		//,keepFiring: true
	}
}, undef
;


function Robot(robot) {
	var z = this;
	z.tick = 0;
	z.robots = {};
	z.timeouts = {};
	z.spawnClones(robot);
	z.enemySpotted = null;
}

Robot.prototype.onIdle = function(ev) {
	var z = this
	,robot = ev.robot
	,robotHq = z.registerRobot(robot)
	if (robotHq.enemyLocked) {
		robotHq.fire();
		if (!robotHq.stoppedToFire) {
			robotHq.stoppedToFire = true;
			robotHq.resetIndecision();
			var uid = robotHq.enemyLockedUid
			,resume = function(){
				robotHq.enemyLocked = null;
				robotHq.stoppedToFire = false;
				robotHq.stubbornTicks = 0;
			}
			z.setTimeout(function(){
				if (robotHq.enemyLockedUid != uid)
					return;
				resume();
			},settings.standAndFire);
			z.setTimeout(resume,settings.standAndFire*1.5);
		}
	} else if (z.enemySpotted && z.enemySpotted.by != robot.id) {
		z.aim(robot,z.enemySpotted);
		z.enemySpotted = null;
		robotHq.resetIndecision();
	} else {
		if (settings.jitter) {
			robot.move(settings.travelEachTick, robotHq.jitterDir);
			robotHq.jitterDistance = (robotHq.jitterDistance || 0) + settings.travelEachTick;
			if (robotHq.jitterDistance >= settings.jitter.distance) {
				robotHq.jitterDistance = 0;
				robotHq.jitterDir = robotHq.jitterDir == 1 ? -1 : 1;
			}
		} else {
			robot.ahead(settings.travelEachTick);
		}
		if (settings.indecision && typeof robotHq.stubbornTicks == 'number') {
			if (robotHq.stubbornTicks > settings.indecision.stubborness) {
				robotHq.pie = robotHq.pie ? robotHq.pie+1 : 1;
				if (robotHq.pie <= settings.indecision.humility) {
					robotHq.stubbornTicks = 0;
					z.switchCannonRotation(robot);
					//robot.log('('+robot.id+') indecision switch '+robotHq.pie+' '+z.rand(robot,1,1000));
				} else {
					robotHq.resetIndecision();
					//robot.log('('+robot.id+') indecision done switching'+' '+z.rand(robot,1,1000));
				}
			}
			if (settings.indecision.keepFiring)
				robotHq.fire();
		}
		robot.rotateCannon(settings.cannonRotateEachTick*robotHq.rotateCannonDir);
	}
	if (z.isClone(robot) && !robotHq.cloneRetreated) {
		robot.stop();
		robot.back(150);
		robot.turn(90);
		robotHq.cloneRetreated = true;
	}
	z.checkTimeouts(robot);
	++z.tick;
	if (typeof robotHq.stubbornTicks == 'number')
		++robotHq.stubbornTicks;
}

Robot.prototype.onRobotCollision = function(ev) {
	if (this.isAlly(ev.robot,ev.collidedRobot)) {
		ev.robot.back(75);
	} else {
		this.foundEnemy(ev.robot,ev.collidedRobot);
		this.aim(ev.robot,ev.collidedRobot.position);
	}
}

Robot.prototype.onWallCollision = function(ev) {
	var robot = ev.robot
	,dir = Math.round(this.rand(robot,0,1)) ? 1 : -1
	,deg = this.rand(robot,30,100);
	robot.stop(); // not sure if benefit, but prevent getting stuck on wall
	robot.turn(dir*deg);
}

Robot.prototype.onScannedRobot = function(ev) {
	var robot = ev.robot
	,robotHq = this.registerRobot(robot)
	if (!this.isAlly(ev.robot,ev.scannedRobot)) {
		this.foundEnemy(robot,ev.scannedRobot);
		robot.stop();
		robotHq.stoppedToFire = false;
		if (settings.switchRotationOnScan)
			this.switchCannonRotation(robot);
	} else {
		robotHq.dontFire = 1;
	}
}

Robot.prototype.onHitByBullet = function(ev) {
	var robot = ev.robot
	,robotHq = this.registerRobot(robot)
	,deg = ev.bearing+robot.cannonRelativeAngle
	// todo: confirm this works
	//robot.log('SHOT!',ev.bearing,robot.cannonRelativeAngle,deg); 
	robotHq.rotateCannonDir = deg > 0 ? 1 : -1;

	if (robot.availableDisappears) {
		robot.disappear();
		/*robot.stop();
		robot.turn(deg/10);*/
		robot.ahead(50);
	} else if (settings.onHitBurst) {
		robot.move(settings.onHitBurst[1], settings.onHitBurst[0]);
	} else {
		foundEnemy(robot,{
			x: 1/Math.sin(deg)
			,y: 1
		});
	}
}




Robot.prototype.registerRobot = function(robot){
	if (!this.robots[robot.id]) {
		this.robots[robot.id] = {
			rotateCannonDir: robot.id.indexOf('1') == -1 ? -1 : 1
			,jitterDir: robot.id.indexOf('1') == -1 ? -1 : 1
			,resetIndecision: function(){
				this.stubbornTicks = null;
				this.pie = null;
			}
			,fire: function(){
				if (this.dontFire)
					return --this.dontFire;
				this.robot.fire();
			}
		};
	}
	this.robots[robot.id].robot = robot;
	return this.robots[robot.id];
}

Robot.prototype.spawnClones = function(robot){
	for (var i=0;i<robot.availableClones;++i)
		robot.clone();
}

Robot.prototype.isAlly = function(self,target){ 
	return self.id == target.parentId || self.parentId == target.id; 
}

Robot.prototype.isClone = function(robot){
	return robot.parentId !== null;
}

Robot.prototype.foundEnemy = function(self,target){
	var robotHq = this.registerRobot(self);
	robotHq.enemyLocked = target;
	robotHq.enemyLockedUid = this.tick;
	this.enemySpotted = {
		by: self.id
		,x: target.position.x
		,y: target.position.y
	}
}

Robot.prototype.switchCannonRotation = function(robot){
	var robotHq = this.registerRobot(robot);
	robotHq.rotateCannonDir = robotHq.rotateCannonDir == 1 ? -1 : 1;
}

Robot.prototype.aim = function(robot,target){
	var x = target.x-robot.position.x
	,y = target.y-robot.position.y
	if (!x && !y)
		return;
	var deg = Math.atan(y/x)*(180/Math.PI)
	deg -= robot.cannonAbsoluteAngle - (x > 0 ? 180 : 0);
	while (Math.abs(deg) > 180)
		deg > 1 ? deg -= 360 : deg += 360;

	// faster with turn
	deg = deg/2;
	robot.turn(deg);
	// /faster with turn

	this.registerRobot(robot).rotateCannonDir = deg < 1 ? -1 : 1; // continue sweep
	robot.rotateCannon(deg);
}

Robot.prototype.rand = function(robot,min,max){
	// source: https://github.com/ianb/whrandom
	var seed = robot.position.x+robot.position.y+this.tick;
	var x = (seed % 30268) + 1;
	seed = (seed - (seed % 30268)) / 30268;
	var y = (seed % 30306) + 1;
	seed = (seed - (seed % 30306)) / 30306;
	var z = (seed % 30322) + 1;
	seed = (seed - (seed % 30322)) / 30322;
	x = (171 * x) % 30269;
	y = (172 * y) % 30307;
	z = (170 * z) % 30323;
	var r = (x / 30269.0 + y / 30307.0 + z / 30323.0) % 1.0;
 	return r*(max-min)+min; 
}

Robot.prototype.setTimeout = function(cb,t){
	var id = this.lastTimeoutId ? this.lastTimeoutId+1 : 1;
	this.timeouts[id] = {
		end: this.tick+t
		,cb: cb
	}
	return this.lastTimeoutId = id;
}

Robot.prototype.clearTimeout = function(id){
	delete this.timeouts[id];
}

Robot.prototype.checkTimeouts = function(){
	for (var id in this.timeouts) {
		if (this.tick >= this.timeouts[id].end) {
			this.timeouts[id].cb();
			delete this.timeouts[id];
		}
	}
}
