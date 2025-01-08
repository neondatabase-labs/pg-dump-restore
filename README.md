# PG Dump Restore

A Lambda function to move Databases around.

## Build & Deploy

```sh
cd aws/infra
terraform init && terraform apply
# note the docker image name

cd ../..
docker build --platform linux/amd64 -t <image-name-above> .
# docker login to AWS ECR
docker push <image-name-above>


cd aws/function
terraform init && terraform apply
```
