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
```

## Customize version
```
git checkout 923ca5e6c1c3443f7d828915e7f7aab01c6c8d3a  #for version 0.35.2 of superset
git branch 0.35.2.1  #add .1 as the casebook increment
git checkout 0.35.2.1
```

# Create image
```
vi Dockerfile
version=0.35.2.1
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
