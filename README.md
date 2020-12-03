# Casebook Infrastructure

Fork of github.com:amancevice/docker-superset.git (upstrem)

## Initial First time Setup
```
git clone git@github.com:Casecommons/superset.git
cd superset
git remote add upstream https://github.com/amancevice/docker-superset

git remote -v
  origin  git@github.com:Casecommons/superset.git (fetch)
  origin  git@github.com:Casecommons/superset.git (push)
  upstream        https://github.com/amancevice/docker-superset (fetch)
  upstream        https://github.com/amancevice/docker-superset (push)

git checkout master
git merge upstream/master
```

## Update with upstream
```
git fetch upstream
git fetch upstream --tags
git ls-remote --tags https://github.com/amancevice/docker-superset
```

## Customize version
```
# note: 0.35.2.x x is casebook revision
# version can be found from: 
#   https://github.com/amancevice/docker-superset/blob/2020.12.1/Makefile
#   SUPERSET_VERSION := 0.38.0
# git checkout tags/2020.12.1 -b 0.38.0.1 2020.12.1 # 2020.12.1 is 0.38.0

revision=1
version=0.38.0.${revision}
old_version=0.37.2.1
amancevice_version=2020.12.1

# git checkout previous version
git checkout ${old_version}
rsync -av custom /tmp
cp README.md Dockerfile /tmp
git fetch --all --tags
git checkout  tags/${amancevice_version} -b ${version}
mv /tmp/custom .
mv /tmp/README.md .
git add custom/*
```

# Create image
```
vi .dockerignore
!custom

vi Dockerfile
  ARG SUPERSET_VERSION=[version]
  and custom build section
docker build -t casebook/superset:${version} .
```

```
issue
-------
11% building 9/18 modules 9 active ...t/superset/assets/src/welcome/index.jsxBr 
92% chunk asset optimization OptimizeCssAssetsWebpackPluginBrowserslist: caniuse-lite is outdated. Please run next command `npm update`
92% chunk asset optimization TerserPluginnpm ERR! code ELIFECYCLE

npm ERR! errno 1
npm ERR! superset@0.35.0 build: `cross-env NODE_OPTIONS=--max_old_space_size=8192 NODE_ENV=production webpack --mode=production --colors --progress`
npm ERR! Exit status 1
npm ERR!
npm ERR! Failed at the superset@0.35.0 build script.
npm ERR! This is probably not a problem with npm. There is likely additional logging output above.

solution
--------
ran out of heap memory for docker
On a MacOSX, click docker icon at top right
preferences > resources > + Memory
Click Apply # will kill running containers
```

## Test image
```
docker ps
docker stop [old_superset_pid]
docker run -d  -p 8088:8088 casebook/superset:${version}
docker ps
docker exec -it [new_superset_pid] sh
```

Open in a browser: http://localhost:8088

## Push image to Docker Hub
Requires Docker Hub login to Casebook Group
```
docker login -u [username]
docker tag casebook/superset:${version} casebook/superset:latest
docker push casebook/superset
```
