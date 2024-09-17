import * as http from 'http';
import * as fs from 'fs';
import * as path from 'path';

var verbose = false;

http.createServer(function (request, response) {
    var ip = (request.headers['x-forwarded-for'] || request.socket.remoteAddress);
    console.log('[' + (new Date()).toISOString() + '] IP[' + ip + ']\trequested ' + request.url);

    let filePath = '.' + request.url;
    if (filePath.includes('?')) {
        filePath = filePath.split('?')[0];
    }
    if (filePath == './') {
        filePath = './index.html';
    }
    if (verbose) {
        console.log("\tfilePath=" + filePath);
    }

    var extname = path.extname(filePath).split('?')[0];
    if (verbose) {
        console.log("\textname=" + extname);
    }

    var contentType = 'text/html';
    switch (extname) {
        case '.htm':
        case '.html':
            contentType = 'text/html';
            break;
        case '.js':
            contentType = 'text/javascript';
            break;
        case '.css':
            contentType = 'text/css';
            break;
        case '.json':
            contentType = 'application/json';
            break;
        case '.png':
            contentType = 'image/png';
            break;
        case '.jpg':
            contentType = 'image/jpg';
            break;
        case '.wav':
            contentType = 'audio/wav';
            break;
        default:
            contentType = 'text/plain';
            break;
    }

    if (verbose) {
        console.log("\tcontentType=" + contentType);
    }

    fs.readFile(filePath, function (error, content) {
        if (error) {
            console.error(error);
            if (error.code == 'ENOENT') {
                fs.readFile('./404.html', function (error, content) {
                    response.writeHead(200, { 'Content-Type': contentType });
                    response.end(content, 'utf-8');
                });
            }
            else {
                response.writeHead(500);
                response.end('Sorry, check with the site admin for error: ' + error.code + ' ..\n');
                response.end();
            }
        }
        else {
            response.writeHead(200, { 'Content-Type': contentType });
            response.end(content, 'utf-8');
        }
    });
}).listen(8080);

console.log('Server running at http://127.0.0.1:8080');
