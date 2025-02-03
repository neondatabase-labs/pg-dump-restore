# PG Dump Restore

A [Docker Image based AWS Lambda function](https://docs.aws.amazon.com/lambda/latest/dg/images-create.html)
to transfer PostgreSQL databases from one connection string to another.

This TypeScript function (code in `main.ts`) calls `pg_dump` on the source Postgres connection string,
and pipes the output into `pg_restore` with the destination Postgres connection string.
When it's done, it makes an HTTP `POST` request to the URL of your choice with a JSON body:

```js
{
  "failed": true|false,
  "output": "the content of stderr of pg_dump and all output of pg_restore"
}
```

The way it works:

1. Use Terraform to deploy an AWS ECR Docker repository.
1. Build and push to it the Docker image that the Lambda function will use.
1. Use Terraform to deploy the Lambda function.
1. Note the outputs:
   - function name
   - AWS credentials to call it
1. Call the Lambda function to transfer a database.

## Build & Deploy

You'll need Terraform and an AWS account with sufficient credentials.

```sh
# Clone this repo
git clone https://github.com/neondatabase-labs/pg-dump-restore.git
cd pg-dump-restore

# Deploy the AWS ECR Docker repository
cd aws/infra
terraform init && terraform apply
# Note the docker image name

cd ../..
docker build --platform linux/amd64 -t <image-name-above> .
# Use `docker login` to log in to AWS ECR
# See https://docs.aws.amazon.com/AmazonECR/latest/userguide/registry_auth.html
docker push <image-name-above>

cd aws/function
terraform init && terraform apply
# Note the outputs
# NB: The AWS Credentials are sensitive.
# To view them you may need to do explicitely:
terraform output instagres_webapp_access_key_id
terraform output instagres_webapp_secret_access_key
```

## Use

You can now invoke this function to trigger a DB transfer via the AWS API:
<https://docs.aws.amazon.com/lambda/latest/api/API_Invoke.html>

Use the following JSON payload:

```json
{
  "srcUrl": "postgresql://...",
  "destUrl": "postgresql://...",
  "callbackUrl": "https://your-web-hook"
}
```

After the transfer, `callbackUrl` will be called (`POST` request) with:

```js
{
  "failed": true|false,
  "output": "the content of stderr of pg_dump and all output of pg_restore"
}
```
