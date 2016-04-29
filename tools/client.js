#!/usr/bin/env node
'use strict';
var SQSWorker = require('sqs-worker');
var spawn = require('child_process').spawn;
var winston = require('winston');
require('winston-loggly');

var instanceId = process.env.INSTANCE_ID || 'localhost';
var taskQueueUrl = process.env.QUEUE;

 winston.add(winston.transports.Loggly, {
    token: 'your loggly token',
    subdomain: 'tesera',
    tags: ['djr','djr-instance','djr-instance-'+instanceId],
    json: true
});

winston.log('info', 'client: started with PID: '+process.pid);

function shutdown() {
    winston.log('info', 'client: djr ' + instanceId + ' is shutting down');
    setTimeout(function() {process.exit(0);},5000);
}

var timeout;
function startTimer() {
    timeout = setTimeout(shutdown, 30000);
}

function clearTimer() {
    clearTimeout(timeout);
}

function start(taskQueueUrl) {
    startTimer();
    var params = {
        url: taskQueueUrl,
        region: 'us-east-1'
    };

    winston.log('info', 'client: ' + instanceId + ' started');

    new SQSWorker(params, function worker(task, done) {

        function log(tag, message, level){
            winston.log(level||'info', {
                tag: tag,
                instance: instanceId,
                task: task,
                queue: taskQueueUrl,
                message: 'client: '+message.toString(),
                datetime: new Date()
            });
        }

        log('', 'client: starting task');

        var work = spawn('bash', ['./runner.sh', task]);
        clearTimer();

        work.stdout.on('data', function (data) {
            log('stdout', data, 'debug');
        });

        work.stderr.on('data', function (err) {
            log('stderr', err, 'debug');
        });

        work.on('close', function (code) {
            log('done', 'Job finished on '+instanceId+' with status '+code, 'debug');
            startTimer();
            done(null, !code);
        });
    });
}

winston.log('info', 'client: ' + instanceId + ' listening on task queue ' + taskQueueUrl);

start(taskQueueUrl);
