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
# git checkout -b 0.35.2.1 2020.1.15 # 2020.1.15 is 0.35.2

git checkout -b 0.37.2.1 2020.9.28 # 2020.9.28 is 0.37.2

```

# Create image
```
vi .dockerignore
!custom

vi Dockerfile
version=0.37.2.1
docker build -t casebook/superset:${version} .
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
