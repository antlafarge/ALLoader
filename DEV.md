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

- `cd examples/libs/three.js`
- `git checkout tags/r167 -b r167`
- `cd ../../..`
- `git add .`
- `git commit -m "Update Three.js r167"`
- `git push origin main`

# Start examples

- `node serve.js`
- Go to [localhost](http://localhost:8080)
