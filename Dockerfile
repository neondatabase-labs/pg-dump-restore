FROM public.ecr.aws/lambda/nodejs:22 AS build

COPY . .

RUN npm install && npm run build

FROM public.ecr.aws/lambda/nodejs:22

ENV NODE_ENV=production

# The image's WORKDIR is /var/task
COPY --from=build /var/task/build/* /var/task/package.json /var/task/package-lock.json ./

RUN dnf install -y postgresql16 && dnf clean all && rm -rf /var/cache/yum
RUN npm clean-install

CMD [ "main.default" ]
 