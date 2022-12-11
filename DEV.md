# Setup DEV environment

- Install node.js
    - Windows https://nodejs.org/en/download/
    - Linux `sudo apt update && sudo apt install nodejs npm -y`
- Check node installation `node -v`
- `git submodule init`
- `git submodule update --progress`
- `npm install -g npm`
- `npm install`

## Update three.js

- `git checkout -b r146`
- `cd examples/libs/three.js`
- `git checkout tags/r146 -b 146`
- `cd ../../..`
- `git commit -m "r146"`

# Start examples

- `node serve.js`
- Go to [localhost](http://localhost:8080)
